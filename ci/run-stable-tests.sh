#!/usr/bin/env bash
set -euo pipefail

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
PROJECT_PATH="${PROJECT_PATH:-RecipeApp.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-RecipeApp}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/TestResults.xcresult}"
MAX_UI_RETRIES="${MAX_UI_RETRIES:-3}"

run_regression_ui_tests() {
  xcodebuild test-without-building \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -parallel-testing-enabled NO \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testShoppingListShowsVisibleGenerateButton \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testWeekViewRowCanBeTappedAcrossFullWidth \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testRecipeBuilderKeyboardHasDoneAction \
    -resultBundlePath "$RESULT_BUNDLE" \
    -quiet
}

echo "==> Build for testing"
xcodebuild build-for-testing \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -quiet

echo "==> Run unit tests"
xcodebuild test-without-building \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -parallel-testing-enabled NO \
  -only-testing:RecipeAppTests \
  -quiet

echo "==> Run regression UI tests"
rm -rf "$RESULT_BUNDLE"
attempt=1
until run_regression_ui_tests; do
  if [ "$attempt" -ge "$MAX_UI_RETRIES" ]; then
    echo "Regression UI tests failed after ${MAX_UI_RETRIES} attempts" >&2
    exit 1
  fi

  attempt=$((attempt + 1))
  echo "Retrying regression UI tests (attempt ${attempt}/${MAX_UI_RETRIES})"
  xcrun simctl shutdown all || true
  xcrun simctl erase all || true
  rm -rf "$RESULT_BUNDLE"
  sleep 5
done

echo "==> Stable test run complete"
