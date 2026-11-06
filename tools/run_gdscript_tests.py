#!/usr/bin/env python3
"""Ejecuta las pruebas GDScript del núcleo con Godot 3 en modo headless.

Crea un proyecto temporal con el mod y las pruebas, y lanza cada
tests/gdscript/test_*.gd con:
    godot --no-window --path <proyecto> -s res://tests/gdscript/<prueba>.gd

Uso: python tools/run_gdscript_tests.py --godot RUTA_A_GODOT3
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Sustitutos de clases de ModLoader y del juego (tests/gdscript/stubs) que se
# registran como clases globales, igual que lo haría el editor de Godot.
STUB_CLASSES = [
    ("ModLoaderLog", "Object", "mod_loader_log.gd"),
    ("ModLoaderMod", "Object", "mod_loader_mod.gd"),
    ("WeaponData", "Resource", "weapon_data.gd"),
]


def project_file() -> str:
    classes = ", ".join(
        "{\n\"base\": \"%s\",\n\"class\": \"%s\",\n\"language\": \"GDScript\",\n"
        "\"path\": \"res://tests/gdscript/stubs/%s\"\n}" % (base, name, file)
        for name, base, file in STUB_CLASSES
    )
    icons = ",\n".join('"%s": ""' % name for name, _, _ in STUB_CLASSES)
    return (
        "config_version=4\n\n"
        f"_global_script_classes=[ {classes} ]\n"
        f"_global_script_class_icons={{\n{icons}\n}}\n\n"
        "[application]\n\n"
        'config/name="Caritatos Legends tests"\n'
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", required=True, help="ejecutable de Godot 3 (headless)")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="clc-tests-") as tmp:
        project = Path(tmp)
        (project / "project.godot").write_text(project_file(), encoding="utf-8")
        shutil.copytree(ROOT / "mods-unpacked", project / "mods-unpacked")
        shutil.copytree(ROOT / "tests" / "gdscript", project / "tests" / "gdscript")

        scripts = sorted(f"res://tests/gdscript/{p.name}" for p in (ROOT / "tests" / "gdscript").glob("test_*.gd"))
        if not scripts:
            print("No hay pruebas GDScript.")
            return 1

        failed = False
        for script in scripts:
            print(f"== {script}")
            result = subprocess.run(
                [args.godot, "--no-window", "--path", str(project), "-s", script],
                capture_output=True,
                text=True,
                timeout=300,
            )
            output = result.stdout + result.stderr
            print(output)
            if result.returncode != 0 or "RESULTADO:" not in output or "SCRIPT ERROR" in output:
                failed = True

    if failed:
        print("Las pruebas GDScript han fallado.")
        return 1
    print("Pruebas GDScript correctas.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
