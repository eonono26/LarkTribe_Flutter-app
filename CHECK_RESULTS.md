# Lark Tribe Flutter project check

## Fixed

- Resolved the Dart `Category` name collision by hiding Flutter's foundation `Category` annotation import.
- Corrected catalog filter query parameters to match the Django backend:
  - `department`
  - `category`
  - `brand`
  - `gender`
  - `age_group`
  - `stage`
  - `is_featured`
  - `on_sale`
- Removed calls to catalog routes that are not exposed by the supplied Django backend (`/featured/`, `/new-arrivals/`, `/on-sale/`, `/top-rated/`). These now use the real `/catalog/products/` endpoint with supported filters/orderings.
- Added product variant parsing (`id`, `size`, `color`, `stock`, `sku_suffix`).
- Added `variant_id` support to cart requests.
- Product details now require the appropriate variant selection when a product has multiple variants and automatically select a single available variant.
- Quick-add now prevents a size-required product from sending an invalid cart request.

## Static verification

- 40 Dart files scanned.
- All relative local imports resolve to files in the project.
- All imported third-party packages are declared in `pubspec.yaml`.
- No duplicate public Dart class declarations were found.
- All `ApiService.instance.*` references resolve to declared API service members.

## Runtime note

The execution environment used to prepare this ZIP does not contain the Flutter SDK, so `flutter analyze` and `flutter test` could not be executed here. The project should still be checked locally with:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```
