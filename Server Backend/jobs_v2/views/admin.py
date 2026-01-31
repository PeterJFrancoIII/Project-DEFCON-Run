# Jobs v2 - Admin Views (Strict Spec)
# Employer verification and analytics

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from ..models import JobsDB

# Simple admin secret for MVP - TODO: Replace with proper auth
ADMIN_SECRET = "sentinel-admin-v2"


# Simple admin secret for MVP - TODO: Replace with proper auth
ADMIN_SECRET = "sentinel-admin-v2"


def admin_auth(fn):
    """Simple admin auth decorator."""
    def wrapper(request, *args, **kwargs):
        secret = request.GET.get("secret") or request.headers.get("X-Admin-Secret")
        if secret != ADMIN_SECRET:
            # Also check Django session auth
            if not (request.user.is_authenticated and request.user.is_staff):
                return JsonResponse({"error": "Admin access required"}, status=403)
        return fn(request, *args, **kwargs)
    return wrapper


# =============================================================================
# EMPLOYER VERIFICATION
# =============================================================================

@csrf_exempt
@admin_auth
def get_pending_employers(request):
    """GET /api/jobs_v2/admin/employers/pending"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    pending = JobsDB.get_pending_employers()
    
    return JsonResponse({
        "status": "success",
        "count": len(pending),
        "employers": pending
    })


@csrf_exempt
@admin_auth
def verify_employer(request):
    """POST /api/jobs_v2/admin/employers/verify"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        account_id = data.get("account_id")
        action = data.get("action")  # "approve" or "reject"
        
        if not account_id or action not in ("approve", "reject"):
            return JsonResponse({
                "error": "account_id and action (approve/reject) required"
            }, status=400)
        
        approved = action == "approve"
        JobsDB.verify_employer(account_id, approved)
        JobsDB.log("admin", f"verify_employer_{action}", "account", account_id)
        
        return JsonResponse({
            "status": "success",
            "action": action,
            "account_id": account_id
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =============================================================================
# ANALYTICS
# =============================================================================

@csrf_exempt
@admin_auth
def get_analytics(request):
    """GET /api/jobs_v2/admin/analytics"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    db = JobsDB._db()
    
    # Updated to Strict Collections: jobs_users, jobs_posts, jobs_applications
    stats = {
        "accounts": {
            "total": db.jobs_users.count_documents({}),
            "workers": db.jobs_users.count_documents({"role": "worker"}),
            "employers": db.jobs_users.count_documents({"role": "employer"}),
            "pending_employers": db.jobs_users.count_documents({"role": "employer", "trust_score": {"$lt": 80}}),
        },
        "listings": {
            "total": db.jobs_posts.count_documents({}),
            "active": db.jobs_posts.count_documents({"status": "active"}),
            "filled": db.jobs_posts.count_documents({"status": "filled"}),
        },
        "applications": {
            "total": db.jobs_applications.count_documents({}),
            "pending": db.jobs_applications.count_documents({"status": "pending"}),
            "accepted": db.jobs_applications.count_documents({"status": "accepted"}),
        }
    }
    
    return JsonResponse({
        "status": "success",
        "analytics": stats
    })



# =============================================================================
# ACCOUNT MANAGEMENT
# =============================================================================

@csrf_exempt
@admin_auth
def get_accounts(request):
    """GET /api/jobs_v2/admin/accounts"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    db = JobsDB._db()
    # Fetch latest 100 accounts
    cursor = db.jobs_users.find({}, {"_id": 0, "password_hash": 0}).sort("created_at", -1).limit(100)
    accounts = list(cursor)
    
    for acc in accounts:
        # Serialize datetime
        if acc.get('created_at'): acc['created_at'] = acc['created_at'].isoformat()
        if acc.get('last_login_at'): acc['last_login_at'] = acc['last_login_at'].isoformat()
        if acc.get('employer_verified_at'): acc['employer_verified_at'] = acc['employer_verified_at'].isoformat()
        if acc.get('worker_urgency_updated_at'): acc['worker_urgency_updated_at'] = acc['worker_urgency_updated_at'].isoformat()
        
        # Calculate validity score for UI
        # V2 Trust is 0-100 (Default 50)
        strikes = acc.get('report_strikes', 0) or 0
        trust = acc.get('trust_score', 50) or 50
        validity = trust - (strikes * 10)
        acc['validity_score'] = max(0, min(100, validity))
        
    return JsonResponse({
        "status": "success",
        "accounts": accounts
    })

@csrf_exempt
@admin_auth
def account_action(request):
    """POST /api/jobs_v2/admin/accounts/action"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
        
    try:
        data = json.loads(request.body)
        account_id = data.get("account_id")
        action = data.get("action") # SUSPEND, BAN, REINSTATE
        
        if not account_id or not action:
            return JsonResponse({"error": "account_id and action required"}, status=400)
            
        db = JobsDB._db()
        updates = {}
        
        if action == "SUSPEND":
            updates = {"status": "suspended"}
        elif action == "BAN":
            updates = {"status": "banned"}
        elif action == "REINSTATE":
            updates = {"status": "active"}
        else:
             return JsonResponse({"error": "Invalid action"}, status=400)
             
        db.jobs_users.update_one({"account_id": account_id}, {"$set": updates})
        JobsDB.log("admin", f"account_{action.lower()}", "account", account_id)
        
        return JsonResponse({"status": "success", "action": action})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =============================================================================
# LISTINGS MANAGEMENT
# =============================================================================

@csrf_exempt
@admin_auth
def get_listings(request):
    """GET /api/jobs_v2/admin/listings"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    db = JobsDB._db()
    # Fetch latest 100 listings
    cursor = db.jobs_posts.find({}, {"_id": 0}).sort("created_at", -1).limit(100)
    listings = list(cursor)
    
    # Serialize datetime
    for l in listings:
        if l.get('created_at'): l['created_at'] = l['created_at'].isoformat()
        if l.get('updated_at'): l['updated_at'] = l['updated_at'].isoformat()
    
    # Enrich with generic data if needed (e.g. employer email)
    # For now, raw dump is fine, frontend handles display
    
    return JsonResponse({
        "status": "success",
        "listings": listings
    })

@csrf_exempt
@admin_auth
def listing_action(request):
    """POST /api/jobs_v2/admin/listings/action"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        job_id = data.get("job_id")
        action = data.get("action") # SUSPEND, DELETE, REINSTATE
        
        if not job_id or not action:
            return JsonResponse({"error": "job_id and action required"}, status=400)
            
        if action == "SUSPEND":
            JobsDB.update_post_status(job_id, "suspended")
        elif action == "DELETE":
            JobsDB.update_post_status(job_id, "removed")
        elif action == "REINSTATE":
            JobsDB.update_post_status(job_id, "active")
        else:
             return JsonResponse({"error": "Invalid action"}, status=400)
             
        JobsDB.log("admin", f"listing_{action.lower()}", "job", job_id)
        
        return JsonResponse({"status": "success", "action": action})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
