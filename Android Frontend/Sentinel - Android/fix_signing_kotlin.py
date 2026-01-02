import os

gradle_path = 'android/app/build.gradle.kts'

# 1. READ FILE
if not os.path.exists(gradle_path):
    print(f"ERROR: Could not find {gradle_path}")
    exit(1)

with open(gradle_path, 'r') as f:
    content = f.read()

# 2. DEFINITIONS (Kotlin Syntax)
imports_block = """import java.util.Properties
import java.io.FileInputStream
"""

loader_block = """
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {"""

signing_block = """    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {"""

release_link = 'signingConfig = signingConfigs.getByName("release")'

# 3. INJECT IMPORTS
if "import java.util.Properties" not in content:
    content = imports_block + content
    print(">> Added Imports")

# 4. INJECT LOADER
if "val keystoreProperties" not in content:
    content = content.replace("android {", loader_block)
    print(">> Added Keystore Loader")

# 5. INJECT SIGNING CONFIG
if "create(\"release\")" not in content:
    content = content.replace("buildTypes {", signing_block)
    print(">> Added Signing Config block")

# 6. LINK RELEASE BUILD
# This looks for the release block and adds the signingConfig line if missing
if "signingConfig =" not in content and 'getByName("release")' in content:
    # Standard Flutter structure usually has getByName("release") { ... }
    target_str = 'getByName("release") {'
    content = content.replace(target_str, target_str + "\n            " + release_link)
    print(">> Linked Release Build to Signing Config")

# 7. SAVE
with open(gradle_path, 'w') as f:
    f.write(content)
print(">> KOTLIN BUILD FILE PATCHED SUCCESSFULLY.")
