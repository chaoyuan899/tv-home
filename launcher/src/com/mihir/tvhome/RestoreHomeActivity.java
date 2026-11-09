package com.mihir.tvhome;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;

/** ADB recovery entry. DUMP permission restricts external callers to system/shell. */
public final class RestoreHomeActivity extends Activity {
    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        // Persist before launching stock Home so its window event cannot redirect back.
        getSharedPreferences("home_mode", MODE_PRIVATE).edit().putBoolean("enabled", false).commit();
        startActivity(new Intent().setComponent(new ComponentName("com.tcl.cyberui",
                "com.tcl.cyberui.MainActivity")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        finish();
    }
}
