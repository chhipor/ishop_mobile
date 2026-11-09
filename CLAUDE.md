# CLAUDE.md: iShop Mobile

Flutter client for the existing **iShop electronics e-commerce microservice backend**. Scope: a public
storefront (Home, Product Detail with image gallery), Login, a signed-in customer flow (Cart, Checkout
without payment, My Orders + cancel), and an ADMIN-only dashboard (Dashboard + Products tabs). It must run on an Android emulator or a phone and build into a release APK.

The Dart package is named `ishop_mobile` (imports use `package:ishop_mobile/...`).
The Android `applicationId` is `com.ishop.mobile` and the app label is "iShop". The Kotlin namespace is
also `com.ishop.mobile`. Code has no comments; keep it that way. `work/legacy_lib/` holds an old unrelated exercise
(Angkor Wat pages). It's excluded from analysis, so don't touch it.

## Hard rules (from the original spec)

- **Talk only to the gateway on :8080.** Never call service ports 6666/8888/9999/7777.
  The base URL comes from `--dart-define=API_BASE_URL=...` and defaults to `http://10.0.2.2:8080` (`lib/core/config.dart`).
- **Don't invent endpoints, fields, filters or workflows.** The full allowed API is listed below.
  There is no payment, logout endpoint, auth "me" endpoint, password change, categories, or server-side
  search/pagination. Checkout places a PENDING order; an admin completes it. Register exists on the
  backend but has no screen yet.
- **Use real API data only.** Never hide failures behind mock or fake data.
- **Every data screen handles** loading, empty, error-with-retry, and 401/403.
- **No HTTP in widgets.** All API access goes through `lib/data/api/`.
- Models match the backend DTOs exactly: IDs are UUID strings, timestamps are ISO-8601 parsed with
  `DateTime.parse` (the backend sends up to 9 fractional digits, which Dart accepts), money is `num` → `double`.
- No CORS workarounds (this is a native app).
- Packages are kept minimal: `http`, `shared_preferences`, `provider`, `go_router`, `intl`. Don't add others without reason.

## Architecture

```
lib/
  main.dart            restores the session (TokenStorage.create) BEFORE runApp, wires providers, MaterialApp.router
  app/router.dart      routes + guard (_guard). refreshListenable = AuthController
  app/theme.dart       AppColors, AppTheme.light(), AppTheme.admin(base) (navy chrome)
  core/                config.dart, formatters.dart ($1,299.99 · "Nov 6, 2026 14:05" local), validators.dart (incl. isUuid)
  data/api/api_client.dart   ALL auth/refresh logic lives here
  data/api/{auth,product,admin,cart,order,customer}_api.dart   typed endpoint wrappers (order_api = "my orders")
  data/models/         api_error.dart (ApiErrorResponse + ApiException/ApiErrorKind), auth_response, user, product, cart, order (+Customer, CustomerProfileRequest), reports, cron_status
  data/storage/token_storage.dart   shared_preferences keys ishop.accessToken / ishop.refreshToken / ishop.user, plus an in-memory cache
  state/auth_controller.dart   ChangeNotifier: user, isLoggedIn, isAdmin, sessionExpired flag, login(), logout()
  state/async_controller.dart  AsyncController<T>: per-section loading/data/error (optional initialData); screens own one per independent section
  state/cart_controller.dart   app-wide ChangeNotifier: Cart?, loads on sign-in (by user id), clears on sign-out; every mutation replaces the cart with the server response
  features/home, product, cart, checkout, orders (list + detail), auth (login + forbidden), admin (shell, dashboard, products list, product form)
  widgets/             product_card, product_image (Image.network -> ProductPlaceholder fallback), product_placeholder, cart_button (badge), quantity_stepper,
                       snackbars (showErrorSnackBar skips sessionExpired), status_badge, error_view (ErrorInfo.from), empty_view, loading_skeleton, section_card, account_menu
```

State management is **provider** (DI + AuthController), and screens use `AsyncController` + `ListenableBuilder`.
Keep it that way. Don't mix in Riverpod or Bloc.

### Auth / token rules (implemented in ApiClient; keep them intact)
- Public requests (`auth: false`) send **no** Authorization header. Protected requests send `Bearer <accessToken>`.
- **Token expired** = 401, or **403 with an EMPTY body**, on a request that carried a token. The client then:
  if another request already rotated the token, it retries with that token; otherwise it calls `POST /api/auth/refresh`
  once (`_refreshing` future shared by concurrent callers), saves the NEW access AND refresh token (the old refresh token is
  revoked), and retries once. If the retry is still expired, it signs out, so it never loops.
- If the refresh returns 4xx (backend sends 400), it clears storage, fires `onSessionExpired`, and AuthController sets `_user=null`
  and `sessionExpired=true`. The router then redirects admin routes to `/login?from=...`, and Login shows an "expired" banner.
  A network error or 5xx on refresh keeps the session and surfaces the error.
