package com.mihir.tvhome;

/** Only the stock launcher's main window is redirected; settings and video stay untouched. */
final class HomePolicy {
    static boolean shouldRedirect(boolean enabled, String pkg, String activity) {
        return enabled && "com.tcl.cyberui".equals(pkg)
                && "com.tcl.cyberui.MainActivity".equals(activity);
    }
}
