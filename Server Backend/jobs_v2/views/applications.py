# Jobs v2 - Applications & Messaging Views
# Handles Application Lifecycle and Chat

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from ..models import JobsDB
from .auth import auth_required, employer_required



@csrf_exempt
@auth_required
def get_application_details(request, application_id):
    """GET /api/jobs_v2/applications/<app_id>"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
        
    try:
        app = JobsDB.get_application(application_id)
        if not app:
            return JsonResponse({"error": "Application not found"}, status=404)
        
        job = JobsDB.get_post(app["job_id"])
        
        # Check permissions
        is_applicant = app["worker_id"] == request.jobs_user_id
        is_employer = False
        if job:
             is_employer = job.get("employer_id") == request.jobs_user_id
        
        if not (is_applicant or is_employer):
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        # Enrich Data
        if is_employer:
            worker = JobsDB.get_user(app["worker_id"])
            if worker:
                app["worker_name"] = f"{worker.get('real_name_first')} {worker.get('real_name_last')}"
            else:
                app["worker_name"] = "Unknown Worker"
        
        # Add Job Snapshot
        if job:
            app["job_snapshot"] = {
                "title": job.get("category"),
                "description": job.get("description"),
                "pay": job.get("pay_range"),
                "status": job.get("status")
            }
        else:
             app["job_snapshot"] = {
                "title": "Unknown Job (Deleted)",
                "description": "",
                "pay": "",
                "status": "deleted"
            }
        
        return JsonResponse({"status": "success", "application": app})
        
    except Exception as e:
        # import traceback
        # traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def get_messages(request, application_id):
    """GET /api/jobs_v2/applications/<app_id>/messages"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
        
    try:
        app = JobsDB.get_application(application_id)
        if not app:
            return JsonResponse({"error": "Application not found"}, status=404)
        
        # Check access
        job = JobsDB.get_post(app["job_id"])
        
        is_applicant = app["worker_id"] == request.jobs_user_id
        is_employer = False
        if job:
            is_employer = job.get("employer_id") == request.jobs_user_id
        
        # If job deleted, maybe allow applicant to see history? 
        # But if no job, we can't verify employer.
        # Assuming applicant can always see.
        
        if not (is_applicant or is_employer):
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        messages = JobsDB.get_messages(application_id)
        
        # Cache user lookups
        user_cache = {}
        employer_id = job.get("employer_id") if job else None
        
        # Enrich and serialize
        for m in messages:
            if m.get('created_at'): m['created_at'] = m['created_at'].isoformat()
            if m.get('read_at'): m['read_at'] = m['read_at'].isoformat()
            
            # Add sender info
            sender_id = m.get('sender_id')
            if sender_id and sender_id not in user_cache:
                user_cache[sender_id] = JobsDB.get_user(sender_id)
            
            sender = user_cache.get(sender_id)
            if sender:
                m['sender_name'] = f"{sender.get('real_name_first', '')} {sender.get('real_name_last', '')}".strip() or 'Unknown'
                m['sender_photo_url'] = sender.get('photo_url')
            else:
                m['sender_name'] = 'Unknown'
                m['sender_photo_url'] = None
            
            m['is_employer'] = sender_id == employer_id
            
        return JsonResponse({"status": "success", "messages": messages})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def mark_messages_read(request, application_id):
    """POST /api/jobs_v2/applications/<app_id>/messages/read"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
        
    try:
        app = JobsDB.get_application(application_id)
        if not app:
            return JsonResponse({"error": "Application not found"}, status=404)
        
        # Check access
        job = JobsDB.get_post(app["job_id"])
        is_applicant = app["worker_id"] == request.jobs_user_id
        is_employer = job.get("employer_id") == request.jobs_user_id if job else False
        
        if not (is_applicant or is_employer):
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        JobsDB.mark_messages_read(application_id, request.jobs_user_id)
        
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def send_message(request, application_id):
    """POST /api/jobs_v2/applications/<app_id>/messages"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
        
    try:
        data = json.loads(request.body)
        content = data.get("content", "")
        image_url = data.get("image_url")  # Optional photo attachment
        
        if not content and not image_url:
            return JsonResponse({"error": "Content or image required"}, status=400)
            
        app = JobsDB.get_application(application_id)
        if not app:
            return JsonResponse({"error": "Application not found"}, status=404)
            
        # Check permissions
        job = JobsDB.get_post(app["job_id"])
        is_applicant = app["worker_id"] == request.jobs_user_id
        is_employer = job.get("employer_id") == request.jobs_user_id
        
        if not (is_applicant or is_employer):
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        # Check if messaging is allowed (status check)
        if not app.get("allow_messaging", False):
             # Exception: Employer can always send? No, stick to spec.
             # "Pending should be option for employer to approve... in order for communications to begin"
             # So if not pending/accepted, fail.
             return JsonResponse({"error": "Messaging not enabled. Status must be Pending/Approved."}, status=403)
             
        msg_id = JobsDB.send_message(application_id, request.jobs_user_id, content, image_url)
        
        return JsonResponse({"status": "success", "message_id": msg_id})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def delete_message(request, message_id):
    """DELETE /api/jobs_v2/messages/<msg_id>"""
    if request.method != "DELETE":
        return JsonResponse({"error": "DELETE required"}, status=405)
        
    try:
        success, error = JobsDB.delete_message(message_id, request.jobs_user_id)
        if not success:
            return JsonResponse({"error": error}, status=400)
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@employer_required
def update_status(request, application_id):
    """POST /api/jobs_v2/applications/<app_id>/status"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
        
    try:
        data = json.loads(request.body)
        status = data.get("status") # pending, accepted, declined
        if status not in ["pending", "accepted", "declined"]:
            return JsonResponse({"error": "Invalid status"}, status=400)
            
        app = JobsDB.get_application(application_id)
        job = JobsDB.get_post(app["job_id"])
        
        if job.get("employer_id") != request.jobs_user_id:
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        JobsDB.update_application_status(application_id, status)
        
        # If accepted, mark job as filled? Spec says "Approved means... fully contractual".
        # Does it close the job? Maybe multi-hire?
        # Let's keep job logic separate for now (assign_worker endpoint does that).
        # But this endpoint is for status flow steps.
        
        return JsonResponse({"status": "success", "new_status": status})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def get_inbox(request):
    """GET /api/jobs_v2/inbox"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
        
    try:
        conversations = JobsDB.get_inbox_conversations(request.jobs_user_id)
        
        # Serialize dates
        for c in conversations:
            if c.get("updated_at"): c["updated_at"] = c["updated_at"].isoformat()
            if c.get("last_message_at"): c["last_message_at"] = c["last_message_at"].isoformat()
            
        return JsonResponse({"status": "success", "conversations": conversations})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
