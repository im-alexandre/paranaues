#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_DIR="$ROOT_DIR/ubuntu/scripts"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_not_root

APPLY_DOTFILES=1
INSTALL_LAZYVIM=1

usage() {
  cat <<'EOF'
usage:
  ./install_paranaues.sh [--no-dotfiles] [--no-lazyvim]

env vars:
  GO_VER=1.22.6
  MINIFORGE_DIR=~/miniforge3
  LAZYVIM_REPO=https://github.com/im-alexandre/lazyvim_config
EOF
}

for arg in "$@"; do
  case "$arg" in
    --no-dotfiles) APPLY_DOTFILES=0 ;;
    --no-lazyvim)  INSTALL_LAZYVIM=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "arg inválido: $arg"; usage; exit 2 ;;
  esac
done

APT_LIST="$ROOT_DIR/ubuntu/dependencies/apt.txt"

"$SCRIPT_DIR/00_apt.sh" "$APT_LIST"
"$SCRIPT_DIR/10_node_nvm.sh"
"$SCRIPT_DIR/20_rust.sh"
"$SCRIPT_DIR/30_go.sh"
"$SCRIPT_DIR/40_nvim.sh"
"$SCRIPT_DIR/50_miniforge.sh"
"$SCRIPT_DIR/60_clipboard.sh"

if [[ "$INSTALL_LAZYVIM" -eq 1 ]]; then
  "$SCRIPT_DIR/70_lazyvim.sh"
fi

if [[ "$APPLY_DOTFILES" -eq 1 ]]; then
  "$SCRIPT_DIR/80_dotfiles.sh"
fi

"$SCRIPT_DIR/90_checks.sh"

log "Done. Reabre o terminal (ou: source ~/.profile && source ~/.bashrc)"
