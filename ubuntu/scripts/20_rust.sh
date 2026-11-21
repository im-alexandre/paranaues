#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing Rust (rustup)"
if [[ ! -x "$HOME/.cargo/bin/rustup" ]]; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
fi

# shellcheck disable=SC1091
source "$HOME/.cargo/env"
if ! rustc -V >/dev/null 2>&1; then
  rustup default stable
fi
rustc -V
cargo -V

log "Installing cargo tools (jinja-lsp)"
if ! need_cmd jinja-lsp; then
  cargo install jinja-lsp --locked
fi
