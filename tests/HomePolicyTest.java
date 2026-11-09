package com.mihir.tvhome;
public class HomePolicyTest {
    public static void main(String[] args) {
        if (!HomePolicy.shouldRedirect(true, "com.tcl.cyberui", "com.tcl.cyberui.MainActivity")) throw new AssertionError("Home not redirected");
        if (HomePolicy.shouldRedirect(false, "com.tcl.cyberui", "com.tcl.cyberui.MainActivity")) throw new AssertionError("Disabled mode redirects");
        if (HomePolicy.shouldRedirect(true, "com.tcl.settings", "com.tcl.settings.MainActivity")) throw new AssertionError("Settings intercepted");
        if (HomePolicy.shouldRedirect(true, "com.tcl.cyberui", "com.tcl.cyberui.OtherActivity")) throw new AssertionError("Non-Home screen intercepted");
        if (HomePolicy.shouldRedirect(true, null, null)) throw new AssertionError("Null window intercepted");
        System.out.println("PASS: narrow Home redirect policy (5 checks)");
    }
}
