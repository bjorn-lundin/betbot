Imports System.Windows.Forms

Public Interface IMenuHandler
  Property ResourceManager As ApplicationResourceManager
  Function MenuCreate(ByVal menuName As String) As ContextMenuStrip
  Function MenuBeforeShow(ByVal menu As ContextMenuStrip) As Boolean
  Function MenuItemClick(ByVal item As ToolStripMenuItem) As Boolean
End Interface
