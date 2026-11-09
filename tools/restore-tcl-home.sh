#!/usr/bin/env bash
# Restore TCL as native default Home; retain both APKs and all app data.
set -euo pipefail
SERIAL=${1:-${ADB_SERIAL:-}}
: "${SERIAL:?Usage: restore-tcl-home.sh TV_IP:5555}"
ADB=${ADB:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb}
HELPER_JAR=${HELPER_JAR:-$(dirname "$0")/../launcher/build/legacy-home/tvhome-tools.jar}
[[ -f "$HELPER_JAR" ]] || { echo 'Build tools/legacy-home/build.sh or set HELPER_JAR.' >&2; exit 1; }
"$ADB" connect "$SERIAL"
STOCK=$("$ADB" -s "$SERIAL" shell pm list packages -e com.tcl.cyberui)
printf '%s\n' "$STOCK" | tr -d '\r' | grep -qx 'package:com.tcl.cyberui' || {
  echo 'ERROR: stock TCL Home is not enabled; recovery cannot be confirmed.' >&2; exit 1;
}
"$ADB" -s "$SERIAL" push "$HELPER_JAR" /data/local/tmp/tvhome-tools.jar
# Only our own app can change its HOME alias on this firmware.
RESULT=$("$ADB" -s "$SERIAL" shell am start -n com.mihir.tvhome/.RestoreHomeActivity 2>&1)
printf '%s\n' "$RESULT"
if printf '%s\n' "$RESULT" | grep -Eq 'Error|Exception|Permission Denial'; then exit 1; fi
for ((i=0; i<15; i++)); do
  STATE=$("$ADB" -s "$SERIAL" shell 'CLASSPATH=/data/local/tmp/tvhome-tools.jar app_process /system/bin LegacyHome status')
  if printf '%s\n' "$STATE" | grep -q 'Candidate: com.tcl.cyberui/.MainActivity' &&
     ! printf '%s\n' "$STATE" | grep -q 'Candidate: com.mihir.tvhome/.HomeActivity'; then
    RESULT=$("$ADB" -s "$SERIAL" shell 'CLASSPATH=/data/local/tmp/tvhome-tools.jar app_process /system/bin LegacyHome stock')
    printf '%s\n' "$RESULT"
    printf '%s\n' "$RESULT" | grep -q 'PASS: selected com.tcl.cyberui/.MainActivity' || exit 1
    "$ADB" -s "$SERIAL" shell input keyevent 3
    echo 'Restored native TCL Home. Both APKs and app data are retained.'
    echo 'TCL may open its last input according to its own startup settings.'
    echo 'To use TV Home again, open it and choose Home mode > Use TV Home.'
    exit 0
  fi
  sleep 0.3
done
echo 'ERROR: recovery not confirmed; inspect ADB and the TV.' >&2
exit 1
