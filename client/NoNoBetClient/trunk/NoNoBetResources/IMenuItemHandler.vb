Imports System.Windows.Forms

Public Interface IMenuItemHandler
  Property ResourceManager As ApplicationResourceManager
  Function MenuCreate(ByVal menuName As String) As ContextMenuStrip
  Function MenuShow(ByVal menu As ContextMenuStrip, ByVal gridRow As DataGridViewRow, ByVal pos As System.Drawing.Point) As Boolean
  Function MenuItemClick(ByVal item As ToolStripMenuItem) As Boolean
End Interface
