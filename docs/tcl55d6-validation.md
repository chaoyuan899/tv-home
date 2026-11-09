# TCL 55D6 validation — 2026-11-09

Device: TCL 55D6, chassis T962A3T04, firmware V8-A962T04-LF1V117; Android 5.1.1 / API 22 / armeabi-v7a. Read-only system properties confirmed the platform; the launcher uses no native libraries.

## Passed on the physical television

- Backed up original TCL Home, settings and source-picker APKs before installing the new application. Checked ZIP CRCs, compared device/local MD5, and verified the complete backup with SHA-256. Device-specific files remain private.
- APK minimum SDK 22, ordinary app preview entry, no HOME category. Both v1-compatible signing and real installation work; APK size about 4.5 MiB.
- Pure-Java Home redirect policy: 5 positive/negative cases including disabled preference, unrelated package, unrelated window and null inputs.
- Device instrumentation: launch and clock; ordinary/TV app discovery without duplicates; focus preserved after unchanged and forced refresh; missing configured Dock apps filled; input menu opens. All 5 checks passed on the final APK.
- Repeated rebuild initially crashed the vendor RenderThread in libRScpp. Removing text blur on API 22 resolved it; raised card/popup shadows are also omitted on this version. Hardware acceleration remains enabled.
- TCL's TvInputManager exists but its backing service is null: the original call threw NullPointerException. Guarded enumeration now reaches the vendor fallback.
- Using actual UI buttons opened the TCL settings overlay and source-picker overlay. The source manager's MAIN activity did not open its menu; its exported `com.tcl.insrc.SHOW_WINDOW` service did.
- Launched the TCL app store from the launcher and used Home to return. The exact `com.tcl.cyberui.MainActivity` accessibility event was observed. Transition briefly shows stock Home; ADB-triggered returns took roughly 3–5 seconds, not an instant native default-home replacement.
- UI opt-in persisted, service bound with capabilities=0 (no screen-content retrieval). No key filtering or network permission was added.
- Recovery command invoked DUMP-protected RestoreHomeActivity, returned to the exact stock Home component, and service diagnostics confirmed `enabled=false`. Original Home remained enabled throughout. The new app was then re-enabled through its own Home mode preference.
- Removed only our temporary instrumentation package. Restored both TCL install properties to their original empty values and verified them.

## Reboot

Passed a real `adb reboot`. After startup, `sys.boot_completed=1`, TV Home was the resumed activity, and the accessibility service was bound with `enabled=true authorized=true`. Both temporary install properties remained empty. The disabled-package list exactly matched the pre-install backup. The installed APK MD5 matched the final build delivered to the user.

## Platform restrictions and limits

- Firmware rejects third-party HOME declarations with `INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES`, including a disabled HOME alias. Same signing key and no HOME category installs successfully.
- Firmware rejects shell `pm enable` / `pm disable-user`, including for the new user app. Recovery uses the app's own preference, not package disabling. Shell command exit code 0 alone is not proof of success.
- No system apps removed/disabled; no root, firmware flash, factory reset or bulk settings restore.
- Backup is not a complete firmware image and excludes private app data / DRM.
- Test scope does not include long-term soak, every app, every HDMI input or other TCL models. No claim of removing firmware boot ads or bypassing paid content.
- TV logcat returned no entries; native-crash investigation used read-only kernel logs and explicit instrumentation/service diagnostics.

## Reproduce

```bash
bash launcher/build-and-install.sh --build
bash tests/run.sh
# After backing up and installing the preview on a test TV:
ADB_SERIAL=TV_IP:5555 bash tests/run.sh --device
```

Instrumentation stops the app process and may leave the accessibility service unbound on this firmware. Re-enable only TV Home's accessibility service after testing (preserve other service settings), or reboot. For ordinary use, install only the launcher APK.
