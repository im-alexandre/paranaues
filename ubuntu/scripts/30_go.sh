#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

GO_VER="${GO_VER:-1.22.6}"

log "Installing Go (prefer snap if available, fallback tarball)"

if need_cmd go; then
  log "Go already installed: $(go version)"
  exit 0
fi

if need_cmd snap; then
  set +e
  sudo snap install go --classic
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    log "Go installed via snap"
    go version
    exit 0
  fi
  warn "snap install go falhou; usando fallback tarball"
fi

url="https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz"
tmp="/tmp/go.tgz"
curl -fsSL "$url" -o "$tmp"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$tmp"
rm -f "$tmp"

# Ensure PATH and GOPATH
PROFILE="$HOME/.profile"
ensure_line "$PROFILE" 'export GOPATH="$HOME/.go"'
ensure_line "$PROFILE" 'export PATH="/usr/local/go/bin:$HOME/.go/bin:$HOME/.local/bin:$PATH"'

export GOPATH="$HOME/.go"
export PATH="/usr/local/go/bin:$HOME/.go/bin:$HOME/.local/bin:$PATH"

go version
