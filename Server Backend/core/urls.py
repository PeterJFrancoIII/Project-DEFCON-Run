from django.contrib import admin
from django.urls import path
from . import views
from . import admin_views

urlpatterns = [
    # The Visual Dashboard
    path('', views.home, name='home'),
    
    # The iPhone Data Feed
    path('intel', views.intel_api, name='intel_api'),
    
    # --- ADMIN PORTAL ---
    path('admin_portal', admin_views.admin_home, name='admin_home'),
    
    # --- ADMIN API ---
    path('api/admin/zones', admin_views.api_get_zones, name='api_get_zones'),
    path('api/admin/zones/save', admin_views.api_save_zones, name='api_save_zones'),
    path('api/admin/approvals', admin_views.api_get_approvals, name='api_get_approvals'),
    path('api/admin/approvals/decide', admin_views.api_decide_approval, name='api_decide_approval'),
    path('api/admin/config', admin_views.api_get_config, name='api_get_config'),
    path('api/admin/config/save', admin_views.api_save_config, name='api_save_config'),
]
