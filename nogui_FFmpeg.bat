@echo off
title Nogui FFmpeg Encoder
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
set Video_Encode_Quality=22.5
set Video_Encode_Codec=x265
set Video_Encode_Preset=medium
set Output_File_Format=mkv
set Audio_Encode_Quality=4
set Auto_Crop=0
set Resize=0
set "TEMPFILE=%TEMP%\1pQuality2pOpus.log"
set Config_File=config.ini
if exist %Config_File% for /f "tokens=* eol=; delims=" %%i in (%Config_File%) do set "%%i"
if exist %systemroot%\syswow64\cmd.exe goto :x64

:x86
set FFmpeg=%FFmpeg_x86%
goto :Main

:x64
set FFmpeg=%FFmpeg_x64%
goto :Main

:Main
if not exist %FFmpeg% call :Error %FFmpeg%
if defined Error if [%Error%]==[1] goto :End
set /a args+=1
title Encoding %args% of %argC% - Nogui

:Encode
if not exist "%~1" call :ErrorSrc "%~1"
if [%ErrorSrc%]==[1] goto :Next
if exist "%~dpn1_encoded.%Output_File_Format%" move "%~dpn1_encoded.%Output_File_Format%" "%~dpn1_encoded%RANDOM%.%Output_File_Format%"
if exist "%~dpn1_quality.mka" move "%~dpn1_quality.mka" "%~dpn1_quality%RANDOM%.mka"
if [%Auto_Crop%]==[0] goto :Resize
if [%Auto_Crop%]==[] goto :Resize

:Get_Crop_Value
echo. Begins Get_Crop_Value
FOR /F %%v IN ('busybox sh autocrop.sh "%~1"') DO set Auto_Crop_Value=%%v
set "vf=-vf %Auto_Crop_Value%"
echo. Ends Get_Crop_Value

:Resize
if [%Resize%]==[0] goto :Encode_Audio
if [%Resize%]==[] goto :Encode_Audio
if not [%vf%]==[] set "vf=%vf%,"
if [%vf%]==[] set "vf=-vf "
if /I [%Resize%]==[half] goto :Resize_Half
if [%Resize%]==[720] goto :Resize_1280
if [%Resize%]==[1080] goto :Resize_1920

:Resize_Half
set "vf=%vf%scale=iw*.5:ih*.5"
goto :Encode_Audio

:Resize_1280
set "vf=%vf%scale=1280:-2"
goto :Encode_Audio

:Resize_1920
set "vf=%vf%scale=1920:-2"
goto :Encode_Audio

:Encode_Audio
::set FFREPORT=file='%~dpn1_audio_log.log':level=32
echo. Begins Encode_Audio_By_Quality
%FFmpeg% -hide_banner -i "%~1" -vn -sn -c:a libvorbis -aq %Audio_Encode_Quality% "%~dpn1_quality.mka"
echo. Ends Encode_Audio_By_Quality

:getBitrateFromAAC
%FFmpeg% -hide_banner -i "%~dpn1_quality.mka" >nul 2>"%TEMPFILE%"
FOR /F "tokens=8 delims=:, " %%v IN ('find /i "bitrate" "%TEMPFILE%"') DO set /a Audio_Encode_Bitrate=%%v * 3 / 4
set /a Audio_Encode_Bitrate=(%Audio_Encode_Bitrate%/8+1)*8
if 512 lss %Audio_Encode_Bitrate% set /a Audio_Encode_Bitrate=512
if not defined Audio_Encode_Bitrate call :Error Audio_Encode_Bitrate Not Defined.
goto :Encode_Video

:Encode_Video
set FFREPORT=file='%~dpn1_video_log.log':level=32
echo. Begins Encode_Video
set Video_Encode_Codec_lib=lib%Video_Encode_Codec%

REM Example: resize to 480p(?x480)
REM -vf scale=-4:480 -sws_flags lanczos

REM Example: resize to half
REM -vf scale=iw*.5:ih*.5 -sws_flags lanczos

REM Example: resize to 720p(1280x?)
REM -vf scale=1280:-4 -sws_flags lanczos

REM Example: resize to 1080p(1920x?)
REM -vf scale=1920:-4 -sws_flags lanczos

REM Example: Deinterlace
REM -vf bwdif

REM Example: Denoise
REM -vf hqdn3d

REM Example: postprocessing 
REM -vf pp=ac

REM Example: Encode x265 as 10bit
REM -pix_fmt yuv420p10le -profile:v main10
REM set Video_Encode_CommandLine=%FFmpeg%  -hide_banner -i "%~1" -vf cropdetect=4:4 -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -crf %Video_Encode_Quality% -%Video_Encode_Codec%-params pmode=1:ref=4:aq-mode=2:bframes=8:weightb=1:rc-lookahead=120:crf=18 -q:v %Video_Encode_Quality% -af aformat=channel_layouts="7.1|6.1|5.1|stereo|mono" -c:a libopus -b:a %Audio_Encode_Bitrate%k  "%~dpn1_encoded.%Output_File_Format%"
set Video_Encode_CommandLine=%FFmpeg%  -hide_banner -sws_flags lanczos -i "%~1" %vf% -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -crf %Video_Encode_Quality% -%Video_Encode_Codec%-params pmode=1:ref=4:aq-mode=2:bframes=8:subme=3:me=3:keyint=720:min-keyint=1:rc-lookahead=120:crf=%Video_Encode_Quality% -q:v %Video_Encode_Quality% -af aformat=channel_layouts="7.1|6.1|5.1|stereo|mono" -c:a libopus -b:a %Audio_Encode_Bitrate%k  "%~dpn1_encoded.%Output_File_Format%"

if defined Video_Encode_Custom_Option set Video_Encode_CommandLine=%Video_Encoder% -hide_banner -i "%~1" -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -crf %Video_Encode_Quality% -%Video_Encode_Codec%-params crf=%Video_Encode_Quality%:%Video_Encode_Custom_Option% -q:v %Video_Encode_Quality% -af aformat=channel_layouts="7.1|6.1|5.1|stereo|mono" -c:a libopus -b:a %Audio_Encode_Bitrate%k "%~dpn1_encoded.%Output_File_Format%"

%Video_Encode_CommandLine% && del /q /f "%~dpn1_quality.mka"
echo. Ends Encode_Video
del /q /f "%TEMPFILE%"
goto :Next

:Next
shift /1
set ErrorSrc=0
set Error=0
if [%1] == [] goto :EndDateAndTime
if exist "%~1" goto :Main
if not exist "%~1" echo 可能错误的文件名 %1
pause

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

:Error
set Error=1
echo Error: %1 Not Found!
exit /b

:ErrorSrc
set ErrorSrc=1
echo Error: Source File %1 Not Found!
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