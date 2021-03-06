﻿; weasel installation script
!include FileFunc.nsh
!include LogicLib.nsh
!include MUI2.nsh
!include x64.nsh

Unicode true

!include FontReg.nsh

!ifndef WEASEL_VERSION
!define WEASEL_VERSION 1.0.0
!endif

!ifndef WEASEL_BUILD
!define WEASEL_BUILD 0
!endif

!define WEASEL_ROOT $INSTDIR\ThuanTaigi-${WEASEL_VERSION}

; The name of the installer
Name "意傳台語輸入法 ${WEASEL_VERSION}"

; The file to write
OutFile "archives\ThuanTaigi-v${WEASEL_VERSION}.${WEASEL_BUILD}-installer.exe"

VIProductVersion "${WEASEL_VERSION}.${WEASEL_BUILD}"
; NSIS\Contrib\Language files\TradChinese.nlf
; Language ID: 1028
VIAddVersionKey /LANG=1028 "ProductName" "意傳台語輸入法"
VIAddVersionKey /LANG=1028 "Comments" "Powered by 意傳科技"
VIAddVersionKey /LANG=1028 "CompanyName" "意傳科技"
VIAddVersionKey /LANG=1028 "LegalCopyright" "意傳科技"
VIAddVersionKey /LANG=1028 "FileDescription" "意傳台語輸入法"
VIAddVersionKey /LANG=1028 "FileVersion" "${WEASEL_VERSION}"

!define MUI_ICON ..\resource\weasel.ico
SetCompressor /SOLID lzma

; The default installation directory
InstallDir $PROGRAMFILES\IThuan

