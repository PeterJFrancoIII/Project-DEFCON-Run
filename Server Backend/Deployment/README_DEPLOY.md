# Deployment Instructions - Digital Ocean VPS

## Prerequisites
- SSH Access to the VPS (IP: 146.190.7.51)
- Local machine has `Sentinel - Production` folder.

## Steps

1. **Upload Codebase**
   Upload the entire `Sentinel - Production` directory to the VPS. This ensures all components (Backend, Admin Console) are available for the build.
   ```bash
   scp -r "Sentinel - Production" root@146.190.7.51:/root/
   ```

2. **Connect to VPS**
   ```bash
   ssh root@146.190.7.51
   ```

3. **Navigate to Deployment Folder**
   ```bash
   cd "/root/Server Backend/Deployment"
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
   - Go to `http://146.190.7.51/admin_portal`
   - Login with the superuser credentials.
   - You will be prompted to setup 2FA.
