#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
BT=$SDK/build-tools/${BUILD_TOOLS_VERSION:-35.0.0}
JAR=$SDK/platforms/android-34/android.jar
B=launcher/build/device-tests
mkdir -p "$B/classes" "$B/dex"
"$BT/aapt2" link -o "$B/base.apk" -I "$JAR" --manifest tests/device/AndroidManifest.xml --min-sdk-version 22 --target-sdk-version 30
javac --release 11 -classpath "$JAR" -d "$B/classes" tests/device/SmokeInstrumentation.java
"$BT/d8" --min-api 22 --lib "$JAR" --output "$B/dex" "$B/classes/com/mihir/tvhome/test/"*.class
cp "$B/base.apk" "$B/unsigned.apk"
(cd "$B/dex" && zip -q -u ../unsigned.apk classes.dex)
"$BT/zipalign" -f 4 "$B/unsigned.apk" "$B/aligned.apk"
"$BT/apksigner" sign --ks launcher/debug.keystore --ks-pass pass:android --out "$B/tests.apk" "$B/aligned.apk"
echo "$B/tests.apk"
