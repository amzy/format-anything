#!/usr/bin/env bash
set -Eeuo pipefail

# Run from the repository root. Fail immediately if any verification step fails.
if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK is not on PATH." >&2
  exit 127
fi

echo "==> Flutter version"
flutter --version

echo "==> Resolve dependencies"
flutter pub get

echo "==> Static analysis (warnings and errors must be resolved)"
flutter analyze

echo "==> Unit/widget tests"
flutter test

echo "==> Release web build"
flutter build web --release --base-href /format-anything/

echo "SUCCESS: analyze, tests, and release web build all passed."
