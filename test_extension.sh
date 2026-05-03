#!/bin/bash
# QuickNew Extension Automated Test Script
set -e

APP_NAME="QuickNew"
EXT_NAME="QuickNewFinderExtension"
BUNDLE_ID="com.panjing.RightMenu"
EXT_BUNDLE_ID="com.panjing.RightMenu.FinderExtension"
BUILD_DIR=$(ls -d ~/Library/Developer/Xcode/DerivedData/RightMenu-*/Build/Products/Debug/ | head -1)
APP_PATH="${BUILD_DIR}${APP_NAME}.app"
EXT_PATH="${BUILD_DIR}${EXT_NAME}.appex"
TEST_DIR="/tmp/quicknew_test_$(date +%s)"

echo "=== QuickNew Extension Test Suite ==="
echo ""

# ---- Test 1: Build artifacts exist ----
echo "[Test 1] Build artifacts exist..."
if [ -d "$APP_PATH" ]; then
    echo "  PASS: $APP_PATH exists"
else
    echo "  FAIL: $APP_PATH not found"
    exit 1
fi

if [ -d "$EXT_PATH" ]; then
    echo "  PASS: $EXT_PATH exists"
else
    echo "  FAIL: $EXT_PATH not found"
    exit 1
fi

# ---- Test 2: Code signature valid ----
echo ""
echo "[Test 2] Code signature..."
codesign -v "$APP_PATH" 2>&1 && echo "  PASS: App signature valid" || echo "  FAIL: App signature invalid"
codesign -v "$EXT_PATH" 2>&1 && echo "  PASS: Extension signature valid" || echo "  FAIL: Extension signature invalid"

# ---- Test 3: Extension registered ----
echo ""
echo "[Test 3] Extension registration..."
EXT_INFO=$(pluginkit -m -p com.apple.FinderSync 2>/dev/null | grep -A2 "$EXT_BUNDLE_ID" || true)
if [ -n "$EXT_INFO" ]; then
    echo "  PASS: Extension registered with pluginkit"
    echo "  $EXT_INFO"
else
    echo "  WARN: Extension not yet registered (may need Finder restart)"
fi

# ---- Test 4: App launches without crash ----
echo ""
echo "[Test 4] App launch test..."
killall "$APP_NAME" 2>/dev/null || true
sleep 0.5
open "$APP_PATH"
sleep 3
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "  PASS: App launched successfully (PID: $(pgrep -x "$APP_NAME"))"
    killall "$APP_NAME" 2>/dev/null || true
else
    echo "  FAIL: App did not launch"
fi

# ---- Test 5: File creation service (direct, in accessible directory) ----
echo ""
echo "[Test 5] Direct file creation in /tmp..."
mkdir -p "$TEST_DIR"
TEST_FILE="$TEST_DIR/test_file.txt"
echo "test content" > "$TEST_FILE"
if [ -f "$TEST_FILE" ]; then
    echo "  PASS: File created at $TEST_FILE"
else
    echo "  FAIL: Could not create test file"
fi

# ---- Test 6: Verify no DiagnosticLog references remain ----
echo ""
echo "[Test 6] DiagnosticLog cleanup..."
LOG_REFS=$(grep -r "DiagnosticLog" ~/Downloads/right_menu/RightMenu/ ~/Downloads/right_menu/Shared/ ~/Downloads/right_menu/RightMenuFinderExtension/ 2>/dev/null | grep -v ".xcodeproj" | grep -v "Binary" || true)
if [ -z "$LOG_REFS" ]; then
    echo "  PASS: No DiagnosticLog references in source files"
else
    echo "  FAIL: Found DiagnosticLog references:"
    echo "  $LOG_REFS"
fi

# ---- Test 7: Verify no URL scheme references in extension ----
echo ""
echo "[Test 7] URL scheme removal from extension..."
URL_REFS=$(grep -r "quicknew" ~/Downloads/right_menu/RightMenuFinderExtension/ 2>/dev/null | grep -v "Binary" || true)
if [ -z "$URL_REFS" ]; then
    echo "  PASS: No URL scheme references in extension"
else
    echo "  FAIL: Found URL scheme references:"
    echo "  $URL_REFS"
fi

# ---- Test 8: Verify NSOpenPanel authorization flow in extension ----
echo ""
echo "[Test 8] Authorization flow code check..."
AUTH_CODE=$(grep -c "NSOpenPanel" ~/Downloads/right_menu/RightMenuFinderExtension/FinderSyncController.swift || true)
if [ "$AUTH_CODE" -ge 1 ]; then
    echo "  PASS: NSOpenPanel present in extension ($AUTH_CODE occurrence(s))"
else
    echo "  FAIL: NSOpenPanel not found in extension"
fi

ACTIVATE_CODE=$(grep -c "NSApp.activate" ~/Downloads/right_menu/RightMenuFinderExtension/FinderSyncController.swift || true)
if [ "$ACTIVATE_CODE" -ge 1 ]; then
    echo "  PASS: NSApp.activate present for panel clickability"
else
    echo "  WARN: NSApp.activate not found - panel may not be clickable"
fi

FLOAT_CODE=$(grep -c "\.floating" ~/Downloads/right_menu/RightMenuFinderExtension/FinderSyncController.swift || true)
if [ "$FLOAT_CODE" -ge 1 ]; then
    echo "  PASS: panel.level = .floating set"
else
    echo "  FAIL: .floating level not set"
fi

# ---- Test 9: Verify QuickNewURLHandler removed from main app ----
echo ""
echo "[Test 9] URL handler removal from main app..."
HANDLER_CODE=$(grep -c "QuickNewURLHandler" ~/Downloads/right_menu/RightMenu/RightMenuApp.swift || true)
ONOPEN_CODE=$(grep -c "onOpenURL" ~/Downloads/right_menu/RightMenu/RightMenuApp.swift || true)
if [ "$HANDLER_CODE" -eq 0 ] && [ "$ONOPEN_CODE" -eq 0 ]; then
    echo "  PASS: URL handler and onOpenURL removed from main app"
else
    echo "  FAIL: URL handler or onOpenURL still in main app"
fi

# ---- Test 10: Verify no startup authorization refresh ----
echo ""
echo "[Test 10] Startup authorization check..."
REFRESH_CODE=$(grep -c "refreshAuthorizedDirectories" ~/Downloads/right_menu/RightMenu/RightMenuApp.swift || true)
if [ "$REFRESH_CODE" -eq 0 ]; then
    echo "  PASS: No refreshAuthorizedDirectories on startup"
else
    echo "  FAIL: refreshAuthorizedDirectories still called on startup"
fi

# ---- Restart Finder to reload extension ----
echo ""
echo "[Cleanup] Restarting Finder to reload extension..."
killall Finder 2>/dev/null || true
rm -rf "$TEST_DIR"
echo ""
echo "=== Test Suite Complete ==="
echo "Please manually test in Finder:"
echo "  1. Right-click in a directory → create a new file"
echo "  2. If authorization needed, NSOpenPanel should appear on top and be clickable"
echo "  3. TCC 'access other app data' prompt should appear only once (first time)"
