Imports System
Imports System.Data
Imports System.IO
Imports System.IO.Directory
Imports BaseComponents
Imports NoNoBetComponents
Imports DbInterface

Public Class StartUp

  Public Sub New()

  End Sub

  Private Shared _DbConnection As DbConnection

  Public Shared Function Main() As Integer
    Dim workingDir As String = GetCurrentDirectory()
    Dim currDirectoryInfo As DirectoryInfo = New DirectoryInfo(GetCurrentDirectory())
    workingDir = currDirectoryInfo.Parent.FullName

    'Dim conString As DbConnectionString = New DbConnectionString
    'Dim dbConDialog As DbConnectionDialog = New DbConnectionDialog
    'dbConDialog.StartDialog(conString)
    Dim conMan As New ConnectionManager

    conMan.StartForm(True)

    'Dim connectDialog As DbConnectionForm = New DbConnectionForm

    'connectDialog.ExeceuteDialog(workingDir)

    Return 0
  End Function
End Class
