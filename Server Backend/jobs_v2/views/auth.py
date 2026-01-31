# Jobs v2 - Authentication Views (Strict Spec)
# Enforces Real Identity & Trust Scoring

import json
import jwt
import hashlib
import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from functools import wraps

from ..models import JobsDB

# --- CONFIG ---
JWT_SECRET = "sentinel-jobs-v2-strict-secret"  # TODO: Move to env
JWT_EXPIRY_DAYS = 7


# =============================================================================
# HELPERS
# =============================================================================

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


def generate_token(account_id: str) -> str:
    payload = {
        "sub": account_id,
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=JWT_EXPIRY_DAYS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def verify_token(token: str) -> str | None:
    """Returns account_id if valid, None otherwise."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload.get("sub")
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None


def auth_required(fn):
    """Decorator to require valid JWT token & active user status."""
    @wraps(fn)
    def wrapper(request, *args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return JsonResponse({"error": "Missing token"}, status=401)
        
        token = auth_header[7:]
        account_id = verify_token(token)
        if not account_id:
            return JsonResponse({"error": "Invalid token"}, status=401)
        
        # Attach user to request
        user = JobsDB.get_user(account_id)
        if not user:
            return JsonResponse({"error": "Account not found"}, status=404)
        
        if user.get("status") == "banned":
            return JsonResponse({"error": "Account banned", "reason": user.get("ban_reason")}, status=403)
        
        request.jobs_user = user
        request.jobs_user_id = account_id
        return fn(request, *args, **kwargs)
    return wrapper


def employer_required(fn):
    """Decorator to require verified employer role (Trust Gate)."""
    @wraps(fn)
    @auth_required
    def wrapper(request, *args, **kwargs):
        user = request.jobs_user
        if user.get("role") != "employer":
            return JsonResponse({"error": "Employer access required"}, status=403)
            
        # Strict Verification Gate: Check Trust Score
        # MVP: Trust Score >= 80 implies verified, or explicit check if we added a flag
        # For this spec, we rely on the Server Authority. 
        # New accounts start at 50. Admin verification boosts to 100.
        if user.get("trust_score", 0) < 80:
             return JsonResponse({
                "error": "Employer verification pending",
                "status": "pending_verification",
                "message": "Your account is under review. Please wait for admin verification."
            }, status=403)
            
        return fn(request, *args, **kwargs)
    return wrapper


def worker_required(fn):
    """Decorator to require worker role."""
    @wraps(fn)
    @auth_required
    def wrapper(request, *args, **kwargs):
        if request.jobs_user.get("role") != "worker":
            return JsonResponse({"error": "Worker access required"}, status=403)
        return fn(request, *args, **kwargs)
    return wrapper


# =============================================================================
# ENDPOINTS
# =============================================================================

@csrf_exempt
def register(request):
    """POST /api/jobs_v2/auth/register"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        
        # Strict Fields
        email = data.get("email", "").strip().lower()
        password = data.get("password", "")
        phone = data.get("phone", "").strip() # E.164
        real_name_first = data.get("real_name_first", "").strip()
        real_name_last = data.get("real_name_last", "").strip()
        role = data.get("role", "worker")
        
        # Validation
        if not email or not password or not phone or not real_name_first:
            return JsonResponse({
                "error": "Missing required fields: email, password, phone, real_name_first"
            }, status=400)
            
        if role not in ("worker", "employer"):
            return JsonResponse({"error": "Invalid role"}, status=400)
        
        # Check uniqueness (Server Authoritative)
        if JobsDB.get_user_by_email(email):
            return JsonResponse({"error": "Email already registered"}, status=409)
        if JobsDB.get_user_by_phone(phone):
            return JsonResponse({"error": "Phone number already registered"}, status=409)
        
        # Create User (Trust Score initialized to 50)
        account_id = JobsDB.create_user(
            role=role,
            email=email,
            phone=phone,
            real_name_first=real_name_first,
            real_name_last=real_name_last,
            password_hash=hash_password(password),
            device_hash=data.get("device_hash") # Optional for MVP prevention
        )
        
        token = generate_token(account_id)
        JobsDB.log(account_id, "register", "user", account_id, {"role": role})
        
        # Employer Gate Response
        if role == "employer":
            return JsonResponse({
                "status": "pending_verification",
                "message": "Account created. Verification required before posting.",
                "token": token,
                "account_id": account_id
            })
        
        return JsonResponse({
            "status": "success",
            "token": token,
            "account_id": account_id
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def login(request):
    """POST /api/jobs_v2/auth/login"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        email = data.get("email", "").strip().lower()
        password = data.get("password", "")
        
        user = JobsDB.get_user_by_email(email)
        if not user:
            return JsonResponse({"error": "Invalid credentials"}, status=401)
        
        if user.get("password_hash") != hash_password(password):
            return JsonResponse({"error": "Invalid credentials"}, status=401)
        
        if user.get("status") == "banned":
             return JsonResponse({
                 "error": "Account banned",
                 "reason": user.get("ban_reason")
             }, status=403)
        
        token = generate_token(user["account_id"])
        
        # Update Location if provided (Strict Tracking)
        if "location" in data:
            loc = data["location"]
            JobsDB.update_user_location(
                user["account_id"], 
                loc.get("lat"), 
                loc.get("lon"), 
                loc.get("accuracy", 0)
            )
            
        JobsDB.log(user["account_id"], "login", "user", user["account_id"])
        
        return JsonResponse({
            "status": "success",
            "token": token,
            "account_id": user["account_id"],
            "role": user.get("role"),
            "trust_score": user.get("trust_score", 50),
            "verified": user.get("trust_score", 0) >= 80 # Derived verification status
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@auth_required
def get_profile(request):
    """GET /api/jobs_v2/auth/profile"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    user = request.jobs_user.copy()
    user["verified"] = user.get("trust_score", 0) >= 80
    
    return JsonResponse({"status": "success", "profile": user})


@csrf_exempt
@auth_required
def update_profile(request):
    """POST /api/jobs_v2/auth/profile"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        
        # Allowed fields to update (Strict)
        # For now, maybe just skills or display name? Real name/Phone shouldn't change easily.
        # Let's allowed minimal updates or just pass for MVP if not strictly required.
        # jobs_users schema handles updates? 
        # Models.py doesn't have explicit update_user method but we can add or use direct db access.
        # But wait, models.py DOES NOT have update_user. I need to add that or skip.
        # Let's just log and return updated for now to satisfy import, or implement direct DB update here.
        
        # Simple implementation using JobsDB._db() for MVP update
        updates = {}
        if "skills" in data:
            updates["skills"] = data["skills"]
        if "urgency" in data:
            updates["urgency"] = data["urgency"]
        if "notification_settings" in data:
            updates["notification_settings"] = data["notification_settings"]
        if "messaging_settings" in data:
            updates["messaging_settings"] = data["messaging_settings"]
            
        if updates:
            JobsDB._db().jobs_users.update_one(
                {"account_id": request.jobs_user_id},
                {"$set": updates}
            )
            JobsDB.log(request.jobs_user_id, "update_profile", "user", request.jobs_user_id)
        
        return JsonResponse({"status": "updated"})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def logout(request):
    """POST /api/jobs_v2/auth/logout"""
    # Stateless JWT - just log it if we have context, but without auth_required we might not know who.
    # If client sends token, we could decode, but strictly it's client side.
    return JsonResponse({"status": "logged_out"})


@csrf_exempt
@auth_required
def upgrade_to_employer(request):
    """POST /api/jobs_v2/auth/upgrade_to_employer
    
    Allows a verified Worker to upgrade to Employer by providing organization details.
    """
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        user = request.jobs_user
        
        # Must currently be a worker
        if user.get("role") != "worker":
            return JsonResponse({"error": "Already an employer or invalid role"}, status=400)
        
        data = json.loads(request.body)
        
        # Required fields
        org_name = data.get("organization_name", "").strip()
        org_type = data.get("organization_type", "").strip()
        
        if not org_name or not org_type:
            return JsonResponse({"error": "Organization name and type required"}, status=400)
        
        # Update user to employer with org info
        # New employers start with trust_score 50 (pending verification)
        updates = {
            "role": "employer",
            "organization": {
                "name": org_name,
                "type": org_type
            },
            "trust_score": 50  # Reset to pending for employer verification
        }
        
        JobsDB._db().jobs_users.update_one(
            {"account_id": request.jobs_user_id},
            {"$set": updates}
        )
        
        JobsDB.log(request.jobs_user_id, "upgrade_to_employer", "user", request.jobs_user_id)
        
        return JsonResponse({
            "status": "success",
            "message": "Upgraded to Employer. Pending verification.",
            "role": "employer",
            "verified": False
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
