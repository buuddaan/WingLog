# WingLog

Backend is a Spring Boot microservice architecture; frontend is Flutter, run live with `flutter run` on port 3000.

## Overview
- Spring Boot microservice backend (7 services + API gateway) with a Flutter frontend.
- JWT auth with Google OAuth; gateway-level routing, JWT validation.
- Application for birdwatchers to store pictures, identify bird species by image or sound, a geo-location pinning feature to share where sightings of birds have taken place.
- Backend runs in Docker; frontend runs live via `flutter run` on port 3000.
- Authors: PVT15 Group 2.


## Architecture

| Service       | Port | Description                          |
|---------------|------|--------------------------------------|
| api-gateway   | 8080 | Routes requests, JWT validation      |
| auth-service  | 8081 | Authentication, Google OAuth, JWT    |
| user-service  | 8082 | User profiles                        |
| geo-service   | 8085 | Sightings + PostGIS geometry         |
| photo-service | 8086 | Photo upload (Cloudinary)            |
| audio-service | 8087 | Audio records, calls birdnet         |
| birdnet       | 5000 | Python/Flask bird-sound ID           |
| frontend      | 3000 | Flutter web                          |


## Prerequisites

- Docker + Docker Compose
- A PostgreSQL instance with the PostGIS extension (see Database setup)
- A Google OAuth client (see OAuth setup)
- Flutter SDK and (Dart 3.11.4+) — required by the `record` package


## Database setup

WingLog uses a **single PostgreSQL database**. You provide your own — no
project database is shipped. Tables are created automatically the first time
the services start (Hibernate `ddl-auto=update`), so you do **not** need a
schema dump. You only need to prepare an empty database before the first run:

**1. Create a database** (or use the default `postgres` database).

**2. Enable the PostGIS extension.** geo-service stores sighting locations as
geometry columns and will fail to start without it:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```
**Note on SSL.** The `sslmode` in `SPRING_DATASOURCE_URL` must match your
database. The shipped `.env.example` uses `sslmode=disable` for a plain local
Postgres. For a provider with SSL (e.g. Supabase, on by default), change it to
`sslmode=require`. A mismatch fails with "The server does not support SSL".


**3. Creating the schemas.** Each service writes to its own schema:

```sql
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS user_schema;
CREATE SCHEMA IF NOT EXISTS geo_schema;
CREATE SCHEMA IF NOT EXISTS photo_schema;
CREATE SCHEMA IF NOT EXISTS audio_schema;
```

After this, the tables themselves are created on first startup. Point the
`DB_*` variables in your `.env` at this database.


## OAuth setup

Register your own Google OAuth client at
https://console.cloud.google.com/apis/credentials :

1. Create an OAuth 2.0 Client ID (type: Web application).
2. Add an authorized redirect URI matching `OAUTH_REDIRECT_URI` in your `.env`
   (e.g. `http://localhost:8081/login/oauth2/code/google`).
3. Put the client ID and secret into `.env`.

For photo-service, create a service account, download its JSON key, and
base64-encode it into `GOOGLE_CREDENTIALS_JSON`:
```bash
base64 -i service-account.json
```

## Cloudinary setup

photo-service stores uploaded images on Cloudinary. Create a free account at
https://cloudinary.com/users/register_free and open the **Dashboard**. Under
**Account Details** (or **API Keys**) you will find the three values to put in
your `.env`:

- `CLOUDINARY_CLOUD_NAME` — the "Cloud name" shown at the top of the dashboard
- `CLOUDINARY_API_KEY` — the "API Key"
- `CLOUDINARY_API_SECRET` — the "API Secret" (click to reveal)


## Configuration

1. Copy the example env file and fill in your own values:
```bash
cp backend/.env.example backend/.env
```
2. Set every variable listed in `.env.example`. No project credentials are
   shipped — all values are your own.


## Frontend (development)

The frontend runs live with Flutter on port 3000. The port matters:
`APP_FRONTEND_URL` in `.env` must match it, otherwise Google OAuth redirects to
the wrong place after login (blank screen with `?code=...` in the URL).

```bash
cd frontend
flutter pub get                       # downloads dependencies
flutter run -d chrome --web-port=3000
```

If you don't have Flutter installed, follow
https://docs.flutter.dev/get-started/install first and verify with
`flutter --version` (Dart 3.11.4 or newer — required by the `record` package).


## Run

Start the backend and frontend separately.

**Backend** (from the `backend/` directory):
```bash
docker compose up --build
```

**Frontend** (from the `frontend/` directory):
```bash
flutter run -d chrome --web-port=3000
```

- Frontend: http://localhost:3000
- API gateway: http://localhost:8080

## Environment variables

See `backend/.env.example` for the complete list with descriptions. Key groups:
database (`DB_*`, `SPRING_DATASOURCE_*`), JWT (`JWT_*`), Google OAuth
(`GOOGLE_*`, `OAUTH_REDIRECT_URI`, `APP_FRONTEND_URL`), Cloudinary
(`CLOUDINARY_*`), mail (`SPRING_MAIL_*`), and `INTERNAL_SECRET`.

**`INTERNAL_SECRET`** is a shared secret the backend services use to
authenticate internal calls to each other (e.g. user-service → auth-service).
You can pick any string — there are no format or length requirements — but you
must use the **same value across all services**, and you should change it from
the example value.
