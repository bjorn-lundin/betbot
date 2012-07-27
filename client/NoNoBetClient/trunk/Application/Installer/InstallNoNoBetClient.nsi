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
File ..\bin\Release\Application.exe
File ..\bin\Release\BaseComponents.dll
File ..\bin\Release\DbInterface.dll
File ..\bin\Release\NoNoBetComponents.dll 
File ..\bin\Release\NoNoBetDb.dll
File ..\bin\Release\Npgsql.dll
File ..\bin\Release\policy.2.0.Npgsql.dll
File ..\bin\Release\Mono.Security.dll

WriteUninstaller $INSTDIR\UninstallNoNoBetClient.exe
SectionEnd


Section "Uninstall"

Delete $INSTDIR\Application.exe
Delete $INSTDIR\BaseComponents.dll
Delete $INSTDIR\DbInterface.dll
Delete $INSTDIR\NoNoBetComponents.dll 
Delete $INSTDIR\NoNoBetDb.dll
Delete $INSTDIR\Npgsql.dll
Delete $INSTDIR\policy.2.0.Npgsql.dll
Delete $INSTDIR\Mono.Security.dll

Delete $INSTDIR\UninstallNoNoBetClient.exe
SectionEnd