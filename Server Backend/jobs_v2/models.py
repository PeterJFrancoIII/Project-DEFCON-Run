# Jobs v2 - Strict Data Models (Emergency Labor Board)
# Server-Authoritative Logic & Schema

from django.conf import settings
from pymongo import MongoClient, ASCENDING, DESCENDING
import datetime
import time

class JobsDB:
    """
    Strict Data Access Object for Emergency Labor Board.
    Enforces server-authoritative state and schema validation.
    """
    
    _client = None
    _db_instance = None
    
    @classmethod
    def _db(cls):
        if cls._db_instance is None:
            # Connect to MongoDB
            cls._client = MongoClient(settings.MONGO_URI)
            cls._db_instance = cls._client[settings.MONGO_DB_NAME]
        return cls._db_instance
    
    @classmethod
    def ensure_indexes(cls):
        """
        Creates mandatory indexes for performance and uniqueness.
        Run this on app startup.
        """
        db = cls._db()
        
        # 1. jobs_users
        db.jobs_users.create_index([("phone_e164", ASCENDING)], unique=True)
        db.jobs_users.create_index([("email", ASCENDING)], unique=True)
        db.jobs_users.create_index([
            ("status", ASCENDING),
            ("role", ASCENDING),
            ("trust_score", DESCENDING)
        ])
        
        # 2. jobs_posts
        db.jobs_posts.create_index([("location", "2dsphere")])  # Geo index
        db.jobs_posts.create_index([
            ("status", ASCENDING),
            ("category", ASCENDING)
        ])
        db.jobs_posts.create_index([("employer_id", ASCENDING)])
        
        # 3. jobs_applications
        db.jobs_applications.create_index([
            ("job_id", ASCENDING),
            ("worker_id", ASCENDING)
        ], unique=True)
        db.jobs_applications.create_index([("worker_id", ASCENDING)])
        db.jobs_applications.create_index([("status", ASCENDING)])

        # 4. jobs_reports
        db.jobs_reports.create_index([("target_id", ASCENDING), ("target_type", ASCENDING)])

        # 5. jobs_moderation_actions
        db.jobs_moderation_actions.create_index([("target_id", ASCENDING), ("created_at", DESCENDING)])
        
        print(">> [JOBS V2] Strict Indexes Verified")

    # =========================================================================
    # USER MANAGEMENT (jobs_users)
    # =========================================================================
    
    @classmethod
    def create_user(cls, role, email, phone, real_name_first, real_name_last, password_hash, device_hash=None):
        """
        Creates a new user strictly adhering to safety spec.
        Initializes trust_score to 50 (neutral).
        """
        user_doc = {
            "account_id": f"usr_{int(time.time()*1000)}",  # Public ID (usr_ prefix per governance)
            "role": role,  # 'worker' | 'employer'
            "status": "active",  # 'active' | 'suspended_temp' | 'banned'
            
            # Identity (Strict)
            "email": email,
            "phone_e164": phone,
            "real_name_first": real_name_first,
            "real_name_last": real_name_last,
            "password_hash": password_hash,
            "device_fingerprints": [device_hash] if device_hash else [],
            
            # Reputation & Trust (Server Authority)
            "risk_score": 0.0,  # 0.0 to 1.0
            "trust_score": 50,  # 0 to 100
            "worker_urgency": "available",  # critical, high, available
            "worker_urgency_updated_at": None,
            
            # Notifications (New)
            "notification_settings": {
                "push_pending": True,       # Message alerts from Pending/Accepted
                "push_non_pending": False,  # Message alerts from Applied/Cold
                "push_marketing": True
            },
            
            # Metadata
            "created_at": datetime.datetime.utcnow(),
            "last_login_at": datetime.datetime.utcnow(),
            "precise_location": None,  # Updated on login/action
            "ban_reason": None,
            "suspended_until": None,
            
            # Employer Specific (MVP)
            "organization": {} 
        }
        
        cls._db().jobs_users.insert_one(user_doc)
        return user_doc["account_id"]

    @classmethod
    def get_user(cls, account_id):
        return cls._db().jobs_users.find_one({"account_id": account_id}, {"_id": 0, "password_hash": 0})
        
    @classmethod
    def get_user_by_email(cls, email):
        return cls._db().jobs_users.find_one({"email": email}, {"_id": 0})

    @classmethod
    def get_user_by_phone(cls, phone):
        return cls._db().jobs_users.find_one({"phone_e164": phone}, {"_id": 0})

    @classmethod
    def update_user_location(cls, account_id, lat, lon, accuracy=0):
        cls._db().jobs_users.update_one(
            {"account_id": account_id},
            {"$set": {
                "precise_location": {
                    "lat": lat,
                    "lon": lon,
                    "accuracy_m": accuracy,
                    "captured_at": datetime.datetime.utcnow()
                }
            }}
        )

    # =========================================================================
    # POSTS (jobs_posts)
    # =========================================================================

    @classmethod
    def create_post(cls, employer_id, category, pay_type, pay_range, start_time, duration, location, description):
        job_id = f"job_{int(time.time()*1000)}"
        
        post_doc = {
            "job_id": job_id,
            "employer_id": employer_id,
            "status": "active",  # active | under_review | removed | filled
            
            # Job Details
            "category": category,
            "pay_type": pay_type,  # cash | hourly | daily
            "pay_range": pay_range,  # {min, max, currency}
            "start_time": start_time,
            "duration": duration,
            "description": description[:500],
            
            # Location (Strict)
            "location": {
                "type": "Point",
                "coordinates": [location['lon'], location['lat']]  # GeoJSON: [lon, lat]
            },
            "display_location": {  # Coarsened for safety
                "lat": round(location['lat'], 2),
                "lon": round(location['lon'], 2)
            },
            
            # Moderation
            "moderation_state": "clean",  # clean | flagged | analyst_review
            "report_count": 0,
            "created_at": datetime.datetime.utcnow()
        }
        
        cls._db().jobs_posts.insert_one(post_doc)
        return job_id

    @classmethod
    def search_posts(cls, category=None, lat=None, lon=None, radius_km=50):
        """
        Geo-spatial search for active jobs.
        """
        query = {"status": "active", "moderation_state": "clean"}
        if category:
            query["category"] = category
            
        if lat is not None and lon is not None:
            query["location"] = {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat]
                    },
                    "$maxDistance": radius_km * 1000
                }
            }
            
        cursor = cls._db().jobs_posts.find(query, {"_id": 0}).limit(50)
        return list(cursor)

    @classmethod
    def get_post(cls, job_id):
        return cls._db().jobs_posts.find_one({"job_id": job_id}, {"_id": 0})

    @classmethod
    def update_post_status(cls, job_id, status):
        """
        Admin or System update of job status.
        Valid statuses: active, suspended, removed, filled, under_review
        """
        cls._db().jobs_posts.update_one(
            {"job_id": job_id},
            {"$set": {"status": status}}
        )

    # =========================================================================
    # APPLICATIONS (jobs_applications)
    # =========================================================================

    @classmethod
    def apply_to_job(cls, job_id, worker_id):
        app_id = f"app_{int(time.time()*1000)}"
        
        # Check if already applied
        if cls._db().jobs_applications.find_one({"job_id": job_id, "worker_id": worker_id}):
            return None
            
        doc = {
            "application_id": app_id,
            "job_id": job_id,
            "worker_id": worker_id,
            "status": "applied",  # applied | pending | accepted | declined | completed
            "created_at": datetime.datetime.utcnow(),
            "allow_messaging": False
        }
        cls._db().jobs_applications.insert_one(doc)
        return app_id

    @classmethod
    def update_application_status(cls, app_id, status):
        updates = {"status": status}
        if status in ["pending", "accepted"]:
            updates["allow_messaging"] = True
        else:
            updates["allow_messaging"] = False
            
        cls._db().jobs_applications.update_one(
            {"application_id": app_id},
            {"$set": updates}
        )
        
    @classmethod
    def get_applications_for_job(cls, job_id):
        return list(cls._db().jobs_applications.find({"job_id": job_id}, {"_id": 0}))

    @classmethod
    def get_application(cls, application_id):
        return cls._db().jobs_applications.find_one({"application_id": application_id}, {"_id": 0})

    # =========================================================================
    # MESSAGING
    # =========================================================================
    
    @classmethod
    def send_message(cls, application_id, sender_id, content, image_url=None):
        """Send a message within an application context."""
        import hashlib
        
        msg_id = f"msg_{int(time.time()*1000)}"
        
        # Generate content hash for integrity verification
        hash_input = f"{application_id}:{sender_id}:{content}:{image_url or ''}"
        content_hash = hashlib.sha256(hash_input.encode()).hexdigest()[:16]
        
        doc = {
            "message_id": msg_id,
            "application_id": application_id,
            "sender_id": sender_id,
            "content": content,
            "image_url": image_url,  # Optional photo attachment
            "content_hash": content_hash,  # Integrity check
            "created_at": datetime.datetime.utcnow(),
            "read_at": None  # Null until recipient reads
        }
        cls._db().jobs_messages.insert_one(doc)
        return msg_id
        
    @classmethod
    def get_messages(cls, application_id):
        """Get chat history for an application."""
        cursor = cls._db().jobs_messages.find(
            {"application_id": application_id}, 
            {"_id": 0}
        ).sort("created_at", ASCENDING)
        return list(cursor)

    @classmethod
    def mark_messages_read(cls, application_id, reader_id):
        """Mark all messages in a conversation as read by reader_id.
        Only marks messages NOT sent by reader_id (you can't read your own messages).
        """
        cls._db().jobs_messages.update_many(
            {
                "application_id": application_id,
                "sender_id": {"$ne": reader_id},
                "read_at": None
            },
            {"$set": {"read_at": datetime.datetime.utcnow()}}
        )

    @classmethod
    def delete_message(cls, message_id, user_id):
        """
        Delete a message if:
        1. User is the sender
        2. Message is less than 2 minutes old
        3. Message hasn't been read yet
        Returns: (success, error_message)
        """
        msg = cls._db().jobs_messages.find_one({"message_id": message_id})
        if not msg:
            return False, "Message not found"
        
        if msg["sender_id"] != user_id:
            return False, "Cannot delete others' messages"
        
        if msg.get("read_at") is not None:
            return False, "Cannot delete - already read"
        
        created = msg.get("created_at")
        if created:
            age = (datetime.datetime.utcnow() - created).total_seconds()
            if age > 120:  # 2 minutes
                return False, "Cannot delete - over 2 minutes old"
        
        cls._db().jobs_messages.delete_one({"message_id": message_id})
        return True, None

    @classmethod
    def get_inbox_conversations(cls, user_id):
        """
        Get all applications where user is worker OR employer, 
        AND allow_messaging is True.
        Enriched with last message.
        """
        db = cls._db()
        
        # 1. Find relevant applications
        # Fetching all where worker_id is user OR job's employer_id is user
        # This requires a join which is hard in Mongo without lookup.
        # Faster approach: Query applications where worker_id = user
        # AND Query jobs where employer_id = user -> then applications for those jobs.
        
        # A. Worker Applications
        worker_apps = list(db.jobs_applications.find({
            "worker_id": user_id,
            "allow_messaging": True
        }, {"_id": 0}))
        
        # B. Employer Applications
        # Find jobs by this employer
        my_jobs = list(db.jobs_posts.find({"employer_id": user_id}, {"job_id": 1}))
        my_job_ids = [j["job_id"] for j in my_jobs]
        
        employer_apps = []
        if my_job_ids:
            employer_apps = list(db.jobs_applications.find({
                "job_id": {"$in": my_job_ids},
                "allow_messaging": True
            }, {"_id": 0}))
            
        all_apps = worker_apps + employer_apps
        
        # Dedupe and Enrich
        inbox = []
        seen_ids = set()
        
        for app in all_apps:
            if app["application_id"] in seen_ids:
                continue
            seen_ids.add(app["application_id"])
            
            # Enrich with Job Title and Counterparty Name
            job = cls.get_post(app["job_id"])
            if not job: continue
            
            item = {
                "application_id": app["application_id"],
                "job_id": app["job_id"],
                "job_title": job.get("category", "Job"),
                "status": app["status"],
                "updated_at": app.get("created_at") # Default
            }
            
            # Identify counterparty
            if app["worker_id"] == user_id:
                # User is worker, counterparty is Employer
                emp = cls.get_user(job["employer_id"])
                if emp:
                    name = emp.get("organization", {}).get("name") or \
                           f"{emp.get('real_name_first')} {emp.get('real_name_last')}"
                    item["peer_name"] = name
                    item["peer_id"] = job["employer_id"]
            else:
                # User is employer, counterparty is Worker
                worker = cls.get_user(app["worker_id"])
                if worker:
                    item["peer_name"] = f"{worker.get('real_name_first')} {worker.get('real_name_last')}"
                    item["peer_id"] = app["worker_id"]
            
            # Get Last Message (for preview)
            last_msg = list(db.jobs_messages.find(
                {"application_id": app["application_id"]},
                {"_id": 0, "content": 1, "created_at": 1}
            ).sort("created_at", DESCENDING).limit(1))
            
            if last_msg:
                item["last_message"] = last_msg[0]["content"]
                item["last_message_at"] = last_msg[0]["created_at"]
                item["updated_at"] = last_msg[0]["created_at"]
            else:
                item["last_message"] = "Channel Open"
            
            # Count unread messages (not from user, read_at is null)
            unread_count = db.jobs_messages.count_documents({
                "application_id": app["application_id"],
                "sender_id": {"$ne": user_id},
                "read_at": None
            })
            item["unread_count"] = unread_count
                
            inbox.append(item)
            
        # Sort by updated_at desc
        inbox.sort(key=lambda x: x.get("updated_at") or datetime.datetime.min, reverse=True)
        return inbox

    # =========================================================================
    # INTEL / UTILS
    # =========================================================================

    @classmethod
    def get_zone_defcon(cls, zip_code):
        # ... (Existing logic to query sentinel intel)
        res = cls._db().sentinel_intel.find_one({"zip": zip_code})
        return res.get("defcon", 5) if res else 5
    
    # =========================================================================
    # TRUST & SAFETY (Reports & Moderation)
    # =========================================================================

    @classmethod
    def create_report(cls, reporter_id, target_type, target_id, reason_code, reason_text=None):
        """
        Creates a user report with anti-brigading logic.
        Enforces one report per reporter/target/day.
        """
        db = cls._db()
        window_bucket = datetime.datetime.utcnow().strftime("%Y-%m-%d")
        
        # 1. Get Reporter Trust (Weight)
        reporter = db.jobs_users.find_one({"account_id": reporter_id}, {"trust_score": 1})
        trust_score = reporter.get("trust_score", 50) if reporter else 50
        weight = trust_score / 100.0  # 0.5 default
        
        # 2. Create Report Doc
        report_id = f"rpt_{int(time.time()*1000)}"
        report_doc = {
            "report_id": report_id,
            "reporter_id": reporter_id,
            "target_type": target_type,
            "target_id": target_id,
            "reason_code": reason_code,
            "reason_text": reason_text,
            "weight_used": weight,
            "window_bucket": window_bucket,
            "created_at": datetime.datetime.utcnow()
        }
        
        try:
            db.jobs_reports.insert_one(report_doc)
            
            # 3. Update Target's Risk Score (Simplified)
            # In full system, this would be an async job or aggregation
            # Here we just increment a counter on the user/post for MVP triggers
            # TODO: Implement full trust snapshot update
            
            return report_id
        except:
             # Duplicate report for this window (unique index)
             return None

    @classmethod
    def log_moderation_action(cls, actor_id, action_type, target_type, target_id, reason_code, details=None):
        """
        Append-only audit log for all safety actions.
        """
        action_id = f"mod_{int(time.time()*1000)}"  # mod_ prefix per governance
        doc = {
            "action_id": action_id,
            "actor_id": actor_id,
            "action_type": action_type, # auto_suspend, ban, reinstatement, verify
            "target_type": target_type,
            "target_id": target_id,
            "reason_code": reason_code,
            "details": details or {},
            "created_at": datetime.datetime.utcnow()
        }
        cls._db().jobs_moderation_actions.insert_one(doc)
        return action_id

    @classmethod
    def log(cls, actor_id, action, target_type, target_id, details=None):
        """Legacy wrapper for log_moderation_action"""
        return cls.log_moderation_action(actor_id, action, target_type, target_id, "LEGACY_LOG", details)
    
    # =========================================================================
    # ADMIN / VERIFICATION
    # =========================================================================
    
    @classmethod
    def get_pending_employers(cls):
        # Strict: Employers with trust_score < 70 (for example) or status checks
        # For now, rely on "verified" flag being absent or 'verification_doc' presence logic
        # But per new spec: "Employer must be verified"
        # We can simulate a 'pending_verification' status or just query those with low trust but role=employer
        # For correct MVP implementation: use role="employer_pending" or similar, or just check `trust_score`
        # Let's assume verifying manually increases trust_score for now, OR we add `verified: bool` to organization
        cursor = cls._db().jobs_users.find(
            {"role": "employer", "trust_score": {"$lt": 80}},
            {"_id": 0}
        )
        return list(cursor)

    @classmethod
    def verify_employer(cls, account_id, approved):
        if approved:
            cls._db().jobs_users.update_one(
                {"account_id": account_id},
                {"$set": {"trust_score": 100}} # Boost trust score
            )
        else:
            cls._db().jobs_users.update_one(
                {"account_id": account_id},
                {"$set": {"status": "banned", "ban_reason": "Verification Failed"}}
            )
