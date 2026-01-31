from django.core.management.base import BaseCommand
from jobs.db_models import JobsDAO, DB_LISTINGS, DB_REPORTS, DB_AUDIT
from datetime import datetime, timedelta
import logging

class Command(BaseCommand):
    help = 'Prunes old data from the Jobs module (Listings, Reports, Audit Logs)'

    def handle(self, *args, **options):
        self.stdout.write("Starting Jobs Pruning...")
        db = JobsDAO._get_db()
        
        # 1. Prune Old Listings (Completed/Cancelled > 30 Days)
        # Note: We keep "accepted" indefinitely until completed? 
        # Prompt says "remove old listings". Let's assume non-active ones.
        cutoff_30d = (datetime.utcnow() - timedelta(days=30)).isoformat()
        
        res_l = db[DB_LISTINGS].delete_many({
            "status": {"$in": ["completed", "cancelled"]},
            "updated_at": {"$lt": cutoff_30d}
        })
        self.stdout.write(f"Deleted {res_l.deleted_count} old listings.")
        
        # 2. Prune Old Reports & Cases (> 90 Days)
        cutoff_90d = (datetime.utcnow() - timedelta(days=90)).isoformat()
        
        res_r = db[DB_REPORTS].delete_many({
            "created_at": {"$lt": cutoff_90d}
        })
        self.stdout.write(f"Deleted {res_r.deleted_count} old reports.")

        # 3. Prune Old Audit Logs (> 90 Days)
        res_a = db[DB_AUDIT].delete_many({
            "at": {"$lt": cutoff_90d}
        })
        self.stdout.write(f"Deleted {res_a.deleted_count} old audit logs.")
        
        self.stdout.write(self.style.SUCCESS("Pruning Complete."))
