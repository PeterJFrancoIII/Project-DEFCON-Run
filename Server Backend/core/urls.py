from django.contrib import admin
from django.urls import path
from . import views
import portal_views as admin_views

urlpatterns = [
    # The Visual Dashboard
    path('', views.home, name='home'),
    
    # The iPhone Data Feed
    path('intel', views.intel_api, name='intel_api'),
    path('intel/status', views.intel_status, name='intel_status'),
    path('intel/citations', views.intel_citations, name='intel_citations'),
    path('intel/report/<str:id>/citations', views.intel_citations, name='intel_report_citations'), # Alias
    
    # Public Config
    path('config/public', views.config_public, name='config_public'),
    
    # --- ADMIN PORTAL ---
    path('admin_portal', admin_views.admin_home, name='admin_home'),
    path('admin/login', admin_views.admin_login, name='admin_login'),
    path('admin/logout', admin_views.admin_logout, name='admin_logout'),
    path('admin/setup-2fa', admin_views.setup_2fa, name='setup_2fa'),
    
    # --- ADMIN API: ZONES ---
    path('api/admin/zones', admin_views.api_get_zones, name='api_get_zones'),
    path('api/admin/zones/save', admin_views.api_save_zones, name='api_save_zones'),
    
    # --- ADMIN API: INTELLIGENCE ---
    path('api/admin/prompt', admin_views.api_get_prompt, name='api_get_prompt'),
    path('api/admin/prompt/save', admin_views.api_save_prompt, name='api_save_prompt'),
    path('api/admin/osint', admin_views.api_get_osint, name='api_get_osint'),
    path('api/admin/osint/save', admin_views.api_save_osint, name='api_save_osint'),
    path('api/admin/zips/search', admin_views.api_search_zips, name='api_search_zips'),
    
    # --- ADMIN API: ASSETS & CONFIG ---
    path('api/admin/contact', admin_views.api_get_contact, name='api_get_contact'),
    path('api/admin/contact/save', admin_views.api_save_contact, name='api_save_contact'),
    path('api/admin/logo/upload', admin_views.api_upload_logo, name='api_upload_logo'),
    path('api/admin/api_config', admin_views.api_get_api_config, name='api_get_api_config'),
    path('api/admin/api_config/save', admin_views.api_save_api_config, name='api_save_api_config'),
    path('api/admin/config', admin_views.api_get_config, name='api_get_config'),
    path('api/admin/config/save', admin_views.api_save_config, name='api_save_config'),

    # --- ADMIN API: OPS ---
    path('admin/ops/logs', views.get_server_logs, name='get_server_logs'),
    path('api/admin/approvals', admin_views.api_get_approvals, name='api_get_approvals'),
    path('api/admin/approvals/decide', admin_views.api_decide_approval, name='api_decide_approval'),
    path('api/admin/alerts', admin_views.api_get_active_alerts, name='api_get_active_alerts'),
    path('api/admin/alerts/save', admin_views.api_save_alert_map, name='api_save_alert_map'),
    path('api/admin/threats', admin_views.api_get_threats, name='api_get_threats'),
    
    # --- DEBUG: ATLAS G3 ---
    path('api/debug/pipeline', views.debug_pipeline, name='debug_pipeline'),
]
