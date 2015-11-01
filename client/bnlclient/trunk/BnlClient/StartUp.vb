Imports System
Imports System.Data
Imports NoNoBetBaseComponents
Imports NoNoBetResources

Public Class StartUp

  Private Shared WithEvents _ConMan As ConnectionManager

  Public Shared Function Main() As Integer
    'Create and start a new Connection Manager
    'Wait for StartApplication event before starting application

    '=== To start logging, uncomment next line ===
    'ApplicationResourceManager.SetLoggingOn("BnlClient")
    '=============================================
    _ConMan = New ConnectionManager
    _ConMan.FormTitle = "Connection Manager"
    _ConMan.StartForm(True)

    Return 0
  End Function

  Private Shared Sub _ConMan_StartApplication(sender As Object, e As NoNoBetBaseComponents.ConnectionManager.StartApplicationEventArgs) Handles _ConMan.StartApplication
    'Do something
    If (e.ResourceManager IsNot Nothing) Then

    End If
  End Sub
End Class
