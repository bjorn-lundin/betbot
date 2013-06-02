Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface
Imports NoNoBetResources
Imports NoNoBetComponents.RaceBetSim

Public Class StatForm
  Inherits BaseForm
  Friend WithEvents textTotEquipages As System.Windows.Forms.TextBox
  Friend WithEvents buttonTotEquipages As System.Windows.Forms.Button
  Friend WithEvents groupTotWinEquipages As System.Windows.Forms.GroupBox
  Friend WithEvents buttonTotWinEquipages As System.Windows.Forms.Button
  Friend WithEvents textToWinEquipages As System.Windows.Forms.TextBox
  Friend WithEvents groupTotEcuipages As System.Windows.Forms.GroupBox
  Friend WithEvents textTotRaces As System.Windows.Forms.TextBox
  Friend WithEvents buttonTotRaces As System.Windows.Forms.Button
  Friend WithEvents groupStartPosStat As System.Windows.Forms.GroupBox
  Friend WithEvents gridStartPosStats As BaseComponents.BaseGrid
  Friend WithEvents buttonStartPosStats As System.Windows.Forms.Button
  Friend WithEvents labelTrack As System.Windows.Forms.Label
  Friend WithEvents comboTracks As System.Windows.Forms.ComboBox
  Friend WithEvents labelEndDate As System.Windows.Forms.Label
  Friend WithEvents dpEndDate As System.Windows.Forms.DateTimePicker
  Friend WithEvents labelStartDate As System.Windows.Forms.Label
  Friend WithEvents dpStartdate As System.Windows.Forms.DateTimePicker
  Friend WithEvents groupStartType As System.Windows.Forms.GroupBox
  Friend WithEvents radioAuto As System.Windows.Forms.RadioButton
  Friend WithEvents radioIgnore As System.Windows.Forms.RadioButton
  Friend WithEvents radioVolt As System.Windows.Forms.RadioButton
  Friend WithEvents groupBetType As System.Windows.Forms.GroupBox
  Friend WithEvents radioBetTypeWinner As System.Windows.Forms.RadioButton
  Friend WithEvents radioBetTypePlace As System.Windows.Forms.RadioButton
  Friend WithEvents groupTop As System.Windows.Forms.GroupBox

  Private Sub InitializeComponent()
    Me.groupTop = New System.Windows.Forms.GroupBox()
    Me.buttonTotRaces = New System.Windows.Forms.Button()
    Me.textTotRaces = New System.Windows.Forms.TextBox()
    Me.groupTotEcuipages = New System.Windows.Forms.GroupBox()
    Me.buttonTotEquipages = New System.Windows.Forms.Button()
    Me.textTotEquipages = New System.Windows.Forms.TextBox()
    Me.groupTotWinEquipages = New System.Windows.Forms.GroupBox()
    Me.buttonTotWinEquipages = New System.Windows.Forms.Button()
    Me.textToWinEquipages = New System.Windows.Forms.TextBox()
    Me.groupStartPosStat = New System.Windows.Forms.GroupBox()
    Me.labelEndDate = New System.Windows.Forms.Label()
    Me.dpEndDate = New System.Windows.Forms.DateTimePicker()
    Me.labelStartDate = New System.Windows.Forms.Label()
    Me.dpStartdate = New System.Windows.Forms.DateTimePicker()
    Me.buttonStartPosStats = New System.Windows.Forms.Button()
    Me.labelTrack = New System.Windows.Forms.Label()
    Me.comboTracks = New System.Windows.Forms.ComboBox()
    Me.gridStartPosStats = New BaseComponents.BaseGrid()
    Me.groupStartType = New System.Windows.Forms.GroupBox()
    Me.radioAuto = New System.Windows.Forms.RadioButton()
    Me.radioIgnore = New System.Windows.Forms.RadioButton()
    Me.radioVolt = New System.Windows.Forms.RadioButton()
    Me.groupBetType = New System.Windows.Forms.GroupBox()
    Me.radioBetTypeWinner = New System.Windows.Forms.RadioButton()
    Me.radioBetTypePlace = New System.Windows.Forms.RadioButton()
    Me.groupTop.SuspendLayout()
    Me.groupTotEcuipages.SuspendLayout()
    Me.groupTotWinEquipages.SuspendLayout()
    Me.groupStartPosStat.SuspendLayout()
    CType(Me.gridStartPosStats, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.groupStartType.SuspendLayout()
    Me.groupBetType.SuspendLayout()
    Me.SuspendLayout()
    '
    'groupTop
    '
    Me.groupTop.Controls.Add(Me.buttonTotRaces)
    Me.groupTop.Controls.Add(Me.textTotRaces)
    Me.groupTop.Dock = System.Windows.Forms.DockStyle.Top
    Me.groupTop.Location = New System.Drawing.Point(0, 0)
    Me.groupTop.Name = "groupTop"
    Me.groupTop.Size = New System.Drawing.Size(754, 68)
    Me.groupTop.TabIndex = 0
    Me.groupTop.TabStop = False
    Me.groupTop.Text = "Total number races"
    '
    'buttonTotRaces
    '
    Me.buttonTotRaces.Location = New System.Drawing.Point(644, 21)
    Me.buttonTotRaces.Name = "buttonTotRaces"
    Me.buttonTotRaces.Size = New System.Drawing.Size(75, 23)
    Me.buttonTotRaces.TabIndex = 1
    Me.buttonTotRaces.Text = "Show"
    Me.buttonTotRaces.UseVisualStyleBackColor = True
    '
    'textTotRaces
    '
    Me.textTotRaces.Location = New System.Drawing.Point(32, 21)
    Me.textTotRaces.Name = "textTotRaces"
    Me.textTotRaces.Size = New System.Drawing.Size(181, 22)
    Me.textTotRaces.TabIndex = 0
    '
    'groupTotEcuipages
    '
    Me.groupTotEcuipages.Controls.Add(Me.buttonTotEquipages)
    Me.groupTotEcuipages.Controls.Add(Me.textTotEquipages)
    Me.groupTotEcuipages.Dock = System.Windows.Forms.DockStyle.Top
    Me.groupTotEcuipages.Location = New System.Drawing.Point(0, 68)
    Me.groupTotEcuipages.Name = "groupTotEcuipages"
    Me.groupTotEcuipages.Size = New System.Drawing.Size(754, 66)
    Me.groupTotEcuipages.TabIndex = 1
    Me.groupTotEcuipages.TabStop = False
    Me.groupTotEcuipages.Text = "Total number equipages"
    '
    'buttonTotEquipages
    '
    Me.buttonTotEquipages.Location = New System.Drawing.Point(644, 21)
    Me.buttonTotEquipages.Name = "buttonTotEquipages"
    Me.buttonTotEquipages.Size = New System.Drawing.Size(75, 23)
    Me.buttonTotEquipages.TabIndex = 3
    Me.buttonTotEquipages.Text = "Show"
    Me.buttonTotEquipages.UseVisualStyleBackColor = True
    '
    'textTotEquipages
    '
    Me.textTotEquipages.Location = New System.Drawing.Point(32, 21)
    Me.textTotEquipages.Name = "textTotEquipages"
    Me.textTotEquipages.Size = New System.Drawing.Size(181, 22)
    Me.textTotEquipages.TabIndex = 2
    '
    'groupTotWinEquipages
    '
    Me.groupTotWinEquipages.Controls.Add(Me.buttonTotWinEquipages)
    Me.groupTotWinEquipages.Controls.Add(Me.textToWinEquipages)
    Me.groupTotWinEquipages.Dock = System.Windows.Forms.DockStyle.Top
    Me.groupTotWinEquipages.Location = New System.Drawing.Point(0, 134)
    Me.groupTotWinEquipages.Name = "groupTotWinEquipages"
    Me.groupTotWinEquipages.Size = New System.Drawing.Size(754, 64)
    Me.groupTotWinEquipages.TabIndex = 2
    Me.groupTotWinEquipages.TabStop = False
    Me.groupTotWinEquipages.Text = "Total number winning equipages"
    '
    'buttonTotWinEquipages
    '
    Me.buttonTotWinEquipages.Location = New System.Drawing.Point(644, 21)
    Me.buttonTotWinEquipages.Name = "buttonTotWinEquipages"
    Me.buttonTotWinEquipages.Size = New System.Drawing.Size(75, 23)
    Me.buttonTotWinEquipages.TabIndex = 5
    Me.buttonTotWinEquipages.Text = "Show"
    Me.buttonTotWinEquipages.UseVisualStyleBackColor = True
    '
    'textToWinEquipages
    '
    Me.textToWinEquipages.Location = New System.Drawing.Point(32, 21)
    Me.textToWinEquipages.Name = "textToWinEquipages"
    Me.textToWinEquipages.Size = New System.Drawing.Size(181, 22)
    Me.textToWinEquipages.TabIndex = 4
    '
    'groupStartPosStat
    '
    Me.groupStartPosStat.Controls.Add(Me.groupBetType)
    Me.groupStartPosStat.Controls.Add(Me.groupStartType)
    Me.groupStartPosStat.Controls.Add(Me.labelEndDate)
    Me.groupStartPosStat.Controls.Add(Me.dpEndDate)
    Me.groupStartPosStat.Controls.Add(Me.labelStartDate)
    Me.groupStartPosStat.Controls.Add(Me.dpStartdate)
    Me.groupStartPosStat.Controls.Add(Me.buttonStartPosStats)
    Me.groupStartPosStat.Controls.Add(Me.labelTrack)
    Me.groupStartPosStat.Controls.Add(Me.comboTracks)
    Me.groupStartPosStat.Dock = System.Windows.Forms.DockStyle.Top
    Me.groupStartPosStat.Location = New System.Drawing.Point(0, 198)
    Me.groupStartPosStat.Name = "groupStartPosStat"
    Me.groupStartPosStat.Size = New System.Drawing.Size(754, 188)
    Me.groupStartPosStat.TabIndex = 3
    Me.groupStartPosStat.TabStop = False
    Me.groupStartPosStat.Text = "Start position statistics"
    '
    'labelEndDate
    '
    Me.labelEndDate.AutoSize = True
    Me.labelEndDate.Location = New System.Drawing.Point(191, 78)
    Me.labelEndDate.Name = "labelEndDate"
    Me.labelEndDate.Size = New System.Drawing.Size(65, 17)
    Me.labelEndDate.TabIndex = 11
    Me.labelEndDate.Text = "End date"
    '
    'dpEndDate
    '
    Me.dpEndDate.Location = New System.Drawing.Point(194, 102)
    Me.dpEndDate.Name = "dpEndDate"
    Me.dpEndDate.Size = New System.Drawing.Size(200, 22)
    Me.dpEndDate.TabIndex = 10
    '
    'labelStartDate
    '
    Me.labelStartDate.AutoSize = True
    Me.labelStartDate.Location = New System.Drawing.Point(191, 29)
    Me.labelStartDate.Name = "labelStartDate"
    Me.labelStartDate.Size = New System.Drawing.Size(70, 17)
    Me.labelStartDate.TabIndex = 9
    Me.labelStartDate.Text = "Start date"
    '
    'dpStartdate
    '
    Me.dpStartdate.Location = New System.Drawing.Point(194, 53)
    Me.dpStartdate.Name = "dpStartdate"
    Me.dpStartdate.Size = New System.Drawing.Size(200, 22)
    Me.dpStartdate.TabIndex = 8
    '
    'buttonStartPosStats
    '
    Me.buttonStartPosStats.Location = New System.Drawing.Point(644, 52)
    Me.buttonStartPosStats.Name = "buttonStartPosStats"
    Me.buttonStartPosStats.Size = New System.Drawing.Size(75, 23)
    Me.buttonStartPosStats.TabIndex = 6
    Me.buttonStartPosStats.Text = "Show"
    Me.buttonStartPosStats.UseVisualStyleBackColor = True
    '
    'labelTrack
    '
    Me.labelTrack.AutoSize = True
    Me.labelTrack.Location = New System.Drawing.Point(12, 29)
    Me.labelTrack.Name = "labelTrack"
    Me.labelTrack.Size = New System.Drawing.Size(44, 17)
    Me.labelTrack.TabIndex = 2
    Me.labelTrack.Text = "Track"
    '
    'comboTracks
    '
    Me.comboTracks.FormattingEnabled = True
    Me.comboTracks.Location = New System.Drawing.Point(12, 52)
    Me.comboTracks.Name = "comboTracks"
    Me.comboTracks.Size = New System.Drawing.Size(162, 24)
    Me.comboTracks.TabIndex = 1
    '
    'gridStartPosStats
    '
    Me.gridStartPosStats.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridStartPosStats.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridStartPosStats.Location = New System.Drawing.Point(0, 386)
    Me.gridStartPosStats.Name = "gridStartPosStats"
    Me.gridStartPosStats.RowTemplate.Height = 24
    Me.gridStartPosStats.Size = New System.Drawing.Size(754, 231)
    Me.gridStartPosStats.TabIndex = 0
    '
    'groupStartType
    '
    Me.groupStartType.Controls.Add(Me.radioAuto)
    Me.groupStartType.Controls.Add(Me.radioIgnore)
    Me.groupStartType.Controls.Add(Me.radioVolt)
    Me.groupStartType.Location = New System.Drawing.Point(406, 52)
    Me.groupStartType.Name = "groupStartType"
    Me.groupStartType.Size = New System.Drawing.Size(94, 117)
    Me.groupStartType.TabIndex = 25
    Me.groupStartType.TabStop = False
    Me.groupStartType.Text = "Start typ"
    '
    'radioAuto
    '
    Me.radioAuto.AutoSize = True
    Me.radioAuto.Location = New System.Drawing.Point(16, 49)
    Me.radioAuto.Name = "radioAuto"
    Me.radioAuto.Size = New System.Drawing.Size(58, 21)
    Me.radioAuto.TabIndex = 20
    Me.radioAuto.TabStop = True
    Me.radioAuto.Text = "Auto"
    Me.radioAuto.UseVisualStyleBackColor = True
    '
    'radioIgnore
    '
    Me.radioIgnore.AutoSize = True
    Me.radioIgnore.Location = New System.Drawing.Point(16, 73)
    Me.radioIgnore.Name = "radioIgnore"
    Me.radioIgnore.Size = New System.Drawing.Size(69, 21)
    Me.radioIgnore.TabIndex = 21
    Me.radioIgnore.TabStop = True
    Me.radioIgnore.Text = "Ignore"
    Me.radioIgnore.UseVisualStyleBackColor = True
    '
    'radioVolt
    '
    Me.radioVolt.AutoSize = True
    Me.radioVolt.Location = New System.Drawing.Point(16, 25)
    Me.radioVolt.Name = "radioVolt"
    Me.radioVolt.Size = New System.Drawing.Size(53, 21)
    Me.radioVolt.TabIndex = 19
    Me.radioVolt.TabStop = True
    Me.radioVolt.Text = "Volt"
    Me.radioVolt.UseVisualStyleBackColor = True
    '
    'groupBetType
    '
    Me.groupBetType.Controls.Add(Me.radioBetTypeWinner)
    Me.groupBetType.Controls.Add(Me.radioBetTypePlace)
    Me.groupBetType.Location = New System.Drawing.Point(512, 52)
    Me.groupBetType.Name = "groupBetType"
    Me.groupBetType.Size = New System.Drawing.Size(92, 117)
    Me.groupBetType.TabIndex = 26
    Me.groupBetType.TabStop = False
    Me.groupBetType.Text = "Speltyp"
    '
    'radioBetTypeWinner
    '
    Me.radioBetTypeWinner.AutoSize = True
    Me.radioBetTypeWinner.Location = New System.Drawing.Point(12, 36)
    Me.radioBetTypeWinner.Name = "radioBetTypeWinner"
    Me.radioBetTypeWinner.Size = New System.Drawing.Size(78, 21)
    Me.radioBetTypeWinner.TabIndex = 20
    Me.radioBetTypeWinner.TabStop = True
    Me.radioBetTypeWinner.Text = "Vinnare"
    Me.radioBetTypeWinner.UseVisualStyleBackColor = True
    '
    'radioBetTypePlace
    '
    Me.radioBetTypePlace.AutoSize = True
    Me.radioBetTypePlace.Location = New System.Drawing.Point(12, 66)
    Me.radioBetTypePlace.Name = "radioBetTypePlace"
    Me.radioBetTypePlace.Size = New System.Drawing.Size(60, 21)
    Me.radioBetTypePlace.TabIndex = 21
    Me.radioBetTypePlace.TabStop = True
    Me.radioBetTypePlace.Text = "Plats"
    Me.radioBetTypePlace.UseVisualStyleBackColor = True
    '
    'StatForm
    '
    Me.ClientSize = New System.Drawing.Size(754, 617)
    Me.Controls.Add(Me.gridStartPosStats)
    Me.Controls.Add(Me.groupStartPosStat)
    Me.Controls.Add(Me.groupTotWinEquipages)
    Me.Controls.Add(Me.groupTotEcuipages)
    Me.Controls.Add(Me.groupTop)
    Me.Name = "StatForm"
    Me.Text = "NoNoBet Statistics"
    Me.groupTop.ResumeLayout(False)
    Me.groupTop.PerformLayout()
    Me.groupTotEcuipages.ResumeLayout(False)
    Me.groupTotEcuipages.PerformLayout()
    Me.groupTotWinEquipages.ResumeLayout(False)
    Me.groupTotWinEquipages.PerformLayout()
    Me.groupStartPosStat.ResumeLayout(False)
    Me.groupStartPosStat.PerformLayout()
    CType(Me.gridStartPosStats, System.ComponentModel.ISupportInitialize).EndInit()
    Me.groupStartType.ResumeLayout(False)
    Me.groupStartType.PerformLayout()
    Me.groupBetType.ResumeLayout(False)
    Me.groupBetType.PerformLayout()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Function GetStartType() As StartType
    If radioAuto.Checked Then
      Return StartType.Auto
    ElseIf radioVolt.Checked Then
      Return StartType.Volt
    Else
      Return StartType.Ignore
    End If
  End Function

  Private Function GetBetType() As RaceBetSim.BetType
    If radioBetTypePlace.Checked Then
      Return RaceBetSim.BetType.Place
    Else
      Return RaceBetSim.BetType.Winner
    End If
  End Function

  Private Sub buttonTotEquipages_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotEquipages.Click
    textTotEquipages.Text = MyBase.ResourceManager.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM ekipage").ToString
  End Sub

  Private Sub buttonTotRaces_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotRaces.Click
    textTotRaces.Text = MyBase.ResourceManager.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM race").ToString

    Dim pos1, pos2, pos3 As Integer
    Dim win1, win2, win3 As Integer
    Dim pcnt1, pcnt2, pcnt3 As Decimal

    GetTrackBestStartPosData(comboTracks.SelectedItem.ToString, dpStartdate.Value, dpEndDate.Value, GetStartType(), GetBetType(), pos1, win1, pcnt1, pos2, win2, pcnt2, pos3, win3, pcnt3)
  End Sub

  Private Sub buttonTotWinEquipages_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotWinEquipages.Click
    textToWinEquipages.Text = MyBase.ResourceManager.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM ekipage WHERE finish_place = 1").ToString
  End Sub

  Public Shared Sub FillTracksComboBox(ByVal db As DbConnection, ByVal cb As ComboBox)
    cb.BeginUpdate()
    cb.Items.Clear()

    Dim sql As String = "SELECT DISTINCT track FROM race ORDER BY track"
    Dim trackReader As Npgsql.NpgsqlDataReader = db.ExecuteSqlCommand(sql)

    While trackReader.Read
      Dim trackName As String = CType(trackReader.Item("track"), String)
      cb.Items.Add(trackName)
    End While

    trackReader.Close()
    cb.EndUpdate()
  End Sub

  Private Function GetStartDateClause() As String
    Return "(race.date >= " & DbConnection.DateToSqlString(dpStartdate.Value, DbInterface.DbConnection.DateFormatMode.DateOnly) & ")"
  End Function

  Private Function GetEndDateClause(ByVal endDate As Date) As String
    Return "(race.date <= " & DbConnection.DateToSqlString(endDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ")"
  End Function

  Private Function GetStartDateClause(ByVal startDate As Date) As String
    Return "(race.date >= " & DbConnection.DateToSqlString(startDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ")"
  End Function

  'Private Function GetAutoStartClause() As String
  '    Dim notStr As String

  '    If CheckAuto.Checked Then
  '        notStr = "NOT "
  '    Else
  '        notStr = ""
  '    End If

  '    Return "(" & notStr & "race.auto_start)"
  'End Function

  Public Shared Function GetStartTypeClause(ByVal startType As StartType) As String
    Select Case startType
      Case startType.Auto
        Return "(race.auto_start)"
      Case startType.Volt
        Return "(NOT race.auto_start)"
      Case Else
        Return ""
    End Select
  End Function

  Private Function GetEndDateClause() As String
    Return "(race.date <= " & DbConnection.DateToSqlString(dpEndDate.Value, DbInterface.DbConnection.DateFormatMode.DateOnly) & ")"
  End Function

  Private Function UseTrack() As Boolean
    Return (comboTracks.SelectedItem IsNot Nothing)
  End Function

  Private Function GetTrackSelectClause() As String
    If UseTrack() Then
      Return ""
    Else
      Return ""
    End If
  End Function

  Public Enum StartType As Integer
    Ignore = 1
    Auto = 2
    Volt = 3
  End Enum

  Public Sub GetTrackBestStartPosData(ByVal trackName As String, ByVal startDate As Date, ByVal endDate As Date, ByVal startType As StartType, ByVal betType As RaceBetSim.BetType, _
                                      ByRef startPos1 As Integer, ByRef winners1 As Integer, ByRef winnersPercent1 As Decimal, _
                                      ByRef startPos2 As Integer, ByRef winners2 As Integer, ByRef winnersPercent2 As Decimal, _
                                      ByRef startPos3 As Integer, ByRef winners3 As Integer, ByRef winnersPercent3 As Decimal)
    Dim sql As String = BuildSingleTrackSql(trackName, startDate, endDate, startType, betType)
    Dim dReader As Npgsql.NpgsqlDataReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    startPos1 = 0
    startPos2 = 0
    startPos3 = 0
    winners1 = 0
    winners2 = 0
    winners3 = 0
    winnersPercent1 = 0.0
    winnersPercent2 = 0.0
    winnersPercent3 = 0.0

    If dReader.Read Then
      startPos1 = CType(dReader.Item("startpos"), Integer)
      winners1 = CType(dReader.Item("nmbrwinners"), Integer)
      winnersPercent1 = CType(dReader.Item("%Winners"), Integer)
    End If

    If dReader.Read Then
      startPos2 = CType(dReader.Item("startpos"), Integer)
      winners2 = CType(dReader.Item("nmbrwinners"), Integer)
      winnersPercent2 = CType(dReader.Item("%Winners"), Integer)
    End If

    If dReader.Read Then
      startPos3 = CType(dReader.Item("startpos"), Integer)
      winners3 = CType(dReader.Item("nmbrwinners"), Integer)
      winnersPercent3 = CType(dReader.Item("%Winners"), Integer)
    End If

    dReader.Close()
  End Sub

  Public Function BuildSingleTrackSql(ByVal trackName As String, ByVal startDate As Date, ByVal endDate As Date, ByVal startType As StartType, ByVal betType As RaceBetSim.BetType) As String
    Dim sql As String
    Dim startTypeClauseStr As String = Nothing


    sql = "SELECT * FROM ("

    sql &= "SELECT TrackLineRec.track as track, TrackLineRec.start_place as startpos,TrackLineRec.cnt as nmbrwinners,ROUND(100.0*TrackLineRec.cnt/TrackRec.cnt,2) ""%Winners"" FROM "
    sql &= "(SELECT race.track, count(*) as cnt FROM ekipage " + _
           "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
           "JOIN race ON (race.id = race_ekipage.race_id) " + _
           "WHERE (ekipage.finish_place "

    If (betType = RaceBetSim.BetType.Winner) Then
      sql &= "= 1)"
    ElseIf betType = RaceBetSim.BetType.Place Then
      sql &= "in (1,2,3))"
    End If

    startTypeClauseStr = GetStartTypeClause(startType)
    If (startTypeClauseStr.Length > 0) Then
      sql &= " AND " & startTypeClauseStr
    End If

    sql &= " AND " & GetStartDateClause(startDate)
    sql &= " AND " & GetEndDateClause(endDate)

    sql &= " GROUP BY race.track) TrackRec" + _
           " JOIN " + _
           "(SELECT ekipage.start_place,race.track,count(*) as cnt FROM ekipage " + _
            "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
            "JOIN race ON (race.id = race_ekipage.race_id) " + _
            "WHERE (ekipage.finish_place "

    If (betType = RaceBetSim.BetType.Winner) Then
      sql &= "= 1)"
    ElseIf betType = RaceBetSim.BetType.Place Then
      sql &= "in (1,2,3))"
    End If

    If (startTypeClauseStr.Length > 0) Then
      sql &= " AND " & startTypeClauseStr
    End If

    sql &= " AND " & GetStartDateClause(startDate)
    sql &= " AND " & GetEndDateClause(endDate)

    sql += " GROUP BY race.track, ekipage.start_place) TrackLineRec " + _
            "ON (TrackLineRec.track = TrackRec.track) " + _
          ")TrackView "

    sql += "WHERE (track = '" + trackName + "') "
    sql += "ORDER BY track,nmbrwinners DESC"

    Return sql
  End Function

  Private Sub buttonStartPosStats_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonStartPosStats.Click
    Dim sql As String

    sql = BuildSingleTrackSql(CType(comboTracks.SelectedItem, String), dpStartdate.Value, dpEndDate.Value, GetStartType(), GetBetType())

    ''sql = "SELECT ekipage.start_place, count(*) as cnt, race.track FROM ekipage " + _
    ''      "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
    ''      "JOIN race ON (race.id = race_ekipage.race_id) " + _
    ''      "WHERE (ekipage.finish_place = 1) "

    'sql = "SELECT * FROM ("
    'sql &= "SELECT "

    'If UseTrack() Then
    '    sql &= "TrackLineRec.track ""Track"","
    'End If

    'sql &= "TrackLineRec.start_place ""StartPos"",TrackLineRec.cnt ""NmbrWinners"",ROUND(100.0*TrackLineRec.cnt/TrackRec.cnt) ""%Winners"" FROM "
    'sql &= "(SELECT "

    'If UseTrack() Then
    '    sql &= "race.track,"
    'End If

    'sql &= "count(*) as cnt FROM ekipage " + _
    '       "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
    '       "JOIN race ON (race.id = race_ekipage.race_id) " + _
    '       "WHERE (ekipage.finish_place = 1)"


    'sql &= " AND " & GetAutoStartClause()
    'sql &= " AND " & GetStartDateClause()
    'sql &= " AND " & GetEndDateClause()

    'If UseTrack() Then
    '    sql &= " GROUP BY race.track"
    'End If

    'sql &= ") TrackRec " + _
    '       "JOIN " + _
    '       "(SELECT ekipage.start_place"

    'If UseTrack() Then
    '    sql &= ",race.track"
    'End If

    'sql &= ",count(*) as cnt FROM ekipage " + _
    '       "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
    '       "JOIN race ON (race.id = race_ekipage.race_id) " + _
    '       "WHERE (ekipage.finish_place = 1)"

    'sql &= " AND " & GetAutoStartClause()
    'sql &= " AND " & GetStartDateClause()
    'sql &= " AND " & GetEndDateClause()

    'sql += " GROUP BY "

    'If UseTrack() Then
    '    sql &= "race.track,"
    'End If

    'sql &= "ekipage.start_place) TrackLineRec " + _
    '        "ON (TrackLineRec.track = TrackRec.track) " + _
    '      ")TrackView "


    'If (comboTracks.SelectedItem IsNot Nothing) Then
    '    Dim track As String = CType(comboTracks.SelectedItem, String)
    '    'sql += "AND (race.track = '" + track + "') "
    '    sql += "WHERE (""Track"" = '" + track + "') "
    'End If


    ''sql += "GROUP BY race.track,ekipage.start_place " + _
    ''       "ORDER BY race.track,cnt DESC"
    'sql += "ORDER BY ""Track"",""NmbrWinners"" DESC"
    gridStartPosStats.ExecuteSql(MyBase.ResourceManager, sql)

  End Sub

  Private Sub StatForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    FillTracksComboBox(MyBase.ResourceManager.DbConnection, comboTracks)
    comboTracks.SelectedIndex = 0
    dpStartdate.Value = Today
    dpEndDate.Value = Today
    gridStartPosStats.SetReadOnlyMode()
  End Sub

End Class
