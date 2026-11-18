#!/usr/bin/env python3
"""Conservative static resource reachability audit for the unified project."""

from __future__ import annotations

import json
import re
from collections import defaultdict, deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESOURCE_RE = re.compile(r"res://[^\"'\s)\],}]+")
TEXT_EXTENSIONS = {
    ".gd", ".tscn", ".tres", ".json", ".cfg", ".godot", ".gdshader",
    ".translation", ".csv", ".txt", ".md",
}
IGNORED_PARTS = {".git", ".godot", "builds", "reports", "docs"}


def relative_resource(value: str) -> Path | None:
    if not value.startswith("res://"):
        return None
    path = Path(value[6:].split("::", 1)[-1])
    return path if (ROOT / path).is_file() else None


def text_references(path: Path) -> set[Path]:
    if path.suffix.lower() not in TEXT_EXTENSIONS and path.name != "project.godot":
        return set()
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return set()
    found: set[Path] = set()
    for match in RESOURCE_RE.findall(text):
        resource = relative_resource(match.rstrip(".,;"))
        if resource is not None:
            found.add(resource)
    return found


def catalog_scenes(path: Path, key: str) -> list[Path]:
    data = json.loads(path.read_text(encoding="utf-8"))
    values: list[str] = []
    if key == "entries":
        for entry in data[key]:
            values.extend(entry.get("scene_candidates", []))
    else:
        for entry in data:
            scene = entry.get("scene", "")
            if scene:
                values.append("res://learning/" + scene)
    return [resource for value in values if (resource := relative_resource(value))]


def main() -> int:
    roots = [Path("project.godot"), Path("scenes/main.tscn")]
    roots += catalog_scenes(ROOT / "simulator_ui/data/temp_planet_cards_v1151p24.json", "entries")
    roots += catalog_scenes(ROOT / "learning/catalog.json", "learning")
    roots += [
        Path("planet_hub/data/planet_game_cards_v104.json"),
        Path("simulator_ui/data/temp_planet_cards_v1151p24.json"),
        Path("learning/catalog.json"),
    ]

    reachable: set[Path] = set()
    parents: dict[Path, set[Path]] = defaultdict(set)
    queue = deque(roots)
    while queue:
        resource = queue.popleft()
        if resource in reachable or not (ROOT / resource).is_file():
            continue
        reachable.add(resource)
        for child in text_references(ROOT / resource):
            parents[child].add(resource)
            if child not in reachable:
                queue.append(child)

    scopes = (Path("learning"), Path("planet_hub/games"))
    all_files: set[Path] = set()
    for scope in scopes:
        for path in (ROOT / scope).rglob("*"):
            if not path.is_file() or path.suffix in {".import", ".uid"}:
                continue
            relative = path.relative_to(ROOT)
            if any(part in IGNORED_PARTS for part in relative.parts):
                continue
            all_files.add(relative)

    unused = all_files - reachable
    totals: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    for resource in unused:
        parts = resource.parts
        depth = 4 if parts[:2] == ("planet_hub", "games") else 3
        group = "/".join(parts[:depth])
        source = ROOT / resource
        size = source.stat().st_size
        imported = Path(str(source) + ".import")
        totals[group][0] += size
        totals[group][1] += imported.stat().st_size if imported.is_file() else 0
        totals[group][2] += 1

    print(f"Reachable source resources: {len(reachable)}")
    print(f"Unreferenced candidates: {len(unused)}")
    print("SOURCE_MIB  FILES  GROUP")
    for group, (size, _descriptor_size, count) in sorted(
        totals.items(), key=lambda item: item[1][0], reverse=True
    ):
        print(f"{size / 1024 / 1024:10.2f} {count:6d}  {group}")
    print("\nLargest unreferenced candidates")
    for resource in sorted(unused, key=lambda item: (ROOT / item).stat().st_size, reverse=True)[:100]:
        print(f"{(ROOT / resource).stat().st_size / 1024 / 1024:8.2f} MiB  {resource}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