- **403 WITH a JSON body** ("Access denied") is a real permission error: no refresh, show the forbidden state.
- A 401/403 on a *public* request is shown as "Backend configuration problem" (`ErrorView(publicRequest: true)`).
- Logout only clears local storage, then goes to `/`.
- After login, LoginScreen itself calls `context.go(postLoginLocation(auth, from))` (`from` if present, else ADMIN → `/admin`, others → `/`).
  Don't rely on the router redirect alone: Login is often *pushed*, and the refresh redirect doesn't replace a pushed page.

### Routes
`/` Home · `/products/:id` (validates the UUID client-side first; invalid → "Product not found") ·
`/cart` · `/checkout` · `/orders` · `/orders/:id` (`extra` = OrderResponse for instant display, always refetched) ·
`/login?from=` · `/forbidden` · ShellRoute (AdminShell, bottom nav): `/admin`, `/admin/products`,
`/admin/products/new` and `/admin/products/:id/edit` (full-screen on the root navigator; `extra` = ProductResponse,
otherwise fetched by id). The form pops with a `String` success message, and the list shows it as a snackbar and reloads.
Guard: cart/checkout/orders need any signed-in user (else Login with `from`); admin routes: signed out → Login,
signed in but not ADMIN → `/forbidden`. Enforced in the router, not only by hiding buttons.

### Screen specifics worth remembering
- Home shows only `active == true` products, with client-side search (name/SKU), sort (name, price low/high), pull-to-refresh,
  a skeleton grid, and `SliverGridDelegateWithMaxCrossAxisExtent(230)` (2 columns on phones, more on tablets).
  Client-side pagination: `AppConfig.productsPerPage` = 6, `PaginationBar` below the grid ("Showing 7–12 of 15"); search/sort
  reset to page 1, page change scrolls to top, page is clamped after a refresh. The backend still returns the full list.
- Stock badge: "Out of stock" (≤0), "Low stock" (≤5, `AppConfig.lowStockThreshold`), "In stock".
- Images: cards use `thumbnail` → `images.first` → placeholder; Detail gallery (PageView) uses `images` → `thumbnail` → placeholder.
  `errorBuilder` falls back to the placeholder. Seed images are .webp from cdn.dummyjson.com.
- Detail: quantity stepper capped at min(stock, 99) minus what's already in the cart (POST /cart/items ADDS). Out of stock / inactive →
  disabled button. Signed out → `/login?from=/products/<id>`. 404 → not-found view with "Back to products".
- Cart: stepper (PUT sets qty), swipe/X remove, "Clear cart" (confirm), warning chip when `!available`, Checkout disabled if empty/any
  unavailable. Reloads on open. Never compute totals locally.
- Checkout: GET/PUT /customers/me (firstName/lastName required, email read-only; PUT only if changed), "No payment" note, then
  POST /cart/checkout → `go('/orders/<id>')`. 400 messages ("Insufficient stock…", "Product is inactive…") shown in a banner.
- Orders: list (number, date, status, total, thumbnails), detail with "Cancel order" only when PENDING (confirm dialog).
- Login maps 401 → "Invalid email or password" and 400 → `fieldErrors` under matching fields (`email`, `password`). The dev hint
  shows `admin@local.test / Admin@1234!` with a "Use" button.
- Dashboard: KPI tiles are labelled "Reports" with a note that the reporting DB may differ from live lists and that totals include
  cancelled orders. Each tile/card has its own AsyncController, so one failure doesn't break the page. Recent orders = latest 8
  by `orderDate` desc (client-side). Low stock = live products with `quantityInStock <= 5`. Cron null → "Not run since restart".
- Products tab lists ALL products (incl. inactive). Delete asks for confirmation; **409 → "This product is used in orders. Set it
  inactive instead."** The form mirrors ProductRequest validation (name ≤150, sku ≤80, description ≤500 optional, price > 0,
  qty ≥ 0 int, active bool, thumbnail URL ≤1000 optional, images ≤10 URLs) and shows server `fieldErrors` keys
  `name/sku/description/unitPrice/quantityInStock/active/thumbnail/images`. PUT is a full replace, so the form always sends the
  current thumbnail/images back.
- Admin endpoints are ADMIN-only on the backend: a non-admin gets 403 + JSON "Access denied" (permission error, no refresh).

## API reference (the ONLY endpoints the app may call)

