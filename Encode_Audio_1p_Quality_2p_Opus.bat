@echo off
title FFmpeg 1p Quality 2p Opus Audio Encoder
setlocal EnableExtensions EnableDelayedExpansion
color 1f
if [%1]==[] goto :Input
if not exist %1 goto :Input
goto :BeginDateAndTime

:Input
set /p "_f=把片源拖到此处并回车:"
if [%_f%]==[] goto :Input
if not exist %_f% goto :Input
if exist %_f% start %0 %_f%
exit /b

:BeginDateAndTime
set args=0
call :getargc argC %*
set start=%time%
SET startdate=%date%
FOR /F "DELIMS=" %%T IN ('TIME /T') DO SET starttime=%%T
SET @HOUR=%starttime:~0,2%
SET @SUFFIX=%starttime:~5,1%
IF /I "%@SUFFIX%"=="A" IF %@HOUR% EQU 12 SET @HOUR=00
IF /I "%@SUFFIX%"=="P" IF %@HOUR% LSS 12 SET /A @HOUR=%@HOUR% + 12
SET @NOW=%@HOUR%%starttime:~3,2%
SET @NOW=%@NOW: =0%
set Year=
for /f "skip=2" %%x in ('wmic Path Win32_LocalTime get Year^,Month^,Day^,Hour^,Minute^,Second /Format:List') do (
  if not defined Year set %%x
)
if %Hour% LSS 12 (
  set ampm=AM
  if %Hour%==0 set Hour=12
) else (
  set ampm=PM
  set /a Hour-=12
)
if %Minute% LSS 10 set Minute=0%Minute%
if %Hour% LSS 10 set Hour=0%Hour%
if %Second% LSS 10 set Second=0%Second%
set StartTimestamp=%Hour%:%Minute%:%Second% %ampm%
SET StartTimestamp1=%time:~0,2%:%time:~3,2%:%Second%
echo 进程开始于 %startdate% // %StartTimestamp% -- %StartTimestamp1% //

:Init
CD /D "%~dp0"
pushd "%~dp0"
set FFmpeg_x64=ffmpeg_hi.exe
set FFmpeg_x86=ffmpeg.exe
set Audio_Encode_Quality=4
set "TEMPFILE=%TEMP%\1pQuality2pOpus.log"
if exist %systemroot%\syswow64\cmd.exe goto :x64

:x86
set FFmpeg=%FFmpeg_x86%
goto :Main

:x64
set FFmpeg=%FFmpeg_x64%
goto :Main

:Error
type %TEMPFILE%
echo. Error : %*
pause
exit

:Main
if exist "%~dpn1_quality.mka" move "%~dpn1_quality.mka" "%~dpn1_quality%RANDOM%.mka"
if exist "%~dpn1_opus.mka" move "%~dpn1_opus.mka" "%~dpn1_opus%RANDOM%.mka"

:Encode_By_Quality
echo. Begins Encode_By_Quality
%FFmpeg% -hide_banner -i "%~1" -vn -sn -to 300 -c:a libvorbis -aq %Audio_Encode_Quality% "%~dpn1_quality.mka"
echo. Ends Encode_By_Quality

:getBitrateFromAAC
%FFmpeg% -hide_banner -i "%~dpn1_quality.mka" >nul 2>"%TEMPFILE%"
FOR /F "tokens=8 delims=:, " %%v IN ('find /i "bitrate" "%TEMPFILE%"') DO set /a Audio_Encode_Bitrate=%%v * 3 / 4
set /a Audio_Encode_Bitrate=(%Audio_Encode_Bitrate%/8+1)*8
if 512 lss %Audio_Encode_Bitrate% set /a Audio_Encode_Bitrate=512
if not defined Audio_Encode_Bitrate call :Error Audio_Encode_Bitrate Not Defined.

:Encode_Opus
echo. Begins Encode_Opus
%FFmpeg% -hide_banner -i "%~1" -vn -sn -to 300 -af aformat=channel_layouts="7.1|6.1|5.1|stereo|mono" -c:a libopus -b:a %Audio_Encode_Bitrate%k "%~dpn1_opus.mka" && del /q /f "%~dpn1_quality.mka"
echo. Ends Encode_Opus
del /q /f "%TEMPFILE%"
goto :Next

:Next
shift /1
set ErrorSrc=0
set Error=0
if [%1] == [] goto :EndDateAndTime
if exist %1 goto :Main

:EndDateAndTime
set end=%time%
set options="tokens=1-4 delims=:."
for /f %options% %%a in ("%start%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%end%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %hours% lss 0 set /a hours = 24%hours%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if 1%ms% lss 100 set ms=0%ms%
set /a totalsecs = %hours%*3600 + %mins%*60 + %secs% 
SET enddate=%date%
FOR /F "DELIMS=" %%T IN ('TIME /T') DO SET endtime=%%T
SET @HOUR=%endtime:~0,2%
SET @SUFFIX=%endtime:~5,1%
IF /I "%@SUFFIX%"=="A" IF %@HOUR% EQU 12 SET @HOUR=00
IF /I "%@SUFFIX%"=="P" IF %@HOUR% LSS 12 SET /A @HOUR=%@HOUR% + 12
SET @NOW=%@HOUR%%endtime:~3,2%
SET @NOW=%@NOW: =0%
set Year=
for /f "skip=2" %%x in ('wmic Path Win32_LocalTime get Year^,Month^,Day^,Hour^,Minute^,Second /Format:List') do (
  if not defined Year set %%x
)
if %Hour% LSS 12 (
  set ampm=AM
  if %Hour%==0 set Hour=12
) else (
  set ampm=PM
  set /a Hour-=12
)
if %Minute% LSS 10 set Minute=0%Minute%
if %Hour% LSS 10 set Hour=0%Hour%
if %Second% LSS 10 set Second=0%Second%
set EndTimestamp=%Hour%:%Minute%:%Second% %ampm%
SET EndTimestamp1=%time:~0,2%:%time:~3,2%:%Second%
echo:
echo 进程完成于 %date% // %EndTimestamp% -- %EndTimestamp1% //
IF %mins% GEQ 1 (
goto :WithMinutes
) else ( 
goto :WithoutMinutes
)

:WithMinutes
set /a hrs=%totalsecs%/3600
if %hrs% GEQ 1 goto :WithHours
echo 进程耗时 %mins%分钟%secs%秒（共计%totalsecs%秒）。
goto :End
:WithHours
echo 进程耗时 %hrs%小时%mins%分钟%secs%秒（共计%totalsecs%秒）。
goto :End
:WithoutMinutes
echo 进程耗时 %totalsecs% 秒。

:End
pause
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