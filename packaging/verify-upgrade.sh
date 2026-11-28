#!/usr/bin/env bash
set -euo pipefail
pkg=com.mytraining
adb install fixtures/originale.apk
adb shell run-as "$pkg" mkdir -p "'app_webview/Default/Local Storage/leveldb'"
adb shell "run-as $pkg sh -c \"echo training > 'app_webview/Default/Local Storage/leveldb/000003.log'\""
python3 packaging/dati-ruoss.py backup "$RUNNER_TEMP/ruoss.tar"
if adb install -r fixtures/aggiornamento.apk; then echo 'Unexpected signature match'; exit 1; fi
adb uninstall "$pkg"
adb install fixtures/predecessore.apk
python3 packaging/dati-ruoss.py ripristina "$RUNNER_TEMP/ruoss.tar"
adb install -r fixtures/aggiornamento.apk
adb shell dumpsys package "$pkg" | grep 'versionCode=9'
python3 packaging/dati-ruoss.py backup "$RUNNER_TEMP/check.tar"
python3 - "$RUNNER_TEMP" <<'PY'
import sys, tarfile, pathlib
p=pathlib.Path(sys.argv[1])
def record(name):
    with tarfile.open(p/name) as f:
        return f.extractfile('Local Storage/leveldb/000003.log').read()
assert record('ruoss.tar') == record('check.tar') == b'training\n'
PY
adb shell am start -W -n "$pkg/.MainActivity"
