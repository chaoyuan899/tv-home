#!/usr/bin/env bash
# Build the API 22+ launcher; installation is an explicit preview-only option.
#   launcher/build-and-install.sh --install  build + install as an ordinary app
#   launcher/build-and-install.sh --build    build only
set -euo pipefail
cd "$(dirname "$0")"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export PATH="$JAVA_HOME/bin:$PATH"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BT="$SDK/build-tools/${BUILD_TOOLS_VERSION:-35.0.0}"
JAR="$SDK/platforms/android-34/android.jar"
B=build

rm -rf "$B" && mkdir -p "$B/gen" "$B/classes" "$B/dex"
"$BT/aapt2" compile --dir res -o "$B/res.zip"
"$BT/aapt2" link -o "$B/base.apk" -I "$JAR" --manifest AndroidManifest.xml --java "$B/gen" \
  -A assets --min-sdk-version 22 --target-sdk-version 30 "$B/res.zip"
javac -nowarn -Xlint:-options --release 11 -classpath "$JAR" -d "$B/classes" \
  $(find src "$B/gen" -name '*.java')
"$BT/d8" --min-api 22 --lib "$JAR" --output "$B/dex" $(find "$B/classes" -name '*.class')
cp "$B/base.apk" "$B/unsigned.apk"
(cd "$B/dex" && zip -q -u ../unsigned.apk classes.dex)
"$BT/zipalign" -f 4 "$B/unsigned.apk" "$B/aligned.apk"
[ -f debug.keystore ] || keytool -genkeypair -keystore debug.keystore -storepass android -keypass android \
  -alias tvhome -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=tvhome" >/dev/null 2>&1
"$BT/apksigner" sign --ks debug.keystore --ks-pass pass:android --out "$B/tvhome.apk" "$B/aligned.apk"
echo "built $B/tvhome.apk ($(wc -c < "$B/tvhome.apk") bytes)"
[ "${1:---build}" = "--build" ] && exit 0

# Preview only: setting the default Home is a separate, device-specific operation.
[ "${1:-}" = "--install" ] || { echo "Usage: $0 [--build|--install]" >&2; exit 2; }
: "${ADB_SERIAL:?Set ADB_SERIAL to the TV address or serial}"
ADB="${ADB:-$SDK/platform-tools/adb}"
RESULT=$("$ADB" -s "$ADB_SERIAL" install -r "$B/tvhome.apk" 2>&1)
printf '%s\n' "$RESULT"
printf '%s\n' "$RESULT" | tr -d '\r' | grep -qx Success || { echo "Install was rejected; Home unchanged." >&2; exit 1; }
"$ADB" -s "$ADB_SERIAL" shell am start -n com.mihir.tvhome/.MainActivity
echo "Preview installed. The stock Home is unchanged."
