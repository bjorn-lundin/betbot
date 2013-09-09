Imports System.Windows.Forms
Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetComponents

Public Class BaseGridMenuHandler
  Implements IMenuHandler

  'Public _Item As ToolStripMenuItem = New ToolStripMenuItem

  Private _ResourceManager As ApplicationResourceManager

  Public Property ResourceManager() As ApplicationResourceManager Implements IMenuHandler.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property


  Public Function MenuCreate(menuName As String) As System.Windows.Forms.ContextMenuStrip Implements NoNoBetResources.IMenuHandler.MenuCreate
    Dim m As ContextMenuStrip = New ContextMenuStrip
    m.Name = menuName
    m.Text = menuName

    Select Case menuName
      Case "RacedayBettypes"
        AddItem(m, "Visa", "itemShowRacedayBettype")
      Case "RaceLines"
        AddItem(m, "Visa resultat", "itemShowHorseResults")
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

  Public Function MenuItemClick(item As System.Windows.Forms.ToolStripMenuItem) As Boolean Implements NoNoBetResources.IMenuHandler.MenuItemClick
    Dim menu As ContextMenuStrip = CType(item.Tag, ContextMenuStrip)
    Dim gridRow As DataGridViewRow = CType(menu.Tag, DataGridViewRow)

    Select Case item.Name
      Case "itemShowRacedayBettype"
        ShowRacedayBettypeForm(gridRow)
        Return True
      Case "itemShowHorseResults"
        Dim horseId As Integer = ApplicationResourceManager.GetRowColumnIntValue(gridRow, "horse_id")
        Dim horseResult As HorseResultsChart = New HorseResultsChart
        horseResult.StartForm(True, horseId, _ResourceManager)
        Return True
      Case "itemDo"
        'MessageBox.Show("Doing something...")
        Dim chartFrm As ChartTest = New ChartTest
        chartFrm.StartForm(Me.ResourceManager)

        Return True
      Case "itemUndo"
        MessageBox.Show("Undoing something...")
        Return True
      Case Else
        Return False
    End Select

  End Function

  Public Function MenuShow(menu As System.Windows.Forms.ContextMenuStrip, gridRow As System.Windows.Forms.DataGridViewRow, pos As System.Drawing.Point) As Boolean Implements NoNoBetResources.IMenuHandler.MenuShow
    menu.Tag = gridRow
    menu.Show(pos)
    Return True
  End Function

  Private Sub ShowRacedayBettypeForm(row As DataGridViewRow)
    If (row IsNot Nothing) Then
      Dim betType As String = ApplicationResourceManager.GetRowColumnStringValue(row, "name_code")
      Dim raceDayId As Integer = ApplicationResourceManager.GetRowColumnIntValue(row, "raceday_id")
      Dim raceDateObj As Object = ApplicationResourceManager.GetRowColumnValue(row, "raceday_date")
      Dim raceDate As Date = CType(raceDateObj, Date)

      Select Case betType
        Case "V", "P"
          Dim vpForm As VP = New VP
          vpForm.StartForm(False, Me.ResourceManager, raceDate, raceDayId)
        Case Else
      End Select
    End If
  End Sub

End Class
