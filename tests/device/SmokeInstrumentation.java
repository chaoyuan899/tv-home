package com.mihir.tvhome.test;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Runs against the actual APK on API 22. Does not change the default Home. */
public final class SmokeInstrumentation extends Instrumentation {
    private Activity activity;
    private int passed;
    private Object field(String name) throws Exception {
        Field f = activity.getClass().getDeclaredField(name);
        f.setAccessible(true);
        return f.get(activity);
    }
    private void call(String name) throws Exception {
        Method m = activity.getClass().getDeclaredMethod(name);
        m.setAccessible(true);
        m.invoke(activity);
    }
    private void progress(String message) {
        Bundle b = new Bundle(); b.putString("stream", message + "\n"); sendStatus(0, b);
    }
    private void check(boolean b, String message) {
        if (!b) throw new AssertionError(message);
    }
    private interface Step { void run() throws Exception; }
    private void onUi(Step step) throws Throwable {
        Bundle progress = new Bundle();
        progress.putString("stream", "Starting device check " + (passed + 1) + "\n");
        sendStatus(0, progress);
        final Throwable[] error = {null};
        runOnMainSync(() -> { try { step.run(); } catch (Throwable t) { error[0] = t; } });
        if (error[0] != null) throw error[0];
        passed++;
    }
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            Intent intent = new Intent().setClassName("com.mihir.tvhome", "com.mihir.tvhome.MainActivity")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity = startActivitySync(intent);
            waitForIdleSync();
            onUi(() -> {
                List<View> dock = (List<View>) field("dockCards");
                check(!dock.isEmpty(), "No reachable dock apps on this device");
                check(((TextView) field("clock")).getText().length() > 0, "Clock empty");
            });
            onUi(() -> {
                Set<String> names = new HashSet<>();
                for (String group : new String[]{"dockCards", "gridCards"}) {
                    for (View v : (List<View>) field(group)) {
                        Object app = v.getTag();
                        Field pkg = app.getClass().getDeclaredField("pkg"); pkg.setAccessible(true);
                        check(names.add((String) pkg.get(app)), "Duplicate app card");
                    }
                }
                check(names.contains("com.tcl.settings"), "Ordinary TCL Settings app missing");
            });
            onUi(() -> {
                List<View> dock = (List<View>) field("dockCards");
                View selected = dock.get(dock.size() - 1);
                selected.requestFocus();
                call("buildApps");
                check(activity.getCurrentFocus() == selected, "Unchanged app refresh lost focus");
                Object app = selected.getTag();
                Field pkg = app.getClass().getDeclaredField("pkg"); pkg.setAccessible(true);
                String before = (String) pkg.get(app);
                Field sig = activity.getClass().getDeclaredField("appSignature"); sig.setAccessible(true);
                sig.set(activity, null); call("buildApps");
                Object after = activity.getCurrentFocus().getTag();
                check(after != null && before.equals(pkg.get(after)), "Forced refresh lost app focus");
                selected = activity.getCurrentFocus();
                List<View> pills = (List<View>) field("pills");
                check(selected.focusSearch(View.FOCUS_UP) == pills.get(0), "Dock cannot reach controls");
            });
            onUi(() -> {
                // Empty configured dock must still show accessible application cards.
                Field dock = activity.getClass().getDeclaredField("dockApps"); dock.setAccessible(true);
                Object original = dock.get(activity);
                Field sig = activity.getClass().getDeclaredField("appSignature"); sig.setAccessible(true);
                progress("fallback: setting config");
                dock.set(activity, new String[]{"not.installed.example"}); sig.set(activity, null);
                progress("fallback: building");
                call("buildApps");
                progress("fallback: built");
                check(!((List<?>) field("dockCards")).isEmpty(), "Empty dock has no fallback");
                progress("fallback: restoring");
                dock.set(activity, original); sig.set(activity, null); call("buildApps");
                progress("fallback: restored");
            });
            onUi(() -> {
                List<View> pills = (List<View>) field("pills");
                Method m = activity.getClass().getDeclaredMethod("showInputs", View.class);
                m.setAccessible(true); m.invoke(activity, pills.get(0));
                check(field("inputsPopup") != null, "Input menu failed on API 22");
                ((android.widget.PopupWindow) field("inputsPopup")).dismiss();
            });
            result.putString("stream", "PASS: " + passed + " device checks (launch, discovery, focus, empty dock, input menu)\n");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable t) {
            result.putString("stream", "FAIL after " + passed + " checks: " + android.util.Log.getStackTraceString(t));
            finish(Activity.RESULT_CANCELED, result);
        }
    }
}
