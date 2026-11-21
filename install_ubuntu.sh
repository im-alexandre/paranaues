#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_DIR="$ROOT_DIR/ubuntu/scripts"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

APPLY_DOTFILES=1
INSTALL_LAZYVIM=1

usage() {
  cat <<'EOF'
usage:
  ./install_ubuntu.sh [--no-dotfiles] [--no-lazyvim]

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

require_not_root

APT_LIST="$ROOT_DIR/ubuntu/dependencies/apt.txt"

bash "$SCRIPT_DIR/00_apt.sh" "$APT_LIST"

if [[ "$APPLY_DOTFILES" -eq 1 ]]; then
  bash "$SCRIPT_DIR/80_dotfiles.sh"
fi

for script in 10_node_nvm 20_rust 30_go 40_nvim 50_miniforge 60_clipboard; do
  bash "$SCRIPT_DIR/$script.sh"
done

if [[ "$INSTALL_LAZYVIM" -eq 1 ]]; then
  bash "$SCRIPT_DIR/70_lazyvim.sh"
fi

bash "$SCRIPT_DIR/90_checks.sh"

log "Done. Reabre o terminal (ou: source ~/.profile && source ~/.bashrc)"
