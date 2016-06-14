# Work with vim anywhere. #

## install ##

### linux ###

Execute the `setup.sh`

    sh setup.sh

### windows ###

You may need to install GVIM in your system first.

After install, copy all the files in the directory `files` to the `$HOME` directory.

If you dont know what is the `$HOME` directory, open GVIM, type the command below:

    :ehco $HOME

It will output something like:

    C:\Users\srain\     // This is the $HOME

### Usage

|keys| usage|
|---|---|
|`ctrl + p` | CtrlP |
|`wm`       | toggle left window|
|`,f`       |   go to first window  |
|`,sp`      | :set paste            |
|`,snp`     |  `:set nopaste`       |
