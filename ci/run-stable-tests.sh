#!/usr/bin/env bash
set -euo pipefail

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
PROJECT_PATH="${PROJECT_PATH:-RecipeApp.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-RecipeApp}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/TestResults.xcresult}"
MAX_UI_RETRIES="${MAX_UI_RETRIES:-3}"
MAX_FUNCTIONAL_RETRIES="${MAX_FUNCTIONAL_RETRIES:-2}"
MAX_UNIT_RETRIES="${MAX_UNIT_RETRIES:-2}"

run_regression_ui_tests() {
  xcodebuild test-without-building \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -parallel-testing-enabled NO \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testShoppingListShowsVisibleGenerateButton \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testWeekViewRowCanBeTappedAcrossFullWidth \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testWeekViewDoubleTapOpensDayView \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testRecipeBuilderKeyboardHasDoneAction \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testMealCompletionSheetActionsRemoveRowsAndDismiss \
    -only-testing:RecipeAppUITests/RecipeAppUITests/testRecipeDetailShowsNutritionAllergensAndIngredientCategories \
    -resultBundlePath "$RESULT_BUNDLE" \
    -quiet
}

run_functional_flow_tests() {
  xcodebuild test-without-building \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -parallel-testing-enabled NO \
    -only-testing:RecipeAppTests/FunctionalFlowTests \
    -quiet
}

run_unit_tests() {
  xcodebuild test-without-building \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -parallel-testing-enabled NO \
    -only-testing:RecipeAppTests \
    -quiet
}

retry_with_sim_reset() {
  local label="$1"
  local max_retries="$2"
  shift 2

  local attempt=1
  until "$@"; do
    if [ "$attempt" -ge "$max_retries" ]; then
      echo "${label} failed after ${max_retries} attempts" >&2
      return 1
    fi

    attempt=$((attempt + 1))
    echo "Retrying ${label} (attempt ${attempt}/${max_retries})"
    xcrun simctl shutdown all || true
    xcrun simctl erase all || true
    rm -rf "$RESULT_BUNDLE"
    sleep 5
  done
}

echo "==> Build for testing"
xcodebuild build-for-testing \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -quiet

echo "==> Run functional flow tests"
retry_with_sim_reset "functional flow tests" "$MAX_FUNCTIONAL_RETRIES" run_functional_flow_tests

echo "==> Run unit tests"
retry_with_sim_reset "unit tests" "$MAX_UNIT_RETRIES" run_unit_tests

echo "==> Run regression UI tests"
rm -rf "$RESULT_BUNDLE"
retry_with_sim_reset "regression UI tests" "$MAX_UI_RETRIES" run_regression_ui_tests

echo "==> Verify UX evidence gate"
./ci/verify-ux-gates.sh "$RESULT_BUNDLE"

echo "==> Stable test run complete"
