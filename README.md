# Air Smart Lens — Flutter app (Android)

The customer ordering app for Vishal Optical Co., built natively in Flutter (no WebView) from the phone-app
prototype of 6 November 2026 (`reference/air-smart-lens-prototype.html`, kept unchanged as the source of truth).
Every screen, sheet, flow and rule of the prototype is here. See *Changes on 6 November* below for what changed since
the 3 November version. The 3 November changes:

1. Search icon on Home.
2. SPH / CYL switches above the wheels (CYL off also removes AXIS; SPH off means cylinder only; one of the two is
   always on).
3. After **Add to cart** inside a lens range, the range stays chosen, so the next power can be set on the wheels or
   the **Power chart**.
4. **Add more** in the cart opens the Shop page.
5. **Shop by range**: lens type → every range code of that type → every lens made in it.
6. The cart icon shakes after 5 minutes without a touch when something is in the cart; any touch stops it.
7. A notification "Your cart is waiting" 10 minutes after the app goes to the background with something in the cart;
   opening the app cancels it, tapping it opens the cart.

The prototype has no server, so everything that would come from the ERP (catalogue, prices, stock, account, orders)
comes from `MockOrderingApi`. Replace it with a client for the real API (see *Connecting the real backend*). The
prototype's notes column ("Jump to a screen", "This screen", "Viewing as") is kept as a **debug menu** in debug
builds.

## Changes on 6 November (app brought up to the prototype of 6 November)

**Cart and checkout**
- Parcel and bulk are two separate orders. The cart shows a **Parcel order** and a **Bulk order** group, each with its
  own total and **Check out**; placing one leaves the other in the cart. **All / Parcel / Bulk** at the top shows one
  group at a time.
- Nobody is asked parcel or bulk before adding. Lines from the parcel flow are parcel, lines from the bulk flow are
  bulk; lines added after Home, Shop, Brands, Search, Favorites or Shop by range (and from a product page) get an
  **Order as: Parcel / Bulk** choice in the cart (`CartLine.grp`, `CartLine.free`, `AppState.via`).
- Every cart line shows its powers in a small table: power, quantity, price (a bulk line lists all its powers, the
  first four with **Show all**).
- **Save for later** on every line; saved lines sit under the cart, are never ordered and can be moved back.
- `OrderDraft.group` tells the server which order is being placed.

**Ordering by power**
- **Order by power** on a product page opens the wheels for that lens across all its ranges; the app finds the range.
  Under the wheels, a **range strip** lists every range of the lens and highlights the one the dialled power is in,
  live while a wheel turns; tapping a range moves the wheels into it. The **Power chart** there has range tabs as in
  bulk, and each range keeps its quantities until **Add**.
- A range tapped on a product, brand or Shop by range page opens the wheels in that range straight away (no Parcel /
  Bulk question); it works as before: that range only, no strip, no tabs.
- **Nearest power** is at most one step (0.25) on the sphere and one on the cylinder, and never drops the cylinder or
  the sphere, never flips a sign and never adds a cylinder. **N/A alternatives** are one step on the sphere or the
  cylinder and show the full power.
- Eye choice reads **BE · both eyes / Right eye / Left eye**. In the power screen's list for a lens, the newest power
  is on top. In the Type sheet, Next moves to the next box and Done hands over to the quantity box.
- **Previous Rx** is gone.

**Bulk**
- The power grid keeps the quantities of every range tab (each tab shows its total) until **Add to cart**, which adds
  one line per range (**Add 2 ranges to cart**).

**Home, Shop, header, search**
- Home: **Order by** (Brand, Lens type, Bulk (large quantity), RX, Range) right under the photos, then **Shop by
  brand** with each brand's picture, which moves along by itself every 2.5 s (a touch pauses it for 6 s).
- Shop: the search box at the top; **Order by** with **Parcel (lens type)** and **Bulk (power chart)**.
- Every screen has **Search** next to the cart at the top right (except Search itself and screens that have their own
  search; no cart on the cart, checkout and order-placed screens). The product page has them over the photo.
