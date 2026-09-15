# CAM FIX — Flutter App

On-demand home-service booking app. Flutter client + a Spring Boot backend
(`../Backend`) — no Firebase anywhere; phone/email OTP, JWT auth, and Google
sign-in verification are all done by the Spring API.

## Project structure

```
C:\Cam
├── Backend/            # Spring Boot 4.1 API (Java 21, Maven), port 8081
└── Camfix_App/         # this Flutter app
    lib/
      main.dart               # MaterialApp + named routes
      app_settings.dart       # theme (light/dark) + language (en/km), persisted
      theme/app_theme.dart    # colors, gradients, text styles
      l10n/app_strings.dart   # EN/KM string table
      models/                  # plain data classes
        chat.dart
        live_technician.dart
        route_traffic.dart
        service_provider.dart
        tracking_info.dart
        user_info.dart
      services/                 # backend + platform integrations
        api_client.dart          # HTTP wrapper around the Spring API
        auth_api.dart            # /api/auth/* calls
        token_store.dart         # persists the JWT
        current_user.dart        # cached logged-in user
        bookings_store.dart      # local booking/active-job state
        connectivity_service.dart # Wi-Fi/mobile/offline watcher
        device_location.dart     # geolocator wrapper
        directions_api.dart      # Google Directions API (Android/iOS)
        osrm_api.dart            # OSRM routing (OSM fallback path)
        profile_image.dart       # persisted profile photo
        gmail_connect.dart
        web_wrapper*.dart        # conditional-import shim for web-only APIs
      screens/                   # one file per screen (see table below)
      widgets/
        app_text_field.dart, app_buttons.dart, auth_header.dart,
        otp_boxes.dart, otp_sent_dialog.dart, bottom_nav_bar.dart,
        connectivity_banner.dart, user_avatar.dart,
        google_signin_button.dart, google_map_view.dart
    assets/images/
```

## Screens / routes

| Route | Screen |
|---|---|
| `/` | Splash (auto-advances after 2s) |
| `/language` | Language picker (Khmer / English) |
| `/login` | Login (email/password, Google, phone) |
| `/signup` | Sign up |
| `/phone-login` | Phone number entry |
| `/verify-code` | 6-digit SMS verification |
| `/forgot-password` | Forgot password (email) |
| `/verify-email` | 4-digit email verification |
| `/new-password` | Create new password |
| `/dashboard` | `MainShell` — bottom-nav home (search, service grid, Book a service / Active Job / History) |
| `/services` | Full service category list |
| `/provider` | Technician / provider detail |
| `/live-tracking` | Live map tracking of an assigned technician |
| `/technicians-live` | Nearby technicians on a map |
| `/directions` | Turn-by-turn / route preview map |
| `/map-picker` | Pick an address/location on a map |
| `/chat` | Chat threads list |
| `/chat-thread` | One chat conversation |
| `/profile` | Profile |
| `/edit-profile` | Edit profile |

`booking_sheet.dart` and `tracking_details_sheet.dart` are bottom-sheet
widgets opened from other screens, not routes.

## 1. Run the backend first

The app talks to the Spring API for everything (auth, OTP, profile,
bookings, live location) — start it before `flutter run`.

```bash
cd ../Backend
./mvnw spring-boot:run        # Windows: mvnw.cmd spring-boot:run
```

Requirements/notes (see `Backend/src/main/resources/application.properties`):

- **MySQL**: create a local schema named `CamFix` (default
  `jdbc:mysql://localhost:3306/CamFix`, user `root` / password `12345` —
  edit the datasource block if yours differs). `spring.jpa.hibernate.ddl-auto=none`,
  so the schema must already exist / be migrated separately.
- Boots on **`http://localhost:8081`**.
- **OTP delivery is optional in dev.** With no env vars set, phone/email
  codes are just logged to the console and echoed back in the API response
  (`devCode`, shown as "Dev code" on the verify screen). For real SMS/email,
  copy `Backend/run-with-otp-delivery.example.ps1` →
  `run-with-otp-delivery.ps1` (kept out of git — it holds secrets), fill in
  `TEXTBELT_KEY` or `TWILIO_*`, and `MAIL_*` (a Gmail **App Password**, not
  your normal password), then `. .\run-with-otp-delivery.ps1`. Once real
  delivery works, set `APP_OTP_EXPOSE_CODE=false`.
