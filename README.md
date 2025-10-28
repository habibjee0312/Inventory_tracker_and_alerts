# Inventory Tracker — Flutter Client

A cross-platform Flutter client for the Inventory Tracker backend. This README documents project structure, setup, how the app communicates with the backend API, authentication/token handling, development workflows, and recommendations for production.

## Table of contents
- Project purpose
- Architecture & folders
- Prerequisites
- Setup (run locally)
- Backend integration (endpoints & JSON shapes)
- Authentication & token lifecycle
- Local development notes (emulator / device)
- Testing and debugging
- Building for release
- Contributing & recommended improvements

## Project purpose
This Flutter app lets users register/login, view inventory items, add/edit/delete items, and receive local notifications for expiring / low-stock items. It consumes a Django REST API (Inventory Tracker).

## Architecture & folders
- `lib/models`: data models (`ItemModel`, `UserModel`)
- `lib/viewmodels`: state-management classes (`AuthViewModel`, `InventoryViewModel`) using `ChangeNotifier`
- `lib/services`: API client, storage wrapper, and notification service
- `lib/views`: UI screens (Home, Add/Edit Item, Login, etc.)
- `pubspec.yaml`: dependencies (`provider`, `http`, `shared_preferences`, `flutter_local_notifications`, `intl`, `cupertino_icons`)

Design notes:
- ViewModels perform API calls via ApiService and persist tokens/user via StorageService.
- ItemModel maps server JSON to app-friendly fields (`in_stock`, `days_remaining`, `is_expired` are returned by backend).
- Use provider for dependency injection and screen binding.

## Prerequisites
- Flutter SDK (stable channel) — see https://flutter.dev/docs/get-started/install
- Android SDK / Xcode for device/emulator
- Backend running locally (see Backend README: Backend/inventory_tracker/README.md)

Recommended dev tooling:
- Android Studio or VS Code
- Flutter DevTools

## Setup & run (development)
1. Install dependencies:
   - `flutter pub get`

2. Start the backend API (local dev), e.g.:
   - `cd Backend/inventory_tracker`
   - `python -m venv .venv`
   - `.venv\Scripts\activate`   # Windows
   - `pip install -r requirements.txt`
   - `python manage.py migrate`
   - `python manage.py runserver 0.0.0.0:8000`

3. Configure API base URL in your Flutter app:
   - The ApiService contains the base URL. Update it to your backend host:
     - localhost for web (`http://127.0.0.1:8000`)
     - Android emulator -> 10.0.2.2 (`http://10.0.2.2:8000`)
     - iOS simulator -> 127.0.0.1
     - Physical device -> use machine LAN IP (e.g., `http://192.168.1.42:8000`)

4. Run the Flutter app:
   - `flutter run`

## Backend (server)
This project consumes a Django REST Framework backend (Inventory Tracker). Short summary and integration notes for frontend developers:

- Tech stack: Django + Django REST Framework (DRF). The backend exposes JSON REST endpoints and uses JWT (SimpleJWT) for authentication.
- Where to find it: Backend lives under the repository Backend/inventory_tracker (see its README for full instructions) and is also hosted on GitHub: https://github.com/AbdulMueed1a/inventory_tracker.git
- Run locally:
  - Create and activate a Python virtualenv
  - pip install -r requirements.txt
  - python manage.py migrate
  - python manage.py runserver 0.0.0.0:8000
- Important endpoints used by the Flutter client:
  - Authentication:
    - POST /api/auth/users/         -> signup (returns user + `access` & `refresh` tokens)
    - POST /api/auth/token/         -> obtain tokens (username/password)
    - POST /api/auth/token/refresh/ -> refresh access token
  - Items:
    - GET  /api/items/        -> list items
    - POST /api/items/        -> create item (auth)
    - GET  /api/items/<id>/   -> retrieve item
    - PUT/PATCH/DELETE /api/items/<id>/ -> update / delete (auth)
- Backend notes for Flutter integration:
  - Signup endpoint returns `access` and `refresh` tokens — the app should store and use these.
  - For Android emulator use base URL http://10.0.2.2:8000; iOS simulator use http://127.0.0.1:8000; physical device use your machine LAN IP and runserver on 0.0.0.0.
  - CORS: required for web clients. Native apps do not require CORS.
  - Error formats: DRF returns 400 for validation errors and 401 for auth errors with a `detail` message.
- Backend author: Backend implemented in DRF by ABDUL MUEED (rollno 22SW058).

## Authentication & token lifecycle (recommended)
- After signup/login the backend returns `access` and `refresh` JWT tokens.
- Store tokens securely:
  - Use `flutter_secure_storage` (or platform secure storage) to persist tokens (avoid plain SharedPreferences for sensitive tokens).
- ApiService should attach `Authorization: Bearer <access>` header to authenticated requests.
- On 401 responses:
  - Attempt token refresh by POSTing `{ "refresh": "<refresh_token>" }` to `/api/auth/token/refresh/`.
  - If refresh succeeds, update stored tokens and retry the failed request.
  - If refresh fails, clear local auth state and redirect to login.
- Keep token refresh logic centralized in ApiService or an interceptor (Dio recommended for interceptors).

## Local development notes (emulator/device differences)
- Android emulator: use `http://10.0.2.2:8000` for a backend running on your development machine.
- Genymotion: different mapping (`10.0.3.2`).
- iOS simulator: use `http://127.0.0.1:8000`
- Physical device: use your dev machine LAN IP (ensure firewall allows incoming connections and backend runserver host is `0.0.0.0`)

CORS:
- The backend should enable CORS for the Flutter web or browser-based clients. For native apps, CORS is not applicable.

## Notifications
- App uses `flutter_local_notifications` to display local notifications for:
  - Expiring soon (days remaining ≤ 7)
  - Expired items
  - Low stock alerts
- Initialize `NotificationService` on app startup and request platform permissions as needed (Android/iOS differences).

## Error handling & UX
- ViewModels surface a `error` String for UI to display friendly messages.
- Validate inputs on the client (price >= 0, quantity >= 0, expiry not in the past) before sending to API to provide immediate feedback.
- Display network errors and let users retry.

## Testing & debugging
- Unit tests: add tests for viewmodels and services (mock ApiService).
- Manual API verification: use cURL or Postman to verify endpoints and tokens.
- Logging: avoid logging tokens in plain logs; mask or omit auth tokens.

## Building for release
- Android: `flutter build apk` / `appbundle`; set proper app signing.
- iOS: `flutter build ios`; configure entitlements and app signing.
- Environment: use separate API base URLs for staging/production and avoid exposing debug endpoints in release builds.

## Contributing
- Follow clean commits, small PRs, update docs when behavior changes.
- Keep backend API contract in sync (if fields or endpoints change, update models and serializers).
- Security: prefer secure token storage and consider HttpOnly cookies for refresh tokens on web.

## Helpful commands
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter run --release`

## 👨‍💻 Project Credits

This project was collaboratively developed as part of our coursework.

- **Habibullah Dahani** — Roll No: **22SW010**
- **Abdul Mueed** — Roll No: **22SW058**

### 🛠️ Contributions

- **Base Flutter Project:** Created jointly by **Habibullah Dahani** and **Abdul Mueed**
- **Backend Development:** Implemented by **Abdul Mueed** using **Django REST Framework (DRF)**
- **Models & Backend Scope Planning:** Assisted by **Habibullah Dahani**

---
