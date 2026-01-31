# Jobs v2 - URL Configuration
from django.urls import path
from .views import auth, listings, admin, moderation, applications, uploads

urlpatterns = [
    # Auth
    path('auth/register', auth.register, name='jobs_v2_register'),
    path('auth/login', auth.login, name='jobs_v2_login'),
    path('auth/logout', auth.logout, name='jobs_v2_logout'),
    path('auth/profile', auth.get_profile, name='jobs_v2_profile'),
    path('auth/profile/update', auth.update_profile, name='jobs_v2_profile_update'),
    path('auth/profile/photo', uploads.upload_profile_photo, name='jobs_v2_profile_photo'),
    path('auth/upgrade_to_employer', auth.upgrade_to_employer, name='jobs_v2_upgrade'),
    
    # Listings
    path('listings/create', listings.create_listing, name='jobs_v2_create'),
    path('listings/search', listings.search_listings, name='jobs_v2_search'),
    path('listings/mine', listings.my_listings, name='jobs_v2_my_listings'),
    path('listings/applied', listings.get_applied_jobs, name='jobs_v2_applied'),
    path('listings/<str:job_id>', listings.get_listing, name='jobs_v2_get_listing'),
    path('listings/<str:job_id>/apply', listings.apply_to_job, name='jobs_v2_apply'),
    path('listings/<str:job_id>/applicants', listings.get_applicants, name='jobs_v2_applicants'),
    path('listings/<str:job_id>/assign', listings.assign_worker, name='jobs_v2_assign'),
    path('listings/<str:job_id>/cancel', listings.cancel_listing, name='jobs_v2_cancel'),
    path('listings/<str:job_id>/update', listings.update_listing, name='jobs_v2_update'),
    
    # Admin
    path('admin/employers/pending', admin.get_pending_employers, name='jobs_v2_pending_employers'),
    path('admin/employers/verify', admin.verify_employer, name='jobs_v2_verify_employer'),
    path('admin/analytics', admin.get_analytics, name='jobs_v2_analytics'),
    path('admin/accounts', admin.get_accounts, name='jobs_v2_admin_accounts'),
    path('admin/accounts/action', admin.account_action, name='jobs_v2_admin_account_action'),
    path('admin/listings', admin.get_listings, name='jobs_v2_admin_listings'),
    path('admin/listings/action', admin.listing_action, name='jobs_v2_admin_listing_action'),
    path('admin/reports', moderation.get_admin_reports, name='jobs_v2_admin_reports'),
    
    # Moderation / Safety
    path('report', moderation.post_report, name='jobs_v2_report'),
    # Applications & Messaging
    path('applications/<str:application_id>', applications.get_application_details, name='jobs_v2_app_details'),
    path('applications/<str:application_id>/messages', applications.get_messages, name='jobs_v2_app_messages'),
    path('applications/<str:application_id>/messages/send', applications.send_message, name='jobs_v2_app_send_message'),
    path('applications/<str:application_id>/messages/read', applications.mark_messages_read, name='jobs_v2_app_mark_read'),
    path('applications/<str:application_id>/status', applications.update_status, name='jobs_v2_app_status'),
    
    # Inbox
    path('inbox', applications.get_inbox, name='jobs_v2_inbox'),
    
    # Message Actions
    path('messages/<str:message_id>/delete', applications.delete_message, name='jobs_v2_delete_message'),
    path('messages/upload-image', uploads.upload_chat_image, name='jobs_v2_upload_chat_image'),
]
