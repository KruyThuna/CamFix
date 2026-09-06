# Enabling real Google Maps on the live‑tracking screen

The live‑tracking screen (`lib/screens/live_tracking_screen.dart`) renders with
**real Google Maps** — Google's tiles, its live traffic layer, and real road
routes/ETAs from the Directions API — when a Google Maps API key is configured.
Until then it falls back to the OpenStreetMap view (no key, no cost).

The switch is the `GOOGLE_MAPS_API_KEY` dart‑define **plus** the per‑platform
key wiring below.

---

## 1. Create the key (Google Cloud console)

1. Create / pick a project at <https://console.cloud.google.com/>.
2. Enable **billing** on the project (Google Maps has a free monthly credit but
   requires a billing account).
3. **APIs & Services → Enable APIs** — enable all of:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (web)
   - **Directions API** (real routes + traffic‑aware ETA; used on Android/iOS)
4. **APIs & Services → Credentials → Create credentials → API key.**
5. Restrict the key (recommended): *Application restrictions* per platform, and
   *API restrictions* to the four APIs above. You can make one key per platform
   or reuse one unrestricted key while developing.

---

## 2. Wire the key per platform

### Android
Add to `android/local.properties` (this file is git‑ignored):

```
MAPS_API_KEY=YOUR_ANDROID_KEY
```

`android/app/build.gradle.kts` reads it into the manifest placeholder
`${MAPS_API_KEY}` (already set up). Nothing else to do.

### iOS
Paste the key into `ios/Runner/Info.plist` → `GMSApiKey`:

```xml
<key>GMSApiKey</key>
<string>YOUR_IOS_KEY</string>
```

Then `cd ios && pod install`. `AppDelegate.swift` already calls
`GMSServices.provideAPIKey(...)` with it.

### Web
Paste the key into `web/index.html` — set `GOOGLE_MAPS_API_KEY` in the small
inline `<script>` near the top:

```js
var GOOGLE_MAPS_API_KEY = 'YOUR_WEB_KEY';
```

> Note: on **web**, the Directions API call is blocked by CORS, so the web map
> shows Google's tiles + live traffic layer with the app's drawn route on top
> (not multi‑route directions). Android/iOS get the full Directions routing.

---

## 3. Run with the switch on

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

(The value just has to be non‑empty to flip the UI to `GoogleMapView`; the
actual key used at runtime comes from the platform config above. On Android/iOS
the same value is also used for the Directions API call.)

For a persistent setup, add it to `.vscode/launch.json` `args` or a
`--dart-define-from-file`.

---

## What each side does

| | OpenStreetMap fallback | Google Maps enabled |
|---|---|---|
| Tiles | OSM raster | Google |
| Traffic | simulated bands (green/amber/red/grey) | **Google live traffic layer** |
| Route shape | drawn S‑curve + 2 drawn alternatives | **Directions API** roads (Android/iOS); drawn line on web |
| ETA / distance | estimated from geometry | **Directions API**, traffic‑aware (Android/iOS) |
| Technician marker | animated along the route | same, along the real route |

Relevant code: `lib/widgets/google_map_view.dart`,
`lib/services/directions_api.dart`, and the `_useGoogle` switch in
`lib/screens/live_tracking_screen.dart`.
