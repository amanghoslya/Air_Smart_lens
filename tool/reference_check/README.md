# Checking the Flutter app against the HTML prototype

The prototype in `reference/air-smart-lens-prototype.html` (6 Nov 2026) is the source of truth. Two checks compare
the Flutter code with it. Both reference files are recorded by running the prototype itself headless (jsdom), so
nothing is copied by hand. Recording needs Node and `npm i jsdom@24`.

## 1. Business logic

`export.js` loads the prototype and runs its own functions: hashes, money, range codes, all 479 order grids,
2,106 power searches with their codes, cart sentences, repeat-order grids, simulated stock per box and per power,
N/A alternatives, QR codes, scanning (and its error messages), QR modules, Shop by range and prices.

```
node export.js ../../reference/air-smart-lens-prototype.html ../../test/fixtures/js_reference.json
dart run tool/verify_logic.dart       # plain Dart, no device (from the project folder)
flutter test test/logic_test.dart
```

## 2. App behaviour

`scenarios.py` lists 171 steps (sign in, parcel orders for single vision and progressive, the power grid, cart
changes and shortfalls, checkout for each persona, change and cancel, repeat orders, RX orders, search, brands and
range cards, Shop by range, ordering inside a range with the SPH / CYL switches and the power chart, sold-out
pre-orders, Scan QR, favourite powers, menu screens, jumps, and from 6 Nov: Order by power with the range strip and
chart tabs, cart groups, Order as, Save for later, one group checked out, bulk quantities kept per range). It writes:

- `steps.json`: the steps as clicks on the prototype;
- `flows_body.dart.txt`: the same steps as calls on `AppState`, pasted into the `steps` list of
  `test/app_flow_test.dart`.

`run_original.js` runs the prototype headless and records the state after every step:

```
python3 scenarios.py
node run_original.js ../../reference/air-smart-lens-prototype.html steps.json ../../test/fixtures/js_flow_reference.json
flutter test test/app_flow_test.dart          # or, without Flutter: tool/state_check/run.sh
```

The test compares screen, back history, cart lines (quantities, prices, powers, stock), last order, favourites
(lenses, ranges, powers), pre-orders, the bulk grid, lens type and powers, the range lock, the SPH / CYL switches,
the power chart and Shop by range after every step.

`tool/state_check/run.sh` runs the same steps on the plain Dart VM: it copies `lib/` to a temporary folder with a
small stand-in for `package:flutter/foundation.dart` and silent sounds, so it needs only the Dart SDK.
