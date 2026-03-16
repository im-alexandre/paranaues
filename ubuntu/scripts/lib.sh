#!/usr/bin/env bash
set -euo pipefail

log()  { printf "\n\033[1;32m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m[!] %s\033[0m\n" "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

require_not_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Não roda como root. Usa usuário normal (sudo ok)."
    exit 1
  fi
}

ensure_line() {
  local file="$1" line="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

ensure_block() {
  local file="$1" marker="$2" content="$3"
  if ! grep -Fq "$marker" "$file" 2>/dev/null; then
    printf "\n%s\n%s\n" "$marker" "$content" >> "$file"
  fi
}
