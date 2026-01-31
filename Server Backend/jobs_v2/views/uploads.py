# Jobs v2 - Photo Uploads
# Handles profile photo uploads with file validation

import os
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from ..models import JobsDB
from .auth import auth_required

# Allowed media types
ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/octet-stream']

# Max file size (2MB - should be well under this after client compression)
MAX_SIZE = 2 * 1024 * 1024

@csrf_exempt
@auth_required
def upload_profile_photo(request):
    """POST /api/jobs_v2/auth/profile/photo
    Accepts multipart form with 'photo' file field.
    """
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        if 'photo' not in request.FILES:
            return JsonResponse({"error": "No photo provided"}, status=400)
        
        photo = request.FILES['photo']
        
        # Validate content type
        content_type = photo.content_type
        if content_type not in ALLOWED_TYPES:
            return JsonResponse({"error": f"Invalid file type: {content_type}. Use JPEG or PNG."}, status=400)
        
        # Validate size
        if photo.size > MAX_SIZE:
            return JsonResponse({"error": f"File too large: {photo.size} bytes. Max: 2MB"}, status=400)
        
        # Create photos directory if needed
        photos_dir = os.path.join(settings.BASE_DIR, 'mediafiles', 'jobs', 'photos')
        os.makedirs(photos_dir, exist_ok=True)
        
        # Save file with user ID as filename
        ext = 'jpg' if 'jpeg' in content_type else 'png'
        filename = f"{request.jobs_user_id}.{ext}"
        filepath = os.path.join(photos_dir, filename)
        
        with open(filepath, 'wb+') as f:
            for chunk in photo.chunks():
                f.write(chunk)
        
        # Build URL (relative to media root)
        photo_url = f"/mediafiles/jobs/photos/{filename}"
        
        # Update user document
        JobsDB._db().jobs_users.update_one(
            {"account_id": request.jobs_user_id},
            {"$set": {"photo_url": photo_url}}
        )
        
        JobsDB.log(request.jobs_user_id, "upload_photo", "user", request.jobs_user_id)
        
        return JsonResponse({"status": "success", "photo_url": photo_url})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@auth_required
def upload_chat_image(request):
    """POST /api/jobs_v2/messages/upload-image
    Uploads a chat image and returns the URL for use in send_message.
    """
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)
    
    try:
        if 'image' not in request.FILES:
            return JsonResponse({"error": "No image provided"}, status=400)
        
        image = request.FILES['image']
        
        # Validate content type
        content_type = image.content_type
        if content_type not in ALLOWED_TYPES:
            return JsonResponse({"error": f"Invalid file type: {content_type}. Use JPEG or PNG."}, status=400)
        
        # Validate size (2MB max after client compression)
        if image.size > MAX_SIZE:
            return JsonResponse({"error": f"File too large: {image.size} bytes. Max: 2MB"}, status=400)
        
        # Create chat images directory
        import time
        chat_dir = os.path.join(settings.BASE_DIR, 'mediafiles', 'jobs', 'chat')
        os.makedirs(chat_dir, exist_ok=True)
        
        # Save with unique filename
        ext = 'png' if 'png' in content_type else 'jpg'
        filename = f"{request.jobs_user_id}_{int(time.time()*1000)}.{ext}"
        filepath = os.path.join(chat_dir, filename)
        
        with open(filepath, 'wb+') as f:
            for chunk in image.chunks():
                f.write(chunk)
        
        # Return URL path (not filesystem path)
        image_url = f"/media/jobs/chat/{filename}"
        
        return JsonResponse({"status": "success", "image_url": image_url})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
