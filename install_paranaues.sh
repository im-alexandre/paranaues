#!/usr/bin/env bash
[ ! -d $HOME/.config/nvim/ ] && mkdir -p $HOME/.config/nvim/
[ ! -d $HOME/.config/coc/ ] && mkdir -p $HOME/.config/coc/
[ ! -d $HOME/.bin ] && mkdir -p $HOME/.bin
[ ! -d $HOME/.config/nvim/plugged/vim-snippets/snippets/ ] && mkdir -p $HOME/.config/nvim/plugged/vim-snippets/snippets/

ln -f .bashrc $HOME/.bashrc
ln -f .bash_aliases $HOME/.bash_aliases

ln -f init.vim $HOME/.config/nvim/init.vim
ln -f .profile $HOME/.profile
ln -sf scripts $HOME/.bin

for snippet in `ls *.snippets` ; do
    ln -f $snippet $HOME/.config/nvim/plugged/vim-snippets/snippets/
    echo $snippet
done

