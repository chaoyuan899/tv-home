# TCL 55D6 native Home follow-up

This replaces the first-version accessibility workaround. Tested hardware: 55D6 / T962A3T04, firmware V8-A962T04-LF1V117, Android 5.1.1/API 22. Other models/firmware are not validated.

## Why the previous install failed

Read-only inspection of this device's PackageManagerService showed its HOME verifier uses the installed package named in `sys.currentlauncher` as the signing reference, and requires application metadata `com.tcl.app.type=com.tcl.ui`. Merely declaring HOME fails the vendor signature check. The new installer first establishes our ordinary same-key app if absent, temporarily names it as the reference, and installs the native HOME update. It restores the original property values in `finally`. It does not modify system code, replace TCL signatures, or obtain root.

`LegacyHome` runs as the already-authorized ADB shell. Shell has `SET_PREFERRED_APPLICATIONS` on this firmware, so the helper can call the device's `IPackageManager.replacePreferredActivity` and verify `getHomeActivities`. It is restricted to status/TV Home/original TCL Home. Android 5 lacks the later `cmd package set-home-activity` command.

The application now has a native HOME alias and no accessibility service or boot receiver. The system chooses it when starting Home. The original TCL package remains installed and enabled. The protected recovery activity can disable only our own alias; the shell cannot directly change component enablement on this firmware. The ordinary application entry remains available for reenabling it.

## Boot advertising

The separate `com.tcl.bootadservice` system package has been hidden for user 0 with `pm hide --user 0`, after verifying `pm unhide` works. This prevents the package from running for that user; no APK is uninstalled. The three files in `/data/local/bootvideo` were copied to the computer and device/local MD5 matched before moving them out of the player's expected paths. After reboot, the directory was removed by the firmware and not downloaded again. **The computer backup is authoritative; do not rely on a backup inside this cache directory surviving boot.**

To restore the service, run `adb -s TV_IP:5555 shell pm unhide --user 0 com.tcl.bootadservice`. Retain the saved APK/ODEX and cache files privately. This setting is separate from the default-home selection; returning to TCL Home does not automatically reenable advertisements.

## Scope of verification

A real reboot retained `com.mihir.tvhome/.HomeActivity` as native default. The activity history showed TV Home and no TCL stock Home activity. The advertising service retained `hidden=true`; no boot video was redownloaded. Both install properties remained at their original values. Home alias disable/reenable was exercised on the TV.

The first reboot was captured after ADB became reachable. ADB alone cannot prove what was displayed before it connected. Final visual boot acceptance and regression results are recorded in `tcl55d6-validation.md`; do not interpret final foreground alone as proof of an entirely clean startup. Firmware logo and necessary Android initialization remain outside the launcher.