- Search understands the trade's short forms (`lib/core/search.dart`): BC / BRC blue cut, PC poly, PG photogray, HC hard
  coat, V2 / prog progressive, LRB low reflection blue, O2 / DC double coating (taken as HMC, to confirm), BBC blue cut
  with a blue coating. A short form matches whole tags, so HC never finds HMC. Bulk's product search uses the same.
- "Plain hard coat" now reads **Hard coating**.

The checks were recorded again from the 6 November prototype: `tool/verify_logic.dart` 25,465 checks (fewer than
before because the tighter nearest-power rule finds fewer nearby powers), and the app-flow check now has 171 steps,
30 of them for the changes above (Order by power, range strip and chart tabs, cart groups, Order as, Save for later,
one group placed, bulk ranges kept).

## Requirements

- Flutter 3.38.1 or newer (Dart 3.10 or newer), Android SDK with platform 36, JDK 17
- An Android phone (Android 7.0 / API 24 or newer) or emulator

## First run

```bash
bash tool/setup_platforms.sh     # flutter create --platforms=android, app name, notification receivers, desugaring
flutter pub get
flutter analyze
flutter test
flutter run
```

`setup_platforms.sh` generates `android/` and applies everything the plugins need (see *Android set-up*). It uses the
application id `com.vishaloptical.air_smart_lens`; change `--org` in the script to Vishal Optical's own reverse
domain before the first Play Store upload, because the id cannot change afterwards.

## Builds

```bash
flutter build apk --release                      # one APK for all phones: build/app/outputs/flutter-apk/app-release.apk
flutter build apk --release --split-per-abi      # smaller APKs, one per CPU type
flutter build appbundle --release                # App Bundle for the Play Store
```

A release build is signed with the debug key until a release key is set up. For the Play Store, create an upload
key and `android/key.properties` as in Flutter's guide "Build and release an Android app", and keep the key and its
passwords out of the repository.

The debug menu is on in debug builds only. To show it in a release build for testers:
`flutter build apk --release --dart-define=VLO_DEBUG_MENU=true`.

## Android set-up (done by `tool/setup_platforms.sh`)

| Feature | Plugin | What the app needs |
|---|---|---|
| Scan QR (camera) | `mobile_scanner` 7.5 | `CAMERA` permission and a non-required camera feature come from the plugin's manifest; Android asks the first time Scan QR opens. If refused, the screen says so and the code can be typed. |
| Cart reminder | `flutter_local_notifications` 22.3 + `timezone` | `POST_NOTIFICATIONS` comes from the plugin (asked the first time a reminder is scheduled, Android 13+). The script adds `RECEIVE_BOOT_COMPLETED`, the `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`, core library desugaring (`desugar_jdk_libs` 2.1.4), Java 17 and `minSdk` 24. The reminder uses an inexact alarm, so no exact-alarm permission is needed; it may arrive a minute or two late. |
| QR label PDF | `share_plus` 13.3 | Nothing: the plugin declares its file provider. **Download PDF** opens the phone's share sheet (save to Files, print, WhatsApp). |
| Settings kept on the phone | `shared_preferences` | Nothing. |

Notification icon: the reminder uses the launcher icon (`@mipmap/ic_launcher`). For a cleaner status-bar icon, add a
white-on-transparent `ic_stat_cart` drawable and change it in `lib/services/reminder_service.dart`.

To try the reminders without waiting: debug menu › **Cart reminders** › Test (shake after 10 s, notification 30 s
after leaving the app).

## Project structure

