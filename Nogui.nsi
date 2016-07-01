
!define PRODUCT_NAME "Nogui"
!define PRODUCT_VERSION "1.0"

SetCompressor /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize on
CRCCheck force
!system '>blank set/p=MSCF<nul'
!packhdr temp.dat 'cmd /c Copy /b temp.dat /b +blank&&del blank'
!include "x64.nsh"
!include "FileFunc.nsh"

XPStyle on

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "NoGUI.exe"
InstallDir "$PLUGINSDIR"
#Icon "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
SilentInstall silent
BrandingText " "

Section "Nogui" SEC01
  SetOutPath "$PLUGINSDIR"
  SetOverwrite on
  File "neroAacEnc.exe"
  File "ffmpeg.exe"
  File "mkvmerge.exe"
  ${If} ${RunningX64}
  File "/oname=x264.exe" "x264_64.exe"
${Else}
  File "x264.exe"
${EndIf}
  File "nogui.bat"
  CreateDirectory "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
  SetOutPath "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
  File "locale\zh_CN\LC_MESSAGES\mkvtoolnix.mo"
  File "locale\zh_CN\LC_MESSAGES\wxstd.mo"
  ${GetParameters} $R0
#nsExec::ExecToStack '"$INSTDIR\nogui.bat" $R0'

SetOutPath "$PLUGINSDIR"
ExecWait '"$PLUGINSDIR\nogui.bat" $R0'
Sleep 100000
Delete "neroAacEnc.exe"
Delete "ffmpeg.exe"
Delete "mkvmerge.exe"
Delete "x264.exe"
Delete "nogui.bat"

RMDir /r "$PLUGINSDIR\locale\zh_CN\LC_MESSAGES"
  SetOutPath "$TEMP"

SectionEnd

