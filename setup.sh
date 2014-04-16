#!/bin/bash
function exe_cmd() {
    echo $1
    eval $1
}

root_dir=`pwd`

vim_alias_dir=$HOME/.vim
if[ -e $vim_alias_dir ];then
    d=`date +%Y%m%d`
    cp -R  $vim_alias_dir  $HOME/vim_${d} 
    cp $HOME/.vimrc  $HOME/vimrc_${d}
fi 
if [ -e $vim_alias_dir ]; then
    exe_cmd "rm -r $vim_alias_dir"
fi
exe_cmd "ln -sf $root_dir/files/vimfiles  $vim_alias_dir"
exe_cmd "ln -sf $root_dir/files/_vimrc $HOME/.vimrc"

