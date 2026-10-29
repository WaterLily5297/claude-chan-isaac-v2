#!/usr/bin/env bash
# 提交前检查（和 GitHub 上的自动检查完全一样）。
# Pre-commit checks, identical to the GitHub Actions run.
#
#   bash tools/check.sh
#
# 需要 Lua 5.3+（lua5.4 / lua / texlua 都行）和 Python 3。
# Windows：在 Git Bash 里运行。

set -u
cd "$(dirname "$0")/.."
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8

LUA="${LUA:-}"
if [ -z "$LUA" ]; then
    for c in lua5.4 lua5.3 lua texlua; do
        if command -v "$c" >/dev/null 2>&1; then LUA="$c"; break; fi
    done
fi
if [ -z "$LUA" ]; then
    echo "找不到 Lua 5.3+。Ubuntu: sudo apt-get install lua5.4；Windows: scoop install lua"
    echo "Lua 5.3+ not found."
    exit 1
fi

PY="${PY:-}"
if [ -z "$PY" ]; then
    for c in python3 python; do
        if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; assert sys.version_info >= (3, 9)' >/dev/null 2>&1; then PY="$c"; break; fi
    done
fi

fail=0
ok()  { echo "  ✓ $1"; }
bad() { echo "  ✗ $1"; fail=1; }

echo "== 1. 空文件 / empty files"
# 曾经有脚本 bug 把 risk.lua 清空，而空文件能通过语法检查。
empty=0
while IFS= read -r -d '' f; do
    if [ ! -s "$f" ]; then bad "空文件 / empty: $f"; empty=1; fi
done < <(find . -path ./.git -prune -o -type f \( -name '*.lua' -o -name '*.xml' -o -name '*.md' \) -print0)
[ "$empty" = 0 ] && ok "没有空文件"

echo "== 2. Lua 语法 / syntax ($LUA)"
lua_files=()
while IFS= read -r -d '' f; do lua_files+=("$f"); done \
    < <(find . -path ./.git -prune -o -type f -name '*.lua' -print0)
"$LUA" tools/syntax_check.lua "${lua_files[@]}" || fail=1

echo "== 3. XML 格式 + 贴图路径 / XML + sprite paths"
if [ -z "$PY" ]; then
    bad "Python 3.9+ not found; asset checks are required"
else
    if ! "$PY" - <<'EOF'
import glob, os, sys
import xml.etree.ElementTree as ET

ok = True
files = ["metadata.xml"] + sorted(glob.glob("content/*.xml"))
for path in files:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        print(f"  ✗ {path}: {e}")
        ok = False
        continue
    # items.xml: 每个 gfx= 都要有对应的 PNG
    if root.tag == "items":
        gfxroot = root.get("gfxroot", "")
        for el in root:
            gfx = el.get("gfx")
            if not gfx:
                continue
            # 引擎会自己加 collectibles/ 或 trinkets/，gfx 只能写文件名
            # The engine adds the collectibles/ or trinkets/ folder; gfx is a bare file name.
            if "/" in gfx:
                print(f"  ✗ {path}: 「{el.get('name')}」gfx 不能带文件夹 / gfx must not name a folder: {gfx}")
                ok = False
                continue
            folder = "trinkets" if el.tag == "trinket" else "collectibles"
            if not os.path.isfile(os.path.join("resources", gfxroot, folder, gfx)):
                print(f"  ✗ {path}: 「{el.get('name')}」的贴图不存在 / sprite missing: resources/{gfxroot}{folder}/{gfx}")
                ok = False
if ok:
    print(f"  ✓ {len(files)} 个 XML 文件，贴图都在")
sys.exit(0 if ok else 1)
EOF
    then fail=1; fi
fi

if [ -n "$PY" ]; then
    "$PY" tools/check_assets.py || fail=1
    "$PY" tests/test_item_art.py || fail=1
    "$PY" tests/test_thumbnail.py || fail=1
    "$PY" tests/test_interaction_audit.py || fail=1
    "$PY" tools/audit_interactions.py --check || fail=1
fi

echo "== 4. 测试 / tests (stubbed Isaac API)"
for t in tests/*_test.lua; do
    if out=$("$LUA" "$t" . 2>&1); then
        ok "$t"
    else
        bad "$t"
        echo "$out" | tail -15 | sed 's/^/      /'
    fi
done

echo
if [ "$fail" = 0 ]; then
    echo "全部通过 / all checks passed"
else
    echo "有检查没通过，看上面的 ✗ / some checks failed (see ✗ above)"
fi
exit "$fail"
