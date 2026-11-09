#!/usr/bin/env python3
"""Back up and install native Home on the specifically tested TCL API 22 firmware."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'com.mihir.tvhome'
PROPS = ['sys.currentlauncher', 'persist.tcl.debug.installapk', 'persist.tcl.installapk.enable']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--backup-dir', type=Path, required=True, help='A new private directory')
    parser.add_argument('--select', action='store_true', help='Select TV Home after installation')
    args = parser.parse_args()
    sdk = Path(os.environ.get('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk')))
    adb = [os.environ.get('ADB', str(sdk / 'platform-tools/adb')), '-s', args.serial]

    def run(*parts, timeout=120):
        p = subprocess.run(adb + list(parts), capture_output=True, text=True, timeout=timeout)
        output = (p.stdout + p.stderr).strip()
        if p.returncode or any(x in output for x in ('Permission Denial', 'SecurityException', 'Error:')):
            raise RuntimeError(output)
        return output

    def shell(*parts):
        return run('shell', shlex.join(parts))

    def setprop(key, value):
        shell('setprop', key, value)
        if shell('getprop', key) != value:
            raise RuntimeError('Property did not persist: ' + key)

    def install(apk):
        output = run('install', '-r', str(apk))
        print(output, flush=True)
        if 'Success' not in output.splitlines():
            raise RuntimeError('Device did not explicitly report installation Success')

    if shell('getprop', 'ro.software.version_id') != 'V8-A962T04-LF1V117' or shell('getprop', 'ro.build.version.sdk') != '22':
        raise RuntimeError('This installer is validated only on V8-A962T04-LF1V117 / API 22')
    build = ROOT / 'launcher/build'
    required = [build / 'tvhome.apk', build / 'tvhome-bootstrap.apk', build / 'legacy-home/tvhome-tools.jar']
    for item in required:
        if not item.is_file():
            raise RuntimeError('Build launcher and tools/legacy-home first: ' + str(item))
    args.backup_dir.mkdir(parents=True, exist_ok=False, mode=0o700)
    before = {key: shell('getprop', key) for key in PROPS}
    (args.backup_dir / 'properties.json').write_text(json.dumps(before, indent=2))
    (args.backup_dir / 'preferred-activities.xml').write_text(shell('dumpsys', 'package', 'preferred-xml'))
    previous = shell('pm', 'path', PACKAGE)
    for package in ['com.tcl.cyberui'] + ([PACKAGE] if previous.startswith('package:') else []):
        paths = shell('pm', 'path', package).splitlines()
        if len(paths) != 1 or not paths[0].startswith('package:'):
            raise RuntimeError('Expected one installed APK: ' + package)
        local = args.backup_dir / (package + '.apk')
        remote = paths[0][8:]
        print('Backing up ' + package + ' (may take several minutes over Wi-Fi)', flush=True)
        run('pull', remote, str(local), timeout=600)
        if hashlib.md5(local.read_bytes()).hexdigest() != shell('md5sum', remote).split()[0]:
            raise RuntimeError('Backup hash mismatch: ' + package)
    for f in args.backup_dir.iterdir():
        f.chmod(0o600)
    try:
        setprop(PROPS[1], '1')
        setprop(PROPS[2], '1')
        if not previous.startswith('package:'):
            install(build / 'tvhome-bootstrap.apk')
        # Match the native HOME update against our already-installed signing key.
        setprop(PROPS[0], PACKAGE)
        install(build / 'tvhome.apk')
    finally:
        failures = []
        for key, value in before.items():
            try:
                setprop(key, value)
            except Exception as exc:
                failures.append(str(exc))
        if failures:
            raise RuntimeError('Restore properties from properties.json: ' + '; '.join(failures))
    run('push', str(required[2]), '/data/local/tmp/tvhome-tools.jar')
    if args.select:
        output = shell('am', 'start', '-n', PACKAGE + '/.RestoreHomeActivity', '--ez', 'enable_home', 'true')
        print(output)
        # Wait for the protected activity to apply the component state; am start
        # returning is not evidence that onCreate has finished.
        import time
        for _ in range(20):
            status = run('shell', 'CLASSPATH=/data/local/tmp/tvhome-tools.jar app_process /system/bin LegacyHome status')
            if 'Candidate: com.mihir.tvhome/.HomeActivity' in status:
                break
            time.sleep(0.2)
        output = run('shell', 'CLASSPATH=/data/local/tmp/tvhome-tools.jar app_process /system/bin LegacyHome tvhome')
        print(output)
        if 'PASS: selected com.mihir.tvhome/.HomeActivity' not in output:
            raise RuntimeError('Native Home selection was not confirmed')
        shell('input', 'keyevent', '3')
    print('Installed. Temporary installation properties restored. Stock TCL Home retained.')


if __name__ == '__main__':
    main()
