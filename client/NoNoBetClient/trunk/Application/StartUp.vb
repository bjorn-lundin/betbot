Imports System
Imports System.Data
Imports System.IO
Imports System.IO.Directory
Imports BaseComponents
Imports NoNoBetComponents
Imports DbInterface
Imports NoNoBetConfig

Public Class StartUp

  Public Sub New()

  End Sub

  Private Shared _DbConnection As DbConnection
  Private Shared WithEvents _ConMan As ConnectionManager

  Public Shared Function Main() As Integer
    Dim workingDir As String = GetCurrentDirectory()
    Dim currDirectoryInfo As DirectoryInfo = New DirectoryInfo(GetCurrentDirectory())
    workingDir = currDirectoryInfo.Parent.FullName

    'Dim conString As DbConnectionString = New DbConnectionString
    'Dim dbConDialog As DbConnectionDialog = New DbConnectionDialog
    'dbConDialog.StartDialog(conString)
    _ConMan = New ConnectionManager

    _ConMan.StartForm(True)

    'Dim connectDialog As DbConnectionForm = New DbConnectionForm

    'connectDialog.ExeceuteDialog(workingDir)

    Return 0
  End Function

  Private Shared Sub _ConMan_StartApplication(sender As Object, e As ConnectionManager.StartApplicationEventArgs) Handles _ConMan.StartApplication
    Dim rSelector As RacedaySelector = New RacedaySelector(e.ResourceManager)
    rSelector.StartForm(False)
  End Sub
End Class
