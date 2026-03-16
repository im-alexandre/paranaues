#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing win32yank.exe -> ~/.local/bin (WSL clipboard)"
mkdir -p "$HOME/.local/bin"
if [[ ! -x "$HOME/.local/bin/win32yank.exe" ]]; then
  curl -fsSL -o /tmp/win32yank.zip \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -o /tmp/win32yank.zip -d /tmp >/dev/null
  mv -f /tmp/win32yank.exe "$HOME/.local/bin/win32yank.exe"
  chmod +x "$HOME/.local/bin/win32yank.exe"
  rm -f /tmp/win32yank.zip
fi

BASHRC="$HOME/.bashrc"
ensure_line "$BASHRC" 'export PATH="$HOME/.local/bin:$PATH"'
ensure_block "$BASHRC" '# --- WSL clipboard helpers (win32yank) ---' \
'if grep -qi microsoft /proc/version 2>/dev/null; then
  if command -v win32yank.exe >/dev/null 2>&1; then
    alias clip="win32yank.exe -i"
    alias paste="win32yank.exe -o"
  fi
fi'
