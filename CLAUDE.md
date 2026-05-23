# CLAUDE.md — GoalKeeper Flutter

This file describes the GoalKeeper Flutter project structure for Claude Code.

## Project Overview

GoalKeeper is an AI-powered goal and assignment tracker built with Flutter, targeting macOS and Windows. It uses the Anthropic Claude API for goal analysis, schedule parsing, study guide generation, and in-app chat. The design mirrors the SwiftUI macOS version with a dark theme, three-column layout, and Apple Fitness-style activity rings.

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Provider (`ChangeNotifier`)
- **Persistent storage:** `shared_preferences` (goals, settings) + `flutter_secure_storage` (API key)
- **HTTP:** `http` package
- **Window management:** `window_manager`
- **File picking:** `file_picker`
- **Fonts:** Geist (headings/numbers) + DM Sans (body)

## Project Structure

```
goalkeeper_flutter/
├── assets/
│   └── icon/
│       └── icon.png                  # App icon (1024×1024)
├── fonts/                            # Geist + DM Sans .ttf files
├── lib/
│   ├── main.dart                     # Entry point, Provider setup, window config, appScale ValueNotifier
│   ├── models/
│   │   └── models.dart               # All data models: Goal, GoalStep, ScheduleItem, CalendarEvent, StudyGuide, AnyDeadline
│   ├── store/
│   │   └── goal_store.dart           # ChangeNotifier state store, SharedPreferences persistence
│   ├── services/
│   │   ├── anthropic_service.dart    # All Claude API calls: analyzeGoal, parseSchedule, generateStudyGuide, chatAboutGoal
│   │   ├── keychain_service.dart     # Secure storage: API key (flutter_secure_storage) + model/scale prefs (SharedPreferences)
│   │   ├── ics_parser.dart           # RFC 5545 ICS calendar file parser
│   │   └── update_service.dart       # GitHub version check + ZIP download/install
│   ├── theme/
│   │   └── app_theme.dart            # AppColors, AppText, AppSpacing, AppRadius, AppTheme.dark, cardDecoration()
│   ├── widgets/
│   │   └── progress_ring.dart        # ProgressRing (CustomPainter), ActivityRingsView (3 rings), MiniRingView
│   └── views/
│       ├── main_scaffold.dart        # Root 3-column layout: sidebar + calendar + detail, keyboard shortcuts (⌘N, ⌘,)
│       ├── sidebar_view.dart         # Left column: goals list + schedule grouped by subject, dropdown + menu
│       ├── calendar_dashboard_view.dart  # Middle column: Month/Upcoming tab switcher
│       ├── full_calendar_view.dart   # Upcoming tab: deadlines grouped Today/This Week/This Month/Later
│       ├── goal_detail_view.dart     # Right column: rings + steps + AI summary, Action Plan/Chat tabs
│       ├── goal_chat_view.dart       # Chat UI: conversation with Claude about a specific goal
│       ├── add_goal_view.dart        # New goal dialog: form + Claude analysis preview
│       ├── schedule_detail_view.dart # Assignment detail: upcoming items + study guide generation
│       ├── study_guide_view.dart     # Study guide sheet: Study Guide / Practice / Tips tabs
│       ├── import_schedule_view.dart # Import homework schedule via text or image
│       ├── import_calendar_view.dart # ICS import + manual event creation (two tabs)
│       ├── calendar_event_detail_view.dart  # Event detail with live per-second countdown timer
│       └── settings_view.dart        # Settings dialog: API key, model picker, display size, updates, release notes
├── macos/                            # macOS platform shell (do not edit manually)
│   └── Runner/
│       ├── Configs/
│       │   └── AppInfo.xcconfig      # PRODUCT_NAME = GoalKeeper, PRODUCT_BUNDLE_IDENTIFIER
│       ├── DebugProfile.entitlements # Must include com.apple.security.network.client = true
│       └── Release.entitlements      # Must include com.apple.security.network.client = true
├── windows/                          # Windows platform shell (do not edit manually)
├── pubspec.yaml                      # Dependencies + font declarations
├── version_flutter.json              # Update manifest: { version, url, notes }
└── .gitignore
```

## Key Design Patterns

### State Management
`GoalStore` is a single `ChangeNotifier` provided at the root via `ChangeNotifierProvider`. All views access it via `context.watch<GoalStore>()` (rebuild on change) or `context.read<GoalStore>()` (one-time read). Never access GoalStore outside the widget tree — pass it as a parameter to dialogs using `ChangeNotifierProvider.value`.

### Global Scale
`appScale` is a top-level `ValueNotifier<double>` in `main.dart`. The root `GoalKeeperApp` wraps `MaterialApp` in a `ValueListenableBuilder` that applies `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)))`. Updating `appScale.value` anywhere in the app instantly rescales all text.

