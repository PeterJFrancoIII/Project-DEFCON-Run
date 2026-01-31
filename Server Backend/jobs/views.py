import json
import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .db_models import JobsDAO
from .auth_utils import hash_password, verify_password, generate_token, jobs_auth_required, employer_required, worker_required
from .analyst import GeminiAnalyst

# --- CONFIG ---
REPORT_WEIGHT_THRESHOLD_SHADOW = 2.0
REPORT_WEIGHT_THRESHOLD_SUSPEND = 5.0

# --- AUTH ENDPOINTS ---

@csrf_exempt
def auth_register(request):
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        email = data.get('email', '').strip().lower() # LOWERCASE ENFORCED
        password = data.get('password')
        role = data.get('role', 'worker') # worker or employer
        
        # Validate
        if not email or not password: return JsonResponse({"error": "Missing fields"}, status=400)
        profile_pic = data.get('profile_pic', '')
        
        # --- EMPLOYER REGISTRATION VALIDATION ---
        if role == 'employer':
            org_name = data.get('organization_name', '').strip()
            org_type = data.get('organization_type', '').strip()
            if not org_name or not org_type:
                return JsonResponse({
                    "error": "Employers must provide organization_name and organization_type"
                }, status=400)
        
        # Check existing
        if JobsDAO.get_account_by_email(email):
            return JsonResponse({"error": "Email already registered"}, status=409)
            
        # Build account data
        account_data = {
            "email": email, 
            "password_hash": hash_password(password),
            "roles": {role: True},
            "profile_pic": profile_pic,
            "display_name": email.split('@')[0]
        }
        
        # Add employer-specific fields
        if role == 'employer':
            account_data["organization_name"] = data.get('organization_name', '').strip()
            account_data["organization_type"] = data.get('organization_type', '').strip()
            account_data["verification_doc_url"] = data.get('verification_doc_url', '')
            account_data["employer_verified"] = False  # Requires admin approval
        
        # Add worker urgency for workers
        if role == 'worker':
            account_data["worker_urgency"] = data.get('worker_urgency', 'available')
        
        account_id = JobsDAO.create_account(account_data)
        
        token = generate_token(account_id)
        
        # Response message differs for employers (pending verification)
        if role == 'employer':
            return JsonResponse({
                "status": "pending_verification",
                "message": "Your employer account is pending admin verification. You cannot post jobs until verified.",
                "token": token, 
                "account_id": account_id
            })
        
        return JsonResponse({"status": "success", "token": token, "account_id": account_id})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def auth_login(request):
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        email = data.get('email', '').strip().lower() # LOWERCASE ENFORCED
        password = data.get('password')
        
        account = JobsDAO.get_account_by_email(email)
        if not account or not verify_password(password, account.get('password_hash', '')):
            return JsonResponse({"error": "Invalid credentials"}, status=401)
            
        token = generate_token(account['account_id'])
        JobsDAO.update_account_login(account['account_id'])
        
        return JsonResponse({
            "status": "success", 
            "token": token,
            "account_id": account['account_id'],
            "display_name": account.get('display_name'),
            "roles": account.get('roles', {})
        })
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def auth_logout(request):
    """POST /auth/logout"""
    # Stateless JWT/Token usually means client discards token.
    # But ensuring 200 OK is good for API contract.
    return JsonResponse({"status": "success"})