```
lib/
  main.dart                    App start: data, settings on the phone, sounds, reminders, theme (light / dark)
  core/                        Pure Dart (no Flutter): the business rules
    models.dart                Product, PriceLine (range, envelope), PowerBlock, Rx, Match, PowerGrid, CartLine, StockStatus
    logic.dart                 Power matching, nearest power, made-to-order, range codes, order grids and Super Masters,
                               tier prices, cart lines, shortfall per power, sentences, stock per power, N/A
                               alternatives, VOC1 QR codes and scanning, Shop by range index
    quantity.dart              Pairs / pieces / one eye, axis steps, wheel values, snapping
    stock.dart                 Stock per power (simulated: Available, Low stock, Sold out, N/A)
    format.dart                Powers with the true minus sign, rupees with Indian grouping, names, codes
    brands.dart                Brand photography, names, poster list, brand order, Hindi menu
    catalog_data.dart          Parses the bundled JSON data
    js_compat.dart             Numbers, rounding, the FNV hash and text sorting exactly as the prototype's JavaScript
  data/
    ordering_api.dart          The interface to the ERP (replace the mock with the real client)
    mock_ordering_api.dart     The prototype's simulated data and delays
    content.dart               Ledger, invoices, videos, FAQ, staff logins, RX lab orders
  state/
    app_state.dart             All app state and every action of the prototype (ChangeNotifier)
    app_scope.dart             Puts the state in the widget tree
  services/
    sound_service.dart         Wheel clicks and app sounds (audioplayers) with haptics
    device_store.dart          Settings kept on the phone (shared_preferences)
    reminder_service.dart      The cart reminder notification
    qr_label.dart              QR modules and the A6 label PDF (written by hand, no PDF library)
  ui/
    shell.dart                 Frame: current screen, footer, floating tab bar, toast, loader, side menu; touch = activity
    theme.dart                 Colour tokens (light and dark, from the prototype's CSS), type scale
    widgets.dart               Shared widgets: header, buttons, chips, rows, notes, pills, quantity control, cart nudge
    parts.dart                 Favorite and QR buttons, QR view and label sheet, range rows and the Parcel / Bulk sheet,
                               N/A box, brand lens cards
    power_grid.dart            The power grid (bulk) and power chart (inside a range): stock marks, legend, selected box
    icons.dart, art.dart       Line icons (same SVG paths), brand photos, envelope photos, the painted lens
    wheels.dart                SPH / CYL / AXIS / ADD wheels with switches and fixed values inside a range
    sheets.dart                Bottom sheets: Type, Change quantity, Pre-order
    lens3d.dart                The 3D glass lens: loader, order-placed envelope, confetti
    drawer.dart                Side menu, with Display (dark mode; QR code or Favorite beside each power)
    debug_menu.dart            Prototype tools: jump to a screen, persona, notes, stock mode, reminder test
    screens/
      registry.dart            Screen name → builder (same names as the prototype)
      start_screens.dart       Welcome, Login, Home, Shop, Lens type
      parcel_screens.dart      Power (wheels, power chart), Lens options, Results, Product
      range_screens.dart       Shop by range: lens type, range list, lenses in a range
      scan_screen.dart         Scan QR (camera, sample codes, codes made on this phone, typed code)
      order_screens.dart       Cart, Checkout, Order placed, Orders
      stock_screens.dart       Bulk: lens type, product, range, power grid
      browse_screens.dart      Account, Brands, Brand, Search, Favorites
      rx_screens.dart          RX order, RX details
      menu_screens.dart        Pre-orders, Posters, Videos, Certificates, Price list, Ledger, Transactions, Invoices,
                               Staff logins, Web login, Language, Contact, FAQ, About, Terms
assets/
  data/catalog.json            74 products, 479 range lines (2 Nov price file), prices, power blocks, envelopes
  data/super_masters.json      The standard grids
  data/simulated_account.json  The prototype's shop, past orders, welcome posters, sample QR codes
  images/brand/                Brand cards and posters (53)
  images/envelopes/            Envelope photos, one per range (108)
  sounds/                      Wheel ticks and app sounds (WAV)
  fonts/                       DM Sans, Cormorant Garamond with lining digits (OFL)
test/
  logic_test.dart              Business rules vs the prototype's JavaScript (25,465 checks)
  app_flow_test.dart           171 steps through the app vs the prototype, state compared after every step
  widget_test.dart             Opens every screen once; fails on any build or layout error
  reference_checks.dart        The checks behind logic_test (also run by tool/verify_logic.dart)
  fixtures/                    Reference results recorded from the prototype
tool/
  setup_platforms.sh           Generates android/ with the settings above
  verify_logic.dart            The logic check on plain Dart (no device, no Flutter engine)
  state_check/run.sh           The 171-step flow check on plain Dart (no device, no Flutter engine)
  reference_check/             How the reference results are recorded from the prototype (see its README)
reference/
  air-smart-lens-prototype.html   The prototype of 6 Nov, unchanged
```

