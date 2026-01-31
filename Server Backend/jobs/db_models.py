import logging
import datetime
import uuid
from typing import Optional, List, Dict
from core.db_utils import get_db_handle
from pymongo import ASCENDING, DESCENDING, IndexModel

logger = logging.getLogger(__name__)

# --- CONSTANTS ---
DB_ACCOUNTS = "jobs_accounts"
DB_LISTINGS = "jobs_listings"
DB_RATINGS = "jobs_ratings"
DB_REPORTS = "jobs_reports"
DB_CASES = "jobs_moderation_cases"
DB_AUDIT = "jobs_audit_log"
DB_CONFIG = "jobs_config"
DB_APPLICATIONS = "jobs_applications"

class JobsDAO:
    """
    Data Access Object for the Jobs Module.
    Handles all interactions with MongoDB.
    """
    
    @staticmethod
    def _get_db():
        return get_db_handle()

    @classmethod
    def ensure_indexes(cls):
        """Creates all required indexes on startup."""
        db = cls._get_db()
        
        # G) jobs_config
        db[DB_CONFIG].create_indexes([
            IndexModel([("key", ASCENDING)], unique=True)
        ])
        
        # A) jobs_accounts
        db[DB_ACCOUNTS].create_indexes([
            IndexModel([("email", ASCENDING)], unique=True, partialFilterExpression={"email": {"$type": "string"}}),
            IndexModel([("phone", ASCENDING)], unique=True, partialFilterExpression={"phone": {"$type": "string"}}),
            IndexModel([("account_id", ASCENDING)], unique=True),
            IndexModel([("status", ASCENDING)]),
            IndexModel([("suspension_until", ASCENDING)]),
            IndexModel([("rating_avg", DESCENDING)]),
        ])
        
        # B) jobs_listings
        db[DB_LISTINGS].create_indexes([
            IndexModel([("job_id", ASCENDING)], unique=True),
            IndexModel([("employer_account_id", ASCENDING)]),
            IndexModel([("status", ASCENDING)]),
            IndexModel([("location.zip", ASCENDING)]),
            IndexModel([("location.geo", "2dsphere")]),
            IndexModel([("created_at", DESCENDING)]),
        ])
        
        # C) jobs_ratings
        db[DB_RATINGS].create_indexes([
            IndexModel([("job_id", ASCENDING)]),
            IndexModel([("to_account_id", ASCENDING)]),
            IndexModel([("created_at", DESCENDING)]),
        ])
        
        # D) jobs_reports
        db[DB_REPORTS].create_indexes([
            IndexModel([("target_type", ASCENDING), ("target_id", ASCENDING)]),
            IndexModel([("reporter_account_id", ASCENDING), ("created_at", DESCENDING)]),
        ])
        
        # E) jobs_moderation_cases
        db[DB_CASES].create_indexes([
            IndexModel([("case_id", ASCENDING)], unique=True),
            IndexModel([("status", ASCENDING)]),
            IndexModel([("opened_at", DESCENDING)]),
            IndexModel([("target_type", ASCENDING), ("target_id", ASCENDING)]),
        ])
        
        # F) jobs_audit_log
        db[DB_AUDIT].create_indexes([
            IndexModel([("at", DESCENDING)]),
            IndexModel([("target_type", ASCENDING), ("target_id", ASCENDING)]),
        ])
        
        # H) jobs_applications
        db[DB_APPLICATIONS].create_indexes([
            IndexModel([("application_id", ASCENDING)], unique=True),
            IndexModel([("job_id", ASCENDING)]),
            IndexModel([("applicant_account_id", ASCENDING)]),
            IndexModel([("status", ASCENDING)]),
            IndexModel([("applied_at", DESCENDING)]),
        ])
        
        logger.info("[JOBS] Indexes ensured.")

    # --- ACCOUNTS ---
    @classmethod
    def create_account(cls, data: Dict) -> str:
        db = cls._get_db()
        account_id = str(uuid.uuid4())
        
        # Enforce Lowercase Email
        if 'email' in data:
            data['email'] = data['email'].lower()
            
        doc = {
            "account_id": account_id,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "last_login_at": None,
            "status": "active",
            "profile_pic": "", # URL or Base64
            "photo_id": "", # URL or Base64 (New)
            "bio": "", # New
            "home_address": "", # New
            "job_types_broad": [], # New
            "job_types_specific": [], # New
            "skills": [], # List of {name, score}
            "jobs_completed_count": 0,
            "risk_score": 0,
            "report_strikes": 0,
            "report_strikes_30d": 0,
            "reporter_trust_score": 50,
            "rating_avg": 0.0,
            "rating_count": 0,
            "device_fingerprint_hash": None,
            "last_ip_hash": None,
            "notes_admin": "",
            "roles": {"employer": False, "worker": False},
            # --- EMPLOYER VERIFICATION (New) ---
            "organization_name": "",
            "organization_type": "",  # NGO, Government, Contractor, Local
            "verification_doc_url": "",
            "employer_verified": False,  # Admin must approve
            "employer_verified_at": None,
            # --- WORKER URGENCY (New) ---
            "worker_urgency": "available",  # critical, high, available
            "worker_urgency_updated_at": None,
            **data
        }
        db[DB_ACCOUNTS].insert_one(doc)
        return account_id

    @classmethod
    def get_account_by_email(cls, email: str):
        return cls._get_db()[DB_ACCOUNTS].find_one({"email": email.lower()})

    @classmethod
    def get_account(cls, account_id: str):
        return cls._get_db()[DB_ACCOUNTS].find_one({"account_id": account_id})

    @classmethod
    def update_account_login(cls, account_id: str):
         cls._get_db()[DB_ACCOUNTS].update_one(
             {"account_id": account_id},
             {"$set": {"last_login_at": datetime.datetime.utcnow().isoformat()}}
         )

    @classmethod
    def update_profile(cls, account_id: str, updates: Dict):
        """Updates user profile fields."""
        allowed_fields = [
            "profile_pic", "photo_id", "bio", "home_address", 
            "job_types_broad", "job_types_specific", "skills",
            "availability", "experience_level", "work_radius", 
            "certifications", "languages", "phone",
            "worker_urgency"  # New: critical, high, available
        ]
        clean_updates = {k: v for k, v in updates.items() if k in allowed_fields}
        if clean_updates:
            cls._get_db()[DB_ACCOUNTS].update_one(
                {"account_id": account_id},
                {"$set": clean_updates}
            )

    # --- LISTINGS ---
    @classmethod
    def create_listing(cls, data: Dict) -> str:
        db = cls._get_db()
        job_id = str(uuid.uuid4())
        doc = {
            "job_id": job_id,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "updated_at": datetime.datetime.utcnow().isoformat(),
            "status": "active",
            "report_score": 0.0,
            "report_count": 0,
            "visible_to_clients": True,
            "outcome": "open",
            "accepted_by_account_id": None,
            "accepted_at": None,
            "completed_at": None,
            "last_moderated_at": None,
            "category": data.get("category", "General"),
            "urgency": data.get("urgency", "Normal"), # Critical, High, Normal
            "risk_level": data.get("risk_level", "Low"), # High, Medium, Low
            **data
        }
        db[DB_LISTINGS].insert_one(doc)
        return job_id

    @classmethod
    def search_listings(cls, query: Dict, limit=20, skip=0):
        # Basic filtering logic
        db = cls._get_db()
        cursor = db[DB_LISTINGS].find(query).sort("created_at", DESCENDING).skip(skip).limit(limit)
        return list(cursor)

    @classmethod
    def get_listing(cls, job_id: str):
        return cls._get_db()[DB_LISTINGS].find_one({"job_id": job_id})

    @classmethod
    def update_listing_status(cls, job_id: str, status: str, visible: bool):
        cls._get_db()[DB_LISTINGS].update_one(
            {"job_id": job_id},
            {"$set": {"status": status, "visible_to_clients": visible, "updated_at": datetime.datetime.utcnow().isoformat()}}
        )

    @classmethod
    def get_listings_by_employer(cls, employer_account_id: str, limit=50):
        """Get all listings created by an employer."""
        db = cls._get_db()
        cursor = db[DB_LISTINGS].find({"employer_account_id": employer_account_id}).sort("created_at", DESCENDING).limit(limit)
        return list(cursor)

    @classmethod
    def update_listing(cls, job_id: str, updates: Dict):
        """Update listing fields."""
        allowed = ["title", "description", "category", "urgency", "risk_level", "location", "pay", "duration", "requirements", "status"]
        clean = {k: v for k, v in updates.items() if k in allowed}
        clean["updated_at"] = datetime.datetime.utcnow().isoformat()
        cls._get_db()[DB_LISTINGS].update_one({"job_id": job_id}, {"$set": clean})

    @classmethod
    def assign_worker(cls, job_id: str, worker_account_id: str):
        """Assign a worker to a job."""
        cls._get_db()[DB_LISTINGS].update_one(
            {"job_id": job_id},
            {"$set": {
                "accepted_by_account_id": worker_account_id,
                "accepted_at": datetime.datetime.utcnow().isoformat(),
                "status": "filled",
                "visible_to_clients": False
            }}
        )

    # --- APPLICATIONS ---
    @classmethod
    def create_application(cls, job_id: str, applicant_account_id: str, cover_message: str = "") -> str:
        """Create a job application."""
        db = cls._get_db()
        application_id = str(uuid.uuid4())
        doc = {
            "application_id": application_id,
            "job_id": job_id,
            "applicant_account_id": applicant_account_id,
            "applied_at": datetime.datetime.utcnow().isoformat(),
            "status": "pending",
            "cover_message": cover_message
        }
        db[DB_APPLICATIONS].insert_one(doc)
        return application_id

    @classmethod
    def get_applications_for_job(cls, job_id: str):
        """Get all applications for a specific job."""
        return list(cls._get_db()[DB_APPLICATIONS].find({"job_id": job_id}).sort("applied_at", DESCENDING))

    @classmethod
    def get_applications_by_user(cls, account_id: str):
        """Get all applications submitted by a user."""
        return list(cls._get_db()[DB_APPLICATIONS].find({"applicant_account_id": account_id}).sort("applied_at", DESCENDING))

    @classmethod
    def get_application(cls, application_id: str):
        """Get a single application."""
        return cls._get_db()[DB_APPLICATIONS].find_one({"application_id": application_id})

    @classmethod
    def update_application_status(cls, application_id: str, status: str):
        """Update application status: pending, accepted, rejected, withdrawn."""
        cls._get_db()[DB_APPLICATIONS].update_one(
            {"application_id": application_id},
            {"$set": {"status": status}}
        )

    @classmethod
    def check_existing_application(cls, job_id: str, applicant_account_id: str):
        """Check if user already applied to this job."""
        return cls._get_db()[DB_APPLICATIONS].find_one({
            "job_id": job_id,
            "applicant_account_id": applicant_account_id
        })


    # --- REPORTS & MODERATION ---
    @classmethod
    def create_report(cls, data: Dict):
        db = cls._get_db()
        report_id = str(uuid.uuid4())
        doc = {
            "report_id": report_id,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "processed": False,
            "reporter_weight": 50, # Snapshot
            "linked_case_id": None,
            **data
        }
        db[DB_REPORTS].insert_one(doc)
        return report_id

    @classmethod
    def create_rating(cls, data: Dict):
        db = cls._get_db()
        rating_id = str(uuid.uuid4())
        doc = {
            "rating_id": rating_id,
            "created_at": datetime.datetime.utcnow().isoformat(),
            "is_invalidated": False,
            "invalidated_by": None,
            "invalidated_reason": None,
            **data
        }
        db[DB_RATINGS].insert_one(doc)
        return rating_id

    @classmethod
    def get_reports_for_target(cls, target_type, target_id):
        return list(cls._get_db()[DB_REPORTS].find({"target_type": target_type, "target_id": target_id}))

    @classmethod
    def create_case(cls, data: Dict):
        db = cls._get_db()
        case_id = str(uuid.uuid4())
        doc = {
            "case_id": case_id,
            "opened_at": datetime.datetime.utcnow().isoformat(),
            "status": "open",
            "audit_trail": [],
            **data
        }
        db[DB_CASES].insert_one(doc)
        return case_id

    @classmethod
    def update_case_verdict(cls, case_id: str, analyst_verdict: Dict, final_action: Dict):
        cls._get_db()[DB_CASES].update_one(
            {"case_id": case_id},
            {"$set": {
                "status": "decided",
                "analyst_verdict": analyst_verdict,
                "final_action": final_action
            }, "$push": {"audit_trail": {"event": "verdict_applied", "at": datetime.datetime.utcnow().isoformat()}}}
        )

    @classmethod
    def log_audit(cls, actor_type, actor_id, action, target_type, target_id, details=None):
        db = cls._get_db()
        doc = {
            "at": datetime.datetime.utcnow().isoformat(),
            "actor_type": actor_type,
            "actor_id": actor_id,
            "action": action,
            "target_type": target_type,
            "target_id": target_id,
            "details": details or {}
        }
        db[DB_AUDIT].insert_one(doc)

    # --- CONFIG ---
    @classmethod
    def get_config(cls, key: str, default=None):
        doc = cls._get_db()[DB_CONFIG].find_one({"key": key})
        return doc['value'] if doc else default

    @staticmethod
    def get_account(account_id):
        db = get_db_handle()
        return db.jobs_accounts.find_one({"account_id": account_id}, {"_id": 0})

    @staticmethod
    def delete_account(account_id):
        """Permanently delete an account and anonymize/remove associated data."""
        db = get_db_handle()
        # 1. Delete Account
        db.jobs_accounts.delete_one({"account_id": account_id})
        # 2. Anonymize Listings (Optional: or delete them)
        # For Sentinel, we might want to keep the intel but remove the user link, 
        # OR delete them if we want fresh data. Let's delete active listings for safety.
        db.jobs_listings.delete_many({"employer_id": account_id})
        # 3. Anonymize Reports? Keep them for stats but maybe unlink?
        # db.jobs_reports.update_many({"reporter_id": account_id}, {"$set": {"reporter_id": "deleted"}})

    @staticmethod
    def set_config(key, value):
        db = get_db_handle()
        db.jobs_config.update_one(
            {"key": key},
            {"$set": {"value": value, "updated_at": datetime.utcnow()}},
            upsert=True
        )

    # --- ADMIN METHODS ---
    @staticmethod
    def admin_get_all_accounts():
        """Retrieve all accounts with computed validity score."""
        db = get_db_handle()
        accounts = list(db.jobs_accounts.find({}, {"_id": 0})) # Return all fields logic
        # Enhance with validity score if not present (simple calculation)
        for acc in accounts:
            # Simple Validity Score: 100 - (strikes * 10) + (trust_score * 5)
            # This is a heuristic for the UI
            strikes = acc.get('report_strikes', 0)
            trust = acc.get('trust_score', 0)
            validity = 100 - (strikes * 10) + (trust * 5)
            acc['validity_score'] = max(0, min(100, validity))
            acc['_id'] = str(acc.get('account_id')) # Ensure ID is accessible
        return accounts

    @staticmethod
    def admin_update_account(account_id, updates):
        """Manually update account details."""
        db = get_db_handle()
        db.jobs_accounts.update_one(
            {"account_id": account_id},
            {"$set": updates}
        )

    @staticmethod
    def admin_apply_action(account_id, action, duration_days=None):
        """Apply Ban/Suspend/Reinstate action."""
        db = get_db_handle()
        updates = {}
        if action == "BAN":
            updates = {"status": "banned"}
        elif action == "SUSPEND":
            updates = {"status": "suspended"}
            if duration_days:
                updates["suspended_until"] = datetime.datetime.utcnow() + datetime.timedelta(days=duration_days)
        elif action == "REINSTATE":
            updates = {
                "status": "active",
                "suspended_until": None
            }
        
        if updates:
            db.jobs_accounts.update_one({"account_id": account_id}, {"$set": updates})

    @staticmethod
    def admin_get_all_listings(limit=100):
        """Retrieve latest listings for admin review."""
        db = get_db_handle()
        # Join with Employer Email? No, simplest is two queries or just ID.
        # But UI needs email.
        listings = list(db.jobs_listings.find({}, {"_id": 0}).sort("created_at", DESCENDING).limit(limit))
        
        # Enrich with Employer Email
        employer_ids = list(set([l.get('employer_account_id') for l in listings if l.get('employer_account_id')]))
        employers = list(db.jobs_accounts.find({"account_id": {"$in": employer_ids}}, {"account_id": 1, "email": 1, "_id": 0}))
        emp_map = {e['account_id']: e['email'] for e in employers}
        
        for l in listings:
            l['employer_email'] = emp_map.get(l.get('employer_account_id'), "Unknown")
            # Count Applicants
            l['applicant_count'] = db.jobs_applications.count_documents({"job_id": l['job_id']})
            
        return listings

    @staticmethod
    def admin_apply_listing_action(job_id, action):
        """suspend, close, delete listing."""
        db = get_db_handle()
        if action == "SUSPEND":
            db.jobs_listings.update_one({"job_id": job_id}, {"$set": {"status": "suspended", "visible_to_clients": False}})
        elif action == "CLOSE":
            db.jobs_listings.update_one({"job_id": job_id}, {"$set": {"status": "cancelled", "visible_to_clients": False}})
        elif action == "DELETE":
            # Soft delete? Or hard? Let's Hard delete for admin cleanup.
            db.jobs_listings.delete_one({"job_id": job_id})
            # Clean up applications
            db.jobs_applications.delete_many({"job_id": job_id})

    @staticmethod
    def admin_get_analytics():
        """Get high-level stats."""
        db = get_db_handle()
        return {
            "total_jobs": db.jobs_listings.count_documents({}),
            "active_jobs": db.jobs_listings.count_documents({"status": "active"}),
            "total_users": db.jobs_accounts.count_documents({}),
            "employers": db.jobs_accounts.count_documents({"roles.employer": True}),
            "workers": db.jobs_accounts.count_documents({"roles.worker": True}),
            "jobs_filled": db.jobs_listings.count_documents({"status": "filled"}),
        }

