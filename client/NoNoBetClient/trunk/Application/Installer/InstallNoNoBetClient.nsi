; Installer name
Name "InstallNoNoBetClient"

; Output file name
OutFile "InstallNoNoBetClient.exe"

;Set default install dir to Desktop
installDir $DESKTOP

DirText "This will install NoNoBetClient on your computer. Please choose a directory"

Page Directory
Page InstFiles

Section ""

SetOutPath $INSTDIR

File ..\bin\Release\NoNoBetClient.exe
File ..\bin\Release\BaseComponents.dll
File ..\bin\Release\DbInterface.dll
File ..\bin\Release\NoNoBetComponents.dll 
File ..\bin\Release\NoNoBetDb.dll
File ..\bin\Release\NoNoBetConfig.dll
File ..\bin\Release\NoNoBetResources.dll
File ..\bin\Release\MenuHandlers.dll
File ..\bin\Release\Npgsql.dll
File ..\bin\Release\policy.2.0.Npgsql.dll
File ..\bin\Release\Mono.Security.dll
File ..\images\pic1.ico

WriteUninstaller $INSTDIR\UninstallNoNoBetClient.exe

SectionEnd

Section "Uninstall"

Delete $INSTDIR\NoNoBetClient.exe
Delete $INSTDIR\BaseComponents.dll
Delete $INSTDIR\DbInterface.dll
Delete $INSTDIR\NoNoBetComponents.dll 
Delete $INSTDIR\NoNoBetDb.dll
Delete $INSTDIR\NoNoBetConfig.dll
Delete $INSTDIR\NoNoBetResources.dll
Delete $INSTDIR\MenuHandlers.dll
Delete $INSTDIR\Npgsql.dll
Delete $INSTDIR\policy.2.0.Npgsql.dll
Delete $INSTDIR\Mono.Security.dll
Delete $INSTDIR\pic1.ico

Delete $INSTDIR\UninstallNoNoBetClient.exe

SectionEnd