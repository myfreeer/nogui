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
echo %lc_Timer_Begin% %startdate% // %StartTimestamp% -- %StartTimestamp1% //
