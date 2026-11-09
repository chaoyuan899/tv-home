# TCL 55D6 validation — native Home follow-up

Device: TCL 55D6 / T962A3T04, firmware V8-A962T04-LF1V117; Android 5.1.1 / API 22 / armeabi-v7a.

## Native Home evidence

- Packaged HOME alias and TCL metadata installed successfully with the original TV Home signing key. Installation properties restored to their exact previous values.
- Shell helper enumerated both original TCL Home and TV Home, set native default, then verified `com.mihir.tvhome/.HomeActivity`.
- Pressing Home resumed the new native Home activity. The accessibility service and boot receiver have been removed from the APK; only the obsolete TV Home entry was removed from secure accessibility settings.
- Actual reboot retained native default and resumed HomeActivity; activity history contained no stock Home activity. ADB connected only late in startup, so those captures do not prove all earlier frames.
- Recovery disabled our HOME alias while leaving the ordinary app and original TCL package available. Reenabling from the TV Home UI returned to the new desktop.
- Advertising package hide/unhide was tested. It is now hidden for user 0; APK/ODEX are retained, no system app was uninstalled. Cached boot-ad files were backed up and device/local hashes matched. After reboot the cache directory was absent and the ad package still hidden.
- No root, system partition modification, factory reset, firmware flash, unrelated debloating, or access to paid content.

## Final acceptance

- Final APK: all 5 physical-device instrumentation checks passed (launch/clock, discovery, unchanged and forced refresh focus, empty Dock fallback, input menu). Prior ADB taps left global touch mode enabled, causing the focus test to fail before focus could be requested. Diagnostics confirmed `touchMode=true`; the test now explicitly enters remote-control mode before checking focus.
- Final installer: backup with matching device/local APK MD5, signed upgrade, temporary property restoration and native Home selection all completed successfully. The 47 MiB original Home backup required more than 120 seconds over Wi-Fi; the pull timeout is now 600 seconds. The timed-out attempt stopped before any installation/property mutation.
- Final recovery script: original TCL Home was verified as the selected native Home and the TV Home alias was absent from candidates. TV Home was then reenabled and selected again. Both launchers remain installed and original TCL Home remains enabled.
- Temporary instrumentation package removed after tests.
- Final visible reboot acceptance: the owner watched the entire final reboot and confirmed **TCL logo → TV Home directly**, with no intervening ad, red TCL loading screen or stock Home. The necessary firmware logo and Android initialization remain. No numeric startup-speed improvement is claimed because the final run was not timed with an external camera.

First-install bootstrap is packaged but the deployed TV already had the same-key first version; a clean first install is not yet validated on a separate television. Long-term reliability, firmware updates, power-loss cold start and all input/application combinations remain untested.

## Retained compatibility evidence

The earlier device test passed launch/clock, app discovery without duplicates, unchanged/forced refresh focus, empty Dock fallback, and input menu (5 checks). TCL settings and signal-source overlays opened. API 22's broken text-shadow path was removed after a reproducible vendor RenderThread crash; hardware acceleration remains enabled. TvInputManager's null vendor backing service is caught and handled by the explicit source picker fallback.

Backups are application/settings recovery data, not full firmware or private-app/DRM backups. The computer's backup is authoritative; do not rely on the TV's boot-video cache directory surviving a reboot. TV logcat is empty on this firmware; diagnostics use explicit state assertions and device instrumentation.

For the superseded accessibility implementation and its original validation, see commit `d90c14e` on branch `compat/tcl-55d6-android5`. Its 3–5 second Home redirection no longer describes this branch.
