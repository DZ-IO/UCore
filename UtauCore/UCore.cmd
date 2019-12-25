@echo off
setlocal enabledelayedexpansion
if %1.==. (
    echo msgbox "请双击'双击安装'安装UCore！",64,"提示">alert.vbs 
    start /w alert.vbs
    del alert.vbs
    exit
)
if %1.==Config. goto %1
goto Synth

:Synth
title UCore合成中

for /f %%i in ('%~dp0rini %1 #SETTING ProjectName') do set ProjectName=%%i
title %ProjectName% - UCore合成中
for /f %%i in ('%~dp0rini %1 #SETTING Tempo') do set tempo=%%i
set samples=44100
for /f %%i in ('%~dp0rini %1 #SETTING VoiceDir') do IF EXIST %%i\* set oto=%%i
for /f %%i in ('%~dp0rini %1 #SETTING Tool1') do IF EXIST %%i set tool=%%i
for /f %%i in ('%~dp0rini %1 #SETTING Tool2') do IF EXIST %%i set resamp=%%i
if %cachedir%.==. for /f %%i in ('%~dp0rini %1 #SETTING CacheDir') do IF not %%i.==. set cachedir=%%i
if %cachedir%.==. set cachedir=%~dp0cache
mkdir %cachedir%
set helper=%~dp0helper.bat
@set flag=""
@set env=0 5 35 0 100 100 0
@set stp=0

@del "!output!" 2>nul
@mkdir "!cachedir!" 2>nul
if exist "%cachedir%\*.wav" del /s /q %cachedir%\*.wav
if exist "%output%.whd" del "%output%.whd"
if exist "%output%.dat" del "%output%.dat"

cls
echo [INFO]曲速：!tempo!
echo [INFO]音源：!oto!
echo [INFO]工具1：!tool!
echo [INFO]工具2：!resamp!

for /f "delims=" %%i in (%1) do (
  set v=%%i
  if "!v:~0,1!"=="[" if not !v!==[#SETTING] if not !v!==[#TRACKEND] if not !v!==[#VERSION] CALL :rsynth !v! %1
)
if not exist "%output%.whd" goto E
if not exist "%output%.dat" goto E
copy /Y "%output%.whd" /B + "%output%.dat" /B "%output%"
del "%output%.whd"
del "%output%.dat"
goto :OK
:E
echo [ERR]合成出现错误
:OK
if %2.==q. goto end
pause
exit

:rsynth
FOR /F "delims=[#" %%i IN ("%1") DO FOR /F "delims=]" %%i IN ("%%i") DO (
  set num=%%i
  echo.
  title [!num!/!notes!]%ProjectName% - UCore合成中
  echo [INFO]当前进度:!num!/!notes!
  CALL :synthmain %2
)
goto :eof

:synthmain
for /f %%i in ('%~dp0rini %1 #!num! Length') do set Length=%%i
echo [INFO]长度:!Length!
for /f %%i in ('%~dp0rini %1 #!num! Lyric') do set Lyric=%%i
if !Lyric!==R (
  echo [INFO]R
  echo [INFO]执行:"!tool!" "!output!" "!oto!\R.wav" 0 !Length!@!tempo!+.0 0 0
  "!tool!" "!output!" "!oto!\R.wav" 0 !Length!@!tempo!+.0 0 0
) else (
  echo [INFO]歌词:!Lyric!
  call :synthnote %1
)
goto :eof

:synthnote
for /f %%i in ('%~dp0rini %1 #!num! NoteNum') do set NoteNum=%%i
for /f "eol=; tokens=1,2 delims==" %%i in (%~dp0notes.txt) do if %%j==%NoteNum% set NoteNum=%%i
echo [INFO]音符:!NoteNum!
for /f %%i in ('%~dp0rini %1 #!num! Velocity') do set vel=%%i
echo [INFO]速度:!vel!
set params=100 100 %%tempo! AA#35#ABABACACADADAEAFAFAGAGAH#4#AGAGAFAEADACAA///9/8/6/4/2/1/z/y/w/v/u/u/t/t/u/u/v/w/y/0/2/4/7/+AA#13#
set env=10 139 35 101 101 101 0 0 0
set temp="!cachedir!\!num!_!lyric!_!NoteNum!.wav"
echo [INFO]执行:!helper! "!oto!\!lyric!.wav" !NoteNum! !Length!@!tempo!+.0 0 0.0 400 80.0 197.0 0
call !helper! "!oto!\!lyric!.wav" !NoteNum! !Length!@!tempo!+.0 0 0.0 400 80.0 197.0 0
goto :eof

:Config
mode con: cols=50 lines=4
title UCore错误
ECHO [ERR]您输入的是空文件！
if %2.==q. goto end
pause
exit

:end