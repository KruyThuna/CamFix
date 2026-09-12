# CAM FIX — Technician app

Flutter app technicians use to run their day: sign in, go online, work the jobs
an admin assigns them, and stream their location to the dispatch map.

Part of the [CAM FIX monorepo](../README.md) — it talks to the Spring Boot API
in [`../back-end`](../back-end) (`http://localhost:8081` by default).

## Run

```bash
flutter pub get
flutter run -d chrome            # or any connected device
```

Point at a non-default API host with
`--dart-define=API_BASE_URL=http://<host>:8081`.

## Flow

1. **Register** in the app → the account is created `PENDING`.
2. An admin approves it from the web console → the app unlocks.
3. **Home** — flip the availability switch to go online (starts location
   reporting); assigned jobs appear under *Active* / *History*.
4. **Job** — call the customer, open the address in maps, then
   *Start job* → *Mark complete* (or *Decline* to send it back to dispatch).

Sign-in is email + password or a phone OTP (the code is returned in the API
response while no SMS provider is configured).

## Layout

| Path | |
| --- | --- |
| `lib/services/` | API client, auth, `CurrentTechnician`, `LocationReporter` |
| `lib/models/` | `TechnicianProfile`, `TechJob` |
| `lib/screens/` | splash, login, register, OTP, pending/rejected gate, home, job detail, profile |
| `lib/theme/` | shared palette (mirrors the customer app) |
