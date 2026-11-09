package com.mihir.tvhome;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;

/** ADB recovery entry. DUMP permission restricts external callers to system/shell. */
public final class RestoreHomeActivity extends Activity {
    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        // An app may change its own HOME alias; TCL denies this operation to adb shell.
        boolean enable = getIntent().getBooleanExtra("enable_home", false);
        try {
            getPackageManager().setComponentEnabledSetting(
                new ComponentName(this, "com.mihir.tvhome.HomeActivity"),
                enable ? android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                        : android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                android.content.pm.PackageManager.DONT_KILL_APP);
        } catch (IllegalArgumentException stagingInstall) {
            // The ordinary bootstrap APK deliberately has no HOME alias. It can
            // still return to stock, but cannot enable native Home before upgrade.
            android.util.Log.w("TVHome", "Native Home entry is not installed", stagingInstall);
        }
        if (!enable) startActivity(new Intent().setComponent(new ComponentName("com.tcl.cyberui",
                "com.tcl.cyberui.MainActivity")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        finish();
    }
}
