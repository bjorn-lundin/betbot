Imports System.Windows.Forms

Public Class BaseMenuHandler
  Private _ResourceManager As ApplicationResourceManager

  Public Property ResourceManager() As ApplicationResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property


  Public Function CreateMenu(menuName As String) As ContextMenuStrip
    Dim m As ContextMenuStrip = New ContextMenuStrip
    m.Name = menuName
    m.Text = menuName
    Return m
  End Function

  Public Function GetMenuFromItem(item As ToolStripMenuItem) As ContextMenuStrip
    Return CType(item.Tag, ContextMenuStrip)
  End Function

  Public Function GetGridRowFromMenu(menu As ContextMenuStrip) As DataGridViewRow
    Return CType(menu.Tag, DataGridViewRow)
  End Function

  Public Sub AddItem(ByVal menu As ContextMenuStrip, ByVal itemText As String, ByVal itemName As String)
    Dim item As ToolStripMenuItem = New ToolStripMenuItem
    item.Text = itemText
    item.Name = itemName
    item.Enabled = True
    item.Tag = menu
    menu.Items.Add(item)
  End Sub

  Public Function ItemIsEnabled(item As ToolStripMenuItem) As Boolean
    Return item.Enabled
  End Function

  Public Sub EnableItem(item As ToolStripMenuItem)
    item.Enabled = True
  End Sub

  Public Sub DisableItem(item As ToolStripMenuItem)
    item.Enabled = False
  End Sub
End Class
