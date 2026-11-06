#!/usr/bin/env python3
"""Ejecuta las pruebas GDScript del núcleo con Godot 3 en modo headless.

Crea un proyecto temporal con el mod y las pruebas, y lanza:
    godot --no-window --path <proyecto> -s res://tests/gdscript/test_core.gd

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
TEST_SCRIPTS = ["res://tests/gdscript/test_core.gd"]
PROJECT_FILE = """config_version=4

[application]

config/name="Caritatos Legends tests"
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", required=True, help="ejecutable de Godot 3 (headless)")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="clc-tests-") as tmp:
        project = Path(tmp)
        (project / "project.godot").write_text(PROJECT_FILE, encoding="utf-8")
        shutil.copytree(ROOT / "mods-unpacked", project / "mods-unpacked")
        shutil.copytree(ROOT / "tests" / "gdscript", project / "tests" / "gdscript")

        failed = False
        for script in TEST_SCRIPTS:
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
