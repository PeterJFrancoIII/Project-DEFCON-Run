# PULL OFFICIAL PYTHON IMAGE
FROM python:3.9-slim

# SET WORKING DIRECTORY
WORKDIR /home/app

# SET ENVIRONMENT VARIABLES
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# INSTALL SYSTEM DEPENDENCIES
RUN apt-get update && apt-get install -y netcat-openbsd

# INSTALL PYTHON DEPENDENCIES
RUN pip install --upgrade pip
# Copy requirements from the Server Backend folder (Context is Project Root)
COPY ["Server Backend/requirements.txt", "."]
RUN pip install --no-cache-dir -r requirements.txt

# COPY PROJECT FILES
# Copy Server Backend contents to /home/app/web
COPY ["Server Backend", "/home/app/web"]

# Copy Admin Console to /home/app/Admin Console (sibling to web)
COPY ["Admin Console", "/home/app/Admin Console"]

# CREATE STATIC FOLDERS
RUN mkdir -p "/home/app/web/staticfiles"
RUN mkdir -p "/home/app/web/mediafiles"

# Set Workdir to web for running commands
WORKDIR "/home/app/web"
