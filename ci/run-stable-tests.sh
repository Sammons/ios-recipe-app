#!/usr/bin/env bash
set -euo pipefail

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
PROJECT_PATH="${PROJECT_PATH:-RecipeApp.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-RecipeApp}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/TestResults.xcresult}"
MAX_UI_RETRIES="${MAX_UI_RETRIES:-3}"
MAX_FUNCTIONAL_RETRIES="${MAX_FUNCTIONAL_RETRIES:-2}"
MAX_UNIT_RETRIES="${MAX_UNIT_RETRIES:-2}"
LAST_ATTEMPTS_USED=1
RETRY_RECORDS=""

record_retry_usage() {
  local stage="$1"
  local max_retries="$2"
  local attempts_used="$3"
  local status="$4"

  RETRY_RECORDS+="${stage}|${max_retries}|${attempts_used}|${status}"$'\n'
}

print_retry_summary() {
  local total_retries=0
  local stage
  local max_retries
  local attempts_used
  local status
  local retries_used

  echo "==> Retry summary"
  while IFS='|' read -r stage max_retries attempts_used status; do
    if [ -z "$stage" ]; then
      continue
    fi
    retries_used=$((attempts_used - 1))
    total_retries=$((total_retries + retries_used))
    echo "==>   ${stage}: ${status} on attempt ${attempts_used}/${max_retries} (retries used: ${retries_used})"
  done <<< "$RETRY_RECORDS"
  echo "==> Total retries used: ${total_retries}"
}

trap print_retry_summary EXIT

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

resolve_simulator_udid() {
  xcrun simctl list devices available | awk -F '[()]' -v name="$SIMULATOR_NAME" '
    {
      candidate = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
      if (candidate == name) {
        print $2
        exit
      }
    }
  '
}

prepare_simulator() {
  local udid
  udid="$(resolve_simulator_udid)"

  if [ -z "$udid" ]; then
    echo "Warning: could not resolve simulator UDID for '$SIMULATOR_NAME'; falling back to global reset"
    xcrun simctl shutdown all || true
    sleep 3
    xcrun simctl boot all || true
    sleep 5
    return
  fi

  xcrun simctl shutdown "$udid" 2>/dev/null || true
  sleep 2
  xcrun simctl boot "$udid" 2>/dev/null || true

  # Wait for simulator to fully boot (Springboard ready)
  if ! xcrun simctl bootstatus "$udid" -b 2>/dev/null; then
    echo "Warning: bootstatus wait failed; adding extra delay"
    sleep 8
  fi
  # Extra settle time for Springboard and app installation services
  sleep 3
}

retry_with_sim_reset() {
  local label="$1"
  local max_retries="$2"
  shift 2

  local attempt=1
  prepare_simulator
  until "$@"; do
    if [ "$attempt" -ge "$max_retries" ]; then
      echo "${label} failed after ${max_retries} attempts" >&2
      LAST_ATTEMPTS_USED="$attempt"
      return 1
    fi

    attempt=$((attempt + 1))
    echo "Retrying ${label} (attempt ${attempt}/${max_retries})"
    prepare_simulator
    rm -rf "$RESULT_BUNDLE"
    sleep 5
  done

  LAST_ATTEMPTS_USED="$attempt"
}

report_retry_usage() {
  local stage="$1"
  local max_retries="$2"
  local attempts_used="$3"
  local retries_used=$((attempts_used - 1))

  echo "==> ${stage}: passed on attempt ${attempts_used}/${max_retries} (retries used: ${retries_used})"
}

run_stage_with_retries() {
  local stage="$1"
  local max_retries="$2"
  shift 2

  if retry_with_sim_reset "$stage" "$max_retries" "$@"; then
    record_retry_usage "$stage" "$max_retries" "$LAST_ATTEMPTS_USED" "passed"
    report_retry_usage "$stage" "$max_retries" "$LAST_ATTEMPTS_USED"
    return 0
  fi

  record_retry_usage "$stage" "$max_retries" "$LAST_ATTEMPTS_USED" "failed"
  echo "==> ${stage}: failed on attempt ${LAST_ATTEMPTS_USED}/${max_retries}" >&2
  return 1
}

echo "==> Build for testing"
xcodebuild build-for-testing \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
  -quiet

echo "==> Run functional flow tests"
run_stage_with_retries "functional flow tests" "$MAX_FUNCTIONAL_RETRIES" run_functional_flow_tests

echo "==> Run unit tests"
run_stage_with_retries "unit tests" "$MAX_UNIT_RETRIES" run_unit_tests

echo "==> Run regression UI tests"
rm -rf "$RESULT_BUNDLE"
run_stage_with_retries "regression UI tests" "$MAX_UI_RETRIES" run_regression_ui_tests

echo "==> Verify UX evidence gate"
./ci/verify-ux-gates.sh "$RESULT_BUNDLE"

echo "==> Stable test run complete"
