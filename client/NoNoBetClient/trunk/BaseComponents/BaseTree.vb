Imports System.Windows.Forms
Imports System.Windows.Forms.TreeView
Imports System.Reflection
Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager

Public Class BaseTree
  Inherits TreeView

  Public Class NodeChangeObj
    Private _NodeLevel As Integer
    Private _KeyObject As Object

    Public Sub New(nodeLevel As Integer)
      _NodeLevel = nodeLevel
      _KeyObject = Nothing
    End Sub

    Public Sub New(nodeLevel As Integer, keyObject As Object)
      _NodeLevel = nodeLevel
      _KeyObject = keyObject
    End Sub

    Public ReadOnly Property NodeLevel As Integer
      Get
        Return _NodeLevel
      End Get
    End Property

    Public ReadOnly Property KeyObject As Object
      Get
        Return _KeyObject
      End Get
    End Property
  End Class

  Public Class NodeChangeEventArgs
    Inherits EventArgs

    Private _NodeChangeObject As NodeChangeObj
    Private _Node As TreeNode

    Public ReadOnly Property Node As TreeNode
      Get
        Return _Node
      End Get
    End Property

    Public ReadOnly Property NodeChangeObject As NodeChangeObj
      Get
        Return _NodeChangeObject
      End Get
    End Property

    Public Sub New(node As TreeNode, nodeChangeObject As NodeChangeObj)
      MyBase.New()
      _Node = node
      _NodeChangeObject = nodeChangeObject
    End Sub
  End Class

  Public Sub New()
    MyBase.New()
  End Sub

  Public Event NodeChange(sender As Object, e As NodeChangeEventArgs)
  Public Event NodeExpand(sender As Object, e As NodeChangeEventArgs)

  Private Sub BaseTree_AfterExpand(sender As Object, e As System.Windows.Forms.TreeViewEventArgs) Handles Me.AfterExpand

  End Sub

  Private Sub BaseTree_AfterSelect(sender As Object, e As System.Windows.Forms.TreeViewEventArgs) Handles Me.AfterSelect
    Dim e1 As NodeChangeEventArgs = New NodeChangeEventArgs(e.Node, New NodeChangeObj(e.Node.Level, e.Node.Tag))
    RaiseEvent NodeChange(Me, e1)
  End Sub

  Private Sub BaseTree_BeforeExpand(sender As Object, e As System.Windows.Forms.TreeViewCancelEventArgs) Handles Me.BeforeExpand
    Dim e1 As NodeChangeEventArgs = New NodeChangeEventArgs(e.Node, New NodeChangeObj(e.Node.Level, e.Node.Tag))
    RaiseEvent NodeExpand(Me, e1)
  End Sub
End Class
