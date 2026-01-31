import jwt
import datetime
from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
from django.http import JsonResponse

# Simple Secret for MVP (In prod use settings.SECRET_KEY)
JWT_SECRET = getattr(settings, 'SECRET_KEY', 'sentinel_jobs_secret_key_mvp')

def hash_password(password: str) -> str:
    return make_password(password)

def verify_password(password: str, encoded: str) -> bool:
    return check_password(password, encoded)

def generate_token(account_id: str) -> str:
    payload = {
        "sub": account_id,
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=7) # Long lived for MVP
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")

def decode_token(token: str):
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def jobs_auth_required(func):
    """Decorator to enforce Jobs Module Auth."""
    def wrapper(request, *args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith("Bearer "):
            return JsonResponse({"error": "Unauthorized", "code": "no_token"}, status=401)
        
        token = auth_header.split(" ")[1]
        payload = decode_token(token)
        if not payload:
            return JsonResponse({"error": "Unauthorized", "code": "invalid_token"}, status=401)
            
        # Attach account_id to request
        request.jobs_account_id = payload['sub']
        return func(request, *args, **kwargs)
    return wrapper

def employer_required(func):
    """Decorator to enforce Employer role. Must be used AFTER @jobs_auth_required."""
    def wrapper(request, *args, **kwargs):
        from .db_models import JobsDAO
        account = JobsDAO.get_account(request.jobs_account_id)
        if not account:
            return JsonResponse({"error": "Account not found"}, status=404)
        roles = account.get("roles", {})
        if not roles.get("employer"):
            return JsonResponse({"error": "Employer role required"}, status=403)
        request.jobs_account = account
        return func(request, *args, **kwargs)
    return wrapper

def worker_required(func):
    """Decorator to enforce Worker role. Must be used AFTER @jobs_auth_required."""
    def wrapper(request, *args, **kwargs):
        from .db_models import JobsDAO
        account = JobsDAO.get_account(request.jobs_account_id)
        if not account:
            return JsonResponse({"error": "Account not found"}, status=404)
        roles = account.get("roles", {})
        if not roles.get("worker"):
            return JsonResponse({"error": "Worker role required"}, status=403)
        request.jobs_account = account
        return func(request, *args, **kwargs)
    return wrapper
