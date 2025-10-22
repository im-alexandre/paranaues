# Alias para área de transferência
alias "c=xclip -sel clip"
alias "vx=xclip -sel clip -o"
alias "cx=clear"

#alias "neofetch=neofetch --ascii_distro 'linux'"

# Alias para o neovim
alias "v=nvim"
alias "python=python3"
cdf() {
  local base_dir="${1:-.}"
  local target_dir

  target_dir=$(fdfind . "$base_dir" \
    --type d \
    --hidden \
    --follow \
    --exclude .git \
    --exclude venv \
    -d 6 | fzf)

  if [ -n "$target_dir" ]; then
    cd "$target_dir" || echo "Falha ao entrar em $target_dir"
  fi
}
