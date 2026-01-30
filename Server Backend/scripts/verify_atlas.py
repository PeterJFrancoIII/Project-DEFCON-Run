import sys
import os
import django
from django.conf import settings

# Setup Django minimal environment to import views
# (views.py imports django stuff so we need this)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

# Mock Django settings
if not settings.configured:
    settings.configure(
        DEBUG=True,
        SECRET_KEY='secret',
        ROOT_URLCONF='core.urls',
        INSTALLED_APPS=[
            'core',
        ],
    )
    django.setup()

# Now we can import views
from core.views import run_atlas_pipeline

def main():
    print(">> [VERIFY] Starting Atlas G3 Pipeline Test...")
    try:
        text, packets = run_atlas_pipeline()
        print("\n>> [RESULT] Pipeline Completed.")
        print(f"   Total Clean Packets: {len(packets)}")
        print("\n>> [HEADLINES PREVIEW]")
        print(text[:500] + "..." if len(text) > 500 else text)
        
        if packets:
            p = packets[0]
            print("\n>> [SAMPLE PACKET]")
            print(f"   Title: {p.payload.title}")
            print(f"   Score: {p.triage.validity_score}")
            print(f"   Domain: {p.triage.risk_domain}")
            print(f"   History: {p.triage.gate_history}")
            
    except Exception as e:
        print(f"\n>> [ERROR] {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
