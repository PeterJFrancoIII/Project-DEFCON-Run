#!/bin/bash
set -e

# Configuration
VPS_USER="root"
VPS_HOST="146.190.7.51"
FLUTTER_BUILD_DIR="Android Frontend/Sentinel - Android/build/web"
BACKEND_DIR="Server Backend"
REMOTE_BASE="/root/Server Backend"

echo ">> [DEPLOY] Starting VPS Deployment..."

# 1. Create Remote Directory for Flutter
echo ">> [DEPLOY] Creating remote flutter_web directory..."
ssh $VPS_USER@$VPS_HOST "mkdir -p '$REMOTE_BASE/flutter_web'"

# 2. Upload Flutter Web Build
echo ">> [DEPLOY] Uploading Flutter Web Build..."
scp -r "$FLUTTER_BUILD_DIR/"* $VPS_USER@$VPS_HOST:"$REMOTE_BASE/flutter_web/"

# 3. Upload Backend Code (Updates for Admin/Jobs/Nginx)
echo ">> [DEPLOY] Uploading Scoped Backend Code..."
# We explicitly upload folders that changed. 
# NOT uploading venv, mongodb_data, or __pycache__
scp -r "$BACKEND_DIR/core" "$BACKEND_DIR/jobs" "$BACKEND_DIR/Admin Console" "$BACKEND_DIR/nginx" "$BACKEND_DIR/docker-compose.prod.yml" $VPS_USER@$VPS_HOST:"$REMOTE_BASE/"

# 4. Restart Services
echo ">> [DEPLOY] Restarting Services on VPS..."
ssh $VPS_USER@$VPS_HOST << 'EOF'
    echo ">> [VPS] Restarting Docker Services..."
    cd "/root/Server Backend" || exit 1
    
    # Force Rebuild of Nginx to pick up new config
    # Force Rebuild of Web to pick up new python code
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml up -d --build --remove-orphans
    
    echo ">> [VPS] Services Restarted."
EOF

echo ">> [DEPLOY] Deployment Complete."
echo ">> Please verify at http://$VPS_HOST/"
