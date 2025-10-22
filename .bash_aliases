# Alias para área de transferência
alias "c=xclip -sel clip"
alias "vx=xclip -sel clip -o"
alias "cx=clear"

#alias "neofetch=neofetch --ascii_distro 'linux'"

# Alias para o neovim
alias "v=nvim"
alias "python=python3"
cd() {
  if [ "$1" = "-" ]; then
    builtin cd -
    return
  fi

  if [ -z "$1" ]; then
    builtin cd ~
    return
  fi

  local base_dir="$1"

  # Verifica se é diretório válido
  if [ ! -d "$base_dir" ]; then
    echo "cd: diretório inválido: $base_dir"
    return 1
  fi

  # Cria lista: próprio diretório + subdiretórios
  local target_dir
  target_dir=$( (
    echo "$base_dir"
    fdfind . "$base_dir" \
      --type d \
      --hidden \
      --follow \
      --exclude .git \
      --exclude venv \
      -d 6
  ) | fzf)

  if [ -n "$target_dir" ]; then
    builtin cd "$target_dir"
  fi
}
