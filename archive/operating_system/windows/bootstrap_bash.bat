@echo off

set cygwin_setup_executable=cygwin_setup-x86_64.exe
set cygwin_root=H:\my\scripts\env\cygwin

mkdir %cygwin_root%

curl.exe https://cygwin.com/setup-x86_64.exe --output %cygwin_setup_executable%

%cygwin_setup_executable% ^
--no-desktop ^
--quiet-mode ^
--wait ^
--packages ^
bzip2,^
make,^
dos2unix,^
unzip,^
wget,^
curl,^
vim,^
svn,^
git ^
--site https://ftp.fau.de/cygwin/ ^
--root %cygwin_root%

del %cygwin_setup_executable%

cd %cygwin_root%\bin
bash.exe --login -c "mkdir -p $HOME/my/tools"
bash.exe --login -c "cd $HOME/my/tools && git clone https://github.com/transcode-open/apt-cyg.git"
