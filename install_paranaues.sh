#!/usr/bin/env bash
export DEPS="curl git wget"

for DEP in $DEPS ; do
    if  ( command -v $DEP &> /dev/null); then 
            sudo apt install $DEP -y
    fi
done

PARANAUES_DIR=`pwd`

[[ ! -d ~/.config/nvim ]] && mkdir ~/.config/nvim
[[ ! -d ~/.config/nvim/lua ]] && ln -sf $PARANAUES_DIR/vim/lua ~/.config/nvim/lua


ln -sf $PARANAUES_DIR/.bashrc $HOME/.bashrc
ln -sf $PARANAUES_DIR/.bash_aliases $HOME/.bash_aliases


ln -sf $PARANAUES_DIR/vim/init.vim $HOME/.config/nvim/init.vim

ln -sf $PARANAUES_DIR/.profile $HOME/.profile
[[ ! -d ~/.bin ]] && ln -sf $PARANAUES_DIR/scripts $HOME/.bin
