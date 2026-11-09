# iShop Mobile

Flutter (Material 3) client for the iShop electronics microservice backend:
a public storefront (Home, Product Detail), Login, a customer flow (Cart, Checkout, My Orders),
and a small ADMIN-only dashboard.

The app talks **only** to the API gateway on port `8080`.

## The idea

iShop is an electronics store whose backend is already built as a set of microservices
(auth, operations, reports, scheduled jobs) behind one API gateway. This app is the
mobile front end for that system: one Android app that serves both the people who shop
and the people who run the shop.

- **Shoppers** can browse the catalogue without an account: search, sort, check stock and
  swipe through product photos. After signing in they can fill a cart, check out and follow
  their orders, or cancel one that is still pending. Checkout has no payment step. It places
  a `PENDING` order, and an admin completes it.
- **Admins** sign in to the same app and get a separate dashboard. It shows sales and stock
  reports, recent orders, low-stock products and the status of the background jobs, and lets
  them create, edit and delete products.

Some principles guided the build:

- **The backend is the source of truth.** The app shows only real API data, never mock data.
  Cart totals, prices and stock come from the server and are never calculated on the phone.
- **One door in.** Every request goes through the gateway, and the app uses only the endpoints
  the backend actually exposes.
- **Security is enforced, not just hidden.** Signed-in and admin-only screens are guarded in
  the router. Expired tokens are refreshed automatically, and a real "access denied" is shown
  as such.
- **Failures are visible.** Every screen that loads data has a loading, empty, error-with-retry
  and signed-out state, so a broken connection or a failed report never shows up as a blank
  page.
- **Kept small.** A few well-known packages (`http`, `provider`, `go_router`,
  `shared_preferences`, `intl`) and a clear split between UI, state and data layers, so the app
  is easy to follow and to extend. A Register screen is a natural next step.

## Project layout

```
lib/
  main.dart                 bootstrap: restore session, wire providers, router
  app/                      router.dart (routes + guards), theme.dart
  core/                     config.dart (API_BASE_URL), formatters.dart, validators.dart
  data/
    api/                    api_client.dart (auth header, refresh-once), auth/product/admin/cart/order/customer APIs
    models/                 DTOs with fromJson/toJson matching the backend exactly
    storage/                token_storage.dart (shared_preferences)
  state/                    auth_controller.dart, async_controller.dart, cart_controller.dart
  features/                 home, product, cart, checkout, orders, auth, admin screens
  widgets/                  product card, badges, error/empty/skeleton views
```

State: `provider` (+ `ChangeNotifier`). Navigation: `go_router`. HTTP: `http`.

## Run on the Android emulator

1. Start the backend (gateway on `http://localhost:8080`).
2. Start an emulator, then:

```bash
flutter pub get
flutter run
```

The default base URL is `http://10.0.2.2:8080`, which is the host machine as seen from the
Android emulator, so no extra flags are needed.

## Setting `API_BASE_URL`

Override the gateway URL at build/run time:

```bash
# Real phone on the same Wi-Fi: use your PC's LAN IP (ipconfig / ifconfig)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Make sure the PC firewall allows inbound connections on port 8080.
Cleartext HTTP is enabled in `android/app/src/main/AndroidManifest.xml`
(`android:usesCleartextTraffic="true"`), together with the `INTERNET` permission.

## Build the release APK

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Install with
`adb install -r build/app/outputs/flutter-apk/app-release.apk` or copy it to the phone.

> `API_BASE_URL` is compiled in. Rebuild the APK if the PC's IP changes.

### Release signing

The release build is signed with the **debug keys** so `flutter build apk --release` works
out of the box. To publish, use a real keystore:

1. `keytool -genkey -v -keystore ~/ishop-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ishop`
2. Create `android/key.properties` (don't commit it):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=ishop
   storeFile=C:/Users/you/ishop-release.jks
   ```
3. In `android/app/build.gradle.kts`, load that file, add
   `signingConfigs { create("release") { ... } }`, and set
   `signingConfig = signingConfigs.getByName("release")` in the `release` build type.

### Windows build troubleshooting

- **`[CXX1416] Could not find Ninja`**: the Flutter Gradle plugin runs an empty CMake project so
  the NDK gets used. Install the Android SDK "CMake" package (Android Studio → SDK Manager → SDK
  Tools), or put `ninja` on `PATH` (`scoop install ninja`).
- **CMake "C compiler is broken" / `'C:\Program' is not recognized`**: a broken
  `AutoRun` value under `HKLM\Software\Microsoft\Command Processor` makes every `cmd.exe /C`
  exit with code 1. Remove it from an **elevated** prompt:
  `reg delete "HKLM\Software\Microsoft\Command Processor" /v AutoRun /f`
- **"Building with plugins requires symlink support"**: enable Developer Mode
  (`start ms-settings:developers`). This is needed for Windows desktop builds and is harmless
  for Android.

## Auth behaviour

- `accessToken`, `refreshToken` and the `user` JSON are stored in `shared_preferences`, so the
  session survives app restarts.
- Public product requests never send `Authorization`. Protected requests send `Bearer <token>`.
- 401, or 403 with an **empty** body, means the token expired. The client calls
  `POST /api/auth/refresh` once (concurrent requests share it), saves the new access **and**
  refresh tokens, and retries the request once. If the refresh fails, storage is cleared and the
  user is sent to Login.
- 403 **with** a JSON body is a real permission error: no refresh, a forbidden state is shown.
- Logout clears local storage (there is no logout endpoint).
- `/admin/**` routes are guarded in the router: signed out → Login (then back to the route);
  signed in without `ADMIN` → forbidden screen.

Local dev admin: `admin@local.test` / `Admin@1234!`
