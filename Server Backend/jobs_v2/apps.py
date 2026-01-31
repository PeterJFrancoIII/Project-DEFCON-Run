from django.apps import AppConfig


class JobsV2Config(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'jobs_v2'
    
    def ready(self):
        # Ensure indexes on startup
        from .models import JobsDB
        try:
            JobsDB.ensure_indexes()
        except Exception as e:
            print(f"[JOBS_V2] Index creation deferred: {e}")
