#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}
export PATH="$JAVA_HOME/bin:$PATH"
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
ADB=${ADB:-$SDK/platform-tools/adb}
bash tests/check-apk.sh launcher/build/tvhome.apk
mkdir -p launcher/build/policy-tests
javac -d launcher/build/policy-tests launcher/src/com/mihir/tvhome/HomePolicy.java tests/HomePolicyTest.java
java -cp launcher/build/policy-tests com.mihir.tvhome.HomePolicyTest
if [[ ${1:-} == --device ]]; then
  : "${ADB_SERIAL:?Set ADB_SERIAL; install the launcher preview first}"
  bash tests/device/build.sh
  RESULT=$("$ADB" -s "$ADB_SERIAL" install -r launcher/build/device-tests/tests.apk 2>&1)
  printf '%s\n' "$RESULT"
  printf '%s\n' "$RESULT" | tr -d '\r' | grep -qx Success
  RESULT=$("$ADB" -s "$ADB_SERIAL" shell am instrument -w com.mihir.tvhome.test/.SmokeInstrumentation 2>&1)
  printf '%s\n' "$RESULT"
  # TCL may return exit code 0 even for a Java exception or native crash.
  printf '%s\n' "$RESULT" | grep -q '^PASS: 5 device checks'
fi
