#!/bin/bash
set -euo pipefail

INSTALL_ENV=true
if [ "${1:-}" = "--no-install" ]; then
  INSTALL_ENV=false
  shift
fi
if [ $# -lt 1 ] || [ $# -gt 3 ] || [ -z "$1" ]; then
  echo "Usage: $0 [--no-install] <destination> [<project_name> [<description>]]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if "$INSTALL_ENV" && ! command -v uv > /dev/null 2>&1; then
  echo "Error: uv is required; use --no-install to generate files only." >&2
  exit 1
fi

python3 "$SCRIPT_DIR/scripts/generate.py" "$@"
if "$INSTALL_ENV"; then
  cd -- "$1"
  uv venv --python 3.12 .venv
  uv pip install --python .venv/bin/python -e '.[dev]'
  echo "Project environment ready in $PWD/.venv"
fi
