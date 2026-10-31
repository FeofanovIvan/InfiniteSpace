#!/usr/bin/env python3
# MIKA: download original CC0 landscape-source packs to ~/Downloads/MIKA_48_PLANETS
# No AI generation, no image modifications, no fake placeholder images.
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
import zipfile
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path.home() / "Downloads" / "MIKA_48_PLANETS"
RAW = ROOT / "SOURCE_PACKS"
OGA = RAW / "OpenGameArt"
ITCH = RAW / "Itch"
UNPACKED = ROOT / "UNPACKED"
ROOT.mkdir(parents=True, exist_ok=True)
OGA.mkdir(parents=True, exist_ok=True)
ITCH.mkdir(parents=True, exist_ok=True)
UNPACKED.mkdir(parents=True, exist_ok=True)
MANIFEST = ROOT / "DOWNLOAD_REPORT.json"

OPEN_GAME_ART = [
    ("rocky_desert", "https://opengameart.org/content/rocky-desert-landscape-layered-looping"),
    ("ice_planet", "https://opengameart.org/content/ice-planet-landscape-layered-looping"),
    ("sideview_fantasy", "https://opengameart.org/content/sideview-fantasy-patreon-collection"),
    ("cavernous", "https://opengameart.org/content/cavernous-background"),
    ("crystal_cave", "https://opengameart.org/content/abstract-crystal-cave-background"),
    ("mountain_dusk", "https://opengameart.org/content/mountain-at-dusk-background"),
    ("canyon_terrain", "https://opengameart.org/content/canyon-terrain-asset"),
    ("slanty_desert", "https://opengameart.org/content/slanty-desert-rocks-background-looping"),
]
ITCH_PACKS = [
    ("Planet Surfaces 1", "https://screamingbrainstudios.itch.io/planet-surface-backgrounds/purchase",
     "SBS - Planet Backgrounds - 1280x720.rar"),
    ("Planet Surfaces 2", "https://screamingbrainstudios.itch.io/planet-surface-backgrounds-2/purchase",
     "SBS - Planet Surface Backgrounds 2 - 1024x768.rar"),
    ("Seamless Sky Backgrounds", "https://screamingbrainstudios.itch.io/seamless-sky-backgrounds/purchase",
     "SBS - Seamless Sky Backgrounds - 1024x512.rar"),
]
CATALOG_URL = "https://raw.githubusercontent.com/FeofanovIvan/InfiniteSpace/main/docs/MIKA_48_EXTERNAL_SCENE_SOURCE_SELECTIONS.md"
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; MIKA-asset-research/1.0)", "Accept": "*/*"}
report = {"time_utc": datetime.now(timezone.utc).isoformat(), "files": [], "issues": [], "itch": []}

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []
    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        a = dict(attrs)
        if a.get("href"):
            self.urls.append(a["href"])

def read_url(url, referer=None, timeout=35):
    headers = dict(HEADERS)
    if referer:
        headers["Referer"] = referer
    req = urllib.request.Request(url, headers=headers)
    return urllib.request.urlopen(req, timeout=timeout)

def short_hash(file):
    h = hashlib.sha256()
    with file.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def download_binary(url, dest, referer=None):
    if dest.exists() and dest.stat().st_size > 100:
        print("  Есть:", dest.name)
        return True
    for attempt in range(2):
        temp = dest.with_suffix(dest.suffix + ".part")
        try:
            with read_url(url, referer) as response, temp.open("wb") as out:
                typ = response.headers.get("Content-Type", "").lower()
                first = response.read(2048)
                if "text/html" in typ or first.lstrip().lower().startswith((b"<!doctype html", b"<html")):
                    raise ValueError("сервер вернул HTML вместо файла")
                out.write(first)
                total = len(first)
                while True:
                    data = response.read(1024 * 1024)
                    if not data:
                        break
                    out.write(data)
                    total += len(data)
                    if total > 300 * 1024 * 1024:
                        raise ValueError("файл больше защитного лимита 300 МБ")
            if temp.stat().st_size < 100:
                raise ValueError("пустой/неполный файл")
            temp.replace(dest)
            report["files"].append({"name": str(dest.relative_to(ROOT)), "bytes": dest.stat().st_size, "sha256": short_hash(dest), "source": url})
            print("  Скачано:", dest.name, f"({dest.stat().st_size // 1024} КБ)")
            return True
        except Exception as exc:
            temp.unlink(missing_ok=True)
            if attempt == 0:
                time.sleep(1)
            else:
                msg = f"{url}: {exc}"
                print("  Не удалось:", msg)
                report["issues"].append(msg)
    return False

print("\nМИКА — оригинальные игровые референсы")
print("Папка:", ROOT, "\n")
print("1/4. Каталог 48 планет")
download_binary(CATALOG_URL, ROOT / "CATALOG_48_PLANETS.md")

print("\n2/4. Открытые файлы OpenGameArt (CC0)")
for label, page in OPEN_GAME_ART:
    print("\nИсточник:", label)
    try:
        with read_url(page) as f:
            html = f.read().decode("utf-8", "replace")
        if "CC0" not in html and "creativecommons.org/publicdomain/zero" not in html:
            raise ValueError("на странице не удалось подтвердить CC0")
        p = Links()
        p.feed(html)
        links = []
        for href in p.urls:
            full = urllib.parse.urljoin(page, href)
            parsed = urllib.parse.urlparse(full)
            ext = Path(urllib.parse.unquote(parsed.path)).suffix.lower()
            if parsed.netloc not in ("opengameart.org", "www.opengameart.org"):
                continue
            if not parsed.path.startswith("/sites/default/files/"):
                continue
            if ext not in (".png", ".jpg", ".jpeg", ".webp", ".zip"):
                continue
            if full not in links:
                links.append(full)
        if not links:
            report["issues"].append(label + ": прямых ссылок на файлы не обнаружено")
            print("  Прямые ссылки не найдены; страница:", page)
            continue
        folder = OGA / label
        folder.mkdir(exist_ok=True)
        for url in links:
            name = Path(urllib.parse.unquote(urllib.parse.urlparse(url).path)).name
            download_binary(url, folder / name, page)
    except Exception as exc:
        report["issues"].append(f"{page}: {exc}")
        print("  Ошибка:", exc)

print("\n3/4. Импорт архивов, скачанных вручную с itch.io")
downloads = Path.home() / "Downloads"
missing = []
for title, url, filename in ITCH_PACKS:
    target = ITCH / filename
    if not target.exists():
        candidates = [downloads / filename]
        candidates.extend(downloads.glob("SBS*rar"))
        found = next((x for x in candidates if x.is_file() and x.name.lower() == filename.lower()), None)
        if found:
            shutil.copy2(found, target)
            print("  Импортирован:", filename)
    if target.exists():
        report["itch"].append({"pack": title, "status": "downloaded", "file": str(target.relative_to(ROOT))})
    else:
        missing.append((title, url, filename))
        report["itch"].append({"pack": title, "status": "manual_download_needed", "url": url, "file": filename})

if missing:
    instructions = ["Для следующих бесплатных наборов необходим ручной шаг на itch.io:", ""]
    for title, url, filename in missing:
        instructions += [title, url, "Нажать: No thanks, just take me to the downloads", "Скачать файл: " + filename, ""]
    instructions += ["После скачивания в обычную папку Downloads запустите эту же команду ещё раз.",
                     "Ничего переносить вручную не нужно: программа найдёт файлы."]
    (ROOT / "ITCH_DOWNLOAD_INSTRUCTIONS.txt").write_text("\n".join(instructions), encoding="utf-8")
    for title, url, filename in missing:
        print("  Требуется в браузере:", title, "—", filename)
        try:
            webbrowser.open(url)
        except Exception:
            pass

print("\n4/4. Распаковка доступных ZIP и RAR")
unar = shutil.which("unar")
sevenzip = shutil.which("7z") or shutil.which("7zz")
for archive in sorted(RAW.rglob("*")):
    if not archive.is_file() or archive.suffix.lower() not in (".zip", ".rar"):
        continue
    dest = UNPACKED / (archive.stem.replace(" ", "_"))
    if dest.exists() and any(dest.iterdir()):
        continue
    dest.mkdir(parents=True, exist_ok=True)
    try:
        if archive.suffix.lower() == ".zip":
            with zipfile.ZipFile(archive) as zf:
                for member in zf.infolist():
                    target = (dest / member.filename).resolve()
                    if dest.resolve() not in target.parents and target != dest.resolve():
                        raise ValueError("небезопасный путь внутри ZIP")
                zf.extractall(dest)
            print("  ZIP распакован:", archive.name)
        elif unar:
            subprocess.run([unar, "-q", "-o", str(dest), str(archive)], check=True)
            print("  RAR распакован:", archive.name)
        elif sevenzip:
            subprocess.run([sevenzip, "x", "-y", "-o" + str(dest), str(archive)], check=True, stdout=subprocess.DEVNULL)
            print("  RAR распакован:", archive.name)
        else:
            print("  Для RAR установите unar: brew install unar")
            report["issues"].append(archive.name + ": RAR сохранён, но не распакован; нужен unar")
    except Exception as exc:
        report["issues"].append(str(archive) + ": " + str(exc))
        print("  Распаковать не удалось:", exc)

MANIFEST.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print("\nГотово. Все успешно полученные файлы:", ROOT)
print("Это исходные наборы, а не автоматически выбранные 48 утверждённых картинок.")
print("Если itch.io скачивания завершены после работы команды — запустите её ещё раз.")
