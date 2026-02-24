#!/usr/bin/env bash
set -euo pipefail

RESULT_BUNDLE="${1:-build/TestResults.xcresult}"
GATE_CONFIG="${GATE_CONFIG:-ci/ux-gates.json}"

if [ ! -d "$RESULT_BUNDLE" ]; then
  echo "ERROR: missing xcresult bundle at $RESULT_BUNDLE" >&2
  exit 1
fi

if [ ! -f "$GATE_CONFIG" ]; then
  echo "ERROR: missing UX gate config at $GATE_CONFIG" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/raw"
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$TMP_DIR/raw" >/dev/null 2>&1 || true

xcrun xcresulttool get test-results tests \
  --path "$RESULT_BUNDLE" > "$TMP_DIR/test-results.json" 2>/dev/null || echo "{}" > "$TMP_DIR/test-results.json"

python3 << 'PYEOF' "$GATE_CONFIG" "$TMP_DIR/raw/manifest.json" "$TMP_DIR/test-results.json"
import json
import os
import re
import sys

config_path, manifest_path, results_path = sys.argv[1:4]
config = json.load(open(config_path))
required_tests = config.get("required_tests", [])
required_screenshots = config.get("required_screenshots", [])

def normalize_attachment_name(name: str) -> str:
    return re.sub(r"_\d+_[A-F0-9-]+\.png$", ".png", name, flags=re.IGNORECASE)

screenshots = set()
if os.path.exists(manifest_path):
    manifest = json.load(open(manifest_path))
    entries = manifest if isinstance(manifest, list) else [manifest]
    for test_entry in entries:
        for att in test_entry.get("attachments", []):
            exported = att.get("exportedFileName", "")
            suggested = att.get("suggestedHumanReadableName", exported)
            if suggested.lower().endswith(".png"):
                screenshots.add(normalize_attachment_name(suggested))

passing_statuses = {"passed", "expected failure", "success"}
passed_tests = set()

def walk(node):
    node_type = node.get("nodeType", node.get("type", ""))
    name = str(node.get("name", ""))
    if node_type == "Test Case":
        status = str(node.get("result", "")).lower()
        if status in passing_statuses:
            passed_tests.add(name)
    for child in node.get("children", []):
        walk(child)

if os.path.exists(results_path):
    data = json.load(open(results_path))
    roots = data.get("testNodes", [data]) if isinstance(data, dict) else data
    if not isinstance(roots, list):
        roots = [roots]
    for root in roots:
        if isinstance(root, dict):
            walk(root)

missing_tests = []
for required in required_tests:
    if not any(required in test_name for test_name in passed_tests):
        missing_tests.append(required)

missing_screenshots = [shot for shot in required_screenshots if shot not in screenshots]

if missing_tests or missing_screenshots:
    print("ERROR: UX gate failed")
    if missing_tests:
        print("Missing passing tests:")
        for test_name in missing_tests:
            print(f"  - {test_name}")
    if missing_screenshots:
        print("Missing screenshots:")
        for shot in missing_screenshots:
            print(f"  - {shot}")
    sys.exit(1)

print(
    f"UX gate passed: {len(required_tests)} required tests, "
    f"{len(required_screenshots)} required screenshots"
)
PYEOF
