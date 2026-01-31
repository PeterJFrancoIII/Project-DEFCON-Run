# NAMING

Reference: /Naming_Conventions.md

## Directory/File Structure
Root Modules: Proper Case - Description (Sentinel - Development)
Backend Modules: snake_case (jobs_v2)
Frontend Folders: snake_case
Dart Files: snake_case.dart
HTML Templates: snake_case.html

## Database (MongoDB)
Collections: module_entity snake_case (jobs_users, jobs_posts, jobs_applications, jobs_reports, jobs_moderation_actions)
Fields: snake_case (trust_score)
Primary Keys: prefix_timestamp (usr_173750...)

ID Prefixes: User=usr_, Job=job_, App=app_, Report=rpt_, Moderation=mod_, Event=evt_, Source=src_, Claim=clm_, Evidence=evd_
Forbidden: u_, act_

## API/Networking
Base URL: /api/module_version/... (always versioned)
Endpoints: snake_case or kebab-case
Query Params: snake_case (?account_id=...)
Auth Headers: X-Custom-Header format (X-Admin-Secret)

## Code Standards
Python: snake_case vars/funcs, PascalCase classes, UPPER_SNAKE_CASE constants, snake_case.py files
Dart: camelCase vars/funcs, PascalCase classes, snake_case.dart files
JS: camelCase vars/funcs, PascalCase classes, kebab-case DOM IDs (#jobs-listings-table), snake_case.js files

## Domain Terms
Employer=verified user posting jobs, Worker=user applying, Listing=job post, Application=worker request, TrustScore=0-100 int, RiskScore=0.0-1.0 float

Enforcement: New code must comply. Modified code must migrate. Violations block PR.
