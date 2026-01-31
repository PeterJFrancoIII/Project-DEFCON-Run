from django.apps import AppConfig

class JobsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'jobs'

    def ready(self):
        try:
            # Avoid running during migrations or if connection fails
            from .db_models import JobsDAO
            JobsDAO.ensure_indexes()
        except Exception as e:
            print(f"[JOBS] Index creation skipped/failed: {e}")
