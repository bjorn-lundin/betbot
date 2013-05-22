Imports System
Imports System.Windows
Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface
Imports DbInterface.DbConnection
Imports NoNoBetComponents
Imports NoNoBetDb

Public Class RaceDaysForm
  Inherits BaseForm
  Friend WithEvents gridRaceDays As BaseComponents.BaseGrid
  Friend WithEvents dateStart As System.Windows.Forms.DateTimePicker
  Friend WithEvents radioStartdate As System.Windows.Forms.RadioButton
  Friend WithEvents radioAllDates As System.Windows.Forms.RadioButton
  Friend WithEvents buttonShow As System.Windows.Forms.Button
  Friend WithEvents panelTop As System.Windows.Forms.Panel
  Friend WithEvents gridRaces As BaseComponents.BaseGrid
  Friend WithEvents SplitContainer1 As System.Windows.Forms.SplitContainer
  Friend WithEvents SplitContainer2 As System.Windows.Forms.SplitContainer
  Friend WithEvents gridRaceEquipages As BaseComponents.BaseGrid
  Friend WithEvents buttonClose As System.Windows.Forms.Button
  Friend WithEvents HorseStat As System.Windows.Forms.Button

  Private _IsLoaded As Boolean = False

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Sub InitializeComponent()
    Me.panelTop = New System.Windows.Forms.Panel()
    Me.buttonClose = New System.Windows.Forms.Button()
    Me.buttonShow = New System.Windows.Forms.Button()
    Me.dateStart = New System.Windows.Forms.DateTimePicker()
    Me.radioStartdate = New System.Windows.Forms.RadioButton()
    Me.radioAllDates = New System.Windows.Forms.RadioButton()
    Me.gridRaceDays = New BaseComponents.BaseGrid()
    Me.gridRaces = New BaseComponents.BaseGrid()
    Me.SplitContainer1 = New System.Windows.Forms.SplitContainer()
    Me.SplitContainer2 = New System.Windows.Forms.SplitContainer()
    Me.gridRaceEquipages = New BaseComponents.BaseGrid()
    Me.HorseStat = New System.Windows.Forms.Button()
    Me.panelTop.SuspendLayout()
    CType(Me.gridRaceDays, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer1.Panel1.SuspendLayout()
    Me.SplitContainer1.Panel2.SuspendLayout()
    Me.SplitContainer1.SuspendLayout()
    CType(Me.SplitContainer2, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer2.Panel1.SuspendLayout()
    Me.SplitContainer2.Panel2.SuspendLayout()
    Me.SplitContainer2.SuspendLayout()
    CType(Me.gridRaceEquipages, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'panelTop
    '
    Me.panelTop.Controls.Add(Me.HorseStat)
    Me.panelTop.Controls.Add(Me.buttonClose)
    Me.panelTop.Controls.Add(Me.buttonShow)
    Me.panelTop.Controls.Add(Me.dateStart)
    Me.panelTop.Controls.Add(Me.radioStartdate)
    Me.panelTop.Controls.Add(Me.radioAllDates)
    Me.panelTop.Dock = System.Windows.Forms.DockStyle.Top
    Me.panelTop.Location = New System.Drawing.Point(0, 0)
    Me.panelTop.Name = "panelTop"
    Me.panelTop.Size = New System.Drawing.Size(1360, 100)
    Me.panelTop.TabIndex = 0
    '
    'buttonClose
    '
    Me.buttonClose.DialogResult = System.Windows.Forms.DialogResult.Cancel
    Me.buttonClose.Location = New System.Drawing.Point(1141, 51)
    Me.buttonClose.Name = "buttonClose"
    Me.buttonClose.Size = New System.Drawing.Size(75, 23)
    Me.buttonClose.TabIndex = 4
    Me.buttonClose.Text = "Close"
    Me.buttonClose.UseVisualStyleBackColor = True
    '
    'buttonShow
    '
    Me.buttonShow.Location = New System.Drawing.Point(629, 52)
    Me.buttonShow.Name = "buttonShow"
    Me.buttonShow.Size = New System.Drawing.Size(123, 23)
    Me.buttonShow.TabIndex = 3
    Me.buttonShow.Text = "Show races"
    Me.buttonShow.UseVisualStyleBackColor = True
    '
    'dateStart
    '
    Me.dateStart.Location = New System.Drawing.Point(262, 50)
    Me.dateStart.Name = "dateStart"
    Me.dateStart.Size = New System.Drawing.Size(200, 22)
    Me.dateStart.TabIndex = 2
    '
    'radioStartdate
    '
    Me.radioStartdate.AutoSize = True
    Me.radioStartdate.Location = New System.Drawing.Point(98, 51)
    Me.radioStartdate.Name = "radioStartdate"
    Me.radioStartdate.Size = New System.Drawing.Size(91, 21)
    Me.radioStartdate.TabIndex = 1
    Me.radioStartdate.TabStop = True
    Me.radioStartdate.Text = "Start date"
    Me.radioStartdate.UseVisualStyleBackColor = True
    '
    'radioAllDates
    '
    Me.radioAllDates.AutoSize = True
    Me.radioAllDates.Location = New System.Drawing.Point(98, 23)
    Me.radioAllDates.Name = "radioAllDates"
    Me.radioAllDates.Size = New System.Drawing.Size(83, 21)
    Me.radioAllDates.TabIndex = 0
    Me.radioAllDates.TabStop = True
    Me.radioAllDates.Text = "All dates"
    Me.radioAllDates.UseVisualStyleBackColor = True
    '
    'gridRaceDays
    '
    Me.gridRaceDays.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridRaceDays.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridRaceDays.Location = New System.Drawing.Point(0, 0)
    Me.gridRaceDays.Name = "gridRaceDays"
    Me.gridRaceDays.RowTemplate.Height = 24
    Me.gridRaceDays.Size = New System.Drawing.Size(1360, 188)
    Me.gridRaceDays.TabIndex = 1
    '
    'gridRaces
    '
    Me.gridRaces.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridRaces.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridRaces.Location = New System.Drawing.Point(0, 0)
    Me.gridRaces.Name = "gridRaces"
    Me.gridRaces.RowTemplate.Height = 24
    Me.gridRaces.Size = New System.Drawing.Size(1360, 198)
    Me.gridRaces.TabIndex = 2
    '
    'SplitContainer1
    '
    Me.SplitContainer1.Dock = System.Windows.Forms.DockStyle.Fill
    Me.SplitContainer1.Location = New System.Drawing.Point(0, 100)
    Me.SplitContainer1.Name = "SplitContainer1"
    Me.SplitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'SplitContainer1.Panel1
    '
    Me.SplitContainer1.Panel1.Controls.Add(Me.gridRaceDays)
    '
    'SplitContainer1.Panel2
    '
    Me.SplitContainer1.Panel2.Controls.Add(Me.SplitContainer2)
    Me.SplitContainer1.Size = New System.Drawing.Size(1360, 593)
    Me.SplitContainer1.SplitterDistance = 188
    Me.SplitContainer1.TabIndex = 1
    '
    'SplitContainer2
    '
    Me.SplitContainer2.Dock = System.Windows.Forms.DockStyle.Fill
    Me.SplitContainer2.Location = New System.Drawing.Point(0, 0)
    Me.SplitContainer2.Name = "SplitContainer2"
    Me.SplitContainer2.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'SplitContainer2.Panel1
    '
    Me.SplitContainer2.Panel1.Controls.Add(Me.gridRaces)
    '
    'SplitContainer2.Panel2
    '
    Me.SplitContainer2.Panel2.Controls.Add(Me.gridRaceEquipages)
    Me.SplitContainer2.Size = New System.Drawing.Size(1360, 401)
    Me.SplitContainer2.SplitterDistance = 198
    Me.SplitContainer2.TabIndex = 0
    '
    'gridRaceEquipages
    '
    Me.gridRaceEquipages.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridRaceEquipages.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridRaceEquipages.Location = New System.Drawing.Point(0, 0)
    Me.gridRaceEquipages.Name = "gridRaceEquipages"
    Me.gridRaceEquipages.RowTemplate.Height = 24
    Me.gridRaceEquipages.Size = New System.Drawing.Size(1360, 199)
    Me.gridRaceEquipages.TabIndex = 0
    '
    'HorseStat
    '
    Me.HorseStat.Location = New System.Drawing.Point(849, 52)
    Me.HorseStat.Name = "HorseStat"
    Me.HorseStat.Size = New System.Drawing.Size(114, 23)
    Me.HorseStat.TabIndex = 5
    Me.HorseStat.Text = "Show Horse"
    Me.HorseStat.UseVisualStyleBackColor = True
    '
    'RaceDaysForm
    '
    Me.CancelButton = Me.buttonClose
    Me.ClientSize = New System.Drawing.Size(1360, 693)
    Me.Controls.Add(Me.SplitContainer1)
    Me.Controls.Add(Me.panelTop)
    Me.Name = "RaceDaysForm"
    Me.panelTop.ResumeLayout(False)
    Me.panelTop.PerformLayout()
    CType(Me.gridRaceDays, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.Panel1.ResumeLayout(False)
    Me.SplitContainer1.Panel2.ResumeLayout(False)
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.ResumeLayout(False)
    Me.SplitContainer2.Panel1.ResumeLayout(False)
    Me.SplitContainer2.Panel2.ResumeLayout(False)
    CType(Me.SplitContainer2, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer2.ResumeLayout(False)
    CType(Me.gridRaceEquipages, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Private Sub radioAllDates_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles radioAllDates.CheckedChanged, radioStartdate.CheckedChanged
    If (Not _IsLoaded) Then
      Return
    End If

    dateStart.Enabled = radioStartdate.Checked
  End Sub

  Private Sub buttonShow_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonShow.Click
    Dim sql As String = String.Empty

    If radioStartdate.Checked Then
      sql = Race.BuildRacesSelectSql(dateStart.Value, True)
    Else
      sql = Race.BuildRacesSelectSql(True)
    End If

    gridRaceDays.ExecuteSql(MyBase.ResourceManager, sql)
  End Sub

  Private Sub gridRaceDays_SelectionChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles gridRaceDays.SelectionChanged
    If _IsLoaded Then
      Dim trackName As String = Nothing
      Dim raceDate As Date = Nothing
      Dim sql As String = Nothing

      If (gridRaceDays.CurrentRow) IsNot Nothing Then
        trackName = CType(gridRaceDays.GetCurrentRowCellValue("track"), String)
        raceDate = CType(gridRaceDays.GetCurrentRowCellValue("date"), Date)
        sql = Race.BuildTrackRacesSelectSql(raceDate, trackName, True)
      Else
        sql = Race.BuildNullTrackRacesSelectSql()
      End If

      gridRaces.ExecuteSql(Me.ResourceManager, sql)
    End If
  End Sub

  Private Sub gridRaces_SelectionChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles gridRaces.SelectionChanged
    If _IsLoaded Then
      Dim sql As String = Nothing
      Dim raceId As Integer = 0

      If gridRaces.CurrentRow IsNot Nothing Then
        raceId = CType(gridRaces.GetCurrentRowCellValue("id"), Integer)
        sql = "SELECT ekipage.finish_place, ekipage.start_place, horse.name as horse,horse.id as horse_id, driver.name as driver, ekipage.winner_odds," + _
              "ekipage.place_odds, ekipage.distance, ekipage.time, ekipage.time_comment FROM ekipage" + _
              " JOIN race_ekipage ON (race_ekipage.ekipage_id = ekipage.id AND race_ekipage.race_id = " & raceId & ")" + _
              " JOIN horse ON (ekipage.horse_id = horse.id)" + _
              " JOIN driver ON (ekipage.driver_id = driver.id) ORDER BY ekipage.finish_place"
      Else
        gridRaces.Clear()
      End If

      gridRaceEquipages.ExecuteSql(Me.ResourceManager, sql)
    End If
  End Sub


  Private Sub RaceDaysForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    Me.Text = "Race days"
    gridRaceDays.SetReadOnlyMode()
    gridRaces.SetReadOnlyMode()
    gridRaceEquipages.SetReadOnlyMode()
    gridRaceDays.ExecuteSql(Me.ResourceManager, "SELECT date,track FROM race WHERE null = null")
    'gridRaces.ExecuteSql(MyBase.DbConnection, "SELECT * FROM ekipage WHERE null = null")
    gridRaces.ExecuteSql(MyBase.ResourceManager, "SELECT id,date,track FROM race WHERE null = null")
    radioAllDates.Checked = True
    dateStart.Enabled = False
    _IsLoaded = True
  End Sub

  Private Sub buttonClose_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonClose.Click
    Me.EndForm()
  End Sub

  Private Sub HorseStat_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles HorseStat.Click
    Dim horseId As Integer = CType(gridRaceEquipages.GetCurrentRowCellValue("horse_id"), Integer)
    Dim horseFrm As HorseStatForm = New HorseStatForm
    horseFrm.StartForm(Me.ResourceManager.DbConnection, horseId)
  End Sub
End Class
