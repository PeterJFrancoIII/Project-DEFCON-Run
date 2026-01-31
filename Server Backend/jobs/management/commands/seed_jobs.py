import random
import uuid
import datetime
from django.core.management.base import BaseCommand
from jobs.db_models import JobsDAO

class Command(BaseCommand):
    help = 'Seeds the database with sample job board data (Employers, Workers, Listings)'

    def handle(self, *args, **options):
        self.stdout.write("Starting Job Board Seed...")

        # --- 1. Create Employers ---
        employers_data = [
            {
                "email": "recruit@sentinel-heavy.com",
                "phone": "555-0101",
                "password": "password123", # Note: Real auth handles passwords, here we play pretend or just need Account ID
                "name": "Sentinel Heavy Industries",
                "role_type": "employer",
                "bio": "Leading provider of heavy logistics and defense infrastructure.",
                "location": "Sector 7, Industrial Zone"
            },
            {
                "email": "hr@aegis-security.com",
                "phone": "555-0102",
                "password": "password123",
                "name": "Aegis Security Solutions",
                "role_type": "employer",
                "bio": "Private security for high-risk assets and VIPs.",
                "location": "Downtown Metro"
            },
            {
                "email": "ops@biomed-response.org",
                "phone": "555-0103",
                "password": "password123",
                "name": "BioMed Response Team",
                "role_type": "employer",
                "bio": "Emergency medical response and hazardous material containment.",
                "location": "Medical District"
            },
            {
                "email": "dispatch@city-infra.gov",
                "phone": "555-0104",
                "password": "password123",
                "name": "City Infrastructure Corps",
                "role_type": "employer",
                "bio": "maintaining the city's lifeline services.",
                "location": "City Hall"
            }
        ]

        employer_ids = []
        for emp in employers_data:
            existing = JobsDAO.get_account_by_email(emp['email'])
            if existing:
                self.stdout.write(f"Employer {emp['email']} already exists.")
                employer_ids.append(existing['account_id'])
            else:
                aid = JobsDAO.create_account({
                    "email": emp['email'],
                    "phone": emp['phone'],
                    "roles": {"employer": True, "worker": False},
                    "bio": emp['bio'],
                    "home_address": emp['location'],
                    "name": emp['name'], # Storing name in root for convenience, though schema usually puts it in profile?
                    # Schema doesn't strictly enforce 'name' in create_account, but we pass **data. 
                    # Usually user management handles this. We will assume it's okay.
                })
                self.stdout.write(f"Created Employer: {emp['name']} ({aid})")
                employer_ids.append(aid)

        # --- 2. Create Workers ---
        workers_data = [
            {
                "email": "john.doe@worker.com",
                "phone": "555-0201",
                "name": "John Doe",
                "bio": "Reliable general laborer. Experience in warehousing and basic repairs.",
                "skills": [{"name": "Lifting", "score": 8}, {"name": "Forklift", "score": 6}],
                "job_types_broad": ["Logistics", "Construction"],
                "job_types_specific": ["Warehouse Mover", "Site Cleanup"],
                "availability": "Weekdays",
                "experience_level": "Entry",
                "work_radius": "10 miles",
                "certifications": ["OSHA 10"],
                "languages": ["English"]
            },
            {
                "email": "sarah.connor@resistance.net",
                "phone": "555-0202",
                "name": "Sarah Connor",
                "bio": "Specialized security consultant. High threat environment experience.",
                "skills": [{"name": "Firearms", "score": 10}, {"name": "CQC", "score": 9}, {"name": "Risk Assessment", "score": 10}],
                "job_types_broad": ["Security", "Defense"],
                "job_types_specific": ["Bodyguard", "Perimeter Defense"],
                "availability": "Anytime",
                "experience_level": "Expert",
                "work_radius": "Any",
                "certifications": ["CCW", "Adv First Aid"],
                "languages": ["English", "Spanish"]
            },
            {
                "email": "ripley@weyman.corp",
                "phone": "555-0203",
                "name": "Ellen Ripley",
                "bio": "Heavy loader operator. Hazardous environment certified.",
                "skills": [{"name": "Heavy Loader", "score": 10}, {"name": "Hazmat", "score": 9}],
                "job_types_broad": ["Logistics", "Hazardous"],
                "job_types_specific": ["Exosuit Operator", "Cargo Loader"],
                "availability": "Contract",
                "experience_level": "Expert",
                "work_radius": "50 miles",
                "certifications": ["Class 2 Loader", "Hazmat Lv 5"],
                "languages": ["English"]
            }
        ]

        for w in workers_data:
            existing = JobsDAO.get_account_by_email(w['email'])
            if not existing:
                aid = JobsDAO.create_account({
                    "email": w['email'],
                    "phone": w['phone'],
                    "roles": {"employer": False, "worker": True},
                    "bio": w['bio'],
                    "skills": w['skills'],
                    "job_types_broad": w['job_types_broad'],
                    "job_types_specific": w['job_types_specific'],
                    "availability": w['availability'],
                    "experience_level": w['experience_level'],
                    "work_radius": w['work_radius'],
                    "certifications": w['certifications'],
                    "languages": w['languages'],
                    "name": w['name']
                })
                self.stdout.write(f"Created Worker: {w['name']} ({aid})")
            else:
                self.stdout.write(f"Worker {w['email']} already exists.")

        # --- 3. Create Job Listings ---
        titles_logistics = ["Heavy Lifter Needed", "Night Shift Warehouse", "Cargo Loader", "Supply Run Driver"]
        titles_security = ["VIP Escort", "Night Watchman", "Perimeter Guard", "Event Security"]
        titles_medical = ["Emergency EMT", "Triage Nurse Assistant", "Hazmat Cleanup", "Medical Supply Courier"]
        titles_infra = ["Road Repair Crew", "Power Line Technician", "Sewer Maintenance", "Debris Clearance"]

        locations = [
            {"city": "Metro City", "state": "CA", "zip": "90001", "geo": [-118.2437, 34.0522]},
            {"city": "Industrial District", "state": "CA", "zip": "90023", "geo": [-118.1937, 34.0122]},
            {"city": "North Sector", "state": "CA", "zip": "90012", "geo": [-118.2437, 34.0722]},
            {"city": "West Side", "state": "CA", "zip": "90401", "geo": [-118.4912, 34.0195]},
        ]

        urgencies = ["Normal", "High", "Critical"]
        risks = ["Low", "Medium", "High"]

        # Generate 20 Random Jobs
        for i in range(20):
            employer_id = random.choice(employer_ids)
            
            # Pick category based on employer logic (heuristic)
            if employer_ids.index(employer_id) == 0: # Sentinel Heavy
                cat = "Logistics"
                title = random.choice(titles_logistics)
            elif employer_ids.index(employer_id) == 1: # Aegis
                cat = "Security"
                title = random.choice(titles_security)
            elif employer_ids.index(employer_id) == 2: # BioMed
                cat = "Medical"
                title = random.choice(titles_medical)
            else: # City Infra
                cat = "Construction"
                title = random.choice(titles_infra)

            loc = random.choice(locations)
            urgency = random.choice(urgencies)
            risk = random.choice(risks)
            
            # Make some "Urgent/High Risk" matches
            if urgency == "Critical":
                risk = "High"

            amount = random.randint(20, 150)
            pay = f"${amount}/hr"

            desc = f"Looking for a qualified {title} for immediate deployment. "
            if urgency == "Critical":
                desc += "URGENT RESPONSE REQUIRED. "
            if risk == "High":
                desc += "HAZARD PAY INCLUDED. "
            desc += "Must be reliable and verified."

            job_data = {
                "employer_account_id": employer_id,
                "title": title,
                "description": desc,
                "category": cat,
                "urgency": urgency,
                "risk_level": risk,
                "location": {
                    "city": loc["city"],
                    "state": loc["state"],
                    "zip": loc["zip"],
                    "geo": loc["geo"] # raw list [lon, lat] is fine for basic storage, 2dsphere index needs it this way
                },
                "pay": pay,
                "duration": f"{random.randint(1, 12)} months",
                "requirements": ["Valid ID", "Background Check"],
                "status": "active",
                "visible_to_clients": True
            }

            JobsDAO.create_listing(job_data)
        
        self.stdout.write(self.style.SUCCESS("Successfully seeded job board data!"))
