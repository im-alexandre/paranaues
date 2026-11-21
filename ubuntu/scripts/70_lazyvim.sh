#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

LAZYVIM_REPO="${LAZYVIM_REPO:-https://github.com/im-alexandre/lazyvim_config}"
TARGET="${TARGET:-$HOME/.config/nvim}"

log "Installing LazyVim config -> $TARGET"
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  log "Mantendo a configuração existente em $TARGET"
  exit 0
fi
mkdir -p "$(dirname -- "$TARGET")"
git clone "$LAZYVIM_REPO" "$TARGET"
