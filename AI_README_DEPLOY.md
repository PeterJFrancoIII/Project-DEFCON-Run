# AI Protocol: Server Deployment (VPS)

**OBJECTIVE**: Deploy the LocalHost codebase to the Production VPS (`146.190.7.51`) flawlessly.

**TARGET ENVIRONMENT**:
- **IP**: `146.190.7.51`
- **User**: `root` (Requires SSH Key Access)
- **Path**: `/root/Server Backend/Deployment`

## 1. Preparation (Local Modifications)
Before uploading, the AI must ensure the local files are configured for PRODUCTION.

### A. API Key (Production)
- **File**: `Server Backend/Developer Inputs/api_config.py`
- **Action**: Replace Development Key with **PRODUCTION KEY**.
  ```python
  # Ensure this key is valid and NOT leaked
  GEMINI_API_KEY = "AIza..." 
  ```

### B. CORS Configuration (Connectivity)
- **File**: `Server Backend/core/settings.py`
- **Action**: Ensure usage of `django-cors-headers` to allow App/Web access.
  - **INSTALLED_APPS**: Add `'corsheaders'`.
  - **MIDDLEWARE**: Add `'corsheaders.middleware.CorsMiddleware'` (Top of list).
  - **Variable**: Add `CORS_ALLOW_ALL_ORIGINS = True`.

## 2. Deployment Sequence (Remote Execution)

### Step 1: Upload Critical Configs
Use `scp` to patch the server files. **CRITICAL**: Use single quotes for paths with spaces.

```bash
# Upload Settings (CORS Fix)
scp "Server Backend/core/settings.py" root@146.190.7.51:'/root/Server Backend/core/settings.py'

# Upload API Config (Production Key)
scp "Server Backend/Developer Inputs/api_config.py" root@146.190.7.51:'/root/Server Backend/Developer Inputs/api_config.py'
```

### Step 2: Rebuild & Restart Services
Connect via SSH and force a Docker rebuild to bake in the new code.

```bash
ssh root@146.190.7.51 << 'EOF'
    echo ">> [VPS] Starting Deployment..."
    cd "/root/Server Backend/Deployment"
    
    # 1. Stop existing containers
    docker-compose -f docker-compose.prod.yml down
    
    # 2. Rebuild and Start (Detached)
    docker-compose -f docker-compose.prod.yml up -d --build
    
    echo ">> [VPS] Deployment Complete."
EOF
```

## 3. Post-Deployment Verification
Run this command locally to verify the server is responding to public traffic:

```bash
# Expect HTTP 200 OK + JSON Response
curl -v "http://146.190.7.51/intel?zip=10110&country=TH&lang=en"
```

## 4. Mobile App Release Switch
**NOTE**: If building the Android APK for release:
- **File**: `Android Frontend/Sentinel - Android/lib/main.dart`
- **Action**: Change `serverUrl` back to VPS IP:
  ```dart
  return "http://146.190.7.51"; 
  ```
