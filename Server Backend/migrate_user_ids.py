#!/usr/bin/env python3
"""
Migration Script: Rename User ID Prefix (u_ -> usr_)
Run this ONCE to migrate existing user records.

Usage:
  cd "Server Backend"
  python3 migrate_user_ids.py
"""

import os
import sys

# Add parent directory for Django settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

import django
django.setup()

from pymongo import MongoClient
from django.conf import settings

def migrate_user_ids():
    """Migrate user IDs from u_ to usr_ prefix."""
    client = MongoClient(settings.MONGO_URI)
    db = client[settings.MONGO_DB_NAME]
    
    # 1. Find all users with old prefix
    old_prefix = "u_"
    new_prefix = "usr_"
    
    users_to_update = list(db.jobs_users.find({
        "account_id": {"$regex": f"^{old_prefix}"}
    }))
    
    print(f"Found {len(users_to_update)} users with '{old_prefix}' prefix")
    
    if not users_to_update:
        print("No migration needed.")
        return
    
    # 2. Update each user
    updated_count = 0
    for user in users_to_update:
        old_id = user['account_id']
        new_id = old_id.replace(old_prefix, new_prefix, 1)
        
        # Update user document
        db.jobs_users.update_one(
            {"account_id": old_id},
            {"$set": {"account_id": new_id}}
        )
        
        # Update references in other collections
        # Jobs posted by this user
        db.jobs_posts.update_many(
            {"employer_id": old_id},
            {"$set": {"employer_id": new_id}}
        )
        
        # Applications by this user
        db.jobs_applications.update_many(
            {"worker_id": old_id},
            {"$set": {"worker_id": new_id}}
        )
        
        # Reports by/against this user
        db.jobs_reports.update_many(
            {"reporter_id": old_id},
            {"$set": {"reporter_id": new_id}}
        )
        db.jobs_reports.update_many(
            {"target_id": old_id, "target_type": "user"},
            {"$set": {"target_id": new_id}}
        )
        
        # Moderation actions
        db.jobs_moderation_actions.update_many(
            {"actor_id": old_id},
            {"$set": {"actor_id": new_id}}
        )
        db.jobs_moderation_actions.update_many(
            {"target_id": old_id, "target_type": "user"},
            {"$set": {"target_id": new_id}}
        )
        
        updated_count += 1
        print(f"  Migrated: {old_id} -> {new_id}")
    
    print(f"\n✅ Migration complete. Updated {updated_count} users.")

if __name__ == "__main__":
    print("=" * 50)
    print("User ID Migration: u_ -> usr_")
    print("=" * 50)
    
    confirm = input("This will modify the database. Continue? [y/N]: ")
    if confirm.lower() == 'y':
        migrate_user_ids()
    else:
        print("Aborted.")
