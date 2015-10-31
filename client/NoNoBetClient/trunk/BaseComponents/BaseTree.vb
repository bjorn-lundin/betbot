Imports System.Windows.Forms
Imports System.Windows.Forms.TreeView
Imports System.Reflection
Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager

Public Class BaseTree
  Inherits TreeView

  Public Class NodeChangeEventArgs
    Inherits TreeViewEventArgs

    Private _KeyObject As Object = Nothing

    Public Property KeyObject As Object
      Get
        Return _KeyObject
      End Get
      Set(value As Object)
        _KeyObject = value
      End Set
    End Property

    Public Sub New(e As TreeViewEventArgs)
      MyBase.New(e.Node, e.Action)
    End Sub

    Public Sub New(e As TreeViewEventArgs, keyObject As Object)
      MyBase.New(e.Node, e.Action)
      _KeyObject = keyObject
    End Sub
  End Class

  Public Sub New()
    MyBase.New()
  End Sub

  Public Event NodeChange(sender As Object, e As System.Windows.Forms.TreeViewEventArgs)

  Private Sub BaseTree_AfterSelect(sender As Object, e As System.Windows.Forms.TreeViewEventArgs) Handles Me.AfterSelect
    Dim e1 As NodeChangeEventArgs = New NodeChangeEventArgs(e)
    e1.KeyObject = e.Node.Tag
    RaiseEvent NodeChange(Me, e1)
  End Sub
End Class
