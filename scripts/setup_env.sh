#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
VENV_DIR="../.venv"
ROOT_REQUIREMENTS="../requirements.txt"
REQUIREMENTS_FILES=(
  "$ROOT_REQUIREMENTS"
  "../api/requirements.txt"
  "../consumer/requirements.txt"
)

if [ ! -f "$ROOT_REQUIREMENTS" ]; then
  echo "requirements.txt not found in $ROOT_DIR" >&2
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtual environment at $VENV_DIR..."
  python3 -m venv "$VENV_DIR" 2>/dev/null || python -m venv "$VENV_DIR"
fi

if [ ! -f "$VENV_DIR/bin/activate" ]; then
  echo "Could not find the activation script in the venv." >&2
  exit 1
fi

echo "Activating virtual environment..."
# shellcheck source=/dev/null
. "$VENV_DIR/bin/activate"

echo "Updating pip..."
python -m pip install --upgrade pip

for requirements_file in "${REQUIREMENTS_FILES[@]}"; do
  if [ ! -f "$requirements_file" ]; then
    echo "Skipping missing requirements file: $requirements_file"
    continue
  fi

  echo "Installing dependencies from $(basename "$requirements_file")..."
  python -m pip install -r "$requirements_file"
done

echo "Environment ready. The venv is activated in this session."