Imports System.Windows.Forms

Public Class BaseGridMenuHandler
    Public _Item As ToolStripMenuItem = New ToolStripMenuItem

    Public Shared Function MenuCreate(ByVal menuName As String) As ContextMenuStrip
        Dim m As ContextMenuStrip = New ContextMenuStrip
        m.Name = menuName
        m.Text = menuName

        Select Case menuName
            Case Else
                AddItem(m, "Do...", "itemDo")
                AddItem(m, "Undo...", "itemUndo")
        End Select

        Return m
    End Function

    Private Shared Sub AddItem(ByVal menu As ContextMenuStrip, ByVal itemText As String, ByVal itemName As String)
        Dim item As ToolStripMenuItem = New ToolStripMenuItem
        item.Text = itemText
        item.Name = itemName
        item.Enabled = True
        item.Tag = menu
        menu.Items.Add(item)

        AddHandler item.Click, AddressOf ItemClick
    End Sub

    Private Shared Sub ItemClick(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim item As ToolStripMenuItem = CType(sender, ToolStripMenuItem)
        MenuItemClick(item)
    End Sub

    Public Shared Function MenuShow(ByVal menu As ContextMenuStrip, ByVal gridRow As DataGridViewRow, ByVal pos As System.Drawing.Point) As Boolean
        menu.Tag = gridRow
        menu.Show(pos)
    End Function

    Public Shared Function MenuItemClick(ByVal item As ToolStripMenuItem) As Boolean
        Dim menu As ContextMenuStrip = CType(item.Tag, ContextMenuStrip)
        Dim gridRow As DataGridViewRow = CType(menu.Tag, DataGridViewRow)

        Select Case item.Name
            Case "itemDo"
                MessageBox.Show("Doing something...")
                Return True
            Case "itemUndo"
                MessageBox.Show("Undoing something...")
                Return True
            Case Else

        End Select
    End Function
End Class
