# Larktribe — Flutter app

A native mobile client for the Larktribe marketplace (Django backend +
Next.js web storefront). Rebuilt from your original `lib/` with:

- Fields/endpoints aligned to the current backend serializers (catalog,
  cart, orders, wishlist, notifications, AI recommendations/search,
  promotions/coupons, support tickets, delivery tracking).
- A **real native bottom navigation bar** (Home / Shop / Saved / Bag /
  Account) instead of a website-style top nav + drawer.
- Redesigned product cards: discount ribbon, star rating, low-stock /
  sold-out badges, floating wishlist heart, one-tap "add to bag".
- New Shop tab (departments → categories) and Account tab (profile, orders,
  saved items, notifications, sign out).

## Setup

```bash
flutter pub get
```

Point the app at your backend — either edit the default in
`lib/services/api_service.dart`:

```dart
defaultValue: 'http://10.0.2.2:8000/api', // 10.0.2.2 = Android emulator localhost
```

or pass it at run/build time:

```bash
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

Notes:
- On a physical device, `10.0.2.2` won't reach your laptop — use your
  machine's LAN IP or a deployed backend URL instead.
- iOS Simulator can use `http://localhost:8000/api` directly.
- Social login (`socialLogin`) is wired in `api_service.dart` but the
  Google/Apple sign-in buttons in `login_screen.dart` are left as TODOs —
  add `google_sign_in` / `sign_in_with_apple` when you're ready to enable
  those buttons.

## Structure

```
lib/
  main.dart                 # app entry, MaterialApp -> MainShell
  theme/app_theme.dart       # colors, typography, component themes
  models/models.dart         # DTOs matching backend serializers
  services/
    api_service.dart         # all REST calls
    cart_provider.dart        # cart state (Provider)
  screens/
    main_shell.dart           # bottom nav shell (5 tabs)
    home_screen.dart          # Home tab
    categories_screen.dart    # Shop tab
    wishlist_screen.dart      # Saved tab (+ pushed route)
    cart_screen.dart          # Bag tab (+ pushed route)
    account_screen.dart       # Account tab
    product_list_screen.dart  # generic dept/category/brand grid
    product_detail_screen.dart
    search_screen.dart
    checkout_screen.dart
    login_screen.dart / register_screen.dart
    orders_screen.dart / order_detail_screen.dart
    notifications_screen.dart
  widgets/
    product_card.dart, product_row.dart, wishlist_button.dart,
    review_form.dart, chatbot_sheet.dart
```
