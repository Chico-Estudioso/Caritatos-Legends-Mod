#!/usr/bin/env python3
"""Empaqueta Caritatos Legends en el formato que carga ModLoader.

Genera dist/Caritato-LegendsCollection.zip con esta estructura:

    mods-unpacked/
      Caritato-LegendsCollection/
        manifest.json
        mod_main.gd
        ...

El ZIP es reproducible: orden fijo de archivos y fecha fija, de modo que el
mismo código produce exactamente el mismo paquete. Para Steam Workshop y para
la carpeta mods/ de Brotato se usa este mismo ZIP.

Uso: python tools/build.py [--output RUTA]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOD_ID = "Caritato-LegendsCollection"
MOD_DIR = ROOT / "mods-unpacked" / MOD_ID
DEFAULT_OUTPUT = ROOT / "dist" / f"{MOD_ID}.zip"
FIXED_DATE = (2024, 1, 1, 0, 0, 0)
EXCLUDED_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini"}
EXCLUDED_SUFFIXES = {".tmp", ".bak", ".orig"}


def collect_files() -> list[Path]:
    files = []
    for path in MOD_DIR.rglob("*"):
        if not path.is_file():
            continue
        if path.name in EXCLUDED_NAMES or path.suffix in EXCLUDED_SUFFIXES:
            continue
        if any(part.startswith(".") for part in path.relative_to(MOD_DIR).parts):
            continue
        files.append(path)
    return sorted(files, key=lambda p: p.relative_to(MOD_DIR).as_posix())


def build(output: Path) -> Path:
    manifest = json.loads((MOD_DIR / "manifest.json").read_text(encoding="utf-8"))
    output.parent.mkdir(parents=True, exist_ok=True)
    files = collect_files()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            arcname = f"mods-unpacked/{MOD_ID}/{path.relative_to(MOD_DIR).as_posix()}"
            info = zipfile.ZipInfo(arcname, date_time=FIXED_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, path.read_bytes())
    verify(output)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"Paquete: {output.relative_to(ROOT) if output.is_relative_to(ROOT) else output}")
    print(f"Versión: {manifest['version_number']} · archivos: {len(files)} · sha256: {digest}")
    return output


def verify(output: Path) -> None:
    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        prefix = f"mods-unpacked/{MOD_ID}/"
        bad = [name for name in names if not name.startswith(prefix)]
        if bad:
            raise SystemExit(f"ERROR: entradas fuera de {prefix}: {bad[:5]}")
        for required in ("manifest.json", "mod_main.gd"):
            if prefix + required not in names:
                raise SystemExit(f"ERROR: falta {required} en el paquete")
        if archive.testzip() is not None:
            raise SystemExit("ERROR: el ZIP está dañado")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="ruta del ZIP a generar")
    args = parser.parse_args()
    build(args.output.resolve())
    return 0


if __name__ == "__main__":
    sys.exit(main())
