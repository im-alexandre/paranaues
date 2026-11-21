#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

APT_LIST="${1:-}"
if [[ -z "$APT_LIST" || ! -f "$APT_LIST" ]]; then
  echo "usage: $0 /path/to/apt.txt"
  exit 2
fi

log "Atualizando indices do APT"
sudo apt update

log "Installing apt dependencies"
readarray -t packages < <(grep -vE '^\s*($|#)' "$APT_LIST")
sudo apt install --no-upgrade -y "${packages[@]}"

if ! need_cmd fd; then
  sudo ln -s "$(command -v fdfind)" /usr/local/bin/fd
fi
