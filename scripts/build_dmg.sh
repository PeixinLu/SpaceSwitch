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
BACKGROUND_TEXT=${BACKGROUND_TEXT:-"拖动到 Applications 完成安装 / Drag to Applications to install"}

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

STAGING_DIR="$(mktemp -d)"
MOUNT_DIR="$(mktemp -d)"
BG_DIR="${STAGING_DIR}/.background"
BG_SVG="${BG_DIR}/background.svg"
BG_PNG="${BG_DIR}/background.png"
RW_DMG="${PROJECT_NAME}-rw.dmg"

mkdir -p "${BG_DIR}"
cat > "${BG_SVG}" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="560" height="360">
  <rect width="100%" height="100%" fill="#f8f9fb"/>
  <text x="280" y="190" font-family="Helvetica, Arial, sans-serif" font-size="20" fill="#6b7280" text-anchor="middle">${BACKGROUND_TEXT}</text>
</svg>
EOF

qlmanage -t -s 600 -o "${BG_DIR}" "${BG_SVG}" >/dev/null 2>&1 || true
if [[ -f "${BG_DIR}/background.svg.png" ]]; then
  mv "${BG_DIR}/background.svg.png" "${BG_PNG}"
fi

hdiutil create -size 200m -fs HFS+ -volname "${PROJECT_NAME}" -layout SPUD -format UDRW "${RW_DMG}" >/dev/null
hdiutil attach "${RW_DMG}" -mountpoint "${MOUNT_DIR}" -nobrowse >/dev/null

ditto "${APP_PATH}" "${MOUNT_DIR}/${PROJECT_NAME}.app"
ln -s /Applications "${MOUNT_DIR}/Applications"
mkdir -p "${MOUNT_DIR}/.background"
if [[ -f "${BG_PNG}" ]]; then
  cp "${BG_PNG}" "${MOUNT_DIR}/.background/background.png"
fi

osascript <<EOF
tell application "Finder"
  tell disk "${PROJECT_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 200, 760, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set position of item "${PROJECT_NAME}.app" of container window to {150, 180}
    set position of item "Applications" of container window to {410, 180}
    if exists file ".background:background.png" then
      set background picture of viewOptions to file ".background:background.png"
    end if
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

hdiutil detach "${MOUNT_DIR}" >/dev/null
hdiutil convert "${RW_DMG}" -format UDZO -ov -o "${DMG_NAME}" >/dev/null
rm -f "${RW_DMG}"
rm -rf "${STAGING_DIR}" "${MOUNT_DIR}"

echo "Created ${DMG_NAME}"
