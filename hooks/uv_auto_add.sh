#!/usr/bin/env bash
# PostToolUse hook: detect missing packages from edited files and run `uv add`.
# Supports: Python imports, pyproject.toml dependencies, requirements.txt, dbt_project.yml, packages.yml
# Receives hook JSON on stdin.
# Compatible with bash 3.2+ (macOS default).

set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[[ -z "$FILE" ]] && exit 0
[[ -f "$FILE" ]] || exit 0

# Early exit: only process files that could contain package references.
# This avoids the expensive `uv pip list` call on every Write/Edit.
BASENAME=$(basename "$FILE")
case "$BASENAME" in
  *.py|pyproject.toml|requirements*.txt|dbt_project.yml|packages.yml) ;;
  *) exit 0 ;;
esac

# Get already-installed packages (normalized to lowercase)
get_installed() {
  uv pip list --format=columns 2>/dev/null \
    | tail -n +3 \
    | awk '{print tolower($1)}' \
    | tr '-' '_'
}

is_installed() {
  local pkg_lower
  pkg_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  echo "$INSTALLED" | grep -qx "$pkg_lower"
}

# Standard library modules to skip
STDLIB="abc ast asyncio base64 collections contextlib copy csv dataclasses datetime decimal enum \
errno fnmatch fractions functools gc getpass glob gzip hashlib heapq hmac html http importlib \
inspect io itertools json logging math multiprocessing operator os pathlib pickle platform pprint \
profile queue random re secrets select shelve shutil signal socket sqlite3 ssl stat statistics \
string struct subprocess sys tempfile textwrap threading time timeit tkinter token tokenize trace \
traceback turtle types typing unicodedata unittest urllib uuid venv warnings wave weakref webbrowser \
xml xmlrpc zipfile zipimport zlib argparse binascii builtins codecs concurrent configparser ctypes \
difflib dis distutils email encodings ftplib grp idlelib keyword locale lzma mmap numbers pdb pkg_resources \
posixpath pwd pydoc readline resource rlcompleter runpy sched setuptools site smtplib sndhdr spwd \
sre_compile sre_parse sysconfig syslog tabnanny tarfile telnetlib termios test textwrap _thread \
tracemalloc tty unittest wsgiref xdrlib"

# Known PyPI name mismatches: import_name=pypi_name (one per line)
# Add entries here when the import name differs from the PyPI package name.
PYPI_MAP="cv2=opencv-python
sklearn=scikit-learn
yaml=pyyaml
bs4=beautifulsoup4
PIL=pillow
gi=pygobject
attr=attrs
dateutil=python-dateutil
dotenv=python-dotenv
serial=pyserial
usb=pyusb
wx=wxpython
Crypto=pycryptodome"

# Look up a module name in the PyPI map. Prints the mapped name or nothing.
pypi_lookup() {
  local mod="$1"
  local mapped
  mapped=$(echo "$PYPI_MAP" | grep -E "^${mod}=" | head -1 | sed 's/^[^=]*=//')
  echo "$mapped"
}

is_stdlib() {
  echo "$STDLIB" | tr ' ' '\n' | grep -qx "$1"
}

INSTALLED=$(get_installed)
MISSING=()

add_if_missing() {
  local pkg="$1"
  local pkg_lower
  pkg_lower=$(echo "$pkg" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  is_stdlib "$pkg_lower" && return
  is_installed "$pkg" && return
  MISSING+=("$pkg")
}

case "$BASENAME" in
  *.py)
    # Extract top-level import names
    while IFS= read -r mod; do
      if [[ -z "$mod" ]]; then
        continue
      fi
      # Map known mismatches to correct PyPI names
      mapped=$(pypi_lookup "$mod")
      if [[ -n "$mapped" ]]; then
        add_if_missing "$mapped"
      else
        add_if_missing "$mod"
      fi
    done < <(grep -E '^[[:space:]]*(import |from )' "$FILE" 2>/dev/null \
      | sed -E 's/^[[:space:]]*(import|from) +//' \
      | sed -E 's/[. ].*//' \
      | sort -u)
    ;;

  pyproject.toml)
    # Extract dependency names from dependencies array
    while IFS= read -r dep; do
      pkg=$(echo "$dep" | sed -E 's/[>=<!\[; ].*//' | tr -d '"' | tr -d "'" | xargs)
      [[ -n "$pkg" && "$pkg" != "dependencies" && "$pkg" != "]" ]] && add_if_missing "$pkg"
    done < <(sed -n '/dependencies = \[/,/\]/p' "$FILE" 2>/dev/null \
      | grep '"' \
      | sed -E 's/^[[:space:]]*//' | tr -d ',')
    ;;

  requirements*.txt)
    while IFS= read -r line; do
      pkg=$(echo "$line" | sed -E 's/[>=<! ].*//' | xargs)
      [[ -n "$pkg" && "$pkg" != "#"* && "$pkg" != "-"* ]] && add_if_missing "$pkg"
    done < "$FILE"
    ;;

  dbt_project.yml|packages.yml)
    if [[ "$BASENAME" == "dbt_project.yml" ]]; then
      add_if_missing "dbt-core"
    fi
    # Use process substitution instead of pipe to avoid subshell losing MISSING changes.
    # Append `|| true` so grep returning no matches doesn't exit via pipefail.
    while IFS= read -r adapter; do
      [[ -n "$adapter" ]] && add_if_missing "$adapter"
    done < <(grep -oE 'dbt-[a-z]+' "$FILE" 2>/dev/null | sort -u || true)
    ;;
esac

if [[ ${#MISSING[@]} -gt 0 ]]; then
  for pkg in "${MISSING[@]}"; do
    uv add "$pkg" 2>/dev/null || true
  done
fi
