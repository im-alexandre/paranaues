#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Sanity checks"
export PATH="${MINIFORGE_DIR:-$HOME/miniforge3}/bin:$HOME/.cargo/bin:/usr/local/go/bin:/snap/bin:$PATH"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# NVM precisa de um novo carregamento porque foi instalado em outro processo.
set +eu
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh" --no-use && nvm use --lts >/dev/null || exit "$?"
set -eu

for tool in nvim rg fd fzf node npm cargo mamba python; do
  if ! need_cmd "$tool"; then
    warn "Comando ausente: $tool"
    exit 1
  fi
  version=$("$tool" --version)
  printf '%s: %s\n' "$tool" "${version%%$'\n'*}"
done
go version
