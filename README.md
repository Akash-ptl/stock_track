# StockTrack

A mobile stock counting app built with Flutter. Staff can log in, select their business/location, and update inventory counts — even offline.

## Download APK

> **[📥 Download Latest APK](https://github.com/Akash-ptl/stock_track/releases/latest)**
>
> Go to **Releases** → download `app-release.apk` → install on your Android device.
> (Enable "Install from unknown sources" if prompted)

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | flutter_bloc (BLoC pattern) |
| Auth | Firebase Auth + Google Sign-In |
| Networking | http package + REST API |
| Local Storage | SharedPreferences (cache), flutter_secure_storage (token) |
| Typography | Google Fonts (Inter) |

## Project Structure

```
lib/
├── main.dart                          # App entry point, providers & routes
├── core/
│   ├── api_constants.dart             # All API endpoint URLs
│   ├── app_theme.dart                 # Light/Dark theme, colors
│   └── firebase_options.dart          # Firebase config (auto-generated)
└── features/
    ├── auth/
    │   ├── auth_repository.dart       # Google Sign-In + backend JWT auth
    │   ├── auth_bloc/                 # AuthBloc, events, states
    │   ├── login_page.dart            # Login screen UI
    │   ├── splash_page.dart           # Animated splash screen
    │   └── widgets/
    │       └── background_wave.dart   # Decorative wave painter
    └── stock/
        ├── stock_repository.dart      # API calls + offline cache layer
        ├── stock_model.dart           # StockItem data model
        ├── stock_bloc/                # StockBloc, events, states
        ├── home_page.dart             # Main dashboard (item list)
        ├── stock_count_update_page.dart  # Detailed count entry form
        └── widgets/
            └── stock_item_row.dart    # Single item row widget
```

## Architecture

```
UI (Pages/Widgets)
     │
     ▼
BLoC (Business Logic)
     │
     ▼
Repository (Data Layer)
     │
     ├── REST API (online)
     └── SharedPreferences (offline cache)
```

**Key decisions:**
- **Offline-first** — Data is always cached locally. If the API fails, the app shows cached data.
- **Secure token storage** — JWT is stored in `flutter_secure_storage` (encrypted), not plain `SharedPreferences`.
- **Separation of concerns** — UI never touches HTTP or storage directly. Everything goes through Repository → BLoC.

## Setup & Run

```bash
# 1. Clone
git clone https://github.com/your-username/stock_track.git
cd stock_track

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run
```

> **Note:** Requires a physical device or emulator with Google Play Services for Google Sign-In.

## User Flow

```
┌──────────────────────────────────────────────────────────┐
│  1. SPLASH SCREEN                                        │
│     App opens → checks if user is already logged in      │
│     ├── Yes → Go to Home                                 │
│     └── No  → Go to Login                                │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  2. LOGIN SCREEN                                         │
│     Tap "Sign in with Google"                            │
│     → Firebase Auth → Backend JWT token saved            │
│     → Redirected to Home                                 │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  3. HOME (STOCK LIST)                                    │
│     • Select Business from dropdown                      │
│     • Select Location from dropdown                      │
│     • See all stock items with current quantities        │
│     • Tap any item → opens Stock Count Update page       │
│     • Pull down to refresh                               │
│     • Tap sync icon (if pending changes) to push to API  │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  4. STOCK COUNT UPDATE                                   │
│     • Shows item name, SKU, unit conversion info         │
│     • Enter cartons + pieces → total auto-calculated     │
│     • Pick count type, date, counted by                  │
│     • Add optional notes                                 │
│     • Three options:                                     │
│       ├── CLEAR ALL → reset fields                       │
│       ├── SAVE DRAFT → save locally (offline)            │
│       └── SUBMIT COUNT → save + sync to server           │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  5. OFFLINE MODE                                         │
│     • Unsaved items show a red "Unsaved offline" badge   │
│     • Sync icon in app bar shows pending count           │
│     • When back online, tap sync to push all changes     │
└──────────────────────────────────────────────────────────┘
```

## Offline Handling

1. All stock data is cached in `SharedPreferences` per business+location
2. When user saves a count, it's stored locally with `isSynced = false`
3. A sync badge appears in the app bar showing the number of pending items
4. User taps the sync button → app sends a `POST` to create a count session, then `PUT` to finalize it
5. On success, items are marked `isSynced = true`

## API Integration

| Action | Method | Endpoint |
|---|---|---|
| Login | POST | `/api/auth/login` |
| Register | POST | `/api/auth/register` |
| Get Businesses | GET | `/api/businesses` |
| Get Locations | GET | `/api/businesses/{id}/locations` |
| Get Stock Items | GET | `/api/businesses/{id}/locations/{id}/stock-items` |
| Create Count | POST | `/api/businesses/{id}/stock-counts` |
| Finalize Count | PUT | `/api/businesses/{id}/stock-counts/{id}?status=completed` |

## AI Tools & Workflow

AI was used throughout development for planning, code generation, debugging, and code review. Every AI suggestion was manually verified and tested before committing.

**How AI was used:**
- Created implementation plans first, reviewed them, then approved before writing code
- Used AI for code audits to catch security issues, performance bottlenecks, and architecture problems
- All generated code was tested on a real device before finalizing

**Reference files:**
- `ai_prompts_used.txt` — Contains the exact prompts used during development
- `implementation_plan.md` — The initial architecture plan that was reviewed and approved before coding started
