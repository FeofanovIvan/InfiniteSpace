#!/usr/bin/env python3
"""Attribute compressed APK bytes to Godot source directories."""

from __future__ import annotations

import argparse
import re
import zipfile
from collections import defaultdict
from pathlib import Path


IMPORTED_RE = re.compile(r'path="res://\.godot/imported/([^"/]+)"')
SKIP = {".git", ".godot", "builds", "reports"}


def mib(value: int) -> float:
    return value / 1024 / 1024


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--depth", type=int, default=2)
    args = parser.parse_args()
    root = args.root.resolve()

    imported_to_source: dict[str, str] = {}
    for descriptor in root.rglob("*.import"):
        relative = descriptor.relative_to(root)
        if any(part in SKIP for part in relative.parts):
            continue
        try:
            match = IMPORTED_RE.search(descriptor.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue
        if match:
            imported_to_source[match.group(1)] = relative.as_posix()[:-7]

    totals: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    largest: list[tuple[int, int, str, str]] = []
    with zipfile.ZipFile(args.apk) as archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            name = info.filename
            source = ""
            if name.startswith("assets/.godot/imported/"):
                source = imported_to_source.get(Path(name).name, "[unmapped-import]")
                parts = Path(source).parts
                category = "/".join(parts[:args.depth]) if parts and source[0] != "[" else source
            elif name.startswith("assets/"):
                source = name[len("assets/"):]
                parts = Path(source).parts
                category = "/".join(parts[:args.depth]) if parts else "[godot-assets]"
            else:
                first = name.split("/", 1)[0]
                category = "[android]/" + first
                source = name
            row = totals[category]
            row[0] += info.compress_size
            row[1] += info.file_size
            row[2] += 1
            largest.append((info.compress_size, info.file_size, source, category))

    print("COMPRESSED_MIB  RAW_MIB  FILES  CATEGORY")
    for category, (compressed, raw, count) in sorted(totals.items(), key=lambda item: item[1][0], reverse=True):
        print(f"{mib(compressed):14.2f} {mib(raw):8.2f} {count:6d}  {category}")
    print("\nLARGEST COMPRESSED ENTRIES")
    for compressed, raw, source, category in sorted(largest, reverse=True)[:60]:
        print(f"{mib(compressed):8.2f} MiB ({mib(raw):8.2f} raw)  {category:36s}  {source}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
