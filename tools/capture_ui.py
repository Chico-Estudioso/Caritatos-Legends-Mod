#!/usr/bin/env python3
"""Saca capturas de las ventanas del mod con Godot 3 (sin Brotato).

Crea un proyecto temporal con el mod, los sustitutos de ModLoader y un tema
con la fuente indicada (para imitar la de Brotato, Anybody), y ejecuta
tests/ui/capture.gd. Necesita una pantalla: en la CI se lanza con xvfb-run.

Uso:
    python tools/capture_ui.py --godot RUTA_A_GODOT3 --out CARPETA [--font fuente.ttf]
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_gdscript_tests import ROOT, project_file  # noqa: E402

THEME_WITH_FONT = """[gd_resource type="Theme" load_steps=3 format=2]

[ext_resource path="res://capture/font.ttf" type="DynamicFontData" id=1]

[sub_resource type="DynamicFont" id=1]
size = 40
extra_spacing_top = 3
font_data = ExtResource( 1 )

[resource]
default_font = SubResource( 1 )
"""

DISPLAY_SETTINGS = """
[display]

window/size/width=1920
window/size/height=1080
window/stretch/mode="2d"
window/stretch/aspect="keep"

[rendering]

quality/driver/driver_name="GLES2"
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--godot", required=True, help="ejecutable de Godot 3 con gráficos (no headless)")
    parser.add_argument("--out", required=True, help="carpeta donde guardar las capturas")
    parser.add_argument("--font", help="fuente .ttf para el tema (opcional)")
    args = parser.parse_args()

    out_dir = Path(args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="clc-capturas-") as tmp:
        project = Path(tmp)
        (project / "project.godot").write_text(project_file() + DISPLAY_SETTINGS, encoding="utf-8")
        shutil.copytree(ROOT / "mods-unpacked", project / "mods-unpacked")
        shutil.copytree(ROOT / "tests" / "gdscript" / "stubs", project / "tests" / "gdscript" / "stubs")
        shutil.copytree(ROOT / "tests" / "ui", project / "tests" / "ui")
        if args.font and Path(args.font).is_file():
            (project / "capture").mkdir()
            shutil.copy(args.font, project / "capture" / "font.ttf")
            theme_dir = project / "resources" / "themes"
            theme_dir.mkdir(parents=True)
            (theme_dir / "base_theme.tres").write_text(THEME_WITH_FONT, encoding="utf-8")
        else:
            print("Sin fuente: se usa la de Godot por defecto.")

        env = dict(os.environ, CLC_CAPTURE_DIR=str(out_dir))
        result = subprocess.run(
            [args.godot, "--path", str(project), "--resolution", "1920x1080", "-s", "res://tests/ui/capture.gd"],
            capture_output=True,
            text=True,
            timeout=300,
            env=env,
        )
        output = result.stdout + result.stderr
        print(output)

    images = sorted(out_dir.glob("*.png"))
    if result.returncode != 0 or not images or "SCRIPT ERROR" in output:
        print("No se pudieron sacar las capturas.")
        return 1
    print(f"{len(images)} capturas en {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
