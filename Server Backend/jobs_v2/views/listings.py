# Jobs v2 - Listings Views (Strict Spec)
# Server-Authoritative Logic

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from ..models import JobsDB
from .auth import auth_required, employer_required, worker_required


# =============================================================================
# LISTING ENDPOINTS
# =============================================================================

@csrf_exempt
@employer_required
def create_listing(request):
    """POST /api/jobs_v2/listings/create"""
    # Strict Verification Gate is enforced by @employer_required decorator
    # which checks trust_score >= 80
    
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        
        # Mandatory Fields
        title = data.get("title") # Mapped to category/description in strict spec? 
        # Spec says: Category, Pay Type, Pay Range, Start Time, Duration, Location, Desc
        
        category = data.get("category")
        pay_type = data.get("pay_type") # cash | hourly | daily
        pay_range = data.get("pay_range") # {min, max, currency}
        start_time = data.get("start_time")
        duration = data.get("duration")
        description = data.get("description", "")
        
        # Precise Location (Required)
        location = data.get("location") # {lat, lon}
        if not location or "lat" not in location or "lon" not in location:
             return JsonResponse({"error": "Precise location {lat, lon} required"}, status=400)
             
        if not category or not pay_type:
            return JsonResponse({"error": "Category and Pay Type required"}, status=400)

        # Create Post (Strict Schema)
        job_id = JobsDB.create_post(
            employer_id=request.jobs_user_id,
            category=category,
            pay_type=pay_type,
            pay_range=pay_range,
            start_time=start_time,
            duration=duration,
            location=location,
            description=description
        )
        
        JobsDB.log(request.jobs_user_id, "create_post", "job", job_id)
        
        return JsonResponse({
            "status": "success",
            "job_id": job_id
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@auth_required
def search_listings(request):
    """GET /api/jobs_v2/listings/search"""
    # Lazy Load Entrypoint
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    try:
        category = request.GET.get("category")
        lat = float(request.GET.get("lat")) if request.GET.get("lat") else None
        lon = float(request.GET.get("lon")) if request.GET.get("lon") else None
        radius_km = int(request.GET.get("radius_km", 50))
        
        listings = JobsDB.search_posts(
            category=category,
            lat=lat,
            lon=lon,
            radius_km=radius_km
        )
        
        # Enrich with minimal employer info (Trust/Rating)
        for listing in listings:
            employer = JobsDB.get_user(listing.get("employer_id"))
            if employer:
                # Privacy: Only show Organization Name or First Name + L.
                if employer.get("organization", {}).get("name"):
                    name = employer["organization"]["name"]
                else:
                    name = f"{employer.get('real_name_first', '')} {employer.get('real_name_last', '')[:1]}."
                    
                listing["employer_name"] = name
                listing["employer_rating"] = employer.get("rating_score", 0)
                listing["employer_reviews"] = employer.get("review_count", 0)
        
        return JsonResponse({
            "status": "success",
            "count": len(listings),
            "listings": listings
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@auth_required
def get_listing(request, job_id):
    """GET /api/jobs_v2/listings/<job_id>"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    listing = JobsDB.get_post(job_id)
    if not listing:
        return JsonResponse({"error": "Listing not found"}, status=404)
    
    employer = JobsDB.get_user(listing.get("employer_id"))
    if employer:
        if employer.get("organization", {}).get("name"):
            name = employer["organization"]["name"]
        else:
            name = f"{employer.get('real_name_first', '')} {employer.get('real_name_last', '')[:1]}."
        
        listing["employer_name"] = name
        listing["employer_rating"] = employer.get("rating_score", 0)
        listing["employer_reviews"] = employer.get("review_count", 0)
        listing["employer_trust"] = employer.get("trust_score", 50)
    
    return JsonResponse({"status": "success", "listing": listing})


@csrf_exempt
@employer_required
def my_listings(request):
    """GET /api/jobs_v2/listings/mine"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    # Simple find by employer_id (using existing db connection for MVP)
    # TODO: Add specific method in JobsDB if needed, or query directly
    db = JobsDB._db()
    listings = list(db.jobs_posts.find({"employer_id": request.jobs_user_id}, {"_id": 0}))
    
    for listing in listings:
        apps = JobsDB.get_applications_for_job(listing["job_id"])
        listing["application_count"] = len(apps)
    
    return JsonResponse({
        "status": "success",
        "count": len(listings),
        "listings": listings
    })


@csrf_exempt
@auth_required
def get_applied_jobs(request):
    """GET /api/jobs_v2/listings/applied"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    # 1. properties
    db = JobsDB._db()
    
    # 2. Get applications by worker
    apps = list(db.jobs_applications.find({"worker_id": request.jobs_user_id}, {"_id": 0}))
    
    # 3. Enrich with job details
    results = []
    for app in apps:
        job = JobsDB.get_post(app["job_id"])
        if job:
            # Add job details to result
            item = app.copy()
            item["job_title"] = job.get("category", "Job")
            item["employer_id"] = job.get("employer_id")
            item["description"] = job.get("description")
            item["pay_type"] = job.get("pay_type")
            item["pay_range"] = job.get("pay_range")
            results.append(item)
            
    return JsonResponse({
        "status": "success",
        "count": len(results),
        "applications": results
    })


# =============================================================================
# APPLICATION ENDPOINTS
# =============================================================================

@csrf_exempt
@auth_required
def apply_to_job(request, job_id):
    """POST /api/jobs_v2/listings/<job_id>/apply"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        # Check listing active
        listing = JobsDB.get_post(job_id)
        if not listing or listing.get("status") != "active":
             return JsonResponse({"error": "Listing not available"}, status=400)

        app_id = JobsDB.apply_to_job(job_id, request.jobs_user_id)
        if not app_id:
            return JsonResponse({"error": "Already applied"}, status=409)
            
        JobsDB.log(request.jobs_user_id, "apply", "application", app_id)
        
        return JsonResponse({
            "status": "success",
            "application_id": app_id
        })
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@employer_required
def get_applicants(request, job_id):
    """GET /api/jobs_v2/listings/<job_id>/applicants"""
    if request.method != "GET":
        return JsonResponse({"error": "GET required"}, status=405)
    
    listing = JobsDB.get_post(job_id)
    if not listing or listing.get("employer_id") != request.jobs_user_id:
        return JsonResponse({"error": "Unauthorized"}, status=403)
        
    apps = JobsDB.get_applications_for_job(job_id)
    
    for app in apps:
        worker = JobsDB.get_user(app.get("worker_id"))
        if worker:
            app["worker_name"] = f"{worker.get('real_name_first', '')} {worker.get('real_name_last', '')[:1]}."
            app["worker_rating"] = worker.get("rating_score", 0)
            app["worker_trust"] = worker.get("trust_score", 50)
            
    return JsonResponse({
        "status": "success",
        "applicants": apps
    })


@csrf_exempt
@employer_required
def assign_worker(request, job_id):
    """POST /api/jobs_v2/listings/<job_id>/assign"""
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        data = json.loads(request.body)
        worker_id = data.get("worker_id")
        if not worker_id:
            return JsonResponse({"error": "worker_id required"}, status=400)
            
        listing = JobsDB.get_post(job_id)
        if not listing or listing.get("employer_id") != request.jobs_user_id:
             return JsonResponse({"error": "Unauthorized"}, status=403)
        
        # In strict spec: "Handshake" starts here.
        # Employer approves -> status=accepted (or waiting_worker_confirm)
        # For MVP, we'll mark it accepted.
        
        apps = JobsDB.get_applications_for_job(job_id)
        for app in apps:
            if app.get("worker_id") == worker_id:
                JobsDB.update_application_status(app["application_id"], "accepted")
            # Should we auto-reject others? Spec doesn't strictly say, but usually yes for 1-slot jobs.
            # Assuming multi-slot open for now unless "filled".
        
        JobsDB.log(request.jobs_user_id, "assign", "job", job_id, {"worker_id": worker_id})
        
        return JsonResponse({"status": "success", "message": "Worker assigned"})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =============================================================================
# LISTING MANAGEMENT ENDPOINTS
# =============================================================================

@csrf_exempt
@employer_required
def cancel_listing(request, job_id):
    """POST /api/jobs_v2/listings/<job_id>/cancel
    
    Cancels an active listing. Only the employer who created it can cancel.
    """
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        listing = JobsDB.get_post(job_id)
        if not listing:
            return JsonResponse({"error": "Listing not found"}, status=404)
            
        if listing.get("employer_id") != request.jobs_user_id:
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        if listing.get("status") not in ["active", "pending"]:
            return JsonResponse({"error": "Cannot cancel listing in current state"}, status=400)
        
        # Cancel the listing
        JobsDB.update_post_status(job_id, "cancelled")
        JobsDB.log(request.jobs_user_id, "cancel", "job", job_id)
        
        return JsonResponse({"status": "success", "message": "Listing cancelled"})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@employer_required
def update_listing(request, job_id):
    """PATCH /api/jobs_v2/listings/<job_id>/update
    
    Updates listing fields. Only description and pay details can be edited.
    """
    if request.method not in ["POST", "PATCH"]:
        return JsonResponse({"error": "POST/PATCH required"}, status=405)
    
    try:
        listing = JobsDB.get_post(job_id)
        if not listing:
            return JsonResponse({"error": "Listing not found"}, status=404)
            
        if listing.get("employer_id") != request.jobs_user_id:
            return JsonResponse({"error": "Unauthorized"}, status=403)
            
        if listing.get("status") != "active":
            return JsonResponse({"error": "Cannot edit inactive listing"}, status=400)
        
        data = json.loads(request.body)
        
        # Only allow safe fields to be updated
        allowed_fields = ["description", "pay_range", "duration", "start_time"]
        updates = {}
        for field in allowed_fields:
            if field in data:
                updates[field] = data[field]
        
        if not updates:
            return JsonResponse({"error": "No valid fields to update"}, status=400)
        
        # Update via direct DB access (add method to JobsDB if needed)
        db = JobsDB._db()
        db.jobs_posts.update_one(
            {"job_id": job_id},
            {"$set": updates}
        )
        
        JobsDB.log(request.jobs_user_id, "update", "job", job_id, updates)
        
        return JsonResponse({"status": "success", "message": "Listing updated"})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

