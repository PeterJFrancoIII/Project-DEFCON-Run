import google.generativeai as genai
import os

# Setup paths to find .env.local
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
env_file = os.path.join(BASE_DIR, '.env.local')

# Load key manually
if os.path.exists(env_file):
    with open(env_file, 'r') as f:
        for line in f:
            if line.strip() and not line.startswith('#') and 'GEMINI_API_KEY' in line:
                key = line.split('=')[1].strip()
                os.environ['GEMINI_API_KEY'] = key
                break

api_key = os.environ.get('GEMINI_API_KEY')
if not api_key:
    print("No API KEY found in .env.local")
    exit(1)

genai.configure(api_key=api_key)

print(f">> Listing Models for Key: {api_key[:5]}...")
try:
    found = False
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            found = True
            print(f" - {m.name}")
    
    if not found:
        print("No models found supporting generateContent.")

except Exception as e:
    print(f"Error listing models: {e}")
