# CredShowcase 💳

A Flutter Android app — a credit-card management & rewards dashboard — backed by a real **FastAPI** service instead of hardcoded data. The app polls the backend every few seconds, so balances, transactions, and reward coins update live as the server generates new activity, similar to how a real banking/fintech app behaves.

## How it works

```
┌─────────────────────┐        HTTP (poll every 5s)        ┌──────────────────────┐
│   Flutter Android    │ ───────────────────────────────▶  │   FastAPI backend     │
│   app (lib/)          │  GET /api/card                    │   (backend/main.py)   │
│                       │  GET /api/transactions             │  - in-memory state    │
│                       │  GET /api/rewards                  │  - background task    │
│                       │ ◀───────────────────────────────  │    adds a new txn      │
└─────────────────────┘        JSON                         │    every 15–30s        │
                                                              └──────────────────────┘
```

The backend seeds a few starting transactions, then a background task keeps appending new ones on its own timer and bumping the outstanding balance — so if you leave the app open, you'll actually see fresh transactions appear without touching anything.

## Project structure

```
cred_showcase/
├── backend/
│   ├── main.py            # FastAPI app: /api/card, /api/transactions, /api/rewards
│   └── requirements.txt
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── card_model.dart       # CreditCardModel.fromJson
│   │   └── transaction.dart      # Transaction.fromJson
│   ├── services/
│   │   └── api_service.dart      # HTTP client hitting the FastAPI backend
│   ├── screens/                  # Splash, Dashboard (home), Transactions, Rewards, Profile
│   └── widgets/                  # CreditCardWidget, TransactionTile
├── pubspec.yaml
└── README.md
```

## Setup

### 1. Run the backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Leave this running. Visit `http://localhost:8000/api/transactions` in a browser to confirm it's alive — refresh every so often and you'll see the list grow.

### 2. Scaffold the Android project (one-time)

This repo ships only the Dart source (`lib/`) and `pubspec.yaml` — no platform folders — so Flutter can generate them for your exact SDK version:

```bash
cd cred_showcase        # the folder containing pubspec.yaml
flutter create .
```

This adds `android/`, `ios/`, etc. without touching your existing `lib/` code.

### 3. Allow the app to reach the backend over plain HTTP

Android blocks cleartext (non-HTTPS) traffic by default. Since this is a local dev backend, open `android/app/src/main/AndroidManifest.xml` and:

- Add the internet permission, just above `<application ...>`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
- Add `android:usesCleartextTraffic="true"` to the `<application ...>` tag.

### 4. Point the app at your backend

Open `lib/services/api_service.dart` and set `baseUrl`:

- **Android emulator**, backend running on the same machine → leave it as `http://10.0.2.2:8000` (this is the emulator's alias for your host's localhost).
- **Physical device over wireless debugging / same Wi-Fi** → use your computer's LAN IP instead, e.g. `http://192.168.1.42:8000`. Find it with `ipconfig` (Windows) or `ifconfig`/`ip addr` (Mac/Linux). Your phone and computer must be on the same network.

### 5. Install dependencies and run

```bash
flutter pub get
flutter devices     # confirm your emulator/device is detected
flutter run
```

### 6. Build a release APK

```bash
flutter build apk --release
```
APK lands at `build/app/outputs/flutter-apk/app-release.apk`. Install directly with `flutter install`.

## Troubleshooting

- **"Could not reach the backend" on screen** → confirm `uvicorn` is still running, and that `baseUrl` in `api_service.dart` matches how your device reaches your machine (10.0.2.2 for emulator, LAN IP for a real device).
- **Nothing new ever appears** → the backend adds one transaction every 15–30 seconds at random; give it a minute, or restart `uvicorn` to reseed.

## Possible extensions (good talking points in an interview)

- Swap polling for a WebSocket (`/ws`) for true push-based updates instead of 5s polling
- Persist backend state in a real database (SQLite/Postgres) instead of in-memory
- Add `provider`/`riverpod` for state management as the app grows
- Add authentication (JWT) between the app and backend
- Deploy the backend (Render/Railway) so the app works off your local network too

## Note on this project

This is a self-contained Android app + backend built to demonstrate Flutter/Dart and API integration skills — it is not affiliated with or built using any CRED proprietary code, design assets, or APIs.
