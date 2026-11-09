#!/usr/bin/env bash
# Restore TCL Home. Keep both APKs and all application data.
set -euo pipefail
SERIAL=${1:-${ADB_SERIAL:-}}
: "${SERIAL:?Usage: restore-tcl-home.sh TV_IP:5555}"
ADB=${ADB:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb}
"$ADB" connect "$SERIAL"
# This firmware rejects shell pm enable/disable, even for third-party packages.
# Verify stock Home is present/enabled, then ask our DUMP-protected recovery entry
# to persistently turn off redirect and launch stock. No package state changes.
STOCK=$("$ADB" -s "$SERIAL" shell pm list packages -e com.tcl.cyberui)
printf '%s\n' "$STOCK" | tr -d '\r' | grep -qx 'package:com.tcl.cyberui' || {
  echo 'ERROR: stock TCL Home is not enabled; recovery cannot be confirmed.' >&2; exit 1;
}
RESULT=$("$ADB" -s "$SERIAL" shell am start -n com.mihir.tvhome/.RestoreHomeActivity 2>&1)
printf '%s\n' "$RESULT"
if printf '%s\n' "$RESULT" | grep -Eq 'Error|Exception|Permission Denial'; then exit 1; fi
for ((i=0; i<10; i++)); do
  STATE=$("$ADB" -s "$SERIAL" shell dumpsys activity activities)
  if printf '%s\n' "$STATE" | grep -Eq 'mResumedActivity:.*com\.tcl\.cyberui/(com\.tcl\.cyberui)?\.MainActivity[[:space:]}]'; then
    printf '%s\n' "$STATE" | grep mResumedActivity
    echo 'Restored TCL Home. No APK or application data was deleted.'
    echo 'To use TV Home again: open it and choose Home mode > Enable Home return.'
    exit 0
  fi
  sleep 1
done
echo 'ERROR: original TCL Home was not confirmed. Inspect the TV and ADB connection.' >&2
exit 1
