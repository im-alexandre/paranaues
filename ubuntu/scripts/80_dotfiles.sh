#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

DOT_DIR="$ROOT_DIR/dotfiles"

log "Symlinking dotfiles (append-only for .bashrc)"

# 1) .bashrc: NÃO substitui. Só garante include do snippet.
BASHRC="$HOME/.bashrc"
SNIPPET="$HOME/.paranaues.bashrc"

# Copia o snippet (ou atualiza)
cp -f "$DOT_DIR/.bashrc" "$SNIPPET"

# Garante include único no ~/.bashrc
INCLUDE_LINE='[ -f "$HOME/.paranaues.bashrc" ] && . "$HOME/.paranaues.bashrc"'
grep -Fqx "$INCLUDE_LINE" "$BASHRC" 2>/dev/null || echo "" >>"$BASHRC"
grep -Fqx "$INCLUDE_LINE" "$BASHRC" 2>/dev/null || echo "$INCLUDE_LINE" >>"$BASHRC"

# 2) .bash_aliases e .profile: mantém como symlink (se você quiser)
ln -sf "$DOT_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOT_DIR/.profile" "$HOME/.profile"
