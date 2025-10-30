#!/usr/bin/env bash

export PARANAUES_DIR=$(dirname $(readlink -f $0))
export DEPS='
curl git wget fd-find 
fzf 
luarocks 
xclip
lua5.1 
ripgrep
npm
make
g++
gcc
build-essential
nodejs'

export GOPATH=$HOME/.go
# Lê o ID da distro
distro_id=$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)

if [[ "$distro_id" == "ubuntu" ]]; then
  export SNAP_DEPS='
  go
  nvim
  '
  echo "Executando bloco específico para Ubuntu..."
  sudo apt update && sudo apt upgrade -y
  sudo apt install $DEPS -y
  for $DEP in $SNAP_DEPS; do
    sudo snap install $DEP --classic
  done
  go install github.com/jesseduffield/lazygit@latest
else
  echo "Este sistema não é Ubuntu. Pulando bloco..."
fi

mkdir -p $HOME/.config
git clone https://github.com/im-alexandre/lazyvim_config $HOME/.config/nvim

mkdir -p $HOME/.bin
sudo curl -L https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh -o $HOME/.bin/git-sh-prompt

echo $PARANAUES_DIR/.bashrc
ln -sf $PARANAUES_DIR/.bashrc $HOME/.bashrc
ln -sf $PARANAUES_DIR/.bash_aliases $HOME/.bash_aliases
ln -sf $PARANAUES_DIR/.profile $HOME/.profile