## From the prototype to Flutter

| Prototype (HTML/JS) | Flutter |
|---|---|
| `S` state object, `go()`, `back()`, `render()` | `AppState` fields and methods; `notifyListeners` |
| `R.*` and `EXTRA.*` screens | one builder each in `ui/screens/*`, listed in `registry.dart` |
| `data-a` / `data-x` click actions | `AppState` methods with the same behaviour |
| Scroll wheels with switches, power chart | `PowerWheels` (ListWheelScrollView), `PowerChart` / `PowerGridView` |
| `localStorage` (welcome poster, Pairs / Pieces, saved powers, QR or Favorite, dark mode, sound) | `shared_preferences` |
| Scan QR simulator (tap a code) | the phone camera (`mobile_scanner`), plus the same sample codes and a typed code |
| QR label PDF download | the same A6 PDF, shared through the share sheet |
| Cart shake after 5 minutes | `CartNudge` on the bag button (a ring instead when the phone asks for reduced motion) |
| "Notification" 10–15 minutes after leaving | a real local notification after 10 minutes |
| Web Audio sounds, `navigator.vibrate` | WAV files rendered from the same recipes, `HapticFeedback` |
| Notes column, Jump to a screen, Viewing as | debug menu (bug button, debug builds) |

## Connecting the real backend

Implement `OrderingApi` (`lib/data/ordering_api.dart`) and pass it in `main.dart` instead of `MockOrderingApi`:

- `load()`: catalogue (products, lines, power blocks, prices, envelopes, Super Master links), the shop's tier and
  credit, past orders and the account content. The JSON in `assets/data` shows the shapes.
- `stock`: a `StockService` that returns the status of each power from the ERP. Customers see the status only
  (Available, Low stock, Sold out, N/A, Coming soon, Made to order), never quantities. The cart's shortfall check
  needs the available quantity per power, which should come from the server at checkout.
- `requestOtp` / `verifyOtp`: sign in by mobile number and one-time code; the persona (owner, staff, sub-customer)
  and the four switches come back with the session.
- `placeOrder` / `cancelOrder`, and pre-orders (sold-out powers and coming-soon ranges), which today stay on the phone.
- When Vishal prints the VOC1 code on every envelope, scanning works the same: the code is plain text read against
  the catalogue on the phone, so it works offline.

**Security.** Nothing secret is in the app: no API keys, passwords or signing keys. Keep them on the server; the app
should only hold the signed-in user's session token, in platform secure storage (for example
`flutter_secure_storage`). Prices, stock and permissions must be enforced by the server; the switches in the app
only change what is shown.

## What was checked, and how

- Dart analyzer with `flutter_lints`: no issues (`flutter analyze`).
- `tool/verify_logic.dart` / `test/logic_test.dart`: 25,465 checks against the prototype's own JavaScript (all 479
  order grids, 2,106 power searches with codes, simulated stock of 8,722 boxes and 7,804 matched powers, N/A
  alternatives, 1,506 QR codes, scanning with its error messages, QR modules, Shop by range, prices): all equal.
- `tool/state_check/run.sh` / `test/app_flow_test.dart`: 171 steps (sign in, parcel orders, progressive eyes, power
  grid, cart and shortfall, checkout for each persona, change and cancel, repeat orders, RX, search, brands and range
  cards, Shop by range, ordering inside a range with the SPH / CYL switches and the power chart, sold-out pre-orders,
  Scan QR, favourite powers, menu) run on the prototype and on `AppState`: the state matched after every step.
- The QR label PDF was rendered and its QR read back to the same code.

Not possible where this was built (no Flutter engine or Android SDK there): the widget test, the APK build and runs
on a phone. Run `flutter test` and `flutter build apk`, then try it on a phone; worth a close look: the wheels with
the switches, the power chart and grid with the keyboard, Scan QR with real labels, the reminder (debug menu test
mode), and dark mode.

## Small differences from the prototype

- Scan QR uses the real camera; the sample codes stay below it for testing.
- The cart reminder is a real notification 10 minutes after leaving (the prototype simulated 10–15 minutes).
- **Download PDF** shares the label (the share sheet has Save, Print and WhatsApp) instead of a browser download.
