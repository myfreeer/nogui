
!define PRODUCT_NAME "Nogui"
!define PRODUCT_VERSION "1.0"

SetCompressor /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize on
CRCCheck force
#!system '>blank set/p=MSCF<nul'
#!packhdr temp.dat 'cmd /c Copy /b temp.dat /b +blank&&del blank'
!include "x64.nsh"
!include "FileFunc.nsh"

XPStyle on

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Setup.exe"
InstallDir "$PLUGINSDIR"
#Icon "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
SilentInstall silent
BrandingText " "

Section "Nogui"
  SetOutPath "$PLUGINSDIR"
  SetOverwrite on
  CreateDirectory "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
  SetOutPath "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
  File "E:\Documents\Nogui\locale\zh_CN\LC_MESSAGES\mkvtoolnix.mo"
  File "E:\Documents\Nogui\locale\zh_CN\LC_MESSAGES\wxstd.mo"
  SetOutPath "$PLUGINSDIR"
  File "E:\Documents\Nogui\neroAacEnc.exe"
  File "E:\Documents\Nogui\ffmpeg.exe"
  File "E:\Documents\Nogui\mkvmerge.exe"
  File "E:\Documents\Nogui\nogui.bat"
  ${If} ${RunningX64}
    File "/oname=x264.exe" "E:\Documents\Nogui\x264_64.exe"
  ${Else}
    File "E:\Documents\Nogui\x264.exe"
  ${EndIf}
  ${GetParameters} $R0
#nsExec::ExecToStack '"$INSTDIR\nogui.bat" $R0'
ExecWait '"$PLUGINSDIR\nogui.bat" $R0'
MessageBox MB_OK '"$PLUGINSDIR\nogui.bat" $R0'
SetOutPath "$PLUGINSDIR"
Delete "neroAacEnc.exe"
Delete "ffmpeg.exe"
Delete "mkvmerge.exe"
Delete "x264.exe"
Delete "nogui.bat"

RMDir /r "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
	SetOutPath "$TEMP"

SectionEnd

