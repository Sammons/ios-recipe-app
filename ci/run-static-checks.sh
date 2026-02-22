#!/usr/bin/env bash
set -euo pipefail

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
SIMULATOR_OS="${SIMULATOR_OS:-}"
PROJECT_PATH="${PROJECT_PATH:-RecipeApp.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-RecipeApp}"
SOURCES_DIR="Sources/RecipeApp"
DESTINATION="platform=iOS Simulator,name=$SIMULATOR_NAME"

if [[ -n "$SIMULATOR_OS" ]]; then
    DESTINATION="$DESTINATION,OS=$SIMULATOR_OS"
fi

echo "==> Running static analysis via xcodebuild analyze"
if ! xcodebuild analyze \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "$DESTINATION" \
    -quiet 2>&1; then
    echo "ERROR: xcodebuild analyze found issues" >&2
    exit 1
fi

echo "==> Checking for unsafe operators in $SOURCES_DIR (excluding tests)"

try_bang_matches="$(grep -Rns --include="*.swift" 'try!' "$SOURCES_DIR" 2>/dev/null || true)"
as_bang_matches="$(grep -Rns --include="*.swift" 'as!' "$SOURCES_DIR" 2>/dev/null || true)"

if [[ -n "$try_bang_matches" ]]; then
    echo "ERROR: Found 'try!' in the following locations (these can crash at runtime):" >&2
    echo "$try_bang_matches" >&2
    echo "ERROR: Replace try! with safe error handling or use try? with proper fallbacks" >&2
    exit 1
fi

if [[ -n "$as_bang_matches" ]]; then
    echo "ERROR: Found 'as!' in the following locations (these can crash if cast fails):" >&2
    echo "$as_bang_matches" >&2
    echo "ERROR: Replace as! with safe 'as?' or conditional 'as' casting" >&2
    exit 1
fi

echo "==> Static checks passed: no unsafe operators found"
