"""Trasferisce lo storico e le schede locali delle build APK di test RUOSS."""
import argparse
import io
from pathlib import Path
import subprocess
import tarfile

APP = "com.mytraining"
BASE = "app_webview/Default"
STORE = "Local Storage"


def adb(*args, data=None):
    result = subprocess.run(["adb", *args], input=data, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.decode(errors="replace") or result.stdout.decode(errors="replace"))
    return result.stdout


def validate(data):
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:") as archive:
        files = {}
        for entry in archive:
            name = entry.name.rstrip("/")
            if (name != STORE and not name.startswith(STORE + "/")) or ".." in name.split("/") or not (entry.isdir() or entry.isfile()):
                raise ValueError("Archivio non valido.")
            if entry.isfile():
                files[name] = archive.extractfile(entry).read()
    if not any(name.endswith((".ldb", ".log", ".sst")) and value for name,value in files.items()):
        raise ValueError("Archivio privo di dati locali. Conserva la vecchia installazione.")
    return files


def read_device():
    return adb("shell", "-T", f"run-as {APP} tar -C {BASE} -cf - '{STORE}'")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("azione", choices=("backup", "ripristina"))
    parser.add_argument("archivio", type=Path)
    args = parser.parse_args()
    adb("get-state")
    adb("shell", "run-as", APP, "id")
    adb("shell", "am", "force-stop", APP)
    if args.azione == "backup":
        data = read_device()
        validate(data)
        with args.archivio.open("xb") as out:
            out.write(data)
        validate(args.archivio.read_bytes())
        print("Backup verificato:", args.archivio)
        return
    data = args.archivio.read_bytes()
    expected = validate(data)
    adb("shell", "-T", f"run-as {APP} mkdir -p '{BASE}/{STORE}'")
    existing = adb("shell", "-T", f"run-as {APP} ls -A '{BASE}/{STORE}'")
    if existing.strip():
        raise ValueError("Il dispositivo contiene già dati. Ripristina su una nuova installazione prima del primo avvio.")
    adb("shell", "-T", f"run-as {APP} tar -C {BASE} -xf -", data=data)
    if validate(read_device()) != expected:
        raise ValueError("Verifica del ripristino fallita. Conserva il backup.")
    print("Ripristino verificato. Puoi aprire RUOSS.")


if __name__ == "__main__":
    main()
