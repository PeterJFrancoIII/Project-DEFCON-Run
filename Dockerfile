# PULL OFFICIAL PYTHON IMAGE
FROM python:3.9-slim

# SET WORKING DIRECTORY
WORKDIR /home/app/web

# SET ENVIRONMENT VARIABLES
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# INSTALL SYSTEM DEPENDENCIES (Netcat is needed for the database check)
RUN apt-get update && apt-get install -y netcat

# INSTALL PYTHON DEPENDENCIES
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# COPY PROJECT FILES
COPY . .

# CREATE STATIC FOLDERS
RUN mkdir -p /home/app/web/staticfiles
RUN mkdir -p /home/app/web/mediafiles
