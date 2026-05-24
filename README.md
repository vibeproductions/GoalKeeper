# GoalKeeper

AI-powered goal and assignment tracker for macOS and Windows, built with Flutter. Uses the Anthropic Claude API to analyze goals, parse homework schedules, generate study guides, and chat about your goals in real time.

---

## Features

### Goals
- Create goals with type, priority, due date, rubric, and optional image attachment
- Claude analyzes your goal and breaks it into 4–8 ordered steps with time estimates and tips
- Track step completion with Apple Fitness-style triple activity rings
- Chat with Claude directly about any goal for advice, strategy, and motivation
- Re-analyze any goal at any time from the toolbar

### Homework Schedule
- Import a schedule by pasting text or attaching a photo
- Claude extracts all assignments, tests, and quizzes with subjects and due dates
- Review and edit extracted items before saving
- Items are grouped by subject in the sidebar and shown as dots on the calendar

### Study Guides
- Automatically offered for tests, quizzes, and review assignments
- Claude researches the topic and generates a full structured study guide
- Three tabs: **Study Guide** (collapsible sections + key points), **Practice** (tap-to-reveal Q&A), **Tips**
- Guides are saved and persist between sessions — regenerate anytime

### Calendar
- Apple Calendar-style month grid with goal and assignment dots per day
- **Upcoming** tab: all deadlines grouped by Today / This Week / This Month / Later
- Import `.ics` calendar files from Google Calendar, Apple Calendar, or school portals
- Add manual events with title, date, color, and notes
- Click any event to see a live per-second countdown

### Settings
- **API Key** — securely stored using platform Keychain / secure storage
- **AI Model** — choose between Haiku, Sonnet, and Opus
- **Display Size** — global scale slider from 80%–140%
- **Updates** — check and install updates directly in the app
- **Release Notes** — fetched live from GitHub

---

## Setup

### Prerequisites
- Flutter SDK 3.2+ — [flutter.dev/get-started](https://flutter.dev/get-started)
- VS Code with the Flutter extension
- On macOS: Xcode + CocoaPods (`brew install cocoapods`)
- On Windows: Visual Studio with **Desktop development with C++** workload

### Install

```bash
git clone https://github.com/TECWiSaRd/GoalKeeper.git
cd GoalKeeper
flutter pub get
flutter run -d macos   # or -d windows
```

### Fonts
Download and place in the `fonts/` folder:
- **Geist** — [fonts.google.com/specimen/Geist](https://fonts.google.com/specimen/Geist)
- **DM Sans** — [fonts.google.com/specimen/DM+Sans](https://fonts.google.com/specimen/DM+Sans)

Required files: `Geist-Regular.ttf`, `Geist-Medium.ttf`, `Geist-SemiBold.ttf`, `Geist-Bold.ttf`, `DMSans-Regular.ttf`, `DMSans-Medium.ttf`, `DMSans-SemiBold.ttf`, `DMSans-Bold.ttf`

### API Key
Launch the app → open **Settings (⌘,)** → paste your Anthropic API key.

Get a free key with $5 in credits at [console.anthropic.com](https://console.anthropic.com). New accounts don't need a credit card.

---

## Architecture

```
lib/
├── main.dart                     # Entry point, Provider, window setup, global scale
├── models/models.dart            # All data models
├── store/goal_store.dart         # ChangeNotifier state + SharedPreferences persistence
├── services/
│   ├── anthropic_service.dart    # Claude API: analyze, schedule, study guide, chat
│   ├── keychain_service.dart     # Secure API key + preferences storage
│   ├── ics_parser.dart           # RFC 5545 calendar file parser
│   └── update_service.dart       # GitHub version check + ZIP installer
├── theme/app_theme.dart          # Colors, typography, spacing, component styles
├── widgets/progress_ring.dart    # Activity rings (CustomPainter)
└── views/                        # All UI screens and dialogs
```

**State:** Single `GoalStore` provided at root via `ChangeNotifierProvider`. All navigation is handled by updating `store.detailSelection` — no Navigator routing.

---

## Releasing Updates

1. Bump version in `lib/services/update_service.dart` → `currentVersion`
2. Build: `flutter build macos --release`
3. Rename and zip:
```bash
cd build/macos/Build/Products/Release
mv goalkeeper_flutter.app GoalKeeper.app
zip -r GoalKeeper-Flutter.zip GoalKeeper.app
```
4. Create a GitHub Release tagged `flutter-X.Y.Z`, upload the ZIP
5. Update `version_flutter.json` in the repo root:
```json
{
  "version": "1.0.1",
  "url": "https://github.com/TECWiSaRd/GoalKeeper/releases/download/flutter-1.0.1/GoalKeeper-Flutter.zip",
  "notes": "What changed in this version."
}
```

Users will see the update next time they open Settings (⌘,).

---

## Platform Notes

### macOS
- Requires macOS 14.0 (Sonoma) or later
- App Sandbox must have **Outgoing Connections (Client)** enabled in both `DebugProfile.entitlements` and `Release.entitlements`
- First launch requires running `xattr -cr /Applications/GoalKeeper.app` in Terminal to bypass Gatekeeper

### Windows
- Requires Windows 10 or later
- First launch may show a SmartScreen warning — click **More info → Run anyway**

---

## Claude Code

This repo includes a `CLAUDE.md` file with full project documentation for use with Claude Code — structure, design patterns, model reference, and common task recipes.

---

## Requirements

- Flutter 3.2+
- Dart 3.2+
- Anthropic API key ([console.anthropic.com](https://console.anthropic.com))
- macOS 14.0+ or Windows 10+