#!/usr/bin/env bash
# Tests the actual packaged contract, not source strings.
set -euo pipefail
APK=${1:?usage: check-apk.sh path/to.apk}
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
AAPT=${AAPT:-$SDK/build-tools/35.0.0/aapt}
BADGING=$("$AAPT" dump badging "$APK")
MIN=$(printf '%s\n' "$BADGING" | sed -n "s/^sdkVersion:'\([0-9]*\)'.*/\1/p")
[[ -n "$MIN" && "$MIN" -le 22 ]] || { echo "FAIL: minSdk $MIN excludes API 22"; exit 1; }
printf '%s\n' "$BADGING" | grep -q "launchable-activity: name='com.mihir.tvhome.MainActivity'" || { echo 'FAIL: no ordinary app entry for safe preview'; exit 1; }
MANIFEST=$("$AAPT" dump xmltree "$APK" AndroidManifest.xml)
for required in android.intent.category.HOME com.tcl.app.type com.tcl.ui; do
  printf '%s\n' "$MANIFEST" | grep -Fq "$required" || { echo "FAIL: missing native Home contract: $required"; exit 1; }
done
if printf '%s\n' "$MANIFEST" | grep -Eq 'HomeRedirectService|BootReceiver|RECEIVE_BOOT_COMPLETED'; then
  echo 'FAIL: obsolete redirect/boot path is still packaged'; exit 1
fi
echo 'PASS: API 22, ordinary app entry, native Home alias and TCL metadata; no redirect service'
