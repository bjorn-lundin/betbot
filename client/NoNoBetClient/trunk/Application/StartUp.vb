Imports System
Imports System.Data
Imports System.IO
Imports System.IO.Directory
Imports NoNoBetBaseComponents
Imports NoNoBetComponents
Imports NoNoBetDbInterface
Imports NoNoBetConfig

Public Class StartUp

  Public Sub New()

  End Sub

  Private Shared _DbConnection As DbConnection
  Private Shared WithEvents _ConMan As ConnectionManager

  ''' <summary>
  ''' Start the application
  ''' </summary>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function Main() As Integer
    Dim workingDir As String = GetCurrentDirectory()
    Dim currDirectoryInfo As DirectoryInfo = New DirectoryInfo(GetCurrentDirectory())
    workingDir = currDirectoryInfo.Parent.FullName

    'Create and start a new Connection Manager
    'Wait for StartApplication event before starting application
    _ConMan = New ConnectionManager
    _ConMan.FormTitle = "NoNoBet Connection Manager"
    _ConMan.StartForm(True)

    Return 0
  End Function

  Private Shared Sub _ConMan_StartApplication(sender As Object, e As ConnectionManager.StartApplicationEventArgs) Handles _ConMan.StartApplication
    Dim rSelector As RacedaySelector = New RacedaySelector(e.ResourceManager)
    rSelector.StartForm(False)
  End Sub
End Class
