#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}
export PATH="$JAVA_HOME/bin:$PATH"
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
BT=$SDK/build-tools/${BUILD_TOOLS_VERSION:-35.0.0}
JAR=$SDK/platforms/android-34/android.jar
B=launcher/build/legacy-home
mkdir -p "$B/classes" "$B/dex"
javac --release 8 -cp "$JAR" -d "$B/classes" tools/legacy-home/LegacyHome.java
"$BT/d8" --min-api 22 --lib "$JAR" --output "$B/dex" "$B/classes/LegacyHome.class"
(cd "$B/dex" && zip -q ../tvhome-tools.jar classes.dex)
echo "$B/tvhome-tools.jar"
