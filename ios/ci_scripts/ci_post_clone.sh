#!/bin/sh
set -euo pipefail

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Xcode Cloud images do not include Node.js by default.
if ! command -v node >/dev/null 2>&1; then
  brew install node@20
  brew link node@20 --force --overwrite
fi

npm ci

if [ "${XCODE_CLOUD_SKIP_PREBUILD:-}" != "true" ]; then
  npx expo prebuild --platform ios
fi

cd ios
pod install
