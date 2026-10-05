# CAM FIX

On-demand home-service booking app for Cambodia — Spring Boot backend, a
customer Flutter app, a technician Flutter app, and a React admin console.

```
Backend/            Spring Boot 4.1 API (Java 21, Gradle), port 8081
Camfix_App/          Flutter customer app
Camfix_Technician/   Flutter technician app
admin/               React admin console
Database/            SQL schema notes + docker-init.sql
```

## Quickstart with Docker (backend + database only)

The fastest way to get the API running without installing Java, Gradle, or
MySQL locally - useful for anyone pulling the repo who just wants the
backend up:

```bash
docker compose up --build
```

This starts:
- **`mysql`** - MySQL 8, auto-seeded from `Database/docker-init.sql` on
  first run, host port `3309` (override with `MYSQL_HOST_PORT` if that's
  taken too - the backend always reaches it over the internal Docker
  network on 3306 regardless of this mapping).
- **`backend`** - built from `Backend/Dockerfile`, on `http://localhost:8081`.

No `.env` file is required to start it - OTP codes are logged to the
console and a dev JWT secret is used by default. To enable real SMS/email
delivery or Google sign-in verification, set the corresponding variables
(see the commented-out block in `docker-compose.yml`) in a root `.env` file
before running `docker compose up`.

To reset the database (drop all data and re-run `docker-init.sql`):

```bash
docker compose down -v
docker compose up --build
```

## Running things individually (without Docker)

See `Camfix_App/README.md` for the Flutter app and manual backend setup
instructions (local MySQL, running `gradlew bootRun` directly, etc.).

## Hosting the mobile API through Cloudflare Tunnel

The Android APK is installed on devices; Cloudflare Tunnel publishes the
Spring Boot API used by the app. The release app connects to
`https://api.camapp.store`.

Prerequisites:

1. Delegate `camapp.store` to the two nameservers assigned on the Cloudflare
   Overview page.
2. In Cloudflare DNS, keep a proxied `CNAME` named `api` targeting
   `dbdca579-55cf-4120-9396-37bd0ef1f2ad.cfargotunnel.com`.
3. Install `cloudflared` and keep the tunnel credentials outside this repo in
   `%USERPROFILE%\.cloudflared`.
4. Copy `deploy/cloudflare/config.yml.example` to
   `%USERPROFILE%\.cloudflared\config.yml`, then replace `YOUR_USERNAME`.
5. Start MySQL on port 3306.

From the repository root, build the backend and start both the API and named
tunnel:

```powershell
.\scripts\start-hosting.ps1
```

For later starts when `Backend\build\libs\api.jar` is already current:

```powershell
.\scripts\start-hosting.ps1 -SkipBackendBuild
```

Check local API, tunnel connector, public DNS, and public HTTPS separately:

```powershell
.\scripts\check-hosting.ps1
```

Runtime logs and PID files are written to the ignored `.runtime` directory.
Never commit `cert.pem`, the tunnel credentials JSON, database passwords, or
JWT secrets.

Build the release APK only after the public API check returns HTTP 200:

```powershell
cd .\Camfix_App
flutter analyze --no-pub
flutter build apk --release --no-pub
```
