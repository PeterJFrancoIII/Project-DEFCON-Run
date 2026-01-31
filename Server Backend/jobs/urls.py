from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('auth/register', views.auth_register, name='jobs_register'),
    path('auth/login', views.auth_login, name='jobs_login'),
    path('auth/delete', views.auth_delete_account, name='jobs_delete'),
    path('auth/logout', views.auth_logout, name='jobs_logout'),
    path('auth/profile', views.auth_get_profile, name='jobs_profile'),
    path('auth/profile/update', views.auth_update_profile, name='jobs_profile_update'),
    
    # Listings
    path('listings/search', views.search_listings, name='jobs_search'),
    path('listings/create', views.create_listing, name='jobs_create'),
    path('listings/mine', views.my_listings, name='jobs_my_listings'),
    path('listings/<str:job_id>/accept', views.accept_job, name='jobs_accept'),
    path('listings/<str:job_id>/complete', views.complete_job, name='jobs_complete'),
    path('listings/<str:job_id>/applicants', views.get_applicants, name='jobs_applicants'),
    path('listings/<str:job_id>/assign', views.assign_worker, name='jobs_assign'),
    path('listings/<str:job_id>/apply', views.apply_to_job, name='jobs_apply'),
    path('ratings/submit', views.submit_rating, name='jobs_rate'),
    
    # Applications (Worker)
    path('applications/mine', views.my_applications, name='jobs_my_applications'),
    path('applications/<str:application_id>/withdraw', views.withdraw_application, name='jobs_withdraw'),
    
    # Reporting
    path('report', views.report_target, name='jobs_report'),
    
    # Moderation (Analyst)
    path('moderation/case/<str:case_id>/analyst_run', views.run_analyst, name='jobs_analyst_run'),
    
    # Admin Config
    path('admin/config/apikey', views.admin_set_apikey, name='jobs_admin_apikey'),
    path('admin/accounts', views.admin_list_accounts, name='admin_list_accounts'),
    path('admin/accounts/update', views.admin_update_account, name='admin_update_account'),
    path('admin/accounts/action', views.admin_account_action, name='admin_account_action'),
    
    # Admin Listings & Analytics
    path('admin/listings', views.admin_list_listings, name='admin_list_listings'),
    path('admin/listings/action', views.admin_listing_action, name='admin_listing_action'),
    path('admin/analytics', views.admin_get_analytics, name='admin_get_analytics'),
    
    # Admin Employer Verification (New)
    path('admin/employers/pending', views.admin_get_pending_employers, name='admin_pending_employers'),
    path('admin/employers/verify', views.admin_verify_employer, name='admin_verify_employer'),
]
