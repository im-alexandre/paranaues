#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing Neovim (prefer snap if available, fallback AppImage)"

if need_cmd nvim; then
  log "Neovim already installed: $(nvim --version | head -n1)"
  exit 0
fi

if need_cmd snap; then
  set +e
  sudo snap install nvim --classic
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    log "Neovim installed via snap"
    nvim --version | head -n1
    exit 0
  fi
  warn "snap install nvim falhou; usando fallback AppImage"
fi

mkdir -p "$HOME/apps/nvim"
appimage="$HOME/apps/nvim/nvim-linux-x86_64.appimage"
curl -fsSL -o "$appimage" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x "$appimage"
sudo ln -sf "$appimage" /usr/local/bin/nvim
nvim --version | head -n1
