package com.mihir.tvhome;

import android.accessibilityservice.AccessibilityService;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.view.accessibility.AccessibilityEvent;

/** Opt-in Home compatibility for TCL firmware which rejects category.HOME APKs. */
public final class HomeRedirectService extends AccessibilityService {
    private String lastPackage, lastWindow;
    private int events, redirects;
    @Override protected void dump(java.io.FileDescriptor fd, java.io.PrintWriter out, String[] args) {
        out.println("enabled=" + enabled(this) + " authorized=" + authorized(this));
        out.println("events=" + events + " redirects=" + redirects);
        out.println("lastWindow=" + lastPackage + "/" + lastWindow);
    }
    static boolean enabled(Context c) {
        return c.getSharedPreferences("home_mode", MODE_PRIVATE).getBoolean("enabled", false);
    }
    static boolean authorized(Context c) {
        if (Settings.Secure.getInt(c.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, 0) != 1) return false;
        String services = Settings.Secure.getString(c.getContentResolver(), "enabled_accessibility_services");
        if (services == null) return false;
        for (String service : services.split(":")) {
            android.content.ComponentName component = android.content.ComponentName.unflattenFromString(service);
            if (component != null && component.getPackageName().equals(c.getPackageName())
                    && component.getClassName().equals(HomeRedirectService.class.getName())) return true;
        }
        return false;
    }
    static void openHome(Context c) {
        Intent intent = new Intent(c, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        // API 22 defers a service's direct startActivity for several seconds after Home.
        // Use an explicit PendingIntent to our own activity; never expose it to other apps.
        int flags = android.app.PendingIntent.FLAG_UPDATE_CURRENT;
        if (android.os.Build.VERSION.SDK_INT >= 23) flags |= android.app.PendingIntent.FLAG_IMMUTABLE;
        try {
            android.app.PendingIntent.getActivity(c, 0, intent, flags).send();
        } catch (android.app.PendingIntent.CanceledException e) {
            c.startActivity(intent);
        }
    }
    @Override public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        events++;
        lastPackage = event.getPackageName() == null ? null : event.getPackageName().toString();
        lastWindow = event.getClassName() == null ? null : event.getClassName().toString();
        if (HomePolicy.shouldRedirect(enabled(this), lastPackage, lastWindow)) {
            redirects++;
            openHome(this);
        }
    }
    @Override public void onInterrupt() { }
}
