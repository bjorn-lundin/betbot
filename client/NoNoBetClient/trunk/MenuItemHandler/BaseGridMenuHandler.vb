Imports System.Windows.Forms
Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager

Public Class BaseGridMenuHandler
  Implements IMenuItemHandler

  Public _Item As ToolStripMenuItem = New ToolStripMenuItem

  Public Function MenuCreate(ByVal menuName As String) As ContextMenuStrip Implements IMenuItemHandler.MenuCreate
    Dim m As ContextMenuStrip = New ContextMenuStrip
    m.Name = menuName
    m.Text = menuName

    Select Case menuName
      Case "RacedayBettypes"
        AddItem(m, "Visa", "itemShowRacedayBettype")
      Case Else
        AddItem(m, "Do...", "itemDo")
        AddItem(m, "Undo...", "itemUndo")
    End Select

    Return m
  End Function

  Private Sub AddItem(ByVal menu As ContextMenuStrip, ByVal itemText As String, ByVal itemName As String)
    Dim item As ToolStripMenuItem = New ToolStripMenuItem
    item.Text = itemText
    item.Name = itemName
    item.Enabled = True
    item.Tag = menu
    menu.Items.Add(item)

    AddHandler item.Click, AddressOf ItemClick
  End Sub

  Private Sub ItemClick(ByVal sender As Object, ByVal e As System.EventArgs)
    Dim item As ToolStripMenuItem = CType(sender, ToolStripMenuItem)
    MenuItemClick(item)
  End Sub

  Public Function MenuShow(ByVal menu As ContextMenuStrip, ByVal gridRow As DataGridViewRow, ByVal pos As System.Drawing.Point) As Boolean Implements IMenuItemHandler.MenuShow
    menu.Tag = gridRow
    menu.Show(pos)
    Return True
  End Function

  Public Function MenuItemClick(ByVal item As ToolStripMenuItem) As Boolean Implements IMenuItemHandler.MenuItemClick
    Dim menu As ContextMenuStrip = CType(item.Tag, ContextMenuStrip)
    Dim gridRow As DataGridViewRow = CType(menu.Tag, DataGridViewRow)

    Select Case item.Name
      Case "itemShowRacedayBettype"
        ShowRacedayBettypeForm(gridRow)
        Return True
      Case "itemDo"
        MessageBox.Show("Doing something...")
        Return True
      Case "itemUndo"
        MessageBox.Show("Undoing something...")
        Return True
      Case Else
        Return False
    End Select
  End Function

  Public Shared Sub ShowRacedayBettypeForm(row As DataGridViewRow)
    If (row IsNot Nothing) Then
      Dim colVal As Object = GetRowColumnValue(row, "name_code")

      If (colVal IsNot Nothing) Then
        Dim bettype As String = CType(colVal, String)

        Select Case bettype
          Case "V", "P"
            'Dim vp As VP
          Case Else

        End Select
      End If
    End If
  End Sub
End Class
