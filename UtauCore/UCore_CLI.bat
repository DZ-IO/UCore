@ECHO OFF
REM  QBFC Project Options Begin
REM HasVersionInfo: Yes
REM Companyname: ZdaTek
REM Productname: ZOSP
REM Filedescription: UCore_CLI-The UTAU Core CLI Version
REM Copyrights: Copyleft ! 2019， 大泽。版权部分所有，遵循GNU GPL v3.0授权使用。
REM Trademarks: 
REM Originalname: UCore_CLI.bat
REM Comments: 项目官网：https://github.com/daze456/UCore
REM Productversion:  0. 1. 0.25
REM Fileversion:  0. 0. 1.24
REM Internalname: UCore
REM ExeType: console
REM Architecture: x86
REM Appicon: 
REM AdministratorManifest: No
REM  QBFC Project Options End
@ECHO ON
@echo off
setlocal enabledelayedexpansion
mkdir %~dp0cache
if exist "%~dp0cache\temp.ini" del /s /q %~dp0cache\temp.ini
if %output%.==. set output=%1.wav
for /f "eol=; tokens=1,2 delims==" %%i in (%~dp0env.ini) do set %%i=%%j
for /f %%i in (%1) do if not %%i.==UST. echo %%i>>%~dp0cache\temp.ini
for /f "delims=" %%i in (%~dp0cache\temp.ini) do (
  set v=%%i
  if "!v:~0,1!"=="[" ( 
    if not %%i==[#TRACKEND] set notes=%%i
  )
)
FOR /F "delims=[#" %%i IN ("%notes%") DO (
    FOR /F "delims=]" %%i IN ("%%i") DO (
        set notes=%%i
    )
)
if %notes%.==SETTING. Start %~dp0UCore.cmd Config
if not %notes%.==SETTING. if not %notes%.==. call %~dp0UCore.cmd %~dp0cache\temp.ini q
:end