- **Google sign-in verification**: set env var `GOOGLE_CLIENT_ID` to the
  OAuth client ID the Flutter app uses. Blank in dev = the audience check is
  skipped with a warning.
- Auth endpoints, all under `/api/auth`: `POST /register`, `POST /login`,
  `POST /google`, `POST /phone/request-otp`, `POST /phone/verify-otp`,
  `POST /email/request-otp`, `POST /email/verify-otp`, `GET /me`, `PUT /me`.

## 2. Run the Flutter app

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x / Dart ≥3.0. Optional `--dart-define`s:

| Define | Purpose | Default when unset |
|---|---|---|
| `API_BASE_URL` | Backend URL (`lib/services/api_client.dart`) | `http://10.0.2.2:8081` on the Android **emulator**, `http://localhost:8081` everywhere else |
| `GOOGLE_MAPS_API_KEY` | Real Google Maps + Directions API on `/live-tracking` | unset → OpenStreetMap fallback (keyless) |
| `GOOGLE_SIGNIN_CLIENT_ID` | Real Google account picker (`google_sign_in` v7, no Firebase) | unset → "Continue with Google" falls back to email OTP |

**Real physical device**: `10.0.2.2` and `localhost` don't resolve on a
phone — pass your PC's LAN IP and make sure the phone and PC share a Wi-Fi
network and the firewall allows port 8081:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8081
```

### Enabling real Google Maps (optional)

Full walkthrough in [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md). Summary:

1. Create a Google Cloud project, enable billing, enable **Maps SDK for
   Android**, **Maps SDK for iOS**, **Maps JavaScript API**, **Directions API**.
2. Wire the key per platform: Android → `android/local.properties`
   (`MAPS_API_KEY=...`, git-ignored); iOS → `ios/Runner/Info.plist`
   `GMSApiKey`, then `cd ios && pod install`; Web → `web/index.html`
   `GOOGLE_MAPS_API_KEY` inline script var.
3. `flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY`.

Without a key, `/live-tracking` and `/technicians-live` render with OSM
tiles, a simulated traffic overlay, and OSRM-drawn routes instead — no cost,
no setup.

## Guidelines

- **Lint**: `flutter analyze` before committing (`analysis_options.yaml`,
  `package:flutter_lints/flutter.yaml`). `android/ios/web/windows/macos/linux/build`
  are excluded from analysis.
- **No Firebase.** Don't add `firebase_core`/`google-services.json` back —
  auth/OTP intentionally goes through the Spring API so there's no
  reCAPTCHA/bot-check step (`main.dart` has a comment on this).
- **Gradle "build logic queue" lock hang**: if a `flutter run`/build hangs
  waiting on `buildLogic.lock`, the VS Code Java/Gradle extension's daemon is
  probably holding it — kill the `java`/`GradleDaemon` processes and delete
  `android/app_build\.gradle` cache (`android/.gradle`), then rerun
  `flutter run` immediately.
- **Android application ID / signing**: `android/app/build.gradle.kts` still
  has the default `applicationId = com.example.camfix_app` and release
  builds are signed with the debug key (`TODO`s left in the file) — replace
  both before shipping a real release build.
- **Live-tracking has two independent map backends** (OSM vs. real Google
  Maps) selected purely by whether `GOOGLE_MAPS_API_KEY` is non-empty; if you
  touch `live_tracking_screen.dart`, check both paths. The `flutter_map`
  (OSM) animated marker needs a persistent `MapController` and exactly one
  `MapOptions`, or the camera collapses to `minZoom`.

## Things you may want to adjust

- **Nearby technicians & profile photos**: placeholder circle icons where
  the mockups use real headshots — drop photos into `assets/images/` and
  swap the `CircleAvatar` children in `dashboard_screen.dart` / relevant
  provider screens.
- **Fonts/exact colors**: matched by eye from the original mockups (primary
  blue `#1B34FF`, cyan accent `#17D2F0`, dark button `#0B0C1F`) — swap in
  exact brand hex codes if you have a style guide.
