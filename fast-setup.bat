@echo off
setlocal enabledelayedexpansion

REM 获取脚本所在目录
set "__root_dir=%~dp0"
set "__root_dir=%__root_dir:~0,-1%"

set "vim_config_dir=%USERPROFILE%\.vim"
set "vim_rc=%USERPROFILE%\.vimrc"

REM 执行命令并显示
:exe_cmd
echo %1
%1
goto :eof

REM 确保目录存在
:ensure_dir
if not exist "%~1" (
    call :exe_cmd "mkdir "%~1""
)
goto :eof

REM 备份并清理
:backup_and_clean
for /f "tokens=1-6 delims=/: " %%a in ('echo %date% %time%') do (
    set "d=%%c%%a%%b-%%d%%e%%f"
)
set "backup_dir=%USERPROFILE%\.vimbackup\%d%"
call :ensure_dir "%backup_dir%"

if exist "%vim_rc%" (
    call :exe_cmd "move "%vim_rc%" "%backup_dir%\.vimrc""
)

if exist "%vim_config_dir%" (
    call :exe_cmd "xcopy "%vim_config_dir%" "%backup_dir%\.vim" /E /I /Y"
    call :exe_cmd "rmdir /S /Q "%vim_config_dir%""
)
goto :eof

REM 复制新配置
:copy_new_config
call :exe_cmd "copy "%__root_dir%\files\_vimrc" "%vim_rc%""

call :ensure_dir "%vim_config_dir%"
call :exe_cmd "xcopy "%__root_dir%\files\vimfiles\*" "%vim_config_dir%" /E /I /Y"
call :exe_cmd "xcopy "%__root_dir%\3rd\bundle" "%vim_config_dir%\bundle" /E /I /Y"
goto :eof

REM 主执行流程
call :backup_and_clean
call :copy_new_config
call :exe_cmd "vim +PluginInstall +qall"

echo 安装完成！
pause