; Registry key to check for directory (so if you install again, it will
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\IThuan\ThuanTaigi" "InstallDir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------

; Pages

!insertmacro MUI_PAGE_LICENSE "ITHUAN_TIAUKHUAN.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------

; Languages

!insertmacro MUI_LANGUAGE "TradChinese"

;--------------------------------

Function .onInit
  ReadRegStr $R0 HKLM \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi" \
  "UninstallString"
  StrCmp $R0 "" done

  StrCpy $0 "Upgrade"
  IfSilent uninst 0
  MessageBox MB_OKCANCEL|MB_ICONINFORMATION \
  "安裝前，先移除舊版本的意傳台語輸入法。$\n$\n按下「確定」移除舊版本，按下「取消」放棄本次安裝。" \
  IDOK uninst
  Abort

uninst:
  ; Backup data directory from previous installation, user files may exist
  ReadRegStr $R1 HKLM SOFTWARE\IThuan\ThuanTaigi "ThuanTaigiRoot"
  StrCmp $R1 "" call_uninstaller
  IfFileExists $R1\data\*.* 0 call_uninstaller
  CreateDirectory $TEMP\ThuanTaigi-backup
  CopyFiles $R1\data\*.* $TEMP\ThuanTaigi-backup

call_uninstaller:
  ExecWait '$R0 /S'
  Sleep 800

done:
FunctionEnd

; Install font
Section "Fonts"

  StrCpy $FONT_DIR $FONTS
  !insertmacro InstallTTFFont 'fonts\jf-openhuninn-1.1.ttf'

SectionEnd

; The stuff to install
Section "ThuanTaigi"

  SectionIn RO

  ; Write the new installation path into the registry
  WriteRegStr HKLM SOFTWARE\IThuan\ThuanTaigi "InstallDir" "$INSTDIR"

  ; Reset INSTDIR for the new version
  StrCpy $INSTDIR "${WEASEL_ROOT}"

  IfFileExists "$INSTDIR\WeaselServer.exe" 0 +2
  ExecWait '"$INSTDIR\WeaselServer.exe" /quit'

  SetOverwrite try
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  IfFileExists $TEMP\ThuanTaigi-backup\*.* 0 program_files
  CreateDirectory $INSTDIR\data
  CopyFiles $TEMP\ThuanTaigi-backup\*.* $INSTDIR\data
  RMDir /r $TEMP\ThuanTaigi-backup

program_files:
  File "LICENSE.txt"
  File "ITHUAN_TIAUKHUAN.txt"
  File /nonfatal "README.txt"
  File "7-zip-license.txt"
  File "7z.dll"
  File "7z.exe"
  File "COPYING-curl.txt"
  File "curl.exe"
  File "curl-ca-bundle.crt"
  File /nonfatal "rime-install.bat"
  File /nonfatal "rime-install-config.bat"
  File "ThuanTaigi.dll"
  ${If} ${RunningX64}
    File "ThuanTaigix64.dll"
  ${EndIf}
  File "ThuanTaigit.dll"
  ${If} ${RunningX64}
    File "ThuanTaigitx64.dll"
  ${EndIf}
  File "ThuanTaigi.ime"
  ${If} ${RunningX64}
    File "ThuanTaigix64.ime"
  ${EndIf}
  File "ThuanTaigit.ime"
  ${If} ${RunningX64}
    File "ThuanTaigitx64.ime"
  ${EndIf}
  File "WeaselDeployer.exe"
  File "WeaselServer.exe"
  File "WeaselSetup.exe"
  File "rime.dll"
  ; shared data files
  SetOutPath $INSTDIR\data
  File "data\*.yaml"
  File /nonfatal "data\*.txt"
  File /nonfatal "data\*.gram"
  ; images
  SetOutPath $INSTDIR\data\preview
  File "data\preview\*.png"

  SetOutPath $INSTDIR

  ; test /T flag for zh_TW locale
  StrCpy $R2  "/i"
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/S" $R1
  IfErrors +2 0
  StrCpy $R2 "/s"
  ${GetOptions} $R0 "/T" $R1
  IfErrors +2 0
  StrCpy $R2 "/t"

  ExecWait '"$INSTDIR\WeaselSetup.exe" $R2'

  ; run as user...
  ExecWait "$INSTDIR\WeaselDeployer.exe /install"

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi" "DisplayName" "意傳台語輸入法"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Write autorun key
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "ThuanTaigi-WeaselServer" "$INSTDIR\WeaselServer.exe"
  ; Start WeaselServer
  Exec "$INSTDIR\WeaselServer.exe"

  ; Prompt reboot
  SetRebootFlag true

SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\意傳台語輸入法"
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】說明書.lnk" "$INSTDIR\README.txt"
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】輸入法設定.lnk" "$INSTDIR\WeaselDeployer.exe" "" "$SYSDIR\shell32.dll" 21
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】使用者詞典管理.lnk" "$INSTDIR\WeaselDeployer.exe" "/dict" "$SYSDIR\shell32.dll" 6
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】使用者資料更新.lnk" "$INSTDIR\WeaselDeployer.exe" "/sync" "$SYSDIR\shell32.dll" 26
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】重起動.lnk" "$INSTDIR\WeaselDeployer.exe" "/deploy" "$SYSDIR\shell32.dll" 144
  CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】輸入法服務開--開.lnk" "$INSTDIR\WeaselServer.exe" "" "$INSTDIR\WeaselServer.exe" 0
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】使用者設定ê所在.lnk" "$INSTDIR\WeaselServer.exe" "/userdir" "$SYSDIR\shell32.dll" 126
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】輸入法設定ê所在.lnk" "$INSTDIR\WeaselServer.exe" "/weaseldir" "$SYSDIR\shell32.dll" 19
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】檢查新版本.lnk" "$INSTDIR\WeaselServer.exe" "/update" "$SYSDIR\shell32.dll" 13
  ; CreateShortCut "$SMPROGRAMS\意傳台語輸入法\【意傳台語輸入法】安裝選項.lnk" "$INSTDIR\WeaselSetup.exe" "" "$SYSDIR\shell32.dll" 162
  CreateShortCut "$SMPROGRAMS\意傳台語輸入法\移除意傳台語輸入法.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  ExecWait '"$INSTDIR\WeaselServer.exe" /quit'

  ExecWait '"$INSTDIR\WeaselSetup.exe" /u'

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ThuanTaigi"
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "ThuanTaigi-WeaselServer"
  DeleteRegKey HKLM SOFTWARE\IThuan

  ; Remove files and uninstaller
  SetOutPath $TEMP
  Delete /REBOOTOK "$INSTDIR\data\preview\*.*"
  Delete /REBOOTOK "$INSTDIR\data\*.*"
  Delete /REBOOTOK "$INSTDIR\*.*"
  RMDir /REBOOTOK "$INSTDIR\data\preview"
  RMDir /REBOOTOK "$INSTDIR\data"
  RMDir /REBOOTOK "$INSTDIR"
  SetShellVarContext all
  Delete /REBOOTOK "$SMPROGRAMS\意傳台語輸入法\*.*"
  RMDir /REBOOTOK "$SMPROGRAMS\意傳台語輸入法"

  ; Prompt reboot
  SetRebootFlag true

SectionEnd
