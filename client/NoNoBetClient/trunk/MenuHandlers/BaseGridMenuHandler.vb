Imports System.Windows.Forms
Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetComponents

Public Class BaseGridMenuHandler
  Inherits BaseMenuHandler
  Implements IMenuHandler

  Public Shadows Property ResourceManager() As ApplicationResourceManager Implements IMenuHandler.ResourceManager
    Get
      Return MyBase.ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      MyBase.ResourceManager = value
    End Set
  End Property

  Public Overridable Function MenuCreate(menuName As String) As System.Windows.Forms.ContextMenuStrip Implements NoNoBetResources.IMenuHandler.MenuCreate
    If (String.IsNullOrWhiteSpace(menuName)) Then
      Return Nothing
    End If

    Dim m As ContextMenuStrip = MyBase.CreateMenu(menuName)

    Select Case menuName
      Case "RacedayBettypes"
        MyBase.AddItem(m, "Visa", "itemShowRacedayBettype")
      Case "RaceLines"
        MyBase.AddItem(m, "Visa resultat", "itemShowHorseResults")
      Case Else
        MyBase.AddItem(m, "Do...", "itemDo")
        MyBase.AddItem(m, "Undo...", "itemUndo")
    End Select

    Return m
  End Function

  Public Overridable Function MenuItemClick(item As System.Windows.Forms.ToolStripMenuItem) As Boolean Implements NoNoBetResources.IMenuHandler.MenuItemClick
    Dim menu As ContextMenuStrip = MyBase.GetMenuFromItem(item)
    Dim gridRow As DataGridViewRow = MyBase.GetGridRowFromMenu(menu)

    Select Case item.Name
      Case "itemShowRacedayBettype"
        ShowRacedayBettypeForm(gridRow)
        Return True
      Case "itemShowHorseResults"
        Dim horseId As Integer = ApplicationResourceManager.GetRowColumnIntValue(gridRow, "horse_id")
        Dim horseResult As HorseResultsChart = New HorseResultsChart
        horseResult.StartForm(True, horseId, Me.ResourceManager)
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

  Public Overridable Function MenuBeforeShow(menu As System.Windows.Forms.ContextMenuStrip) As Boolean Implements NoNoBetResources.IMenuHandler.MenuBeforeShow
    'Enable/Disable items
    'menu.Items.Item("").Enabled = False
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
