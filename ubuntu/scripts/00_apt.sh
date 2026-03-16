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

log "APT update/upgrade"
sudo apt update
sudo apt -y upgrade

log "Installing apt dependencies"
# shellcheck disable=SC2046
sudo apt install -y $(grep -vE '^\s*($|#)' "$APT_LIST" | tr '\n' ' ')

log "Fix fd (Ubuntu fornece como fdfind)"
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
