#!/bin/bash

# Define API Key
export GEMINI_API_KEY="AIzaSyDAqXQXtWm85QakcmQFqOIVQmDR3MjX4Y0"

echo ">> [1/6] Repairing Directory Structure..."
# Ensure we are in a Django project or create one
if [ ! -f "manage.py" ]; then
    echo "manage.py not found. Creating project 'config'..."
    python3 -m django startproject config .
fi

# Force create app directories
mkdir -p marketplace/management/commands
mkdir -p marketplace/templates/marketplace
touch marketplace/__init__.py
touch marketplace/management/__init__.py
touch marketplace/management/commands/__init__.py

echo ">> [2/6] Writing Database Models (News + Routes + Hotels)..."
cat << 'PY_MODELS' > marketplace/models.py
from djongo import models

# 1. TRACKED ZONES (Zip Codes)
class TrackedZone(models.Model):
    zip_code = models.CharField(max_length=20, unique=True)
    country = models.CharField(max_length=2, default='TH')
    last_analyzed = models.DateTimeField(auto_now=True)
    def __str__(self): return self.zip_code

# 2. EVACUATION ROUTE
class EvacuationRoute(models.Model):
    origin_zone = models.ForeignKey(TrackedZone, on_delete=models.CASCADE)
    destination_name = models.CharField(max_length=200)
    route_description = models.TextField()
    estimated_travel_time = models.CharField(max_length=100)
    risk_level = models.CharField(max_length=50)

# 3. LODGING (Linked to Route)
class Lodging(models.Model):
    linked_route = models.ForeignKey(EvacuationRoute, on_delete=models.CASCADE, null=True)
    name = models.CharField(max_length=200)
    address = models.TextField()
    phone_number = models.CharField(max_length=50)
    availability = models.CharField(max_length=20, default="Unknown")
    latitude = models.FloatField(null=True)
    longitude = models.FloatField(null=True)

# 4. LOCAL NEWS (Linked to Zone)
class LocalNews(models.Model):
    linked_zone = models.ForeignKey(TrackedZone, on_delete=models.CASCADE)
    headline = models.CharField(max_length=255)
    snippet = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    severity = models.IntegerField(default=1)
    class Meta: ordering = ['-timestamp']
PY_MODELS

echo ">> [3/6] Writing Views (Zip Logic)..."
cat << 'PY_VIEWS' > marketplace/views.py
from django.shortcuts import render
from django.http import JsonResponse
from .models import TrackedZone, EvacuationRoute, Lodging, LocalNews
import json

def front_page(request):
    user_zip = request.session.get('user_zip')
    user_country = request.session.get('country_code', 'TH')
    context = {}

    if not user_zip:
        context['prompt_location'] = True
    else:
        # Find or Create Zone
        zone, created = TrackedZone.objects.get_or_create(
            zip_code=user_zip, 
            defaults={'country': user_country}
        )
        context['current_zip'] = user_zip
        
        if created:
            context['status_msg'] = "New Zone Detected. AI Agent queued. Check back shortly."
            context['prompt_location'] = False
        else:
            route = EvacuationRoute.objects.filter(origin_zone=zone).first()
            if route:
                context['route'] = route
                context['lodgings'] = Lodging.objects.filter(linked_route=route)
                context['news'] = LocalNews.objects.filter(linked_zone=zone)
                context['prompt_location'] = False
            else:
                context['status_msg'] = "Calculating Evacuation Plan... (Agent Active)"
                context['prompt_location'] = False

    return render(request, 'marketplace/front_page.html', context)

def set_location(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        method = data.get('method')
        if method == 'manual':
            request.session['user_zip'] = data.get('zip_code')
            request.session['country_code'] = data.get('country')
        elif method == 'gps':
             lat = data.get('lat')
             zip_c = "10110" if lat > 12 else "23000"
             request.session['user_zip'] = zip_c
             request.session['country_code'] = 'TH'
        return JsonResponse({'status': 'ok'})
    return JsonResponse({'status': 'err'}, status=400)
PY_VIEWS

echo ">> [4/6] Writing Gemini Agent..."
cat << 'PY_AGENT' > marketplace/management/commands/fetch_evac_intel.py
from django.core.management.base import BaseCommand
from marketplace.models import TrackedZone, EvacuationRoute, Lodging, LocalNews
import google.generativeai as genai
import json
import os
import time

class Command(BaseCommand):
    help = 'Generates custom Evac Plans for tracked Zips'

    def handle(self, *args, **options):
        api_key = os.environ.get('GEMINI_API_KEY')
        if not api_key:
            self.stdout.write("ERROR: GEMINI_API_KEY missing.")
            return
        
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.0-flash-exp')

        # SEED DEFAULTS if empty
        if TrackedZone.objects.count() == 0:
            TrackedZone.objects.create(zip_code="23000", country="TH") # Trat
            TrackedZone.objects.create(zip_code="10110", country="TH") # BKK
        
        zones = TrackedZone.objects.all()
        print(f">> [AGENT] Analyzing {zones.count()} Zones...")

        for zone in zones:
            print(f"   > Processing Zip: {zone.zip_code}...")
            prompt = f"""
            Act as a Crisis Manager. Create an evacuation plan for Zip Code {zone.zip_code} in {zone.country}.
            Return STRICT JSON with keys:
            1. "route": {{ "destination": "Safe City Name", "instructions": "Brief directions", "travel_time": "Time", "risk": "High/Med/Low" }}
            2. "lodgings": [Array of 5 hotels at destination: name, address, phone, availability (AV/BK), lat, lon]
            3. "news": [Array of 3 news headlines for this origin: headline, snippet, severity (1-5)]
            """
            try:
                response = model.generate_content(prompt)
                text = response.text.replace('```json', '').replace('```', '').strip()
                data = json.loads(text)

                EvacuationRoute.objects.filter(origin_zone=zone).delete()
                route = EvacuationRoute.objects.create(
                    origin_zone=zone,
                    destination_name=data['route']['destination'],
                    route_description=data['route']['instructions'],
                    estimated_travel_time=data['route']['travel_time'],
                    risk_level=data['route']['risk']
                )

                Lodging.objects.filter(linked_route=route).delete()
                for l in data['lodgings']:
                    Lodging.objects.create(
                        linked_route=route,
                        name=l['name'],
                        address=l['address'],
                        phone_number=l['phone'],
                        availability=l.get('availability', 'UN'),
                        latitude=l.get('lat'),
                        longitude=l.get('lon')
                    )

                LocalNews.objects.filter(linked_zone=zone).delete()
                for n in data['news']:
                    LocalNews.objects.create(
                        linked_zone=zone,
                        headline=n['headline'],
                        snippet=n['snippet'],
                        severity=n['severity']
                    )
                print(f"     [+] Plan generated for {zone.zip_code}")
                time.sleep(2) 
            except Exception as e:
                print(f"     [!] Failed {zone.zip_code}: {e}")
PY_AGENT

echo ">> [5/6] Resetting Database..."
# Wipe migrations and database to start fresh with new schema
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
rm -f db.sqlite3
python3 manage.py makemigrations marketplace
python3 manage.py migrate

echo ">> [6/6] Running Agent First Pass..."
python3 manage.py fetch_evac_intel

echo ">> SETUP COMPLETE. Starting Server..."
python3 manage.py runserver 0.0.0.0:5001
