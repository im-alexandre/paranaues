#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing Rust (rustup)"
if [[ ! -d "$HOME/.cargo" ]]; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
fi

# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup update stable
rustup default stable
rustc -V
cargo -V

log "Installing cargo tools (jinja-lsp)"
cargo install jinja-lsp --locked || true
