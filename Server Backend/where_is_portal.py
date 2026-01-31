import sys
import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

try:
    import portal_views
    print(f"FOUND: {portal_views.__file__}")
except ImportError as e:
    print(f"ERROR: {e}")
    # Print sys.path to debug
    print("SYS.PATH:")
    for p in sys.path:
        print(p)
