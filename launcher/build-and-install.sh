#!/usr/bin/env bash
# Build the API 22+ launcher plus a same-key, ordinary-app bootstrap APK.
# Installation on the tested TCL firmware uses tools/install-tcl-home.py.
set -euo pipefail
cd "$(dirname "$0")"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export PATH="$JAVA_HOME/bin:$PATH"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BT="$SDK/build-tools/${BUILD_TOOLS_VERSION:-35.0.0}"
JAR="$SDK/platforms/android-34/android.jar"
B=build
[ "${1:---build}" = "--build" ] || { echo "Build only. Use tools/install-tcl-home.py for TCL installation." >&2; exit 2; }

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

# The TCL verifier compares HOME APK signatures to sys.currentlauncher. A first
# install therefore needs an ordinary app signed by the same key as the update.
python3 - <<'PY_MANIFEST'
import xml.etree.ElementTree as ET
ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
tree = ET.parse('AndroidManifest.xml')
app = tree.getroot().find('application')
for alias in app.findall('activity-alias'):
    app.remove(alias)
tree.write('build/bootstrap-manifest.xml', encoding='utf-8', xml_declaration=True)
PY_MANIFEST
"$BT/aapt2" link -o "$B/bootstrap-unsigned.apk" -I "$JAR" --manifest "$B/bootstrap-manifest.xml" \
  -A assets --min-sdk-version 22 --target-sdk-version 30 "$B/res.zip"
(cd "$B/dex" && zip -q -u ../bootstrap-unsigned.apk classes.dex)
"$BT/zipalign" -f 4 "$B/bootstrap-unsigned.apk" "$B/bootstrap-aligned.apk"
"$BT/apksigner" sign --ks debug.keystore --ks-pass pass:android --out "$B/tvhome-bootstrap.apk" "$B/bootstrap-aligned.apk"
echo "built $B/tvhome-bootstrap.apk (installation staging only)"
