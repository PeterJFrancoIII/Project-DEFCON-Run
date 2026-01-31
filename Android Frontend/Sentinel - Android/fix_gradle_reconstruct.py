import re
import os

gradle_path = 'android/app/build.gradle.kts'

if not os.path.exists(gradle_path):
    print(f"CRITICAL: Could not find {gradle_path}")
    exit(1)

# 1. READ BROKEN FILE TO RESCUE CONFIG
with open(gradle_path, 'r') as f:
    old_content = f.read()

# Try to find namespace and applicationId using regex
namespace_match = re.search(r'namespace\s*=\s*[\'"](.*?)[\'"]', old_content)
app_id_match = re.search(r'applicationId\s*=\s*[\'"](.*?)[\'"]', old_content)

# Default fallbacks if regex fails (unlikely if standard flutter create)
namespace = namespace_match.group(1) if namespace_match else "com.example.sentinel"
app_id = app_id_match.group(1) if app_id_match else "com.example.sentinel"

print(f">> Rescued Configuration:")
print(f"   Namespace: {namespace}")
print(f"   App ID:    {app_id}")

# 2. DEFINE THE CLEAN KOTLIN TEMPLATE
# This template is 100% valid Kotlin DSL for Flutter, with Signing Config integrated.
new_content = f"""plugins {{
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}}

import java.util.Properties
import java.io.FileInputStream

// LOAD KEYSTORE PROPERTIES
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {{
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}}

android {{
    namespace = "{namespace}"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {{
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }}

    kotlinOptions {{
        jvmTarget = "1.8"
    }}

    sourceSets {{
        getByName("main").java.srcDirs("src/main/kotlin")
    }}

    defaultConfig {{
        applicationId = "{app_id}"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }}

    // SIGNING CONFIGURATION
    signingConfigs {{
        create("release") {{
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }}
    }}

    buildTypes {{
        getByName("release") {{
            // LINK SIGNING CONFIG TO RELEASE BUILD
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }}
    }}
}}

flutter {{
    source = "../.."
}}
"""

# 3. OVERWRITE FILE
with open(gradle_path, 'w') as f:
    f.write(new_content)

print(">> SUCCESS: build.gradle.kts has been completely reconstructed.")
