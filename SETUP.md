# GoalKeeper Flutter — Setup Instructions

## Prerequisites
1. Install Flutter: https://docs.flutter.dev/get-started/install
   - Choose macOS as your OS, then select "Desktop" as your target
   - Follow the full install guide including running `flutter doctor`
2. Install VS Code: https://code.visualstudio.com
3. In VS Code, install the **Flutter** extension (by Dart Code)

## Create the Project
Open Terminal and run:
```bash
flutter create goalkeeper_flutter
cd goalkeeper_flutter
```

## Replace pubspec.yaml
Replace the entire contents of pubspec.yaml with the one provided.

## Add Fonts
1. Create a `fonts/` folder in the project root
2. Download Geist from https://vercel.com/font
3. Download DM Sans from https://fonts.google.com/specimen/DM+Sans
4. Place these files in the fonts/ folder:
   - Geist-Regular.ttf
   - Geist-Medium.ttf
   - Geist-SemiBold.ttf
   - Geist-Bold.ttf
   - DMSans-Regular.ttf
   - DMSans-Medium.ttf
   - DMSans-SemiBold.ttf
   - DMSans-Bold.ttf

## Add the Source Files
Replace/create files as follows:
- lib/main.dart                          → replace
- lib/models/models.dart                 → new
- lib/store/goal_store.dart              → new
- lib/services/anthropic_service.dart    → new
- lib/services/keychain_service.dart     → new
- lib/services/update_service.dart       → new
- lib/services/ics_parser.dart           → new
- lib/theme/app_theme.dart               → new
- lib/widgets/progress_ring.dart         → new
- lib/views/main_scaffold.dart           → new
- lib/views/sidebar_view.dart            → new
- lib/views/calendar_dashboard_view.dart → new
- lib/views/goal_detail_view.dart        → new
- lib/views/add_goal_view.dart           → new
- lib/views/settings_view.dart           → new

## Run the App
```bash
flutter run -d macos
```

To run on Windows (once you have a Windows machine or VM):
```bash
flutter run -d windows
```

## Build for Release
macOS:
```bash
flutter build macos --release
```
Windows:
```bash
flutter build windows --release
```