### Theming
All colors are defined as constants in `AppColors`. All text styles are created via `AppText.display()`, `AppText.body()`, `AppText.mono()`, and `AppText.label()` helper functions. Never use raw `TextStyle` or hardcoded colors — always use the theme constants.

### Navigation
There is no Navigator routing. The app is a single-page layout. The right detail panel is switched by updating `store.detailSelection` (an enum: `goal`, `scheduleItem`, `calendarEvent`, `none`) and the corresponding selected ID. `_DetailPanel` in `main_scaffold.dart` watches these and renders the correct view.

### Dialogs
All sheets/modals use `showDialog()` with a custom `Dialog` widget. Always wrap dialogs with `ChangeNotifierProvider.value(value: context.read<GoalStore>(), child: ...)` so the store is accessible inside.

### API Calls
All Anthropic API calls are static methods on `AnthropicService`. The API key and model are loaded from `KeychainService` at call time — never cached in memory. All methods are `async` and throw `AnthropicError` on failure.

## Models Quick Reference

| Model | Key fields |
|---|---|
| `Goal` | id, title, description, type (GoalType), priority, steps, dueDate, aiSummary, progress (computed) |
| `GoalStep` | id, title, detail, estimatedTime, isCompleted, tips |
| `ScheduleItem` | id, title, subject, type (ScheduleItemType), dueDate, isCompleted |
| `CalendarEvent` | id, title, startDate, endDate, isAllDay, color (CalendarEventColor), source |
| `StudyGuide` | id, title, overview, sections, practiceQuestions, studyTips |
| `AnyDeadline` | id, title, subtitle, date, color, icon, kind (DeadlineKind) — unified type for Upcoming view |

All models implement `toJson()` / `fromJson()` for SharedPreferences persistence.

## Enums Quick Reference

| Enum | Values |
|---|---|
| `GoalType` | assignment, project, personalGoal, habit, examPrep, creative |
| `GoalPriority` | low, medium, high |
| `ScheduleItemType` | homework, test, quiz, project, reading, other |
| `CalendarEventColor` | blue, red, green, orange, purple, teal |
| `DetailSelection` | goal, scheduleItem, calendarEvent, none |
| `DeadlineKind` | goal, scheduleItem, event |

## Common Tasks for Claude Code

### Add a new view
1. Create `lib/views/my_new_view.dart`
2. Use `AppColors`, `AppText`, `AppRadius` from `app_theme.dart` — no raw colors or TextStyle
3. Access store via `context.watch<GoalStore>()` or `context.read<GoalStore>()`
4. Wire it into `_DetailPanel` in `main_scaffold.dart` if it's a detail view

### Add a new field to a model
1. Add the field in `models.dart`
2. Update `toJson()` and `fromJson()` in the same class
3. Update any views that display or edit that field

### Add a new Claude API call
1. Add a static method to `AnthropicService` in `anthropic_service.dart`
2. Load `apiKey` and `model` from `KeychainService` at the top of the method
3. Use `_sendRequest()` for the HTTP call
4. Parse the JSON response and return a typed result object

### Add a new setting
1. Add a `static Future<T> loadX()` and `static Future<void> setX(T)` to `KeychainService`
2. Use `SharedPreferences` for non-sensitive values, `FlutterSecureStorage` for sensitive ones
3. Add the UI in `settings_view.dart` following the existing section pattern

## Build Commands

```bash
# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows

# Release build macOS
flutter build macos --release

# Release build Windows
flutter build windows --release

# Get dependencies
flutter pub get

# Clean build cache
flutter clean
```

## Release Process

1. Bump version string in `lib/services/update_service.dart` → `currentVersion`
2. `flutter build macos --release` (or windows)
3. `cd build/macos/Build/Products/Release && mv goalkeeper_flutter.app GoalKeeper.app && zip -r GoalKeeper-Flutter.zip GoalKeeper.app`
4. Create GitHub Release tagged `flutter-X.Y.Z`, upload ZIP
5. Update `version_flutter.json` in repo root with new version + URL

## Important Notes

- **Never hardcode the API key** — it is stored in the Keychain at runtime via `KeychainService`
- **macOS sandbox** — `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` must both have `com.apple.security.network.client = true` for API calls to work
- **Window dragging** — the custom title bar uses `windowManager.startDragging()` on pan gesture; don't remove the `GestureDetector` wrapper in `_TitleBar`
- **Font rendering** — always use `AppText.*` helpers, never raw `TextStyle`, to ensure Geist/DM Sans are applied consistently
- **withOpacity is deprecated** — use `.withValues(alpha: x)` instead throughout
