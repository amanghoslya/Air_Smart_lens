#!/usr/bin/env bash
# Runs the 141 app-flow steps of test/app_flow_test.dart on the plain Dart VM (no Flutter engine, no device), against
# test/fixtures/js_flow_reference.json recorded from the HTML prototype. Needs only the Dart SDK.
#   tool/state_check/run.sh            (from the project folder; uses the qr package from the pub cache)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"; proj="$(cd "$here/../.." && pwd)"
qr="${QR_PACKAGE_DIR:-$(ls -d "${PUB_CACHE:-$HOME/.pub-cache}"/hosted/pub.dev/qr-3.* 2>/dev/null | tail -1)}"
work="$(mktemp -d)"
cfg="$(python3 "$here/make_runner.py" "$proj" "$work" "$qr")"
cd "$work/app" && dart --packages="$cfg" flow.dart
