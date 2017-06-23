@echo off
title Nogui
setlocal EnableExtensions EnableDelayedExpansion
color 1f
pushd "%~dp0"
set args=0
call :getargc argC %*

:Default_Config
set Video_Encode_Codec=x265
set Video_Encode_Quality=21
set Video_Encode_Preset=slow
set Output_File_Format=mkv
set Audio_Encode_Codec=opus
set Audio_Encode_Quality=3
set Auto_Crop=0
set Resize=0

:Import_Config
set Config_File=config.ini
set Locale_File=locale\en.ini
FOR /F "tokens=3" %%a IN ('reg query "HKCU\Control Panel\Desktop" /v PreferredUILanguages ^| find "PreferredUILanguages"') DO set UILanguage=%%a
if "%UILanguage%"=="zh-CN" set Locale_File=locale\zh.ini
if exist %Config_File% for /f "tokens=* eol=; delims=" %%i in (%Config_File%) do set "%%i"
if exist %Locale_File% for /f "tokens=* eol=; delims=" %%i in (%Locale_File%) do set "%%i"

:Check_Input
if [%1]==[] goto :Input
if not exist %1 goto :Input
goto :Init

:Input
set /p "_f=%lc_Input%:"
if [%_f%]==[] goto :Input
if not exist %_f% goto :Input
if exist %_f% start "" "%~0" %_f%
exit /b

:Init
call bin\timer_begin.bat

:Check_Bits
if exist %systemroot%\syswow64\cmd.exe goto :x64

:x86
set "Bin=%~dp0bin32"
goto :Main

:x64
set "Bin=%~dp0bin64"
goto :Main

:Main
if not exist "%Bin%\ffmpeg.exe" call :Error "%Bin%\ffmpeg.exe"
if "%Audio_Encode_Codec%"=="fdkaac" if not exist "%Bin%\fdkaac.exe" call :Error "%Bin%\fdkaac.exe"
if not exist "bin\busybox.exe" call :Error "bin\busybox.exe"
if not exist "bin\nogui.sh" call :Error "bin\nogui.sh"
if defined Error if [%Error%]==[1] goto :End
set /a args+=1
title %lc_Encoding% %args% %lc_Encoding_of% %argC% - Nogui

set CommandLine=bin\busybox.exe sh bin\nogui.sh -b="%Bin%" -i="%~1" -o="%~dpn1_encoded.%Output_File_Format%" -ve=%Video_Encode_Codec% -crf=%Video_Encode_Quality% -vp=%Video_Encode_Preset% -ae=%Audio_Encode_Codec% -aq=%Audio_Encode_Quality% 

if defined Log_File set "CommandLine=%CommandLine% -l=%Log_File%"
if defined Nogui_Preset set "CommandLine=%CommandLine% -p=%Nogui_Preset%"
if defined Resize if "%Resize%" neq "0" set "CommandLine=%CommandLine% -s=%Resize%"
if defined Auto_Crop if "%Auto_Crop%" neq "0" set "CommandLine=%CommandLine% --autocrop"
if defined Video_Encode_Custom_Params set "CommandLine=%CommandLine% -va=%Video_Encode_Custom_Params%"
if defined Pixel_Format set "CommandLine=%CommandLine% --pixfmt==%Pixel_Format%"
if defined Audio_Encode_Profile set "CommandLine=%CommandLine% -ap=%Audio_Encode_Profile%"
if defined Audio_Encode_Channels if "%Audio_Encode_Channels%" neq "0" set "CommandLine=%CommandLine% -ac=%Audio_Encode_Channels%"

if defined Encode_Type if "%Encode_Type%"=="Video" set "CommandLine=%CommandLine% -v"
if defined Encode_Type if "%Encode_Type%"=="Audio" set "CommandLine=%CommandLine% -a"
%CommandLine%
goto :Next

:Next
shift /1
set ErrorSrc=0
set Error=0
if [%1] == [] goto :End
if exist "%~1" goto :Main
if not exist "%~1" echo %lc_Error_Wrong_File% %1
pause

:End
call bin\timer_end.bat
pause
exit /B

:Error
set Error=1
echo %lc_Error%: %1 %lc_Error_Not_Found%!
exit /b

:ErrorSrc
set ErrorSrc=1
echo %lc_Error%: %lc_Error_Source_File% %1 %lc_Error_Not_Found%!
exit /b

REM http://stackoverflow.com/a/1292079/6848772
:getargc
    set getargc_v0=%1
    set /a "%getargc_v0% = 0"
:getargc_l0
    if not x%2x==xx (
        shift
        set /a "%getargc_v0% = %getargc_v0% + 1"
        goto :getargc_l0
    )
    set getargc_v0=
exit /B