#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing Miniforge (mamba) -> ~/miniforge3"
MINIFORGE_DIR="${MINIFORGE_DIR:-$HOME/miniforge3}"

if [[ ! -d "$MINIFORGE_DIR" ]]; then
  curl -fsSL -o /tmp/miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash /tmp/miniforge.sh -b -p "$MINIFORGE_DIR"
  rm -f /tmp/miniforge.sh
fi

# init conda (bash), no auto base
if [[ -f "$MINIFORGE_DIR/etc/profile.d/conda.sh" ]]; then
  # shellcheck disable=SC1091
  source "$MINIFORGE_DIR/etc/profile.d/conda.sh"
  conda config --set auto_activate_base false >/dev/null 2>&1 || true
  if ! conda list -n base | awk '{print $1}' | grep -qx mamba; then
    conda install -n base -y mamba >/dev/null
  fi
fi

"$MINIFORGE_DIR/bin/python" -m pip install -U pip >/dev/null
"$MINIFORGE_DIR/bin/python" -m pip install -U ruff black isort pytest >/dev/null

PROFILE="$HOME/.profile"
ensure_line "$PROFILE" 'export PATH="$HOME/miniforge3/bin:$PATH"'
