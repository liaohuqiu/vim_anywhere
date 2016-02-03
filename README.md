# Work with vim anywhere. #

## install ##

### linux ###

Execute the `setup.sh`

    bash setup.sh

### windows ###

You may need to install GVIM in your system first.

After install, copy all the files in the directory `files` to the `$HOME` directory.

If you dont know what is the `$HOME` directory, open GVIM, type the command below:

    :ehco $HOME

It will output something like:

    C:\Users\srain\     // This is the $HOME

####TODO

In mac, should replace the [`Exuberant CTags`](http://www.scholarslab.org/research-and-development/code-spelunking-with-ctags-and-vim/)

    brew install ctags

In Minimum Installation CentOS

    sudo yum install -y ctags

In Ubuntu

    sudo apt-get install exuberant-ctags

### Usage

|keys| usage|
|---|---|
|`ctrl + p` | CtrlP |
|`wm`       | toggle left window|
|`,f`       |   go to first window  |
|`,sp`      | :set paste            |
|`,snp`     |  `:set nopaste`       |
