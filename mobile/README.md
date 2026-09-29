# Baba Yelp mobile app (Flutter)

One Dart/Flutter codebase for iOS and Android (plus a web build for quick
previews). See the [root README](../README.md) for the big picture.

## Run it

Start the API first (`cd ../backend && bin/rails server -b 0.0.0.0`), then:

```sh
flutter pub get
open -a Simulator && flutter run      # iOS Simulator → http://localhost:3000
flutter run -d emulator-5554          # Android emulator → http://10.0.2.2:3000
```

The app reads the API address from `API_BASE_URL`:

```sh
flutter run --dart-define=API_BASE_URL=http://localhost:3001        # API on another port
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000     # a real phone: use your computer's LAN IP
```

Simulators have no GPS. Set a location to try "near me" search, e.g. Fremont, CA:
`xcrun simctl location booted set 37.5483,-121.9886` (or **Features ▸ Location** in
Simulator; **⋯ ▸ Location** in the Android emulator). You can also tap the
location bar and type a place.

iOS builds use Swift Package Manager, so CocoaPods isn't needed. Android builds
need Android Studio and its SDK.

## Test it

```sh
flutter analyze
flutter test                 # unit tests + widget tests of both use cases (fake API)
```

End to end, against a freshly seeded API (`bin/rails db:reset`) and a booted
simulator. It signs in as `demo@example.com`, posts reviews and adds a
restaurant, then saves screenshots to `build/screenshots/`:

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/use_cases_test.dart \
  --dart-define=API_BASE_URL=http://localhost:3000 -d <simulator id>
```

## Code map

```
lib/
  main.dart, app.dart     startup and dependency wiring (Provider)
  config.dart             API_BASE_URL
  api/api_client.dart     typed client for the Rails API
  models/                 JSON models and the search query
  state/                  AuthState (sign-in, token in Keychain/Keystore), LocationState
  services/               device location, secure token storage
  screens/
    discover_screen.dart         use case 1: pick dishes + location + radius
    results_screen.dart          sorted results, per-dish ratings, filters
    restaurant_screen.dart       menu with ratings, directions, call
    restaurant_dish_screen.dart  one dish at one restaurant: ratings and reviews
    review/                      use case 2: what → where (find or add) → rate
    profile_screen.dart          your reviews, sign out, delete account
  widgets/                dish picker, location picker, stars, cards
```

## Before shipping

* Point `API_BASE_URL` at an HTTPS server. The plain-HTTP allowances
  (`NSAllowsLocalNetworking` on iOS, `usesCleartextTraffic` in the Android
  debug manifest) are for local development only.
* Set real bundle identifiers (currently `com.babayelp.babaYelp` /
  `com.babayelp.baba_yelp`), app icons and release signing.
