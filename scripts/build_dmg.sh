#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="SpaceSwitch"
PROJECT_PATH="${PROJECT_NAME}.xcodeproj"
SCHEME_NAME="${PROJECT_NAME}"
CONFIGURATION="Release"
BUILD_DIR="build"
PRODUCT_DIR="${BUILD_DIR}/Build/Products/${CONFIGURATION}"
APP_PATH="${PRODUCT_DIR}/${PROJECT_NAME}.app"
OUTPUT_DIR="dist"
BACKGROUND_IMAGE=${BACKGROUND_IMAGE:-"SpaceSwitch/assets/image.png"}

rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}" "${PROJECT_NAME}.dmg"

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

STAGING_DIR="$(mktemp -d)"
CONTENT_DIR="${STAGING_DIR}/contents"
BG_DIR="${STAGING_DIR}/background"
BG_PNG="${BG_DIR}/background.png"

mkdir -p "${CONTENT_DIR}" "${BG_DIR}"
ditto "${APP_PATH}" "${CONTENT_DIR}/${PROJECT_NAME}.app"

if [[ -f "${BACKGROUND_IMAGE}" ]]; then
  cp "${BACKGROUND_IMAGE}" "${BG_PNG}"
fi

CREATE_DMG_ARGS=(
  --volname "${PROJECT_NAME}"
  --window-size 660 400
  --icon-size 96
  --icon "${PROJECT_NAME}.app" 230 175
  --app-drop-link 430 175
)

if [[ -f "${BG_PNG}" ]]; then
  CREATE_DMG_ARGS+=(--background "${BG_PNG}")
fi

if create-dmg "${CREATE_DMG_ARGS[@]}" "${PROJECT_NAME}.dmg" "${CONTENT_DIR}"; then
  echo "DMG decoration succeeded"
  sleep 6
else
  echo "DMG decoration skipped (CI fallback)"
  create-dmg "${CREATE_DMG_ARGS[@]}" --skip-jenkins "${PROJECT_NAME}.dmg" "${CONTENT_DIR}"
fi

rm -rf "${STAGING_DIR}"
echo "Created ${PROJECT_NAME}.dmg"
