#!/usr/bin/env python3
"""Conservative Godot source-resource audit.

Finds byte-identical media and media without a literal res:// reference. The
second category is only a review list: Godot projects may construct paths at
runtime, so this script never deletes or moves files.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path


MEDIA_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".webp", ".svg", ".ogg", ".wav", ".mp3",
    ".mp4", ".webm", ".ttf", ".otf",
}
TEXT_EXTENSIONS = {
    ".gd", ".tscn", ".tres", ".json", ".cfg", ".godot", ".csv",
    ".translation", ".shader", ".gdshader",
}
SKIP_PARTS = {".git", ".godot", "builds", "reports", "_mika_backups"}
REFERENCE_SKIP_PARTS = SKIP_PARTS | {"docs", "tools", "planet_hub/tests"}


def skipped(path: Path, extra: set[str] | None = None) -> bool:
    blocked = SKIP_PARTS if extra is None else extra
    return any(part in blocked for part in path.parts)


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def mib(size: int) -> float:
    return round(size / 1024 / 1024, 2)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--json", type=Path)
    parser.add_argument("--markdown", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()

    media = [
        path for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS
        and not skipped(path.relative_to(root))
    ]

    reference_text: list[str] = []
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if (not path.is_file() or skipped(relative, REFERENCE_SKIP_PARTS)
                or path.suffix.lower() not in TEXT_EXTENSIONS):
            continue
        try:
            reference_text.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            pass
    corpus = "\n".join(reference_text)

    by_hash: dict[str, list[Path]] = defaultdict(list)
    unreferenced: list[dict[str, object]] = []
    for path in media:
        by_hash[digest(path)].append(path)
        relative = path.relative_to(root).as_posix()
        if f"res://{relative}" not in corpus:
            unreferenced.append({"path": relative, "bytes": path.stat().st_size})

    duplicate_groups: list[dict[str, object]] = []
    for sha256, paths in by_hash.items():
        if len(paths) < 2:
            continue
        size = paths[0].stat().st_size
        duplicate_groups.append({
            "sha256": sha256,
            "bytes_each": size,
            "reclaimable_bytes": size * (len(paths) - 1),
            "paths": [path.relative_to(root).as_posix() for path in paths],
            "literal_references": [
                f"res://{path.relative_to(root).as_posix()}" in corpus for path in paths
            ],
        })

    duplicate_groups.sort(key=lambda item: int(item["reclaimable_bytes"]), reverse=True)
    unreferenced.sort(key=lambda item: int(item["bytes"]), reverse=True)
    result = {
        "root": str(root),
        "media_files": len(media),
        "media_source_mib": mib(sum(path.stat().st_size for path in media)),
        "duplicate_groups": len(duplicate_groups),
        "duplicate_reclaimable_mib": mib(sum(int(item["reclaimable_bytes"]) for item in duplicate_groups)),
        "unreferenced_candidates": len(unreferenced),
        "unreferenced_candidate_mib": mib(sum(int(item["bytes"]) for item in unreferenced)),
        "duplicates": duplicate_groups,
        "largest_unreferenced_candidates": unreferenced[:200],
        "warning": "Unreferenced candidates may be loaded through runtime-built paths; review before moving.",
    }

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lines = [
        "# Resource audit",
        "",
        f"- Media files: {result['media_files']} ({result['media_source_mib']} MiB source)",
        f"- Exact duplicate groups: {result['duplicate_groups']}",
        f"- Exact duplicate upper bound: {result['duplicate_reclaimable_mib']} MiB",
        f"- No literal `res://` reference: {result['unreferenced_candidates']} files "
        f"({result['unreferenced_candidate_mib']} MiB)",
        "",
        "> The unreferenced list is conservative evidence for review, not a deletion list; paths may be built dynamically.",
        "",
        "## Largest exact duplicate groups",
        "",
    ]
    for group in duplicate_groups[:40]:
        lines.append(f"- {mib(int(group['reclaimable_bytes']))} MiB reclaimable")
        for path, referenced in zip(group["paths"], group["literal_references"]):
            lines.append(f"  - `{path}` (literal reference: {'yes' if referenced else 'no'})")
    lines.extend(["", "## Largest candidates without a literal reference", ""])
    for item in unreferenced[:100]:
        lines.append(f"- {mib(int(item['bytes']))} MiB — `{item['path']}`")
    markdown = "\n".join(lines) + "\n"
    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
