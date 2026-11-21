#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

DOT_DIR="$ROOT_DIR/dotfiles"

log "Instalando dotfiles em arquivos locais"

for name in bashrc bash_aliases profile; do
  source_file="$DOT_DIR/.$name"
  snippet="$HOME/.paranaues.$name"
  profile="$HOME/.$name"
  include="[ -f \"\$HOME/.paranaues.$name\" ] && . \"\$HOME/.paranaues.$name\""

  if ! cmp -s "$source_file" "$snippet"; then
    install -m 644 "$source_file" "$snippet"
  fi

  # Troca links criados pelos instaladores anteriores, inclusive de outro checkout.
  if [[ -L "$profile" && "$(readlink -- "$profile")" == */ubuntu/dotfiles/."$name" ]]; then
    temporary=$(mktemp "$HOME/.paranaues-profile.XXXXXXXX")
    printf '%s\n' "$include" >"$temporary"
    mv -fT -- "$temporary" "$profile"
  elif [[ -L "$profile" ]]; then
    warn "Mantendo link personalizado: $profile"
  else
    ensure_line "$profile" "$include"
  fi
done
