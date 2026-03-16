#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Sanity checks"
set +e
echo "nvim:   $(command -v nvim)"; nvim --version | head -n1
echo "rg:     $(command -v rg)"; rg --version | head -n1
echo "fd:     $(command -v fd)"; fd --version 2>/dev/null | head -n1 || true
echo "fzf:    $(command -v fzf)"; fzf --version | head -n1
echo "node:   $(command -v node)"; node -v
echo "npm:    $(command -v npm)"; npm -v
echo "cargo:  $(command -v cargo)"; cargo -V
echo "mamba:  $(command -v mamba)"; mamba --version
echo "python: $(command -v python)"; python -V
set -e
