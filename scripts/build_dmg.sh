#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="SpaceSwitch"
PROJECT_PATH="${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="${PROJECT_NAME}"
CONFIGURATION="Release"
BUILD_DIR="build"
PRODUCT_DIR="${BUILD_DIR}/Build/Products/${CONFIGURATION}"
APP_PATH="${PRODUCT_DIR}/${PROJECT_NAME}.app"
DMG_NAME="${PROJECT_NAME}.dmg"

rm -rf "${BUILD_DIR}" "${DMG_NAME}"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${BUILD_DIR}" \
  clean build

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Error: App not found at ${APP_PATH}" >&2
  exit 1
fi

hdiutil create \
  -volname "${PROJECT_NAME}" \
  -srcfolder "${APP_PATH}" \
  -ov \
  -format UDZO \
  "${DMG_NAME}"

echo "Created ${DMG_NAME}"
