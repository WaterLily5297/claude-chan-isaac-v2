#!/usr/bin/env python3
"""Build an installable copy of the mod: only the files the game loads.

    python3 tools/package_mod.py            # writes dist/claude-chan-isaac.zip
    python3 tools/package_mod.py --dir      # also writes dist/claude-chan-isaac/
    python3 tools/package_mod.py --dir --no-zip   # folder only (used by CI)

The zip holds one top-level folder named after metadata.xml's <directory>
(claude-chan-isaac), so unzipping it into the game's mods folder gives the
folder name that existing saves and installs use. A GitHub "Download ZIP" of
this repository is named claude-chan-isaac-v2-main instead and also carries
about 40 MB of docs, tests and tools the game never reads.

The zip is byte-for-byte reproducible for the same commit.
"""
import argparse
import os
import shutil
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
# Top-level files and folders the game reads, plus the licence texts.
TOP_FILES = ["main.lua", "metadata.xml", "LICENSE"]
TOP_DIRS = ["content", "resources", "scripts"]
# main.lua loads the developer runtime probe definition unconditionally.
EXTRA_FILES = ["tests/runtime_probe.lua"]
SKIP_DIRS = {"__pycache__"}
SKIP_SUFFIXES = (".pyc",)
FIXED_TIME = (2026, 1, 1, 0, 0, 0)


def folder_name(root=ROOT):
    directory = ET.parse(os.path.join(root, "metadata.xml")).getroot().findtext("directory")
    if not directory or "/" in directory or "\\" in directory:
        raise ValueError("metadata.xml needs a plain <directory> name")
    return directory.strip()


def package_files(root=ROOT):
    """Sorted repository-relative paths (forward slashes) that go into the package."""
    files = list(TOP_FILES) + list(EXTRA_FILES)
    for top in TOP_DIRS:
        for base, dirs, names in os.walk(os.path.join(root, top)):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            for name in names:
                if name.endswith(SKIP_SUFFIXES):
                    continue
                path = os.path.relpath(os.path.join(base, name), root)
                files.append(path.replace(os.sep, "/"))
    for path in files:
        if not os.path.isfile(os.path.join(root, path)):
            raise FileNotFoundError(path)
    return sorted(set(files))


def write_zip(target, root=ROOT):
    name = folder_name(root)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in package_files(root):
            info = zipfile.ZipInfo(f"{name}/{path}", FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            with open(os.path.join(root, path), "rb") as src:
                zf.writestr(info, src.read())
    return target


def write_dir(target, root=ROOT):
    if os.path.exists(target):
        shutil.rmtree(target)
    for path in package_files(root):
        dest = os.path.join(target, *path.split("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copyfile(os.path.join(root, path), dest)
    return target


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=os.path.join(ROOT, "dist"), help="output folder (default: dist/)")
    parser.add_argument("--dir", action="store_true", help="also write an unzipped folder")
    parser.add_argument("--no-zip", action="store_true", help="skip the zip")
    args = parser.parse_args(argv)
    name = folder_name()
    files = package_files()
    if not args.no_zip:
        zip_path = write_zip(os.path.join(args.out, name + ".zip"))
        print(f"{zip_path}: {len(files)} files in {name}/")
    if args.dir:
        print(write_dir(os.path.join(args.out, name)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
