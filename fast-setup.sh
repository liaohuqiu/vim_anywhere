#!/bin/bash

__root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

vim_config_dir=$HOME/.vim
vim_rc=$HOME/.vimrc

function exe_cmd() {
    echo $1
    eval $1
}

function ensure_dir() {
    if [ ! -d $1 ]; then
        exe_cmd "mkdir -p $1"
    fi
}

function backup_and_clean() {
    local d=`date +%Y%m%d-%H%M%S`
    local backup_dir="$HOME/.vimbackup/${d}"
    ensure_dir $backup_dir

    if [ -e $vim_rc ]; then
        exe_cmd "mv $vim_rc  $backup_dir/.vimrc"
    fi

    if [ -e $vim_config_dir ]; then
        exe_cmd "cp -R $vim_config_dir $backup_dir/.vim"
        exe_cmd "rm -rf $vim_config_dir"
    fi 
}

function copy_new_config() {
    exe_cmd "cp $__root_dir/files/_vimrc $vim_rc"

    ensure_dir $vim_config_dir
    exe_cmd "cp -R $__root_dir/files/vimfiles/*  $vim_config_dir/"
    # exe_cmd "cp -R $__root_dir/3rd/bundle $vim_config_dir/"
}

backup_and_clean
copy_new_config
exe_cmd 'vim +PluginInstall +qall'
