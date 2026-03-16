# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.bin" ]; then
  PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.fzf/bin" ]; then
  PATH="$HOME/.fzf/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Só faz o source do .bashrc se ainda não tiver sido feito
if [ -f "$HOME/.bashrc" ] && [ -z "$BASHRC_SOURCED" ]; then
  export BASHRC_SOURCED=1
  . "$HOME/.bashrc"
fi

export GOPATH=$HOME/.go
export GOBIN=$GOPATH/bin

export PATH=$PATH:$GOBIN
# export PATH=$PATH:/opt/node/bin

[[ -f ~/.credenciais.sh ]] && source ~/.credenciais.sh

export GTK_IM_MODULE=cedilla
export QT_IM_MODULE=cedilla
export VIM_APP_DIR=/usr
set -o vi
export VISUAL=nvim
export EDITOR="$VISUAL"
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git --exclude venv'
