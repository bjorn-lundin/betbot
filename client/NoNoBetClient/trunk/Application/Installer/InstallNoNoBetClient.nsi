
!include LogicLib.nsh
!include x64.nsh
#!include textlog.nsh

# Installer header name
Name "NoNoBet Client"

Var /GLOBAL P1
Var /GLOBAL P2

!define "APPLICATION_NAME" "NoNoBet Client"
!define "COMPANY_NAME" "NoNoBet" 
!define "REG_KEY_UNINSTALL" "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPLICATION_NAME}"
!define "REG_VALUE_DISPLAY_NAME" "DisplayName"
!define "REG_VALUE_INSTALL_LOCATION" "InstallLocation"
!define "REG_VALUE_UNINSTALL_STRING" "UninstallString"
!define "REG_VALUE_PUBLISHER" "Publisher"
!define "REG_VALUE_VERSION_MAJOR" "VersionMajor"
!define "REG_VALUE_VERSION_MINOR" "VersionMinor"
!define "REG_VALUE_DISPLAY_VERSION" "DisplayVersion"
!define VERSIONMAJOR 1
!define VERSIONMINOR 2

# Output file name
OutFile "InstallNoNoBetClient.exe"

# Set default install dir to Program Files sub directory
installDir "$PROGRAMFILES\${COMPANY_NAME}\${APPLICATION_NAME}"

   
DirText "This will install ${APPLICATION_NAME} on your computer. Please choose a directory"

Page Directory
Page InstFiles

Section ""

SetOutPath $INSTDIR

# Test using AccessControl
#AccessControl::GrantOnFile \
#  "$INSTDIR" "(BU)" "GenericRead + GenericWrite"

File ..\bin\Release\NoNoBetClient.exe
File ..\bin\Release\NoNoBetBaseComponents.dll
File ..\bin\Release\NoNoBetDbInterface.dll
File ..\bin\Release\NoNoBetComponents.dll 
File ..\bin\Release\NoNoBetDb.dll
File ..\bin\Release\NoNoBetConfig.dll
File ..\bin\Release\NoNoBetResources.dll
File ..\bin\Release\MenuHandlers.dll
File ..\bin\Release\Npgsql.dll
File ..\bin\Release\policy.2.0.Npgsql.dll
File ..\bin\Release\Mono.Security.dll
File ..\Config\TermsConfig.xml
File ..\Config\MenuHandlersConfig.xml
File ..\images\pic1.ico

WriteUninstaller $INSTDIR\UninstallNoNoBetClient.exe

# Start Menu
createDirectory "$SMPROGRAMS\${COMPANY_NAME}"
createShortCut "$SMPROGRAMS\${COMPANY_NAME}\${APPLICATION_NAME}.lnk" "$INSTDIR\NoNoBetClient.exe" "" "$INSTDIR\pic1.ico"

# Registry information
WriteRegStr HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_DISPLAY_NAME}" "${APPLICATION_NAME}"
WriteRegStr HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_INSTALL_LOCATION}" "$\"$INSTDIR$\""
WriteRegStr HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_UNINSTALL_STRING}" "$\"$INSTDIR\UninstallNoNoBetClient.exe$\""
WriteRegStr HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_PUBLISHER}" "${COMPANY_NAME}"
WriteRegDWORD HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_VERSION_MAJOR}" ${VERSIONMAJOR}
WriteRegDWORD HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_VERSION_MINOR}" ${VERSIONMINOR}
WriteRegStr HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_DISPLAY_VERSION}" "${VERSIONMAJOR}.${VERSIONMINOR}"
SectionEnd

Section "Uninstall"

# Remove Start Menu launcher
delete "$SMPROGRAMS\${COMPANY_NAME}\${APPLICATION_NAME}.lnk"
# Try to remove the Start Menu folder - this will only happen if it is empty
rmDir "$SMPROGRAMS\${COMPANY_NAME}"

# Remove files
Delete $INSTDIR\NoNoBetClient.exe
Delete $INSTDIR\NoNoBetBaseComponents.dll
Delete $INSTDIR\NoNoBetDbInterface.dll
Delete $INSTDIR\NoNoBetComponents.dll 
Delete $INSTDIR\NoNoBetDb.dll
Delete $INSTDIR\NoNoBetConfig.dll
Delete $INSTDIR\NoNoBetResources.dll
Delete $INSTDIR\MenuHandlers.dll
Delete $INSTDIR\Npgsql.dll
Delete $INSTDIR\policy.2.0.Npgsql.dll
Delete $INSTDIR\Mono.Security.dll
Delete $INSTDIR\TermsConfig.xml
Delete $INSTDIR\MenuHandlersConfig.xml
Delete $INSTDIR\pic1.ico
# Remove the uninstaller
Delete $INSTDIR\UninstallNoNoBetClient.exe
# Remove the install directory 
rmDir $INSTDIR

# Remove registry information
DeleteRegKey HKLM "${REG_KEY_UNINSTALL}"

SectionEnd

# ---------------------------------------
# Function called when about to uninstall
# ---------------------------------------
function un.onInit
  ${If} ${RunningX64}
    StrCpy $INSTDIR "$PROGRAMFILES64\${COMPANY_NAME}\${APPLICATION_NAME}"
	SetRegView 64
  ${Else}
    StrCpy $INSTDIR "$PROGRAMFILES32\${COMPANY_NAME}\${APPLICATION_NAME}"
	SetRegView 32
  ${EndIf}
  
  #Verify the uninstaller - last chance to back out
  MessageBox MB_OKCANCEL "Permanantly remove ${APPLICATION_NAME}?" IDOK TheEnd
    Abort
TheEnd:
functionEnd

# -------------------------------------
# Function called when about to install
# -------------------------------------
function .onInit

  # Check if target system is 32/64 bit
  ${If} ${RunningX64}
    StrCpy $INSTDIR "$PROGRAMFILES64\${COMPANY_NAME}\${APPLICATION_NAME}"
	SetRegView 64
  ${Else}
    StrCpy $INSTDIR "$PROGRAMFILES32\${COMPANY_NAME}\${APPLICATION_NAME}"
	SetRegView 32
  ${EndIf}

  #SetOutPath $INSTDIR
  #${LogSetFileName} "$INSTDIR\MyInstallLog.txt"
  #${LogSetOn}
  #${LogText} "In .onInit"

  # Check if application already installed (by reading the registry)
  ReadRegStr $P1 HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_UNINSTALL_STRING}"
  ReadRegStr $P2 HKLM "${REG_KEY_UNINSTALL}" "${REG_VALUE_INSTALL_LOCATION}"
 
  # Skip if no key value
  ${If} $P1 == ""
    Goto uninstall_done
  ${EndIf}
 
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "${APPLICATION_NAME} is already installed. $\n$\nClick `OK` to remove the previous version or `Cancel` to cancel this upgrade." IDOK uninstall_go
  Abort
 
uninstall_go:
  ClearErrors
  # Try to run the Uninstaller
  #${LogText} "About to exec uninstaller P1=$P1,P2=$P2"
  #ExecWait '"$P1" _?=$P2'
  ExecWait "$P1"
 
  # Check if error during uninstall
  IfErrors uninstall_failed uninstall_done
 
uninstall_failed:
  # Failed to run the Uninstall program  
  # No action, continue with registry cleanup
  #${LogText} "Failed exec uninstaller"

  #MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "Failed to exec uninstaller...."

uninstall_done:
  # Clean up registry
  #MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "About to clean up registry"
  #${LogText} "Cleaning registry"
  DeleteRegKey HKLM "${REG_KEY_UNINSTALL}"
functionEnd
 