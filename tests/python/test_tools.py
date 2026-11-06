"""Pruebas de las herramientas de validación y empaquetado.

Ejecutar desde la raíz del repositorio:
    python -m unittest discover -s tests/python -v
"""

from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import shutil
import sys
import tempfile
import unittest
import zipfile
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_tool(name: str):
    spec = importlib.util.spec_from_file_location(f"clc_{name}", ROOT / "tools" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


validate = load_tool("validate")
build = load_tool("build")


def run_validate(mod_dir: Path | None = None) -> tuple[int, str]:
    original = validate.MOD_DIR
    if mod_dir is not None:
        validate.MOD_DIR = mod_dir
    buffer = io.StringIO()
    old_argv = sys.argv
    sys.argv = ["validate.py"]
    try:
        with redirect_stdout(buffer):
            code = validate.main()
    finally:
        sys.argv = old_argv
        validate.MOD_DIR = original
    return code, buffer.getvalue()


class ValidateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.mod_dir = Path(self.tmp.name) / build.MOD_ID
        shutil.copytree(build.MOD_DIR, self.mod_dir)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_module(self, module_id: str, definition: dict) -> None:
        module_dir = self.mod_dir / "modules" / module_id
        module_dir.mkdir(parents=True, exist_ok=True)
        (module_dir / "module.json").write_text(json.dumps(definition), encoding="utf-8")
        index_path = self.mod_dir / "modules" / "modules.json"
        index = json.loads(index_path.read_text(encoding="utf-8"))
        if module_id not in index["modules"]:
            index["modules"].append(module_id)
        index_path.write_text(json.dumps(index), encoding="utf-8")

    def test_repository_is_valid(self) -> None:
        code, output = run_validate()
        self.assertEqual(code, 0, output)

    def test_invalid_manifest_is_rejected(self) -> None:
        manifest_path = self.mod_dir / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["version_number"] = "1.0"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        code, output = run_validate(self.mod_dir)
        self.assertEqual(code, 1)
        self.assertIn("version_number", output)

    def test_bad_module_is_rejected(self) -> None:
        self.write_module("broken_legend", {
            "id": "broken_legend",
            "version": "1.0.0",
            "category": "nope",
            "name_key": "CLC_MISSING_NAME",
            "description_key": "CLC_MISSING_DESC",
            "dependencies": ["ghost_legend"],
            "extensions": ["extensions/missing.gd"],
            "settings": [{"key": "x", "type": "int", "default": 99, "min": 0, "max": 10, "label_key": "CLC_MISSING"}],
        })
        code, output = run_validate(self.mod_dir)
        self.assertEqual(code, 1)
        for expected in ("categoría desconocida", "dependencia inexistente", "falta la extensión",
                         "default fuera de rango", "origin.type", "CLC_MISSING_NAME"):
            self.assertIn(expected, output)

    def test_extension_members_need_prefix(self) -> None:
        module_dir = self.mod_dir / "modules" / "prefix_legend"
        (module_dir / "extensions").mkdir(parents=True)
        (module_dir / "extensions" / "main.gd").write_text(
            'extends "res://main.gd"\n\nconst LegendsAPI = null\nvar _clc_prefix_ok := 1\n', encoding="utf-8"
        )
        self.write_module("prefix_legend", {
            "id": "prefix_legend", "version": "1.0.0", "category": "mechanics",
            "name_key": "CLC_MOD_HOOK_LEGEND_NAME", "description_key": "CLC_MOD_HOOK_LEGEND_DESC",
            "origin": {"type": "original"}, "extensions": ["extensions/main.gd"],
        })
        code, output = run_validate(self.mod_dir)
        self.assertEqual(code, 1)
        self.assertIn("'LegendsAPI' debe empezar por _clc_", output)
        self.assertNotIn("'_clc_prefix_ok'", output)

    def test_unlisted_module_folder_is_rejected(self) -> None:
        (self.mod_dir / "modules" / "stray_legend").mkdir()
        code, output = run_validate(self.mod_dir)
        self.assertEqual(code, 1)
        self.assertIn("no listada", output)


class BuildTests(unittest.TestCase):
    def test_zip_structure_and_reproducibility(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            first = Path(tmp) / "a.zip"
            second = Path(tmp) / "b.zip"
            with redirect_stdout(io.StringIO()):
                build.build(first)
                build.build(second)
            self.assertEqual(
                hashlib.sha256(first.read_bytes()).hexdigest(),
                hashlib.sha256(second.read_bytes()).hexdigest(),
                "el ZIP debería ser reproducible",
            )
            with zipfile.ZipFile(first) as archive:
                names = archive.namelist()
            prefix = f"mods-unpacked/{build.MOD_ID}/"
            self.assertIn(prefix + "manifest.json", names)
            self.assertIn(prefix + "mod_main.gd", names)
            self.assertTrue(all(name.startswith(prefix) for name in names))


if __name__ == "__main__":
    unittest.main()
