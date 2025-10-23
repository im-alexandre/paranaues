#!/usr/bin/env bash

export PARANAUES_DIR=$(dirname $(readlink -f $0))
export DEPS='
curl git wget fd-find 
fzf 
luarocks 
lua5.1 
ripgrep
npm'

export GOPATH=$HOME/.go
export SNAP_DEPS="
go \
nvim \
"

mkdir -p $HOME/.config
git clone https://github.com/im-alexandre/lazyvim_config $HOME/.config/nvim

mkdir -p $HOME/.bin
sudo curl -L https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh -o $HOME/.bin/git-sh-prompt

sudo apt install $DEPS -y
sudo snap install $SNAP_DEPS --classic

go install github.com/jesseduffield/lazygit@latest

echo $PARANAUES_DIR/.bashrc
ln -sf $PARANAUES_DIR/.bashrc $HOME/.bashrc
ln -sf $PARANAUES_DIR/.bash_aliases $HOME/.bash_aliases
ln -sf $PARANAUES_DIR/.profile $HOME/.profile
