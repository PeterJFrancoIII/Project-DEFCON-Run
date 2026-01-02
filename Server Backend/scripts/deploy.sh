#!/bin/bash
# ==============================================================================
# SAFE DEPLOYMENT SCRIPT (Non-Interactive)
# ==============================================================================
set -e 

echo "--- STARTING SAFE DEPLOYMENT ---"
export DEBIAN_FRONTEND=noninteractive

# 1. Update System
echo "--- Updating System Lists ---"
sudo apt-get update

# 2. Install Docker (Only if missing)
if ! [ -x "$(command -v docker)" ]; then
  echo "--- Installing Docker ---"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# 3. Install Docker Compose (Only if missing)
if ! [ -x "$(command -v docker-compose)" ]; then
  echo "--- Installing Docker Compose ---"
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# 4. Create Folders
mkdir -p mongo_data static_volume media_volume

# 5. Stop Containers (Ignore errors if none running)
sudo docker-compose -f docker-compose.prod.yml down || true

# 6. Launch App
echo "--- Launching App ---"
sudo docker-compose -f docker-compose.prod.yml up -d --build

# 7. Migrate & Collect Static
echo "--- Running Migrations ---"
sudo docker-compose -f docker-compose.prod.yml exec -T web python manage.py migrate
sudo docker-compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput

echo "--- DEPLOYMENT SUCCESSFUL! ---"
