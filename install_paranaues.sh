#!/usr/bin/env bash
export DEPS="
curl 
git 
wget
fd-find
fzf
compton
i3
i3-wm
i3lock
i3status
suckless-tools
arandr
blueman
luarocks
xautolock
maim
"

export PARANAUES_DIR=`dirname $(readlink -f $0)`

for DEP in $DEPS ; do
    if  (! command -v $DEP &> /dev/null); then 
            sudo apt install $DEP -y
    fi
done


ln -sf $PARANAUES_DIR/.bashrc $HOME/.bashrc
ln -sf $PARANAUES_DIR/.bash_aliases $HOME/.bash_aliases

[[ ! -d $HOME/.config/i3 ]] && ln -sf $PARANAUES_DIR/config/i3 $HOME/.config/i3
ln -sf $PARANAUES_DIR/config/compton.conf $HOME/.config/compton.conf
ln -sf $PARANAUES_DIR/config/i3status.conf $HOME/.config/i3status/config


[[ ! -d $HOME/.config/nvim ]] && ln -sf $PARANAUES_DIR/vim $HOME/.config/nvim

ln -sf $PARANAUES_DIR/.profile $HOME/.profile
[[ ! -d $HOME/.bin ]] && ln -sf $PARANAUES_DIR/scripts $HOME/.bin
