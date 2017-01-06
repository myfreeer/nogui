@echo off
title Nogui
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
set FFmpeg_x64=ffmpeg_64.exe
set FFmpeg_x86=ffmpeg.exe
set Video_Encoder_x64=ffmpeg_64.exe
set Video_Encoder_x86=ffmpeg.exe
set Video_Encode_Quality=23
set Video_Encode_Codec=x265
set Video_Encode_Preset=medium
set Audio_Encoder=neroAacEnc.exe
set Audio_Encode_Quality=0.25
set Audio_Encode_Bitrate=64k
set Output_File_Format=mkv
if exist config.ini for /f "tokens=* eol=; delims=" %%i in (config.ini) do set "%%i"
if exist %systemroot%\syswow64\cmd.exe goto :x64

:x86
set FFmpeg=%FFmpeg_x86%
set Video_Encoder=%Video_Encoder_x86%
goto :Main

:x64
set FFmpeg=%FFmpeg_x64%
set Video_Encoder=%Video_Encoder_x64%
goto :Main

:Main
for %%i in (%FFmpeg%,%Video_Encoder%) do if not exist %%i call :Error %%i
if defined Error if [%Error%]==[1] goto :End
set /a args+=1
title Encoding %args% of %argC% - Nogui
echo %Video_Encoder% | find /i "ffmpeg">nul && goto :ffmpeg
echo %Video_Encoder% | find /i "x264">nul && goto :x264
echo %Video_Encoder% | find /i "x265">nul && goto :x265
echo %Video_Encoder% | find /i "handbrake">nul && goto :handbrake
echo Error: %Video_Encoder% Not Supported or find.exe not available in your system
pause
exit

:ffmpeg
set Video_Encode_Codec_lib=lib%Video_Encode_Codec%
set Video_Encode_CommandLine=%Video_Encoder% -hide_banner -i "%~1" -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -%Video_Encode_Codec%-params no-sao=1:merange=44:aq-mode=1:aq_strength=0.8:psy-rd=1.5:psy-rdoq=3.0:rdoq-level=2:bframes=6:subme=3:me=2:rc-lookahead=80:crf=%Video_Encode_Quality% -q %Video_Encode_Quality% -an "%~dpn1_video.mkv"
if defined Video_Encode_Custom_Option set Video_Encode_CommandLine=%Video_Encoder% -hide_banner -i "%~1" -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -%Video_Encode_Codec%-params %Video_Encode_Custom_Option%:crf=%Video_Encode_Quality% -q %Video_Encode_Quality% -an "%~dpn1_video.mkv"
goto :Encode

:x264
set Video_Encode_CommandLine=%Video_Encoder% --crf %Video_Encode_Quality% --preset %Video_Encode_Preset% -f -3:-3 -r 16 -b 16 -o "%~dpn1_video.mkv" "%~1"
if defined Video_Encode_Custom_Option set Video_Encode_CommandLine=%Video_Encode_CommandLine% %Video_Encode_Custom_Option%
goto :Encode

:x265
::echo Not Supported Yet, Use FFmpeg instead
::set Video_Encoder=%FFmpeg%
::set Video_Encode_Codec=x265
::goto :ffmpeg
if defined Video_Encode_Custom_Option goto :x265_Custom
%FFmpeg% -hide_banner -i "%~1" -f yuv4mpegpipe -an - | %Video_Encoder% --crf %Video_Encode_Quality% --preset %Video_Encode_Preset% --no-rect --ctu 32 --no-sao  --me 2  --subme 3 --no-open-gop --keyint 360 --min-keyint 1 --range limited --deblock -1:-1 --merange 44 --rc-lookahead 80 --bframes 6 --ref 4 --no-amp  --pmode --pme - -o "%~dpn1_video.hevc"
goto :Encode
:x265_Custom
%FFmpeg%  -hide_banner -i "%~1" -f yuv4mpegpipe -an - | %Video_Encoder% --crf %Video_Encode_Quality% --preset %Video_Encode_Preset%  %Video_Encode_Custom_Option% --output "%~dpn1_video.hevc" -
goto :Encode

:handbrake
set Video_Encode_CommandLine=%Video_Encoder% -i "%~1" -o "%~dpn1_video.mkv" -f mkv --detelecine --decomb -e %Video_Encode_Codec% -q %Video_Encode_Quality% -a none --encoder-preset=%Video_Encode_Preset% --verbose=1
if defined Video_Encode_Custom_Option set Video_Encode_CommandLine=%Video_Encode_CommandLine% %Video_Encode_Custom_Option%
goto :Encode

