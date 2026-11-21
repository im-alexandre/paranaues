#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

log "Installing NVM + Node LTS"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  warn "A instalação do NVM não criou $NVM_DIR/nvm.sh."
  exit 1
fi

# NVM não suporta errexit; seus scripts também podem acessar variáveis unset.
# Verifique explicitamente as falhas enquanto essas opções estão desativadas.
set +eu
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh" --no-use || exit "$?"

if ! nvm use --lts >/dev/null 2>&1; then
  nvm install --lts || exit "$?"
fi
set -eu
node -v
npm -v
