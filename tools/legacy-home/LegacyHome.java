import android.content.ComponentName;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ResolveInfo;
import java.util.ArrayList;
import java.util.List;

/** ADB-shell utility for API 22, where cmd package set-home-activity is absent. */
public final class LegacyHome {
    public static void main(String[] args) throws Exception {
        String action = args.length == 0 ? "status" : args[0];
        if (!action.equals("status") && !action.equals("tvhome") && !action.equals("stock"))
            throw new IllegalArgumentException("Only status, tvhome, stock are supported");
        Class<?> pmType = Class.forName("android.content.pm.IPackageManager");
        Object pm = Class.forName("android.app.ActivityThread").getMethod("getPackageManager").invoke(null);
        List<ResolveInfo> homes = new ArrayList<>();
        ComponentName current = (ComponentName) pmType.getMethod("getHomeActivities", List.class).invoke(pm, homes);
        System.out.println("Default Home: " + current);
        List<ComponentName> components = new ArrayList<>();
        int match = 0;
        for (ResolveInfo home : homes) {
            ComponentName c = new ComponentName(home.activityInfo.packageName, home.activityInfo.name);
            components.add(c);
            match = Math.max(match, home.match);
            System.out.println("Candidate: " + c.flattenToShortString() + " priority=" + home.priority + " match=" + home.match);
        }
        if (action.equals("status")) return;
        ComponentName selected = action.equals("tvhome")
                ? new ComponentName("com.mihir.tvhome", "com.mihir.tvhome.HomeActivity")
                : new ComponentName("com.tcl.cyberui", "com.tcl.cyberui.MainActivity");
        if (!components.contains(selected)) throw new IllegalStateException("Selected Home is not enabled/installed: " + selected);
        IntentFilter filter = new IntentFilter(Intent.ACTION_MAIN);
        filter.addCategory(Intent.CATEGORY_HOME);
        filter.addCategory(Intent.CATEGORY_DEFAULT);
        pmType.getMethod("replacePreferredActivity", IntentFilter.class, int.class, ComponentName[].class,
                ComponentName.class, int.class).invoke(pm, filter, match,
                components.toArray(new ComponentName[0]), selected, 0);
        homes.clear();
        current = (ComponentName) pmType.getMethod("getHomeActivities", List.class).invoke(pm, homes);
        if (!selected.equals(current)) throw new IllegalStateException("Home not selected: " + current);
        System.out.println("PASS: selected " + selected.flattenToShortString());
    }
}
