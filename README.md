# WingLog

Backend is a Spring Boot is a microservice architecture; frontend is Flutter (web build served via nginx).

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
| frontend      | 8090 | Flutter web (nginx)                  |


## Prerequisites

- Docker + Docker Compose
- A PostgreSQL instance with the PostGIS extension (see Database setup)
- A Google OAuth client (see OAuth setup)
- Flutter SDK 3.44.1 or newer (Dart 3.11.4+) — required by the `record` package


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
**Note on SSL.** The services connect with `sslmode=require`, so your
PostgreSQL instance must have SSL enabled. Managed providers such as Supabase
have this on by default. A plain local Postgres usually does not, and will
fail with "The server does not support SSL" — either enable SSL on it or use
a provider that has it.

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


## Build the frontend

The frontend is **not** run with `flutter run` — it is compiled to a static web
build that Docker serves through nginx on port 8090. You must build it once
before starting Docker (the build output is not committed):

​```bash
cd frontend
flutter pub get      # downloads dependencies
flutter build web    # compiles to frontend/build/web, which Docker mounts
cd ..
​```

If you don't have Flutter installed, follow
https://docs.flutter.dev/get-started/install first. Verify with `flutter --version`
(SDK 3.44.1 / Dart 3.11.4 or newer — required by the `record` package).
The app is not reachable until you run Docker (see Run); there is no separate
frontend server to start.


## Run

From the `backend/` directory:
```bash
docker compose up --build
```

- Frontend: http://localhost:8090
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
