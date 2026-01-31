#!/bin/bash

# Deployment Setup Script for Sentinel Server
# Run this on the Digital Ocean VPS

# 1. Update System
echo "Updating system..."
apt-get update && apt-get upgrade -y

# 2. Install Docker & Docker Compose (if not present)
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null
then
    echo "Installing Docker Compose..."
    apt-get install -y docker-compose
fi

# 3. Create .env.prod if not exists (User should edit this)
if [ ! -f .env.prod ]; then
    echo "Creating .env.prod..."
    echo "DEBUG=0" > .env.prod
    echo "SECRET_KEY=$(openssl rand -hex 32)" >> .env.prod
    echo "DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 [YOUR_DROPLET_IP]" >> .env.prod
fi

# 4. Build and Run
echo "Building and Deploying Sentinel Containers..."
# Note: existing docker-compose.prod.yml expects context ../.. which works if we are in Server Backend/Deployment
# BUT on the server, we might just have this folder content.
# This script assumes you uploaded the ENTRE Project Root, or at least Server Backend + Admin Console.
# If you are running this from the Deployment folder on the server:

docker-compose -f docker-compose.prod.yml up -d --build

echo "Deployment Complete."
echo "Admin Console: http://[YOUR_IP]/admin_portal"
echo "API: http://[YOUR_IP]/"