:Encode
if not exist "%~1" call :ErrorSrc "%~1"
if [%ErrorSrc%]==[1] goto :Next
echo %Audio_Encoder% | find /i "ffmpeg">nul && goto :Encode_ffmpeg
if not exist %Audio_Encoder% call :Error %Audio_Encoder%
if [%Error%]==[1] goto :Encode_ffmpeg_All
if exist "%~dpn1_encoded.%Output_File_Format%" move "%~dpn1_encoded.%Output_File_Format%" "%~dpn1_encoded%RANDOM%.%Output_File_Format%"
if exist "%~dpn1_video.mkv" move "%~dpn1_video.mkv" "%~dpn1_video%RANDOM%.mkv"
if exist "%~dpn1_aac.m4a" move "%~dpn1_aac.m4a" "%~dpn1_aac%RANDOM%.m4a"

:Encode_Audio
%FFmpeg% -hide_banner -i "%~1" -c:a pcm_f32le -f wav - | %Audio_Encoder% -q %Audio_Encode_Quality% -ignorelength -if - -of "%~dpn1_aac.m4a"
echo.
goto :Encode_Video

:Encode_Video
if not defined Video_Encode_CommandLine goto :Mux_And_Clean
%Video_Encode_CommandLine%
echo.
goto :Mux_And_Clean

:Encode_ffmpeg
if exist "%~dpn1_encoded.%Output_File_Format%" move "%~dpn1_encoded.%Output_File_Format%" "%~dpn1_encoded%RANDOM%.%Output_File_Format%"
echo %Video_Encoder% | find /i "ffmpeg">nul && goto :Encode_ffmpeg_All

:Encode_Audio_ffmpeg
if exist "%~dpn1_opus.mka" move "%~dpn1_opus.mka" "%~dpn1_opus%RANDOM%.mka"
if exist "%~dpn1_video.mkv" move "%~dpn1_video.mkv" "%~dpn1_video%RANDOM%.mkv"
%FFmpeg% -hide_banner -i "%~1" -c:a libopus -b:a %Audio_Encode_Bitrate% "%~dpn1_opus.mka"
goto :Encode_Video

:Encode_ffmpeg_All
set Video_Encode_CommandLine=%FFmpeg% -hide_banner -i "%~1" -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -%Video_Encode_Codec%-params no-sao=1:merange=44:aq-mode=1:aq_strength=0.8:psy-rd=1.5:psy-rdoq=3.0:rdoq-level=2:bframes=6:subme=3:me=2:rc-lookahead=80:crf=%Video_Encode_Quality% -c:a libopus -b:a %Audio_Encode_Bitrate% "%~dpn1_encoded.%Output_File_Format%"
if defined Video_Encode_Custom_Option set Video_Encode_CommandLine=%FFmpeg% -hide_banner -i "%~1" -preset %Video_Encode_Preset% -c:v %Video_Encode_Codec_lib% -%Video_Encode_Codec%-params %Video_Encode_Custom_Option%:crf=%Video_Encode_Quality% -c:a libopus -b:a %Audio_Encode_Bitrate% "%~dpn1_encoded.%Output_File_Format%"
%Video_Encode_CommandLine%
goto :Next

:Mux_And_Clean
echo %Audio_Encoder% | find /i "ffmpeg">nul && goto :Mux_Opus
%FFmpeg% -hide_banner -i "%~dpn1_video.mkv" -i "%~dpn1_aac.m4a" -c copy -map 0:v:0 -map 1:a:0 "%~dpn1_encoded.%Output_File_Format%"
if [%ERRORLEVEL%] == [0] if exist "%~dpn1_encoded.%Output_File_Format%" (
del /f /q "%~dpn1_aac.m4a"
del /f /q "%~dpn1_video.mkv"
)
echo.
goto :Next

:Mux_Opus
%FFmpeg% -hide_banner -i "%~dpn1_video.mkv" -i "%~dpn1_opus.mka" -c copy -map 0:v:0 -map 1:a:0 "%~dpn1_encoded.%Output_File_Format%" 
if [%ERRORLEVEL%] == [0] if exist "%~dpn1_encoded.%Output_File_Format%" (
del /f /q "%~dpn1_opus.mka"
del /f /q "%~dpn1_video.mkv"
)
echo.

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