#!/usr/bin/env bash
[ ! -d $HOME/.config/nvim/ ] && mkdir -p $HOME/.config/nvim/
[ ! -d $HOME/.config/coc/ ] && mkdir -p $HOME/.config/coc/

ln -f .bashrc $HOME/.bashrc

ln -f init.vim $HOME/.config/nvim/init.vim
ln -f .profile $HOME/.profile

for snippet in `ls *.snippets` ; do
    ln -f $snippet $HOME/.config/nvim/plugged/vim-snippets/snippets/
    echo $snippet
done

