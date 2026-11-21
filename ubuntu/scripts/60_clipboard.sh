#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

is_wsl || exit 0

log "Installing win32yank.exe -> ~/.local/bin (WSL clipboard)"
mkdir -p "$HOME/.local/bin"
if [[ ! -x "$HOME/.local/bin/win32yank.exe" ]]; then
  temporary=$(mktemp -d)
  trap 'rm -f -- "$temporary/win32yank.zip" "$temporary/win32yank.exe"; rmdir -- "$temporary"' EXIT
  curl -fsSL -o "$temporary/win32yank.zip" \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -j "$temporary/win32yank.zip" win32yank.exe -d "$temporary" >/dev/null
  chmod +x "$temporary/win32yank.exe"
  mv -f -- "$temporary/win32yank.exe" "$HOME/.local/bin/win32yank.exe"
fi

BASHRC="$HOME/.bashrc"
ensure_line "$BASHRC" 'export PATH="$HOME/.local/bin:$PATH"'
if [[ ! -L "$BASHRC" && ! -f "$HOME/.paranaues.bashrc" ]]; then
  ensure_block "$BASHRC" '# --- WSL clipboard helpers (win32yank) ---' \
'if grep -qi microsoft /proc/version 2>/dev/null; then
  if command -v win32yank.exe >/dev/null 2>&1; then
    alias clip="win32yank.exe -i"
    alias paste="win32yank.exe -o"
  fi
fi'
fi
