# Fastlane Setup & Automated Deployment Guide

I have set up **Fastlane** for both Android and iOS to automate your deployments. However, for security reasons, you must provide the access credentials.

## 1. Android (Google Play) Setup

### Step A: Generate Service Account Key
1.  Open the **[Google Cloud Console](https://console.cloud.google.com/)**.
2.  Select your project connected to Google Play.
3.  Go to **IAM & Admin** > **Service Accounts**.
4.  Create a Service Account (e.g., `fastlane-deployer`).
5.  **Role**: Grant it `Service Account User`.
6.  **Create Key**: Select **JSON** and download the file.
7.  **Rename** this file to `service_account.json`.
8.  **Move** it to: `Android Frontend/Sentinel - Android/android/service_account.json`

### Step B: Grant Access in Google Play Console
1.  Open **[Google Play Console](https://play.google.com/console)**.
2.  Go to **Users & Permissions** > **Invite new users**.
3.  Enter the **email address** of the Service Account (found in the JSON file).
4.  Grant **Admin** permissions (or at least "Release apps to production").

## 2. iOS (App Store) Setup

### Step A: Generate API Key
1.  Open **[App Store Connect](https://appstoreconnect.apple.com/access/api)**.
2.  Go to **Users and Access**.
3.  Click the **Integrations** tab (sometimes labeled **Keys**).
4.  Look for the **App Store Connect API** section.
5.  Click the **+** button (or "Request Access" if it's your first time) to generate a new key.
6.  **Name**: "Fastlane Upload".
5.  **Access**: "App Manager".
6.  **Download** the `.p8` key file.
7.  **IMPORTANT**: Note the **Key ID** and **Issuer ID** shown on the page.

### Step B: Create JSON Configuration
Create a file named `fastlane_api_key.json` in `Android Frontend/Sentinel - Android/ios/` with this content:

```json
{
  "key_id": "YOUR_KEY_ID",
  "issuer_id": "YOUR_ISSUER_ID",
  "key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----",
  "in_house": false
}
```

## 3. How to Run Deployments

Once the keys are in place:

**Deploy Android:**
```bash
cd "Android Frontend/Sentinel - Android/android"
fastlane deploy
```

**Deploy iOS:**
```bash
cd "Android Frontend/Sentinel - Android/ios"
fastlane release
```
