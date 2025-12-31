import os
import shutil
import re

# --- CONFIGURATION ---
NEW_PACKAGE = "com.sentinel.defcon"
NEW_PATH_SUFFIX = NEW_PACKAGE.replace('.', '/')
PROJECT_ROOT = "android/app"
KOTLIN_ROOT = f"{PROJECT_ROOT}/src/main/kotlin"

print(f">> INITIATING PACKAGE RENAME TO: {NEW_PACKAGE}")

# 1. LOCATE MAIN ACTIVITY & DETERMINE OLD PACKAGE
main_activity_path = None
old_package = None

for root, dirs, files in os.walk(KOTLIN_ROOT):
    if "MainActivity.kt" in files:
        main_activity_path = os.path.join(root, "MainActivity.kt")
        # Derive old package from path structure relative to KOTLIN_ROOT
        # e.g., .../kotlin/com/example/sentinel -> com.example.sentinel
        rel_path = os.path.relpath(root, KOTLIN_ROOT)
        old_package = rel_path.replace(os.sep, '.')
        break

if not main_activity_path:
    print("CRITICAL: Could not find MainActivity.kt. Is this a standard Flutter project?")
    exit(1)

print(f">> FOUND OLD PACKAGE: {old_package}")

# 2. MOVE MAIN ACTIVITY TO NEW STRUCTURE
new_dir = os.path.join(KOTLIN_ROOT, NEW_PATH_SUFFIX)
os.makedirs(new_dir, exist_ok=True)
new_main_activity_path = os.path.join(new_dir, "MainActivity.kt")

# Read content, update package declaration, write to new location
with open(main_activity_path, 'r') as f:
    content = f.read()

new_content = content.replace(f"package {old_package}", f"package {NEW_PACKAGE}")

with open(new_main_activity_path, 'w') as f:
    f.write(new_content)

print(f">> MOVED MainActivity.kt to {new_dir}")

# 3. CLEAN UP OLD DIRECTORIES
# Only delete if empty and not the same as new path
old_dir = os.path.dirname(main_activity_path)
if os.path.abspath(old_dir) != os.path.abspath(new_dir):
    try:
        shutil.rmtree(os.path.join(KOTLIN_ROOT, old_package.split('.')[0]))
        print(">> CLEANED up old directories.")
    except Exception as e:
        print(f">> NOTE: Could not fully clean old dirs (harmless): {e}")

# 4. UPDATE BUILD.GRADLE.KTS
gradle_path = f"{PROJECT_ROOT}/build.gradle.kts"
with open(gradle_path, 'r') as f:
    gradle_content = f.read()

# Replace namespace and appId
# We use a generic regex to catch whatever was there before
gradle_content = re.sub(r'namespace\s*=\s*".*?"', f'namespace = "{NEW_PACKAGE}"', gradle_content)
gradle_content = re.sub(r'applicationId\s*=\s*".*?"', f'applicationId = "{NEW_PACKAGE}"', gradle_content)

with open(gradle_path, 'w') as f:
    f.write(gradle_content)
print(">> UPDATED build.gradle.kts")

# 5. UPDATE MANIFESTS (Debug, Main, Profile)
manifest_files = [
    f"{PROJECT_ROOT}/src/main/AndroidManifest.xml",
    f"{PROJECT_ROOT}/src/debug/AndroidManifest.xml",
    f"{PROJECT_ROOT}/src/profile/AndroidManifest.xml"
]

for m_file in manifest_files:
    if os.path.exists(m_file):
        with open(m_file, 'r') as f:
            m_content = f.read()
        # Some manifests might still use the package attribute
        if old_package in m_content:
            m_content = m_content.replace(old_package, NEW_PACKAGE)
            with open(m_file, 'w') as f:
                f.write(m_content)
            print(f">> UPDATED {m_file}")

print(">> SUCCESS: IDENTITY SHIFT COMPLETE.")