Errors use `ApiErrorResponse { timestamp, status, error, message, path, fieldErrors? }`.
400 = validation (`message` "Validation failed" + `fieldErrors`), a business rule, a bad UUID in the path, or malformed JSON;
401 = bad login; 403 empty = missing/expired token; 403 JSON = "Access denied"; 404 not found; 409 "Database constraint violation"
or "Customer email is linked to another account"; 500 = unexpected.
Lists are plain JSON arrays with no envelope and no pagination.

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | /api/auth/login | public | `{email,password}` → AuthResponse; 400/401 |
| POST | /api/auth/refresh | public | `{refreshToken}` → new AuthResponse (replace BOTH tokens); 400 → sign out |
| GET | /api/operations/products | public | `List<ProductResponse>` incl. inactive |
| GET | /api/operations/products/{id} | public | ProductResponse; 404 |
| POST | /api/operations/products | token | ProductRequest → 201; 400 "SKU already exists"/"Product name already exists" |
| PUT | /api/operations/products/{id} | token | full replace; 400/404 |
| DELETE | /api/operations/products/{id} | token | `{message}`; 404; 409 if used in an order |
| GET/PUT | /api/operations/customers/me | token | CustomerResponse (auto-created on first GET); PUT CustomerProfileRequest `{firstName,lastName,phone?,address?}` |
| GET/DELETE | /api/operations/cart | token | Cart (auto-created) / cleared Cart |
| POST | /api/operations/cart/items | token | `{productId, quantity 1..99}` ADDS → Cart |
| PUT/DELETE | /api/operations/cart/items/{productId} | token | `{quantity 1..99}` sets → Cart / remove → Cart |
| POST | /api/operations/cart/checkout | token | 201 OrderResponse (PENDING); cart emptied, stock deducted |
| GET | /api/operations/orders/me · /orders/me/{id} | token | own orders newest first / one (404 if not yours) |
| POST | /api/operations/orders/me/{id}/cancel | token | → CANCELLED (stock returned); 400 unless PENDING |
| GET | /api/operations/orders | ADMIN | `List<OrderResponse>` (admin also has /customers[/{id}], PUT /orders/{id}) |
| GET | /api/reports/products · /orders · /customers · /sales | ADMIN | report DTOs (see `lib/data/models/reports.dart`) |
| GET | /api/jobs/status | ADMIN | CronStatusResponse (fields null until run since restart) |

Product adds `thumbnail` (String?) and `images` (List<String>, never null). OrderItem adds `thumbnail`; Customer adds `userId` (String?).
CartItem: id, productId, productName, sku, thumbnail?, unitPrice (current price), quantity, lineTotal, quantityInStock, available, addedAt.
Cart: id, customerId, items, totalQuantity, totalAmount, createdAt, updatedAt.
AuthResponse: tokenType, accessToken, refreshToken, accessTokenExpiresInSeconds (3600), refreshTokenExpiresInSeconds (604800), user.
Access JWT lasts 60 min. Refresh JWT lasts 7 days, is single-use and rotated. Logging in revokes the user's previous refresh tokens.
Roles: `ADMIN`, `USER` (`user.roles.contains("ADMIN")`).

## Android / release readiness (already done; keep it)
- MAIN manifest has `INTERNET` permission + `android:usesCleartextTraffic="true"` + label "iShop".
- `android/app/build.gradle.kts`: `applicationId = "com.ishop.mobile"`, release signed with debug keys (the
  README "Release signing" section explains how to plug in a real keystore). minSdk = flutter default (fine for all packages).
- README covers emulator run, `API_BASE_URL`, APK build, signing and Windows troubleshooting.

## Commands
```bash
flutter analyze          # must be "No issues found!"
flutter test             # test/widget_test.dart: models (incl. cart/order/images), formatters, ApiClient + CartApi tests (MockClient)
flutter build apk --release --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8080
# output: build/app/outputs/flutter-apk/app-release.apk
```
Run `dart format lib test` after edits. Lints: flutter_lints + prefer_single_quotes, always_declare_return_types, avoid_print.
Dart SDK ^3.12 (null-aware elements like `?trailing` are used).

## Dev machine notes (Windows; this specific PC)
- Shell: the Bash tool's heredocs with complex quoting failed. Use the Write/Edit tools for source files.
- Flutter SDK: `D:\setec\Year4\Flutter\flutter` (3.44, stable). Android SDK: `C:\Users\User\AppData\Local\Android\Sdk`
  (NDK 28.2.13676358, **no SDK CMake package**; Gradle uses system CMake 3.22 at `C:\Program Files\CMake`).
- Ninja was missing and was installed with `scoop install ninja` (needed by the CMake step the Flutter Gradle plugin always runs).
- **Known blocker (as of 2026-11-06):** `HKLM\Software\Microsoft\Command Processor\AutoRun` = unquoted
  `C:\Program Files\PowerShell\7\pwsh.exe`. Every `cmd.exe /C` prints `'C:\Program' is not recognized` and exits 1,
  which fails the CMake/Ninja link step, so **every Android build fails**. Fix (admin shell):
  `reg delete "HKLM\Software\Microsoft\Command Processor" /v AutoRun /f`. Check with
  `cmd.exe /C "cd . && echo ok"`: the exit code must be 0. Once fixed, re-run `flutter build apk --release` and confirm the APK exists.
- "Building with plugins requires symlink support" warning = Developer Mode is off. It didn't block Android builds.

## Status
- Done: all screens incl. cart/checkout/my orders/images (2026-11-09), data layer, guards, refresh logic, Android config, README,
  tests (18 passing), analyze clean.
- Pending: a successful `flutter build apk --release` (blocked only by the AutoRun registry issue above), then
  verifying it against a live backend on the emulator/phone. Optional: a Register screen (customers currently need an account
  created elsewhere).
