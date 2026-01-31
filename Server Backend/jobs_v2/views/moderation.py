# Jobs v2 - Moderation & Safety Views
# Handling reports and trust signals

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from ..models import JobsDB
from .auth import auth_required
from .admin import admin_auth

# =============================================================================
# USER REPORTING
# =============================================================================

@csrf_exempt
@auth_required
def post_report(request):
    """POST /api/jobs_v2/report"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        target_type = data.get("target_type")
        target_id = data.get("target_id")
        reason_code = data.get("reason_code")
        reason_text = data.get("reason_text")
        
        if not all([target_type, target_id, reason_code]):
            return JsonResponse({
                "error": "Missing required fields: target_type, target_id, reason_code"
            }, status=400)
            
        if target_type not in ("user", "job"):
             return JsonResponse({"error": "Invalid target_type"}, status=400)

        # Call Model Logic
        report_id = JobsDB.create_report(
            reporter_id=request.jobs_user_id,
            target_type=target_type,
            target_id=target_id,
            reason_code=reason_code,
            reason_text=reason_text
        )
        
        if not report_id:
             return JsonResponse({
                 "error": "Report already submitted for this target today."
             }, status=409)
             
        return JsonResponse({
            "status": "success",
            "report_id": report_id
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =============================================================================
# ADMIN MODERATION
# =============================================================================

@csrf_exempt
@admin_auth
def get_admin_reports(request):
    """GET /api/jobs_v2/admin/reports"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    db = JobsDB._db()
    # Fetch latest 50 reports
    cursor = db.jobs_reports.find({}, {"_id": 0}).sort("created_at", -1).limit(50)
    reports = list(cursor)
    
    return JsonResponse({
        "status": "success",
        "count": len(reports),
        "reports": reports
    })
