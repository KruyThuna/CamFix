# CAM FIX — Flutter App

A Flutter recreation of the CAM FIX on-demand home-service booking app, built
from the provided UI mockups (splash, language, auth flow, and dashboard).

## Screens included

| Route | Screen |
|---|---|
| `/` | Splash (auto-advances after 2s) |
| `/language` | Language picker (Khmer / English) |
| `/login` | Login (email/password, Google, phone) |
| `/signup` | Sign Up |
| `/phone-login` | Phone number entry |
| `/verify-code` | 6-digit SMS verification |
| `/forgot-password` | Forgot password (email) |
| `/verify-email` | 4-digit email verification |
| `/new-password` | Create new password |
| `/dashboard` | Home — search, service grid, Book a service / Active Job / History tabs, bottom nav |

## Project structure

```
lib/
  main.dart                  # MaterialApp + named routes
  theme/app_theme.dart        # Colors, gradients, text styles
  widgets/
    app_text_field.dart       # Rounded white input field
    app_buttons.dart          # Primary/Secondary buttons, back button
    auth_header.dart          # Robot mascot + wave + logo badge header
    otp_boxes.dart             # 4/6-digit code input boxes
    bottom_nav_bar.dart       # Floating pill bottom nav
  screens/                    # One file per screen listed above
assets/
  images/robot.png            # Mascot art (from your uploads)
  images/sharp.png             # Decorative wave graphic (from your uploads)
```

## Running it

This code was written and reviewed without a local Flutter SDK in the
generation environment (no network access to pub.dev/Flutter's download
servers here), so it hasn't been compiled in this sandbox. To run it:

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x (Dart ≥3.0). No third-party packages beyond
`cupertino_icons` are required — all inputs, OTP boxes, and buttons are
hand-built widgets so there's nothing extra to fetch.

## Notes / things you may want to adjust

- **Nearby Technicians & profile photos**: the mockups use real headshots I
  don't have assets for, so those are placeholder circle icons. Drop photos
  into `assets/images/` and swap the `CircleAvatar` children in
  `dashboard_screen.dart` to use them.
- **Active Job state**: `dashboard_screen.dart` seeds one active job (Air
  Conditioner) so you can see the populated state from your mockup. Set
  `_activeJobs` to an empty list to see the empty state instead.
- **Navigation**: screens are wired together to match the flow implied by the
  mockups (Login → Forgot Password → Verify Email → New Password → back to
  Login; Sign Up → Verify Email → New Password; Phone Login → Verification
  Code → Dashboard). Adjust in `main.dart` / individual `Navigator` calls if
  your intended flow differs.
- **Fonts/exact colors**: matched by eye from the screenshots (primary blue
  `#1B34FF`, cyan accent `#17D2F0`, dark button `#0B0C1F`). Swap in exact
  brand hex codes if you have a style guide.
