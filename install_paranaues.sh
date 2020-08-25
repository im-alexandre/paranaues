#!/usr/bin/env bash
[ ! -d $HOME/.config/nvim/ ] && mkdir -p $HOME/.config/nvim/
[ ! -d $HOME/.config/coc/ ] && mkdir -p $HOME/.config/coc/

ln -f init.vim $HOME/.config/nvim/init.vim

for snippet in `ls *.snippets` ; do
    ln -f $snippet $HOME/.config/nvim/plugged/vim-snippets/snippets/
    echo $snippet
done

