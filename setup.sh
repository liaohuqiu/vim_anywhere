#!/bin/bash
function exe_cmd() {
    echo $1
    eval $1
}

root_dir=`pwd`

vim_alias_dir=$HOME/.vim
vim_rc=$HOME/.vimrc
d=`date +%Y%m%d-%H%M%S`

if [ -e $vim_alias_dir ]; then
    exe_cmd "cp -R  $vim_alias_dir  $HOME/vim_${d}"
    exe_cmd "rm -r $vim_alias_dir"
fi 

if [ -e $vim_rc ]; then
    exe_cmd "mv $vim_rc  $HOME/vimrc_${d}"
fi

exe_cmd "ln -sf $root_dir/files/vimfiles  $vim_alias_dir"
exe_cmd "ln -sf $root_dir/files/_vimrc $vim_rc"

exe_cmd 'git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim'
exe_cmd 'vim +PluginInstall +qall'
