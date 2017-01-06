@echo off
title Nogui
setlocal EnableExtensions
setlocal EnableDelayedExpansion
color 1f
if [%1]==[] echo 需要把片源或者AVS拖到EXE文件上&&goto :end


:BeginDateAndTime
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

CD /D "%~dp0"
pushd "%~dp0"

:Main
if exist "%~dpn1_crf.mkv" ren "%~dpn1_crf.mkv" "%~dpn1_crf%RANDOM%.mkv"
if exist "%~dpn1_crf.264" ren "%~dpn1_crf.264" "%~dpn1_crf%RANDOM%.mp4"
if exist "%~dpn1_aac.m4a" ren "%~dpn1_aac.m4a" "%~dpn1_aac%RANDOM%.m4a"
ffmpeg -hide_banner -i "%~1" -c:a pcm_f32le -f wav - | neroaacenc -q 0.1 -ignorelength -if - -of "%~dpn1_aac.m4a"
echo.

x264_64.exe --crf 40 --preset 5 --fps 30 -o "%~dpn1_crf.264" "%~1"
echo.

:Clean
mkvmerge.exe -o "%~dpn1_crf.mkv" "%~dpn1_crf.264" "%~dpn1_aac.m4a"
if exist "%~dpn1_crf.mkv" (
del /f /q "%~dpn1_aac.m4a"
del /f /q "%~dpn1_crf.264"
)
echo.
shift /1
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