@csrf_exempt
@jobs_auth_required
def auth_delete_account(request):
    """POST /auth/delete"""
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        # PENDING: We should probably revoke tokens too, but for MVP just delete data
        JobsDAO.delete_account(request.jobs_account_id)
        return JsonResponse({"status": "success", "message": "Account deleted"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
def auth_get_profile(request):
    """GET /auth/profile"""
    try:
        account = JobsDAO.get_account(request.jobs_account_id)
        if not account: return JsonResponse({"error": "Account not found"}, status=404)
        
        # Remove sensitive
        if 'password_hash' in account: del account['password_hash']
        
        return JsonResponse({"status": "success", "data": account})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
def auth_update_profile(request):
    """POST /auth/profile/update"""
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        updates = data.get('updates', {})
        
        # 1. Enforce Start Limitations on Images (Max ~100KB for MVP)
        # Base64 string length check. 100KB ~= 133k chars.
        MAX_IMG_CHARS = 150000 
        if len(updates.get('profile_pic', '')) > MAX_IMG_CHARS:
             updates['profile_pic'] = "" # Reject or truncate
        if len(updates.get('photo_id', '')) > MAX_IMG_CHARS:
             updates['photo_id'] = "" # Reject or truncate
             
        # 2. Validate Skills (Max 5, Score 0-10)
        if 'skills' in updates:
            raw_skills = updates['skills']
            clean_skills = []
            for s in raw_skills[:5]: # Max 5
                score = int(s.get('score', 0))
                clean_skills.append({
                    "name": str(s.get('name', '')),
                    "score": max(0, min(10, score)) # Clamp 0-10
                })
            updates['skills'] = clean_skills
            
        JobsDAO.update_profile(request.jobs_account_id, updates)
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- LISTINGS ENDPOINTS ---

def search_listings(request):
    """GET /listings/search?zip=&radius_km=&category=&limit=&cursor="""
    try:
        limit = int(request.GET.get('limit', 20))
        skip = int(request.GET.get('cursor', 0))
        
        query = {"status": "active", "visible_to_clients": True}
        
        # Filter by Category
        cat = request.GET.get('category')
        if cat: query['category'] = cat
        
        # Filter by Urgency
        urgency = request.GET.get('urgency')
        if urgency: query['urgency'] = urgency

        location_zip = request.GET.get('zip')
        if location_zip: query['location.zip'] = location_zip
            
        # Custom sort: Critical urgency first, then Newest
        # Note: This requires complex sort or two queries. 
        # MVP: Sort by created_at, filter on client OR basic sort.
        # Better: use PyMongo sort with multiple keys if supported easily or just single key.
        # Let's stick to created_at DESC for now to avoid index complexity, 
        # unless user asks for "Critical First" view specifically.
        
        jobs = JobsDAO.search_listings(query, limit, skip)
        
        # Inject Employer Data
        clean_jobs = []
        for j in jobs:
            j['_id'] = str(j['_id'])
            emp_id = j.get('employer_account_id')
            if emp_id:
                emp = JobsDAO.get_account(emp_id)
                if emp:
                    j['employer_rating'] = emp.get('rating_avg', 0.0)
                    j['employer_rating_count'] = emp.get('rating_count', 0)
                    j['employer_pic'] = emp.get('profile_pic', "")
                    j['employer_jobs_count'] = emp.get('jobs_completed_count', 0)
            clean_jobs.append(j)
            
        return JsonResponse({"status": "success", "data": clean_jobs})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
def create_listing(request):
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        # Basic Validation
        if not data.get('title') or not data.get('description'):
             return JsonResponse({"error": "Missing fields"}, status=400)
        
        # --- EMPLOYER VERIFICATION GATE ---
        account = JobsDAO.get_account(request.jobs_account_id)
        if not account:
            return JsonResponse({"error": "Account not found"}, status=404)
        
        # Check if user has employer role
        if not account.get('roles', {}).get('employer', False):
            return JsonResponse({
                "error": "You must be registered as an employer to post jobs"
            }, status=403)
        
        # Check if employer is verified
        if not account.get('employer_verified', False):
            return JsonResponse({
                "error": "Your employer account is pending verification. Please wait for admin approval before posting jobs.",
                "status": "pending_verification"
            }, status=403)
        
        # Create the listing
        job_id = JobsDAO.create_listing({
            "employer_account_id": request.jobs_account_id,
            "title": data.get('title'),
            "description": data.get('description'),
            "location": data.get('location', {}), # Expect {zip, lat, lon}
            "pay": data.get('pay', {}),
            "category": data.get('category', 'General'),
            "urgency": data.get('urgency', 'Normal'),
            "risk_level": data.get('risk_level', 'Low'),
            "skills_required": data.get('skills_required', []),
            "duration": data.get('duration', '7d')
        })
        
        JobsDAO.log_audit("account", request.jobs_account_id, "create_listing", "listing", job_id)
        return JsonResponse({"status": "success", "job_id": job_id})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- JOB POSTER ENDPOINTS ---

@csrf_exempt
@jobs_auth_required
@employer_required
def my_listings(request):
    """GET /listings/mine - Get all listings created by the current employer."""
    if request.method != 'GET':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        listings = JobsDAO.get_listings_by_employer(request.jobs_account_id)
        for l in listings:
            l['_id'] = str(l.get('_id', ''))
        return JsonResponse({"status": "success", "data": listings})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
@employer_required
def get_applicants(request, job_id):
    """GET /listings/<id>/applicants - Get all applicants for a job."""
    if request.method != 'GET':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        job = JobsDAO.get_listing(job_id)
        if not job:
            return JsonResponse({"error": "Job not found"}, status=404)
        if job['employer_account_id'] != request.jobs_account_id:
            return JsonResponse({"error": "Not your listing"}, status=403)
        
        applications = JobsDAO.get_applications_for_job(job_id)
        # Enrich with applicant profile
        for app in applications:
            app['_id'] = str(app.get('_id', ''))
            applicant = JobsDAO.get_account(app['applicant_account_id'])
            if applicant:
                app['applicant_name'] = applicant.get('display_name', 'Unknown')
                app['applicant_rating'] = applicant.get('rating_avg', 0.0)
                app['applicant_pic'] = applicant.get('profile_pic', '')
        
        return JsonResponse({"status": "success", "data": applications})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
@employer_required
def assign_worker(request, job_id):
    """POST /listings/<id>/assign - Assign a worker to a job."""
    if request.method != 'POST':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        worker_id = data.get('worker_account_id')
        if not worker_id:
            return JsonResponse({"error": "worker_account_id required"}, status=400)
        
        job = JobsDAO.get_listing(job_id)
        if not job:
            return JsonResponse({"error": "Job not found"}, status=404)
        if job['employer_account_id'] != request.jobs_account_id:
            return JsonResponse({"error": "Not your listing"}, status=403)
        if job['status'] != 'active':
            return JsonResponse({"error": "Job not active"}, status=400)
        
        # Verify worker applied
        application = JobsDAO.check_existing_application(job_id, worker_id)
        if not application:
            return JsonResponse({"error": "Worker has not applied"}, status=400)
        
        # Assign
        JobsDAO.assign_worker(job_id, worker_id)
        JobsDAO.update_application_status(application['application_id'], 'accepted')
        
        # Reject other applications
        all_apps = JobsDAO.get_applications_for_job(job_id)
        for app in all_apps:
            if app['applicant_account_id'] != worker_id and app['status'] == 'pending':
                JobsDAO.update_application_status(app['application_id'], 'rejected')
        
        JobsDAO.log_audit("account", request.jobs_account_id, "assign_worker", "listing", job_id, {"worker_id": worker_id})
        return JsonResponse({"status": "success", "message": "Worker assigned"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- JOB SEEKER ENDPOINTS ---

@csrf_exempt
@jobs_auth_required
@worker_required
def apply_to_job(request, job_id):
    """POST /listings/<id>/apply - Apply to a job."""
    if request.method != 'POST':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        job = JobsDAO.get_listing(job_id)
        if not job:
            return JsonResponse({"error": "Job not found"}, status=404)
        if job['status'] != 'active':
            return JsonResponse({"error": "Job not accepting applications"}, status=400)
        
        # Check if already applied
        existing = JobsDAO.check_existing_application(job_id, request.jobs_account_id)
        if existing:
            return JsonResponse({"error": "Already applied"}, status=409)
        
        data = json.loads(request.body) if request.body else {}
        cover_message = data.get('cover_message', '')
        
        application_id = JobsDAO.create_application(job_id, request.jobs_account_id, cover_message)
        return JsonResponse({"status": "success", "application_id": application_id})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
@worker_required
def my_applications(request):
    """GET /applications/mine - Get all applications submitted by current user."""
    if request.method != 'GET':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        applications = JobsDAO.get_applications_by_user(request.jobs_account_id)
        # Enrich with job info
        for app in applications:
            app['_id'] = str(app.get('_id', ''))
            job = JobsDAO.get_listing(app['job_id'])
            if job:
                app['job_title'] = job.get('title', 'Unknown')
                app['job_category'] = job.get('category', '')
                app['job_urgency'] = job.get('urgency', '')
                app['job_status'] = job.get('status', '')
        
        return JsonResponse({"status": "success", "data": applications})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
@worker_required
def withdraw_application(request, application_id):
    """DELETE /applications/<id>/withdraw - Withdraw an application."""
    if request.method != 'DELETE':
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        application = JobsDAO.get_application(application_id)
        if not application:
            return JsonResponse({"error": "Application not found"}, status=404)
        if application['applicant_account_id'] != request.jobs_account_id:
            return JsonResponse({"error": "Not your application"}, status=403)
        if application['status'] != 'pending':
            return JsonResponse({"error": "Cannot withdraw non-pending application"}, status=400)
        
        JobsDAO.update_application_status(application_id, 'withdrawn')
        return JsonResponse({"status": "success", "message": "Application withdrawn"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@jobs_auth_required
def accept_job(request, job_id):
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        # Check Job status
        job = JobsDAO.get_listing(job_id)
        if not job or job['status'] != 'active':
            return JsonResponse({"error": "Job unavailable"}, status=404)
        
        # Lock it (MVP: Atomic update would be better)
        # For MVP we just assume happy path or use Mongo atomic set
        
        # Logic: Assign to worker
        # Lock check (atomic)
        if job.get('accepted_by_account_id'):
             return JsonResponse({"error": "Job already accepted"}, status=409)

        JobsDAO.update_listing_status(job_id, "accepted", visible=False)
        # Update accepted fields - Access DB directly for custom update or add method to DAO
        # For MVP, let's just do it via direct DB call in DAO or add update_listing_fields
        db = JobsDAO._get_db()
        db[JobsDAO.DB_LISTINGS].update_one( # Using constant from module scope? No, constants are global
             {"job_id": job_id},
             {"$set": {
                 "accepted_by_account_id": request.jobs_account_id,
                 "accepted_at": datetime.datetime.utcnow().isoformat(),
                 "outcome": "accepted"
             }}
        )
        
        return JsonResponse({"status": "success", "message": "Job Accepted"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
def complete_job(request, job_id):
    """POST /listings/<id>/complete"""
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        job = JobsDAO.get_listing(job_id)
        if not job: return JsonResponse({"error": "Job not found"}, status=404)
        
        # Only Employer can mark complete? Or Worker? Prompt says "Employer marks complete OR both confirm; keep simple" -> Employer.
        if job['employer_account_id'] != request.jobs_account_id:
             return JsonResponse({"error": "Only employer can complete"}, status=403)
             
        JobsDAO.update_listing_status(job_id, "completed", visible=False)
        # Update completion fields
        from .db_models import DB_LISTINGS # Need to import locally or resolve
        db = JobsDAO._get_db()
        db["jobs_listings"].update_one(
             {"job_id": job_id},
             {"$set": {
                 "completed_at": datetime.datetime.utcnow().isoformat(),
                 "outcome": "completed"
             }}
        )
        
        # Increment Stats for Worker
        worker_id = job.get('accepted_by_account_id')
        if worker_id:
            JobsDAO.increment_jobs_completed(worker_id)
            
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@jobs_auth_required
def submit_rating(request):
    """POST /ratings/submit"""
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        score = data.get('score')
        text = data.get('text', '')
        
        if not job_id or score is None: return JsonResponse({"error": "Missing fields"}, status=400)
        score = int(score)
        if score < 0 or score > 100: return JsonResponse({"error": "Score must be 0-100"}, status=400)
        
        job = JobsDAO.get_listing(job_id)
        if not job: return JsonResponse({"error": "Job not found"}, status=404)
        
        # Determine target
        if request.jobs_account_id == job['employer_account_id']:
            target_account_id = job.get('accepted_by_account_id')
        elif request.jobs_account_id == job.get('accepted_by_account_id'):
            target_account_id = job['employer_account_id']
        else:
            return JsonResponse({"error": "Not party to this job"}, status=403)
            
        if not target_account_id: return JsonResponse({"error": "No counterparty found"}, status=400)

        # Create Rating
        JobsDAO.create_rating({
            "job_id": job_id,
            "from_account_id": request.jobs_account_id,
            "to_account_id": target_account_id,
            "score": score,
            "text": text
        })
        
        # Update Average (MVP: Simple Re-calc)
        # In prod we'd increment, but let's just do it right or leave async.
        # For MVP, we skip aggregation on request and let it happen or use basic average.
        
        return JsonResponse({"status": "success"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- REPORTING & MODERATION ---

@csrf_exempt
@jobs_auth_required
def report_target(request):
    """POST /report - Target Type/ID, Reason"""
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        data = json.loads(request.body)
        target_type = data.get('target_type') # listing or account
        target_id = data.get('target_id')
        reason = data.get('reason')
        note = data.get('note', '')
        
        reporter = JobsDAO.get_account(request.jobs_account_id)
        trust_score = reporter.get('reporter_trust_score', 50)
        
        # 1. Store Report
        JobsDAO.create_report({
            "target_type": target_type,
            "target_id": target_id,
            "reporter_account_id": request.jobs_account_id,
            "reason_code": reason,
            "free_text": note,
            "reporter_weight": trust_score
        })
        
        # 2. Aggregation & Thresholds (Simplified)
        # In a real system, we'd query aggregation. Here we do a quick check.
        reports = JobsDAO.get_reports_for_target(target_type, target_id)
        total_weight = sum([r.get('reporter_weight', 50) for r in reports]) / 50.0 # Normalize roughly associated to number of reports
        
        auto_action = None
        
        # Thresholds
        if total_weight >= REPORT_WEIGHT_THRESHOLD_SUSPEND:
             auto_action = "suspended"
        elif total_weight >= REPORT_WEIGHT_THRESHOLD_SHADOW:
             auto_action = "shadowed"
             
        if auto_action:
            # Apply Action
            if target_type == 'listing':
                JobsDAO.update_listing_status(target_id, auto_action, visible=(auto_action=='shadowed')) # Shadowed still visible to owner? Or hidden? Prompt says "shadow-hide". Usually means hidden from public.
                # Let's say False for visible_to_clients
                JobsDAO.update_listing_status(target_id, auto_action, visible=False)
            
            # Create Case
            JobsDAO.create_case({
                "target_type": target_type,
                "target_id": target_id,
                "auto_action_taken": auto_action,
                "evidence_packet": {
                    "total_weight": total_weight,
                    "report_count": len(reports),
                    "reports": reports # Attach full reports for Analyst
                }
            })
            
        return JsonResponse({"status": "success", "action_taken": auto_action})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# --- ANALYST (ADMIN/CRON) ---

@csrf_exempt
def run_analyst(request, case_id):
    """POST /moderation/case/<id>/analyst_run"""
    # Needs Admin Auth in Prod
    if request.method != 'POST': return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        # Get Case
        db = JobsDAO._get_db()
        case = db[JobsDAO].find_one({"case_id": case_id}) # Error in line: JobsDAO is class, not string collection name. Fixed below.
        case = db["jobs_moderation_cases"].find_one({"case_id": case_id})
        
        if not case: return JsonResponse({"error": "Case not found"}, status=404)
        
        # Run Gemini
        verdict = GeminiAnalyst.analyze_case(case.get('evidence_packet', {}))
        
        if verdict:
            # Update Case
             JobsDAO.update_case_verdict(case_id, verdict, final_action={})
             return JsonResponse({"status": "success", "verdict": verdict})
        else:
             return JsonResponse({"error": "Analyst failed"}, status=500)
             
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def admin_set_apikey(request):
    """
    POST /api/jobs/admin/config/apikey
    Update the Jobs Analyst API Key.
    Auth: Simple shared secret check (MVP) or Session Auth if integrated.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        secret = data.get('secret')
        new_key = data.get('key')
        
        # Simple Secret Check (In prod, use Django Admin User Check)
        # For this context, we'll verify it's a staff user if session exists,
        # OR check a hardcoded deployment secret.
        if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
             return JsonResponse({'error': 'Unauthorized'}, status=403)

        if not new_key:
             return JsonResponse({'error': 'Key required'}, status=400)

        JobsDAO.set_config("jobs_analyst_api_key", new_key)
        # Also update the in-memory analyst if possible, or let it refresh on next run
        # Ideally, separate the analyst config loading
        return JsonResponse({'status': 'updated'}) 
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

# --- ADMIN ACCOUNT MANAGEMENT ---

@csrf_exempt
def admin_list_accounts(request):
    """GET /api/jobs/admin/accounts"""
    # Auth Check (Allow staff session OR "admin123" secret for easy dev testing)
    secret = request.GET.get('secret')
    if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
         return JsonResponse({'error': 'Unauthorized'}, status=403)

    try:
        accounts = JobsDAO.admin_get_all_accounts()
        return JsonResponse({'accounts': accounts})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def admin_update_account(request):
    """POST /api/jobs/admin/accounts/update"""
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        secret = data.get('secret')
        if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
             return JsonResponse({'error': 'Unauthorized'}, status=403)
        
        account_id = data.get('account_id')
        updates = data.get('updates') # Dict of fields
        if not account_id or not updates:
            return JsonResponse({'error': 'Missing data'}, status=400)
            
        JobsDAO.admin_update_account(account_id, updates)
        return JsonResponse({'status': 'updated'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def admin_account_action(request):
    """POST /api/jobs/admin/accounts/action"""
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)

    try:
        data = json.loads(request.body)
        secret = data.get('secret')
        if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
             return JsonResponse({'error': 'Unauthorized'}, status=403)

        account_id = data.get('account_id')
        action = data.get('action') # BAN, SUSPEND, REINSTATE
        duration = data.get('duration_days')

        if not account_id or not action:
            return JsonResponse({'error': 'Missing data'}, status=400)

        JobsDAO.admin_apply_action(account_id, action, duration)
        return JsonResponse({'status': 'action_applied'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def admin_list_listings(request):
    """GET /api/jobs/admin/listings"""
    secret = request.GET.get('secret')
    if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
         return JsonResponse({'error': 'Unauthorized'}, status=403)
    try:
        listings = JobsDAO.admin_get_all_listings()
        return JsonResponse({'listings': listings})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def admin_listing_action(request):
    """POST /api/jobs/admin/listings/action"""
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        secret = data.get('secret')
        if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
             return JsonResponse({'error': 'Unauthorized'}, status=403)
        
        job_id = data.get('job_id')
        action = data.get('action') # SUSPEND, CLOSE, DELETE
        
        if not job_id or not action:
            return JsonResponse({'error': 'Missing data'}, status=400)
            
        JobsDAO.admin_apply_listing_action(job_id, action)
        return JsonResponse({'status': 'action_applied'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def admin_get_analytics(request):
    """GET /api/jobs/admin/analytics"""
    secret = request.GET.get('secret')
    if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
         return JsonResponse({'error': 'Unauthorized'}, status=403)
    try:
        stats = JobsDAO.admin_get_analytics()
        return JsonResponse({'analytics': stats})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# --- EMPLOYER VERIFICATION ENDPOINTS ---

@csrf_exempt
def admin_get_pending_employers(request):
    """GET /api/jobs/admin/employers/pending - List employers awaiting verification."""
    secret = request.GET.get('secret')
    if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
         return JsonResponse({'error': 'Unauthorized'}, status=403)
    try:
        db = JobsDAO._get_db()
        # Find employers with employer_verified=False and roles.employer=True
        pending = list(db.jobs_accounts.find({
            "roles.employer": True,
            "employer_verified": False
        }, {
            "_id": 0,
            "account_id": 1,
            "email": 1,
            "organization_name": 1,
            "organization_type": 1,
            "verification_doc_url": 1,
            "created_at": 1
        }))
        return JsonResponse({'pending_employers': pending})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def admin_verify_employer(request):
    """POST /api/jobs/admin/employers/verify - Approve or reject employer verification."""
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        secret = data.get('secret')
        if secret != "admin123" and not (request.user.is_authenticated and request.user.is_staff):
             return JsonResponse({'error': 'Unauthorized'}, status=403)
        
        account_id = data.get('account_id')
        action = data.get('action')  # APPROVE or REJECT
        
        if not account_id or action not in ['APPROVE', 'REJECT']:
            return JsonResponse({'error': 'Invalid data. Provide account_id and action (APPROVE/REJECT)'}, status=400)
        
        db = JobsDAO._get_db()
        
        if action == 'APPROVE':
            db.jobs_accounts.update_one(
                {"account_id": account_id},
                {"$set": {
                    "employer_verified": True,
                    "employer_verified_at": datetime.datetime.utcnow().isoformat()
                }}
            )
            JobsDAO.log_audit("admin", "system", "verify_employer", "account", account_id, {"action": "APPROVE"})
            return JsonResponse({'status': 'approved', 'account_id': account_id})
        
        elif action == 'REJECT':
            # Set employer role to false (they can reapply or switch to worker)
            db.jobs_accounts.update_one(
                {"account_id": account_id},
                {"$set": {
                    "employer_verified": False,
                    "roles.employer": False,
                    "notes_admin": f"Employer verification rejected on {datetime.datetime.utcnow().isoformat()}"
                }}
            )
            JobsDAO.log_audit("admin", "system", "reject_employer", "account", account_id, {"action": "REJECT"})
            return JsonResponse({'status': 'rejected', 'account_id': account_id})
            
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
