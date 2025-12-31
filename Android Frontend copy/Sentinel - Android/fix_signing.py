import os

gradle_path = 'android/app/build.gradle.kts'

# 1. READ FILE
with open(gradle_path, 'r') as f:
    content = f.read()

# 2. DEFINE CONFIG BLOCKS
loader_block = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {"""

signing_block = """    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {"""

# 3. INJECT LOADER
if "def keystoreProperties" not in content:
    content = content.replace("android {", loader_block)
    print(">> Injected Keystore Loader")
else:
    print(">> Keystore Loader already present.")

# 4. INJECT SIGNING CONFIG
if "signingConfigs {" not in content:
    content = content.replace("buildTypes {", signing_block)
    print(">> Injected Signing Configs")
else:
    print(">> Signing Configs already present.")

# 5. ACTIVATE RELEASE SIGNING
if "signingConfig signingConfigs.debug" in content:
    content = content.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
    print(">> Activated Release Signing")

# 6. SAVE
with open(gradle_path, 'w') as f:
    f.write(content)
print(">> BUILD.GRADLE VERIFIED.")
