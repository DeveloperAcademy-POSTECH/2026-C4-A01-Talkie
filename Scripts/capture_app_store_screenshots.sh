#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
DEVICE_NAME="${TALKIE_SCREENSHOT_DEVICE:-iPhone 17 Pro Max}"
OS_VERSION="${TALKIE_SCREENSHOT_OS:-26.5}"
RUNTIME_ID="com.apple.CoreSimulator.SimRuntime.iOS-${OS_VERSION//./-}"
BUNDLE_ID="com.NestLeavers.Talkie"
DERIVED_DATA_PATH="$REPO_ROOT/.build/release-screenshots"
OUTPUT_DIR="$REPO_ROOT/fastlane/screenshots/ko-KR"
PROJECT_PATH="$REPO_ROOT/Talkie/Talkie.xcodeproj"

export DEVELOPER_DIR

DEVICE_ID="$({
  xcrun simctl list devices available -j \
    | jq -r --arg runtime "$RUNTIME_ID" --arg name "$DEVICE_NAME" \
      '.devices[$runtime][]? | select(.name == $name) | .udid' \
    | head -n 1
})"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Screenshot simulator not found: $DEVICE_NAME / iOS $OS_VERSION" >&2
  echo "Override with TALKIE_SCREENSHOT_DEVICE and TALKIE_SCREENSHOT_OS." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
find "$OUTPUT_DIR" -type f -name '*.png' -delete
find "$OUTPUT_DIR" -type f -name '*.jpg' -delete

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl ui "$DEVICE_ID" appearance dark
xcrun simctl status_bar "$DEVICE_ID" override \
  --time '9:41' \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme Talkie \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Talkie.app"
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

capture() {
  local order="$1"
  local mode="$2"
  local slug="$3"
  local output="$OUTPUT_DIR/${order}_${slug}.jpg"
  local raw_output="$OUTPUT_DIR/${order}_${slug}.raw.png"

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  launch_output="$(xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" \
    -talkieScreenshotMode "$mode" \
    -AppleLanguages '(ko)' \
    -AppleLocale 'ko_KR')"
  sleep 2

  pid="${launch_output##*: }"
  if ! xcrun simctl spawn "$DEVICE_ID" /bin/kill -0 "$pid" 2>/dev/null; then
    echo "Talkie exited before screenshot capture: $mode" >&2
    exit 1
  fi

  xcrun simctl io "$DEVICE_ID" screenshot --type=png "$raw_output"
  sips -s format jpeg -s formatOptions 100 "$raw_output" --out "$output" >/dev/null
  rm "$raw_output"
  echo "Captured $output"
}

capture '01' phoneHome phone_home
capture '02' activeCall active_call
capture '03' sos sos_actions
capture '04' scenarioList scenario_list
capture '05' onboardingSafety onboarding_safety

xcrun simctl status_bar "$DEVICE_ID" clear

EXPECTED_WIDTH="${TALKIE_SCREENSHOT_WIDTH:-1320}"
EXPECTED_HEIGHT="${TALKIE_SCREENSHOT_HEIGHT:-2868}"

for screenshot in "$OUTPUT_DIR"/*.jpg; do
  width="$(sips -g pixelWidth "$screenshot" | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$screenshot" | awk '/pixelHeight/ { print $2 }')"
  has_alpha="$(sips -g hasAlpha "$screenshot" | awk '/hasAlpha/ { print $2 }')"

  if [[ "$width" != "$EXPECTED_WIDTH" || "$height" != "$EXPECTED_HEIGHT" ]]; then
    echo "Unexpected screenshot size: $screenshot (${width}x${height})" >&2
    echo "Expected ${EXPECTED_WIDTH}x${EXPECTED_HEIGHT}." >&2
    exit 1
  fi

  if [[ "$has_alpha" != "no" ]]; then
    echo "Screenshot contains an alpha channel: $screenshot" >&2
    exit 1
  fi
done

echo "Captured and validated 5 screenshots in $OUTPUT_DIR"
