from django.contrib import admin
from django.shortcuts import redirect
from .models import JobsDashboard

@admin.register(JobsDashboard)
class JobsDashboardAdmin(admin.ModelAdmin):
    """
    Redirects the admin change list to the custom Sentinel Admin Portal's Jobs tab.
    """
    def changelist_view(self, request, extra_context=None):
        # Redirect to the main admin portal where the actual Jobs GUI lives
        return redirect('/admin_portal#jobs')
