#!/usr/bin/env python3
"""Validaciones estáticas de Caritatos Legends.

Comprueba, sin necesidad de Brotato:
  - manifest.json según las reglas de ModLoader 6.3.0.
  - Archivos obligatorios y archivos prohibidos dentro del mod.
  - Índice de leyendas y cada modules/<id>/module.json (mismas reglas que
    core/module_registry.gd), dependencias, ciclos y archivos referenciados.
  - Que las extensiones apunten a scripts que existen en la versión objetivo
    del juego (tools/game_scripts.txt).
  - Rutas res:// propias que se usan en los scripts.
  - Claves de texto CLC_* presentes en todos los idiomas.
  - Coherencia de versiones (manifest, mod_main.gd y CHANGELOG.md).
  - Sintaxis GDScript con gdparse (gdtoolkit 3) si se pasa --gdparse.

Uso: python tools/validate.py [--gdparse]
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOD_ID = "Caritato-LegendsCollection"
MOD_DIR = ROOT / "mods-unpacked" / MOD_ID
MOD_RES_PREFIX = f"res://mods-unpacked/{MOD_ID}/"
GAME_SCRIPTS_FILE = ROOT / "tools" / "game_scripts.txt"

NAME_RE = re.compile(r"^[a-zA-Z0-9_]{3,}$")
SEMVER_RE = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
MODULE_ID_RE = re.compile(r"^[a-z][a-z0-9_]{2,47}$")
SETTING_KEY_RE = re.compile(r"^[a-z][a-z0-9_]{0,47}$")
TEXT_KEY_RE = re.compile(r"\bCLC_[A-Z0-9_]+\b")
EXTENDS_RE = re.compile(r'^extends\s+"(res://[^"]+)"', re.MULTILINE)
RES_PATH_RE = re.compile(r'"(res://mods-unpacked/[^"]+)"')

REQUIRED_MANIFEST_ROOT = ["name", "namespace", "version_number", "website_url", "description", "dependencies", "extra"]
REQUIRED_MANIFEST_GODOT = ["authors", "compatible_mod_loader_version", "compatible_game_version"]
VALID_CATEGORIES = {"mechanics", "shop", "economy", "balance", "content", "quality_of_life"}
VALID_SETTING_TYPES = {"bool", "int", "float", "enum"}
VALID_COMPAT_STATUS = {"tested", "untested", "needs_adaptation", "incompatible"}
FORBIDDEN_SUFFIXES = {".pck", ".exe", ".dll", ".so", ".dylib", ".zip"}
# Prefijos de claves construidas dinámicamente en la interfaz.
DYNAMIC_KEY_PREFIXES = ("CLC_CATEGORY_",)


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def warning(self, message: str) -> None:
        self.warnings.append(message)


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path, report: Report):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        report.error(f"{rel(path)}: no existe")
    except json.JSONDecodeError as exc:
        report.error(f"{rel(path)}: JSON inválido ({exc})")
    return None


def res_to_path(res_path: str) -> Path | None:
    if not res_path.startswith(MOD_RES_PREFIX):
        return None
    return MOD_DIR / res_path[len(MOD_RES_PREFIX):]


def validate_manifest(report: Report) -> dict | None:
    manifest = load_json(MOD_DIR / "manifest.json", report)
    if not isinstance(manifest, dict):
        return None
    for key in REQUIRED_MANIFEST_ROOT:
        if key not in manifest:
            report.error(f"manifest.json: falta '{key}'")
    godot = manifest.get("extra", {}).get("godot") if isinstance(manifest.get("extra"), dict) else None
    if not isinstance(godot, dict):
        report.error("manifest.json: falta extra.godot")
        return manifest
    for key in REQUIRED_MANIFEST_GODOT:
        if key not in godot:
            report.error(f"manifest.json: falta extra.godot.{key}")

    for field in ("name", "namespace"):
        value = manifest.get(field, "")
        if not isinstance(value, str) or not NAME_RE.match(value):
            report.error(f"manifest.json: '{field}' solo admite letras, números y _ (mínimo 3)")
    expected_id = f"{manifest.get('namespace')}-{manifest.get('name')}"
    if expected_id != MOD_ID:
        report.error(f"manifest.json: el id '{expected_id}' no coincide con la carpeta '{MOD_ID}'")

    version = manifest.get("version_number", "")
    if not isinstance(version, str) or not SEMVER_RE.match(version) or len(version) > 16:
        report.error(f"manifest.json: version_number '{version}' no es semver válido")

    for field in ("compatible_mod_loader_version", "compatible_game_version", "authors"):
        value = godot.get(field)
        if not isinstance(value, list) or not value:
            report.error(f"manifest.json: extra.godot.{field} debe ser una lista no vacía")
    for value in godot.get("compatible_mod_loader_version", []) or []:
        if not SEMVER_RE.match(str(value)):
            report.error(f"manifest.json: versión de ModLoader '{value}' no es semver")
    if manifest.get("dependencies"):
        report.error("manifest.json: la colección no debe depender de otros mods de Workshop")
    return manifest


def validate_files(report: Report) -> None:
    for required in ("manifest.json", "mod_main.gd", "core/legends_core.gd", "i18n/strings.json", "modules/modules.json"):
        if not (MOD_DIR / required).is_file():
            report.error(f"falta el archivo obligatorio {required}")
    for path in MOD_DIR.rglob("*"):
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES:
            report.error(f"{rel(path)}: tipo de archivo no permitido dentro del mod")


def validate_setting(module_id: str, index: int, setting, seen: set, report: Report) -> list[str]:
    keys: list[str] = []
    where = f"[{module_id}] ajuste #{index}"
    if not isinstance(setting, dict):
        report.error(f"{where}: no es un objeto")
        return keys
    key = setting.get("key")
    if not isinstance(key, str) or not SETTING_KEY_RE.match(key):
        report.error(f"{where}: clave inválida ({key!r})")
        return keys
    where = f"[{module_id}] ajuste '{key}'"
    if key in seen:
        report.error(f"{where}: duplicado")
    seen.add(key)

    setting_type = setting.get("type")
    if setting_type not in VALID_SETTING_TYPES:
        report.error(f"{where}: tipo desconocido ({setting_type!r})")
        return keys

    for text_field in ("label_key", "help_key"):
        if text_field in setting:
            if not isinstance(setting[text_field], str):
                report.error(f"{where}: {text_field} debe ser texto")
            elif setting[text_field]:
                keys.append(setting[text_field])
    if not setting.get("label_key"):
        report.error(f"{where}: falta label_key")

    default = setting.get("default")
    if setting_type == "bool":
        if not isinstance(default, bool):
            report.error(f"{where}: default debe ser booleano")
    elif setting_type in ("int", "float"):
        numbers = [setting.get(name) for name in ("min", "max", "default")] + [setting.get("step", 1)]
        if any(isinstance(n, bool) or not isinstance(n, (int, float)) for n in numbers):
            report.error(f"{where}: min, max, step y default deben ser números")
        else:
            low, high, default_value, step = numbers
            if low > high:
                report.error(f"{where}: min mayor que max")
            if not low <= default_value <= high:
                report.error(f"{where}: default fuera de rango")
            if step <= 0:
                report.error(f"{where}: step debe ser positivo")
            if setting_type == "int" and any(float(n) != int(n) for n in numbers):
                report.error(f"{where}: un ajuste int necesita valores enteros")
    elif setting_type == "enum":
        options = setting.get("options")
        if not isinstance(options, list) or not options or not all(isinstance(o, str) for o in options):
            report.error(f"{where}: options debe ser una lista de textos")
        elif default not in options:
            report.error(f"{where}: default no está entre las opciones")
        else:
            label = setting.get("label_key", "")
            keys.extend(f"{label}_{option.upper()}" for option in options)

    depends_on = setting.get("depends_on")
    if depends_on is not None and not isinstance(depends_on, str):
        report.error(f"{where}: depends_on debe ser texto")
    return keys


def validate_modules(report: Report, game_scripts: set[str]) -> tuple[list[str], list[str]]:
    """Devuelve (ids de módulos, claves de texto referenciadas)."""
    text_keys: list[str] = []
    index = load_json(MOD_DIR / "modules" / "modules.json", report)
    if not isinstance(index, dict) or not isinstance(index.get("modules"), list):
        report.error("modules/modules.json: debe contener {\"modules\": [...]}")
        return [], text_keys

    listed = index["modules"]
    module_dirs = {p.name for p in (MOD_DIR / "modules").iterdir() if p.is_dir()}
    for missing in sorted(module_dirs - set(listed)):
        report.error(f"modules/{missing}: carpeta no listada en modules.json")

    definitions: dict[str, dict] = {}
    for entry in listed:
        if not isinstance(entry, str):
            report.error("modules.json: todas las entradas deben ser texto")
            continue
        base = MOD_DIR / "modules" / entry
        definition = load_json(base / "module.json", report)
        if not isinstance(definition, dict):
            continue
        module_id = definition.get("id")
        if not isinstance(module_id, str) or not MODULE_ID_RE.match(module_id):
            report.error(f"modules/{entry}: id inválido ({module_id!r})")
            continue
        if module_id in definitions:
            report.error(f"modules/{entry}: id duplicado '{module_id}'")
            continue
        if module_id != entry:
            report.error(f"modules/{entry}: la carpeta no coincide con el id '{module_id}'")
        definitions[module_id] = definition

        for field in ("name_key", "description_key"):
            value = definition.get(field)
            if not isinstance(value, str) or not value:
                report.error(f"[{module_id}] falta {field}")
            else:
                text_keys.append(value)
        if definition.get("category") not in VALID_CATEGORIES:
            report.error(f"[{module_id}] categoría desconocida ({definition.get('category')!r})")
        version = definition.get("version", "")
        if not isinstance(version, str) or not SEMVER_RE.match(version):
            report.error(f"[{module_id}] version '{version}' no es semver")
        if not isinstance(definition.get("enabled_by_default", True), bool):
            report.error(f"[{module_id}] enabled_by_default debe ser booleano")

        compatibility = definition.get("compatibility", {})
        if not isinstance(compatibility, dict) or compatibility.get("status", "untested") not in VALID_COMPAT_STATUS:
            report.error(f"[{module_id}] compatibility.status inválido")

        origin = definition.get("origin")
        if not isinstance(origin, dict) or not origin.get("type"):
            report.error(f"[{module_id}] falta origin.type (procedencia y licencia)")

        for field in ("dependencies", "conflicts", "requires_dlc", "extensions"):
            value = definition.get(field, [])
            if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
                report.error(f"[{module_id}] {field} debe ser una lista de textos")

        for extension in definition.get("extensions", []) or []:
            path = base / extension
            if not path.is_file():
                report.error(f"[{module_id}] falta la extensión {extension}")
                continue
            validate_extension(path, game_scripts, report)

        runtime = definition.get("runtime", "")
        if runtime and not (base / runtime).is_file():
            report.error(f"[{module_id}] falta el runtime {runtime}")

        settings = definition.get("settings", [])
        if not isinstance(settings, list):
            report.error(f"[{module_id}] settings debe ser una lista")
            settings = []
        seen: set[str] = set()
        for i, setting in enumerate(settings):
            text_keys.extend(validate_setting(module_id, i, setting, seen, report))
        for setting in settings:
            if isinstance(setting, dict) and setting.get("depends_on") and setting["depends_on"] not in seen:
                report.error(f"[{module_id}] ajuste '{setting.get('key')}' depende de un ajuste inexistente")

    for module_id, definition in definitions.items():
        for dependency in definition.get("dependencies", []) or []:
            if dependency == module_id:
                report.error(f"[{module_id}] depende de sí mismo")
            elif dependency not in definitions:
                report.error(f"[{module_id}] dependencia inexistente '{dependency}'")
        if depends_on(definitions, module_id, module_id, set()):
            report.error(f"[{module_id}] dependencia circular")

    return list(definitions), text_keys


def depends_on(definitions: dict, start: str, target: str, visited: set) -> bool:
    for dependency in definitions.get(start, {}).get("dependencies", []) or []:
        if dependency == target:
            return True
        if dependency in visited:
            continue
        visited.add(dependency)
        if depends_on(definitions, dependency, target, visited):
            return True
    return False


def validate_extension(path: Path, game_scripts: set[str], report: Report) -> None:
    text = path.read_text(encoding="utf-8")
    match = EXTENDS_RE.search(text)
    if not match:
        report.error(f"{rel(path)}: una extensión debe empezar con extends \"res://...\"")
        return
    target = match.group(1)
    if target.startswith("res://mods-unpacked/"):
        report.error(f"{rel(path)}: una extensión debe extender un script del juego, no del mod")
    elif game_scripts and target not in game_scripts:
        report.error(f"{rel(path)}: {target} no existe en la versión objetivo del juego")


def validate_core_extensions(report: Report, game_scripts: set[str]) -> None:
    extensions_dir = MOD_DIR / "extensions"
    if not extensions_dir.is_dir():
        return
    main_text = (MOD_DIR / "mod_main.gd").read_text(encoding="utf-8")
    for path in sorted(extensions_dir.rglob("*.gd")):
        validate_extension(path, game_scripts, report)
        relative = path.relative_to(MOD_DIR).as_posix()
        if f'"{relative}"' not in main_text:
            report.error(f"{rel(path)}: no está instalada en mod_main.gd")


def validate_res_paths(report: Report) -> None:
    for path in sorted(MOD_DIR.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for res_path in RES_PATH_RE.findall(text):
            target = res_to_path(res_path)
            if target is None:
                report.error(f"{rel(path)}: ruta de otro mod {res_path}")
            elif not target.exists():
                report.error(f"{rel(path)}: la ruta {res_path} no existe")


def validate_texts(report: Report, referenced_keys: list[str], categories_used: set[str]) -> None:
    strings = load_json(MOD_DIR / "i18n" / "strings.json", report)
    if not isinstance(strings, dict) or not strings:
        report.error("i18n/strings.json: debe contener al menos un idioma")
        return
    for required_locale in ("es", "en"):
        if required_locale not in strings:
            report.error(f"i18n/strings.json: falta el idioma '{required_locale}'")

    locale_keys = {locale: set(messages) for locale, messages in strings.items() if isinstance(messages, dict)}
    all_keys = set().union(*locale_keys.values()) if locale_keys else set()
    for locale, keys in locale_keys.items():
        for missing in sorted(all_keys - keys):
            report.error(f"i18n/strings.json: '{missing}' falta en '{locale}'")
        for key, value in strings[locale].items():
            if not isinstance(value, str) or not value.strip():
                report.error(f"i18n/strings.json: '{key}' está vacío en '{locale}'")

    used = set(referenced_keys)
    for path in MOD_DIR.rglob("*.gd"):
        for key in TEXT_KEY_RE.findall(path.read_text(encoding="utf-8")):
            if not key.endswith("_") and not key.startswith(DYNAMIC_KEY_PREFIXES):
                used.add(key)
    for category in categories_used:
        used.add(f"CLC_CATEGORY_{category.upper()}")
    for category in VALID_CATEGORIES:
        if f"CLC_CATEGORY_{category.upper()}" not in all_keys:
            report.error(f"i18n/strings.json: falta CLC_CATEGORY_{category.upper()}")

    for key in sorted(used - all_keys):
        report.error(f"texto '{key}' sin traducción en i18n/strings.json")
    for key in sorted(all_keys - used):
        if not key.startswith(DYNAMIC_KEY_PREFIXES):
            report.warning(f"texto '{key}' definido pero sin uso")


def validate_versions(report: Report, manifest: dict | None) -> None:
    if not manifest:
        return
    version = manifest.get("version_number")
    main_text = (MOD_DIR / "mod_main.gd").read_text(encoding="utf-8")
    match = re.search(r'const VERSION := "([^"]+)"', main_text)
    if not match or match.group(1) != version:
        report.error(f"mod_main.gd: VERSION debe coincidir con manifest.json ({version})")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8") if (ROOT / "CHANGELOG.md").exists() else ""
    if version and f"[{version}]" not in changelog and "[Sin publicar]" not in changelog:
        report.warning(f"CHANGELOG.md no menciona la versión {version}")


def run_gdparse(report: Report) -> None:
    executable = shutil.which("gdparse")
    if executable is None:
        report.error("gdparse no está instalado (pip install 'gdtoolkit==3.*')")
        return
    files = sorted(str(p) for p in list(MOD_DIR.rglob("*.gd")) + list((ROOT / "tests").rglob("*.gd")))
    for file in files:
        result = subprocess.run([executable, file], capture_output=True, text=True)
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip().splitlines()
            report.error(f"{rel(Path(file))}: error de sintaxis GDScript: {detail[-1] if detail else ''}")


def load_game_scripts(report: Report) -> set[str]:
    if not GAME_SCRIPTS_FILE.is_file():
        report.warning("tools/game_scripts.txt no existe; no se comprueban los destinos de las extensiones")
        return set()
    lines = GAME_SCRIPTS_FILE.read_text(encoding="utf-8").splitlines()
    return {line.strip() for line in lines if line.strip().startswith("res://")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--gdparse", action="store_true", help="comprueba la sintaxis GDScript con gdparse")
    args = parser.parse_args()

    report = Report()
    if not MOD_DIR.is_dir():
        print(f"ERROR: no existe {rel(MOD_DIR)}")
        return 1

    game_scripts = load_game_scripts(report)
    manifest = validate_manifest(report)
    validate_files(report)
    module_ids, text_keys = validate_modules(report, game_scripts)
    validate_core_extensions(report, game_scripts)
    validate_res_paths(report)
    categories = set()
    for module_id in module_ids:
        definition = json.loads((MOD_DIR / "modules" / module_id / "module.json").read_text(encoding="utf-8"))
        categories.add(definition.get("category", ""))
    validate_texts(report, text_keys, categories)
    validate_versions(report, manifest)
    if args.gdparse:
        run_gdparse(report)

    for warning in report.warnings:
        print(f"AVISO: {warning}")
    for error in report.errors:
        print(f"ERROR: {error}")
    print(f"Leyendas encontradas: {len(module_ids)} ({', '.join(module_ids) or 'ninguna'})")
    if report.errors:
        print(f"Validación fallida: {len(report.errors)} errores.")
        return 1
    print("Validación correcta.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
