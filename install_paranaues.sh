#!/usr/bin/env bash
[ ! -d $HOME/.config/nvim/ ] && mkdir -p $HOME/.config/nvim/
[ ! -d $HOME/.config/coc/ ] && mkdir -p $HOME/.config/coc/
[ ! -d $HOME/.config/nvim/plugged/vim-snippets/snippets/ ] && mkdir -p $HOME/.config/nvim/plugged/vim-snippets/snippets/

cp -r ranger ~/.config/ranger
ln -f ~/paranaues/.bashrc $HOME/.bashrc
ln -f ~/paranaues/.bash_aliases $HOME/.bash_aliases


ln -f ~/paranaues/init.vim $HOME/.config/nvim/init.vim
ln -f ~/paranaues/.profile $HOME/.profile
ln -sf ~/paranaues/scripts $HOME/.bin

for snippet in `ls snippets/` ; do
    ln -sf $HOME/paranaues/snippets/$snippet $HOME/.config/nvim/plugged/vim-snippets/snippets/
    echo $snippet
done

