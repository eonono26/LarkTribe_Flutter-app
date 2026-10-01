# Lark Tribe — Modern Flutter Mobile UI

This package contains the updated Flutter `lib/` for the Lark Tribe mobile app.

## What changed

- Modern mobile-first visual system:
  - rounded product imagery
  - softer editorial surfaces
  - modern typography
  - floating rounded bottom navigation
  - improved buttons, fields, cards, sheets and dialogs
  - restrained Lark Tribe warm accent while retaining the editorial brand
- Home page now reads the website's consolidated backend endpoint:
  - `GET /api/catalog/home/`
- Home page also reads:
  - `GET /api/catalog/products/on-sale/`
  - `GET /api/promotions/showcase-videos/`
  - `GET /api/catalog/brands/`
- Added a visible API connection/retry state instead of silently showing an empty store.
- Android emulator local API default changed from `127.0.0.1` to `10.0.2.2`.
- API URL remains configurable with `--dart-define=API_BASE_URL=...`.
- Existing authentication, cart, wishlist, checkout, orders, reviews, AI search, chatbot and recommendation API methods were retained.

## Local backend + Android Emulator

If Django is running on your computer at:

`http://127.0.0.1:8000`

the Android emulator should use:

`http://10.0.2.2:8000/api`

The updated API service does this automatically for Android.

Run:

```bash
flutter run
```

## Physical Android phone

A physical phone cannot use `10.0.2.2`.

Find the computer's LAN IP, for example:

`192.168.1.20`

Then run:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

Make sure the phone and computer are on the same network and Django accepts the connection.

## Deployed API

When the backend is deployed, use the deployed API directly:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN/api
```

For a release build:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN/api
```

or:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN/api
```

## Important

The uploaded first project contained only the Flutter `lib/` directory, not the Flutter project's `pubspec.yaml` and platform folders. Therefore this deliverable updates the source layer without replacing your existing Android/iOS project configuration.

Replace your project's `lib/` with the included `lib/` folder.

Required packages already used by the original source include:

- `http`
- `provider`
- `shared_preferences`
- `flutter_secure_storage`
- `cached_network_image`
- `google_fonts`
- `shimmer`

No backend API changes are required for the new home endpoint because the supplied Django backend already exposes:

`GET /api/catalog/home/`
