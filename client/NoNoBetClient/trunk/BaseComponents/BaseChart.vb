Imports System.Windows.Forms
Imports System.Windows.Forms.DataVisualization
Imports System.Windows.Forms.DataVisualization.Charting

Public Class BaseChart
  Inherits Charting.Chart

  Private _AxisMenu As ContextMenuStrip
  Private WithEvents _MaxItem As ToolStripMenuItem
  Private WithEvents _MinItem As ToolStripMenuItem
  Private WithEvents _IntervalItem As ToolStripMenuItem

  Private Sub BaseChart_MouseClick(sender As Object, e As System.Windows.Forms.MouseEventArgs) Handles Me.MouseClick
    If (e.Button = Windows.Forms.MouseButtons.Right) Then
      Dim hit As HitTestResult = Me.HitTest(e.Location.X, e.Location.Y)

      Select Case hit.ChartElementType
        Case ChartElementType.Axis
          ShowAxisMenu(hit.Object)
      End Select
    End If
  End Sub

  Private Sub ShowAxisMenu(tagObject As Object)
    If _AxisMenu Is Nothing Then
      Dim l As ToolStripLabel = New ToolStripLabel("Axis Properties")

      _AxisMenu = New ContextMenuStrip

      _MaxItem = New ToolStripMenuItem("Max")
      _MinItem = New ToolStripMenuItem("Min")
      _IntervalItem = New ToolStripMenuItem("Interval")

      _AxisMenu.Items.Add(l)
      _AxisMenu.Items.Add(New ToolStripSeparator)
      _AxisMenu.Items.Add(_MaxItem)
      _AxisMenu.Items.Add(_MinItem)
      _AxisMenu.Items.Add(_IntervalItem)
    End If

    _AxisMenu.Tag = tagObject
    _AxisMenu.Show(Windows.Forms.Cursor.Position)
  End Sub

  Private Sub _MaxItem_Click(sender As Object, e As System.EventArgs) Handles _MaxItem.Click

  End Sub

  Private Sub _MinItem_Click(sender As Object, e As System.EventArgs) Handles _MinItem.Click

  End Sub

  Private Sub _IntervalItem_Click(sender As Object, e As System.EventArgs) Handles _IntervalItem.Click

  End Sub
End Class
