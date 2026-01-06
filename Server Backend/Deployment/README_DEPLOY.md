# Deployment Instructions - Digital Ocean VPS

## Prerequisites
- SSH Access to the VPS (IP: 68.183.231.91)
- Local machine has `Sentinel - Server Production` folder.

## Steps

1. **Upload Codebase**
   Upload the entire `Sentinel - Server Production` directory to the VPS. This ensures all components (Backend, Admin Console) are available for the build.
   ```bash
   scp -r "Sentinel - Server Production" root@68.183.231.91:/root/
   ```

2. **Connect to VPS**
   ```bash
   ssh root@68.183.231.91
   ```

3. **Navigate to Deployment Folder**
   ```bash
   cd "Sentinel - Server Production/Server Backend/Deployment"
   ```

4. **Run Setup Script**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

5. **Create Superuser (First Time Only)**
   Access the web container to create the initial admin account (for 2FA setup).
   ```bash
   docker-compose -f docker-compose.prod.yml exec web python manage.py migrate
   docker-compose -f docker-compose.prod.yml exec web python manage.py createsuperuser
   ```

6. **Access Admin Console**
   - Go to `http://68.183.231.91/admin_portal`
   - Login with the superuser credentials.
   - You will be prompted to setup 2FA.
