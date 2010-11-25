Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface

Public Class TestForm
    Inherits BaseForm
    Friend WithEvents buttonRun As System.Windows.Forms.Button
    Friend WithEvents textNmbrRaces As System.Windows.Forms.TextBox
    Friend WithEvents textTotWinAmount As System.Windows.Forms.TextBox
    Friend WithEvents textTotBetAmount As System.Windows.Forms.TextBox
    Friend WithEvents labelAmount As System.Windows.Forms.Label
    Friend WithEvents textAmount As System.Windows.Forms.TextBox

    Private _TotWinAmount As Decimal = 0
    Private _BetAmount As Decimal = 0
    Private _ToBetAmount As Decimal = 0
    Private _TotWins As Integer = 0
    Private _TotLosses As Integer = 0
    Private _IsLoaded As Boolean = False
    Private _ComboIsFilled As Boolean = False

    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents textWins As System.Windows.Forms.TextBox
    Friend WithEvents groupTop As System.Windows.Forms.GroupBox
    Friend WithEvents dateStart As System.Windows.Forms.DateTimePicker
    Friend WithEvents radioStartdate As System.Windows.Forms.RadioButton
    Friend WithEvents radioAllDates As System.Windows.Forms.RadioButton
    Friend WithEvents groupBottom As System.Windows.Forms.GroupBox
    Friend WithEvents groupCenter As System.Windows.Forms.GroupBox
    Friend WithEvents textLosses As System.Windows.Forms.TextBox
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents radioSpecificTrack As System.Windows.Forms.RadioButton
    Friend WithEvents radioAllTracks As System.Windows.Forms.RadioButton
    Friend WithEvents groupTrack As System.Windows.Forms.GroupBox
    Friend WithEvents comboTracks As System.Windows.Forms.ComboBox
    Friend WithEvents textStartPlaces As System.Windows.Forms.TextBox
    Friend WithEvents checkStartPlaces As System.Windows.Forms.CheckBox
    Friend WithEvents Label7 As System.Windows.Forms.Label
    Friend WithEvents textStatus As System.Windows.Forms.TextBox
    Friend WithEvents Label6 As System.Windows.Forms.Label
    Friend WithEvents textWinFactor As System.Windows.Forms.TextBox
    Friend WithEvents textDataType As System.Windows.Forms.TextBox
    Private _NmbrRaces As Integer = 0
    Private _StartTime As Date
    Friend WithEvents textTime As System.Windows.Forms.TextBox
    Friend WithEvents checkDataTable As System.Windows.Forms.CheckBox
    Friend WithEvents Label9 As System.Windows.Forms.Label
    Friend WithEvents Label8 As System.Windows.Forms.Label
    Friend WithEvents groupBottom2 As System.Windows.Forms.GroupBox
    Friend WithEvents radioAuto As System.Windows.Forms.RadioButton
    Friend WithEvents radioIgnore As System.Windows.Forms.RadioButton
    Friend WithEvents radioVolt As System.Windows.Forms.RadioButton
    Friend WithEvents textStartPos As System.Windows.Forms.TextBox
    Friend WithEvents radioStartPlace As System.Windows.Forms.RadioButton
    Friend WithEvents radioLowWinOdds As System.Windows.Forms.RadioButton
    Private _EndTime As Date

    Private Sub InitializeComponent()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.textWins = New System.Windows.Forms.TextBox()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.textNmbrRaces = New System.Windows.Forms.TextBox()
        Me.textTotWinAmount = New System.Windows.Forms.TextBox()
        Me.textTotBetAmount = New System.Windows.Forms.TextBox()
        Me.labelAmount = New System.Windows.Forms.Label()
        Me.textAmount = New System.Windows.Forms.TextBox()
        Me.buttonRun = New System.Windows.Forms.Button()
        Me.groupTop = New System.Windows.Forms.GroupBox()
        Me.radioAllDates = New System.Windows.Forms.RadioButton()
        Me.radioStartdate = New System.Windows.Forms.RadioButton()
        Me.dateStart = New System.Windows.Forms.DateTimePicker()
        Me.groupBottom = New System.Windows.Forms.GroupBox()
        Me.Label9 = New System.Windows.Forms.Label()
        Me.Label8 = New System.Windows.Forms.Label()
        Me.checkDataTable = New System.Windows.Forms.CheckBox()
        Me.textTime = New System.Windows.Forms.TextBox()
        Me.textDataType = New System.Windows.Forms.TextBox()
        Me.Label7 = New System.Windows.Forms.Label()
        Me.textStatus = New System.Windows.Forms.TextBox()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.textWinFactor = New System.Windows.Forms.TextBox()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.textLosses = New System.Windows.Forms.TextBox()
        Me.groupCenter = New System.Windows.Forms.GroupBox()
        Me.textStartPlaces = New System.Windows.Forms.TextBox()
        Me.checkStartPlaces = New System.Windows.Forms.CheckBox()
        Me.radioSpecificTrack = New System.Windows.Forms.RadioButton()
        Me.radioAllTracks = New System.Windows.Forms.RadioButton()
        Me.groupTrack = New System.Windows.Forms.GroupBox()
        Me.comboTracks = New System.Windows.Forms.ComboBox()
        Me.groupBottom2 = New System.Windows.Forms.GroupBox()
        Me.radioVolt = New System.Windows.Forms.RadioButton()
        Me.radioAuto = New System.Windows.Forms.RadioButton()
        Me.radioIgnore = New System.Windows.Forms.RadioButton()
        Me.radioLowWinOdds = New System.Windows.Forms.RadioButton()
        Me.radioStartPlace = New System.Windows.Forms.RadioButton()
        Me.textStartPos = New System.Windows.Forms.TextBox()
        Me.groupTop.SuspendLayout()
        Me.groupBottom.SuspendLayout()
        Me.groupCenter.SuspendLayout()
        Me.groupTrack.SuspendLayout()
        Me.groupBottom2.SuspendLayout()
        Me.SuspendLayout()
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(89, 144)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(75, 17)
        Me.Label4.TabIndex = 11
        Me.Label4.Text = "Total wins:"
        '
        'textWins
        '
        Me.textWins.Location = New System.Drawing.Point(166, 141)
        Me.textWins.Name = "textWins"
        Me.textWins.Size = New System.Drawing.Size(137, 22)
        Me.textWins.TabIndex = 9
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(45, 104)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(119, 17)
        Me.Label3.TabIndex = 8
        Me.Label3.Text = "Total win amount:"
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(48, 71)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(119, 17)
        Me.Label2.TabIndex = 7
        Me.Label2.Text = "Total bet amount:"
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(45, 40)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(119, 17)
        Me.Label1.TabIndex = 6
        Me.Label1.Text = "Total nmbr races:"
        '
        'textNmbrRaces
        '
        Me.textNmbrRaces.Location = New System.Drawing.Point(166, 40)
        Me.textNmbrRaces.Name = "textNmbrRaces"
        Me.textNmbrRaces.Size = New System.Drawing.Size(137, 22)
        Me.textNmbrRaces.TabIndex = 5
        '
        'textTotWinAmount
        '
        Me.textTotWinAmount.Location = New System.Drawing.Point(166, 104)
        Me.textTotWinAmount.Name = "textTotWinAmount"
        Me.textTotWinAmount.Size = New System.Drawing.Size(137, 22)
        Me.textTotWinAmount.TabIndex = 4
        '
        'textTotBetAmount
        '
        Me.textTotBetAmount.Location = New System.Drawing.Point(166, 68)
        Me.textTotBetAmount.Name = "textTotBetAmount"
        Me.textTotBetAmount.Size = New System.Drawing.Size(137, 22)
        Me.textTotBetAmount.TabIndex = 3
        '
        'labelAmount
        '
        Me.labelAmount.AutoSize = True
        Me.labelAmount.Location = New System.Drawing.Point(956, 13)
        Me.labelAmount.Name = "labelAmount"
        Me.labelAmount.Size = New System.Drawing.Size(56, 17)
        Me.labelAmount.TabIndex = 2
        Me.labelAmount.Text = "Amount"
        '
        'textAmount
        '
        Me.textAmount.Location = New System.Drawing.Point(959, 40)
        Me.textAmount.Name = "textAmount"
        Me.textAmount.Size = New System.Drawing.Size(100, 22)
        Me.textAmount.TabIndex = 1
        '
        'buttonRun
        '
        Me.buttonRun.Location = New System.Drawing.Point(959, 178)
        Me.buttonRun.Name = "buttonRun"
        Me.buttonRun.Size = New System.Drawing.Size(94, 23)
        Me.buttonRun.TabIndex = 0
        Me.buttonRun.Text = "Run"
        Me.buttonRun.UseVisualStyleBackColor = True
        '
        'groupTop
        '
        Me.groupTop.Controls.Add(Me.radioAllDates)
        Me.groupTop.Controls.Add(Me.radioStartdate)
        Me.groupTop.Controls.Add(Me.dateStart)
        Me.groupTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTop.Location = New System.Drawing.Point(0, 94)
        Me.groupTop.Name = "groupTop"
        Me.groupTop.Size = New System.Drawing.Size(1091, 103)
        Me.groupTop.TabIndex = 1
        Me.groupTop.TabStop = False
        Me.groupTop.Text = "Select races"
        '
        'radioAllDates
        '
        Me.radioAllDates.AutoSize = True
        Me.radioAllDates.Location = New System.Drawing.Point(27, 36)
        Me.radioAllDates.Name = "radioAllDates"
        Me.radioAllDates.Size = New System.Drawing.Size(83, 21)
        Me.radioAllDates.TabIndex = 3
        Me.radioAllDates.TabStop = True
        Me.radioAllDates.Text = "All dates"
        Me.radioAllDates.UseVisualStyleBackColor = True
        '
        'radioStartdate
        '
        Me.radioStartdate.AutoSize = True
        Me.radioStartdate.Location = New System.Drawing.Point(27, 64)
        Me.radioStartdate.Name = "radioStartdate"
        Me.radioStartdate.Size = New System.Drawing.Size(91, 21)
        Me.radioStartdate.TabIndex = 4
        Me.radioStartdate.TabStop = True
        Me.radioStartdate.Text = "Start date"
        Me.radioStartdate.UseVisualStyleBackColor = True
        '
        'dateStart
        '
        Me.dateStart.Location = New System.Drawing.Point(144, 61)
        Me.dateStart.Name = "dateStart"
        Me.dateStart.Size = New System.Drawing.Size(200, 22)
        Me.dateStart.TabIndex = 5
        '
        'groupBottom
        '
        Me.groupBottom.Controls.Add(Me.Label9)
        Me.groupBottom.Controls.Add(Me.Label8)
        Me.groupBottom.Controls.Add(Me.checkDataTable)
        Me.groupBottom.Controls.Add(Me.textTime)
        Me.groupBottom.Controls.Add(Me.textDataType)
        Me.groupBottom.Controls.Add(Me.Label7)
        Me.groupBottom.Controls.Add(Me.textStatus)
        Me.groupBottom.Controls.Add(Me.Label6)
        Me.groupBottom.Controls.Add(Me.textWinFactor)
        Me.groupBottom.Controls.Add(Me.Label5)
        Me.groupBottom.Controls.Add(Me.textLosses)
        Me.groupBottom.Controls.Add(Me.textAmount)
        Me.groupBottom.Controls.Add(Me.Label2)
        Me.groupBottom.Controls.Add(Me.labelAmount)
        Me.groupBottom.Controls.Add(Me.Label4)
        Me.groupBottom.Controls.Add(Me.buttonRun)
        Me.groupBottom.Controls.Add(Me.textWins)
        Me.groupBottom.Controls.Add(Me.Label3)
        Me.groupBottom.Controls.Add(Me.textTotBetAmount)
        Me.groupBottom.Controls.Add(Me.textTotWinAmount)
        Me.groupBottom.Controls.Add(Me.Label1)
        Me.groupBottom.Controls.Add(Me.textNmbrRaces)
        Me.groupBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.groupBottom.Location = New System.Drawing.Point(0, 366)
        Me.groupBottom.Name = "groupBottom"
        Me.groupBottom.Size = New System.Drawing.Size(1091, 212)
        Me.groupBottom.TabIndex = 2
        Me.groupBottom.TabStop = False
        Me.groupBottom.Text = "Result"
        '
        'Label9
        '
        Me.Label9.AutoSize = True
        Me.Label9.Location = New System.Drawing.Point(560, 149)
        Me.Label9.Name = "Label9"
        Me.Label9.Size = New System.Drawing.Size(84, 17)
        Me.Label9.TabIndex = 22
        Me.Label9.Text = "Data object:"
        '
        'Label8
        '
        Me.Label8.AutoSize = True
        Me.Label8.Location = New System.Drawing.Point(515, 184)
        Me.Label8.Name = "Label8"
        Me.Label8.Size = New System.Drawing.Size(129, 17)
        Me.Label8.TabIndex = 21
        Me.Label8.Text = "Time elapsed (ms):"
        '
        'checkDataTable
        '
        Me.checkDataTable.AutoSize = True
        Me.checkDataTable.Location = New System.Drawing.Point(959, 112)
        Me.checkDataTable.Name = "checkDataTable"
        Me.checkDataTable.Size = New System.Drawing.Size(125, 21)
        Me.checkDataTable.TabIndex = 20
        Me.checkDataTable.Text = "Use DataTable"
        Me.checkDataTable.UseVisualStyleBackColor = True
        '
        'textTime
        '
        Me.textTime.Location = New System.Drawing.Point(646, 184)
        Me.textTime.Name = "textTime"
        Me.textTime.Size = New System.Drawing.Size(100, 22)
        Me.textTime.TabIndex = 19
        '
        'textDataType
        '
        Me.textDataType.Location = New System.Drawing.Point(646, 144)
        Me.textDataType.Name = "textDataType"
        Me.textDataType.Size = New System.Drawing.Size(100, 22)
        Me.textDataType.TabIndex = 18
        '
        'Label7
        '
        Me.Label7.AutoSize = True
        Me.Label7.Location = New System.Drawing.Point(562, 57)
        Me.Label7.Name = "Label7"
        Me.Label7.Size = New System.Drawing.Size(82, 17)
        Me.Label7.TabIndex = 17
        Me.Label7.Text = "Test status:"
        '
        'textStatus
        '
        Me.textStatus.Location = New System.Drawing.Point(646, 54)
        Me.textStatus.Name = "textStatus"
        Me.textStatus.Size = New System.Drawing.Size(100, 22)
        Me.textStatus.TabIndex = 16
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(538, 112)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(106, 17)
        Me.Label6.TabIndex = 15
        Me.Label6.Text = "Final win factor:"
        '
        'textWinFactor
        '
        Me.textWinFactor.Location = New System.Drawing.Point(646, 107)
        Me.textWinFactor.Name = "textWinFactor"
        Me.textWinFactor.Size = New System.Drawing.Size(137, 22)
        Me.textWinFactor.TabIndex = 14
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(76, 184)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(88, 17)
        Me.Label5.TabIndex = 13
        Me.Label5.Text = "Total losses:"
        '
        'textLosses
        '
        Me.textLosses.Location = New System.Drawing.Point(166, 181)
        Me.textLosses.Name = "textLosses"
        Me.textLosses.Size = New System.Drawing.Size(137, 22)
        Me.textLosses.TabIndex = 12
        '
        'groupCenter
        '
        Me.groupCenter.Controls.Add(Me.textStartPos)
        Me.groupCenter.Controls.Add(Me.radioStartPlace)
        Me.groupCenter.Controls.Add(Me.radioLowWinOdds)
        Me.groupCenter.Controls.Add(Me.textStartPlaces)
        Me.groupCenter.Controls.Add(Me.checkStartPlaces)
        Me.groupCenter.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupCenter.Location = New System.Drawing.Point(0, 197)
        Me.groupCenter.Name = "groupCenter"
        Me.groupCenter.Size = New System.Drawing.Size(1091, 79)
        Me.groupCenter.TabIndex = 3
        Me.groupCenter.TabStop = False
        Me.groupCenter.Text = "Select start places"
        '
        'textStartPlaces
        '
        Me.textStartPlaces.Location = New System.Drawing.Point(451, 21)
        Me.textStartPlaces.Name = "textStartPlaces"
        Me.textStartPlaces.Size = New System.Drawing.Size(218, 22)
        Me.textStartPlaces.TabIndex = 6
        '
        'checkStartPlaces
        '
        Me.checkStartPlaces.AutoSize = True
        Me.checkStartPlaces.Location = New System.Drawing.Point(281, 22)
        Me.checkStartPlaces.Name = "checkStartPlaces"
        Me.checkStartPlaces.Size = New System.Drawing.Size(146, 21)
        Me.checkStartPlaces.TabIndex = 3
        Me.checkStartPlaces.Text = "Select start places"
        Me.checkStartPlaces.UseVisualStyleBackColor = True
        '
        'radioSpecificTrack
        '
        Me.radioSpecificTrack.AutoSize = True
        Me.radioSpecificTrack.Location = New System.Drawing.Point(27, 62)
        Me.radioSpecificTrack.Name = "radioSpecificTrack"
        Me.radioSpecificTrack.Size = New System.Drawing.Size(113, 21)
        Me.radioSpecificTrack.TabIndex = 7
        Me.radioSpecificTrack.TabStop = True
        Me.radioSpecificTrack.Text = "Specific track"
        Me.radioSpecificTrack.UseVisualStyleBackColor = True
        '
        'radioAllTracks
        '
        Me.radioAllTracks.AutoSize = True
        Me.radioAllTracks.Location = New System.Drawing.Point(27, 34)
        Me.radioAllTracks.Name = "radioAllTracks"
        Me.radioAllTracks.Size = New System.Drawing.Size(86, 21)
        Me.radioAllTracks.TabIndex = 6
        Me.radioAllTracks.TabStop = True
        Me.radioAllTracks.Text = "All tracks"
        Me.radioAllTracks.UseVisualStyleBackColor = True
        '
        'groupTrack
        '
        Me.groupTrack.Controls.Add(Me.comboTracks)
        Me.groupTrack.Controls.Add(Me.radioAllTracks)
        Me.groupTrack.Controls.Add(Me.radioSpecificTrack)
        Me.groupTrack.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTrack.Location = New System.Drawing.Point(0, 0)
        Me.groupTrack.Name = "groupTrack"
        Me.groupTrack.Size = New System.Drawing.Size(1091, 94)
        Me.groupTrack.TabIndex = 4
        Me.groupTrack.TabStop = False
        Me.groupTrack.Text = "Select track"
        '
        'comboTracks
        '
        Me.comboTracks.FormattingEnabled = True
        Me.comboTracks.Location = New System.Drawing.Point(196, 57)
        Me.comboTracks.Name = "comboTracks"
        Me.comboTracks.Size = New System.Drawing.Size(121, 24)
        Me.comboTracks.TabIndex = 8
        '
        'groupBottom2
        '
        Me.groupBottom2.Controls.Add(Me.radioVolt)
        Me.groupBottom2.Controls.Add(Me.radioAuto)
        Me.groupBottom2.Controls.Add(Me.radioIgnore)
        Me.groupBottom2.Dock = System.Windows.Forms.DockStyle.Fill
        Me.groupBottom2.Location = New System.Drawing.Point(0, 276)
        Me.groupBottom2.Name = "groupBottom2"
        Me.groupBottom2.Size = New System.Drawing.Size(1091, 302)
        Me.groupBottom2.TabIndex = 5
        Me.groupBottom2.TabStop = False
        Me.groupBottom2.Text = "Select start type"
        '
        'radioVolt
        '
        Me.radioVolt.AutoSize = True
        Me.radioVolt.Location = New System.Drawing.Point(133, 73)
        Me.radioVolt.Name = "radioVolt"
        Me.radioVolt.Size = New System.Drawing.Size(53, 21)
        Me.radioVolt.TabIndex = 2
        Me.radioVolt.TabStop = True
        Me.radioVolt.Text = "Volt"
        Me.radioVolt.UseVisualStyleBackColor = True
        '
        'radioAuto
        '
        Me.radioAuto.AutoSize = True
        Me.radioAuto.Location = New System.Drawing.Point(133, 46)
        Me.radioAuto.Name = "radioAuto"
        Me.radioAuto.Size = New System.Drawing.Size(58, 21)
        Me.radioAuto.TabIndex = 1
        Me.radioAuto.TabStop = True
        Me.radioAuto.Text = "Auto"
        Me.radioAuto.UseVisualStyleBackColor = True
        '
        'radioIgnore
        '
        Me.radioIgnore.AutoSize = True
        Me.radioIgnore.Location = New System.Drawing.Point(133, 16)
        Me.radioIgnore.Name = "radioIgnore"
        Me.radioIgnore.Size = New System.Drawing.Size(69, 21)
        Me.radioIgnore.TabIndex = 0
        Me.radioIgnore.TabStop = True
        Me.radioIgnore.Text = "Ignore"
        Me.radioIgnore.UseVisualStyleBackColor = True
        '
        'radioLowWinOdds
        '
        Me.radioLowWinOdds.AutoSize = True
        Me.radioLowWinOdds.Location = New System.Drawing.Point(67, 21)
        Me.radioLowWinOdds.Name = "radioLowWinOdds"
        Me.radioLowWinOdds.Size = New System.Drawing.Size(160, 21)
        Me.radioLowWinOdds.TabIndex = 7
        Me.radioLowWinOdds.TabStop = True
        Me.radioLowWinOdds.Text = "Lowest winnser odds"
        Me.radioLowWinOdds.UseVisualStyleBackColor = True
        '
        'radioStartPlace
        '
        Me.radioStartPlace.AutoSize = True
        Me.radioStartPlace.Location = New System.Drawing.Point(67, 52)
        Me.radioStartPlace.Name = "radioStartPlace"
        Me.radioStartPlace.Size = New System.Drawing.Size(137, 21)
        Me.radioStartPlace.TabIndex = 8
        Me.radioStartPlace.TabStop = True
        Me.radioStartPlace.Text = "Specific start pos"
        Me.radioStartPlace.UseVisualStyleBackColor = True
        '
        'textStartPos
        '
        Me.textStartPos.Location = New System.Drawing.Point(281, 52)
        Me.textStartPos.Name = "textStartPos"
        Me.textStartPos.Size = New System.Drawing.Size(137, 22)
        Me.textStartPos.TabIndex = 9
        '
        'TestForm
        '
        Me.ClientSize = New System.Drawing.Size(1091, 578)
        Me.Controls.Add(Me.groupBottom)
        Me.Controls.Add(Me.groupBottom2)
        Me.Controls.Add(Me.groupCenter)
        Me.Controls.Add(Me.groupTop)
        Me.Controls.Add(Me.groupTrack)
        Me.Name = "TestForm"
        Me.Text = "NoNoBet Test"
        Me.groupTop.ResumeLayout(False)
        Me.groupTop.PerformLayout()
        Me.groupBottom.ResumeLayout(False)
        Me.groupBottom.PerformLayout()
        Me.groupCenter.ResumeLayout(False)
        Me.groupCenter.PerformLayout()
        Me.groupTrack.ResumeLayout(False)
        Me.groupTrack.PerformLayout()
        Me.groupBottom2.ResumeLayout(False)
        Me.groupBottom2.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub buttonRun_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonRun.Click
        ResetCounters()
        _BetAmount = CType(textAmount.Text, Decimal)
        RunTest()
    End Sub

    Private Sub ResetCounters()
        _NmbrRaces = 0
        _ToBetAmount = 0
        _TotLosses = 0
        _TotWinAmount = 0
        _TotWins = 0
    End Sub

    Public Function GetRaceEkipageByStartPos(ByVal raceId As Integer, ByVal startPos As Integer, _
                                             ByRef finishPlace As Integer, ByRef winOdds As Decimal, ByRef placeOdds As Decimal) As Boolean
        Dim sql As String = "SELECT * FROM ekipage JOIN race_ekipage ON (race_ekipage.ekipage_id = ekipage.id) " & _
                             "WHERE (race_ekipage.race_id = " & raceId & ") AND (ekipage.start_place = " & startPos & ")"

        Dim dbReader As Npgsql.NpgsqlDataReader = MyBase.DbConnection.ExecuteSqlCommand(sql)

        finishPlace = 0
        winOdds = 0
        placeOdds = 0

        If dbReader.Read Then
            finishPlace = CType(dbReader.Item("finish_place"), Integer)
            winOdds = CType(dbReader.Item("winner_odds"), Decimal)
            placeOdds = CType(dbReader.Item("place_odds"), Decimal)
        Else
            dbReader.Close()
            Return False
        End If

        dbReader.Close()
        Return True
    End Function

    Private Sub BetRace(ByVal raceId As Integer, ByVal amount As Decimal)
        Dim winOdds As Decimal = 0
        Dim placeOdds As Decimal = 0
        Dim finishPlace As Integer = 0

        If radioLowWinOdds.Checked Then
            GetRaceEkipageByWinnerOdds(raceId, winOdds, finishPlace)
        ElseIf radioStartPlace.Checked Then
            Dim sPos As Integer = CType(textStartPos.Text, Integer)
            If GetRaceEkipageByStartPos(raceId, sPos, finishPlace, winOdds, placeOdds) Then

            End If
        Else
            Return
        End If

        _NmbrRaces += 1
        _ToBetAmount += amount

        If (finishPlace = 1) Then
            _TotWins += 1
            _TotWinAmount += winOdds * amount
        Else
            _TotLosses += 1
        End If

        textNmbrRaces.Text = _NmbrRaces.ToString
        textTotBetAmount.Text = _ToBetAmount.ToString
        textTotWinAmount.Text = _TotWinAmount.ToString
        textWins.Text = _TotWins.ToString
        textLosses.Text = _TotLosses.ToString
        Application.DoEvents()

    End Sub

    Private Sub GetRaceEkipageByWinnerOdds(ByVal raceId As Integer, ByRef winOdds As Decimal, ByRef finishPlace As Integer)
        Dim sql As String = "SELECT * FROM ekipage JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id AND " + _
                            "race_ekipage.race_id = " & raceId & ")"

        If checkStartPlaces.Checked Then
            If (textStartPlaces.Text IsNot Nothing) Then
                If (textStartPlaces.Text.Trim.Length > 0) Then
                    sql += " WHERE (ekipage.start_place in (" + textStartPlaces.Text.Trim + "))"
                End If
            End If
        End If

        sql += " ORDER BY winner_odds"

        Dim raceLineReader As Npgsql.NpgsqlDataReader = MyBase.DbConnection.ExecuteSqlCommand(sql)

        If raceLineReader.Read Then
            winOdds = CType(raceLineReader.Item("winner_odds"), Decimal)
            finishPlace = CType(raceLineReader.Item("finish_place"), Integer)
        End If

        raceLineReader.Close()
    End Sub

    Private Sub GetRaceEkipageByStartPos(ByVal raceId As Integer, ByVal startPos As Integer, ByRef winOdds As Decimal, ByRef finishPlace As Integer)
        Dim sql As String = "SELECT * FROM ekipage JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id AND " + _
                            "race_ekipage.race_id = " & raceId & ") WHERE (ekipage.start_place = " & startPos & ") "

        Dim raceLineReader As Npgsql.NpgsqlDataReader = MyBase.DbConnection.ExecuteSqlCommand(sql)

        If raceLineReader.Read Then
            winOdds = CType(raceLineReader.Item("winner_odds"), Decimal)
            finishPlace = CType(raceLineReader.Item("finish_place"), Integer)
        End If

        raceLineReader.Close()
    End Sub

    Private Sub ShowDataType()
        If checkDataTable.Checked Then
            textDataType.Text = "DataTable"
        Else
            textDataType.Text = "DataReader"
        End If
    End Sub

    Private Sub StartTimer()
        _StartTime = Now
        textTime.Text = ""
    End Sub

    Private Sub StopTimer()
        _EndTime = Now
    End Sub

    Private Sub ShowTimer()
        Dim t As TimeSpan = _EndTime.Subtract(_StartTime)

        textTime.Text = t.TotalMilliseconds
    End Sub

    Private Sub RunTest()
        textStatus.Text = "Running..."
        textWinFactor.Text = ""
        StartTimer()
        ShowDataType()

        Dim sql As String = "SELECT DISTINCT id FROM race"
        Dim whereAdded As Boolean = False

        If radioSpecificTrack.Checked Then
            If (comboTracks.SelectedItem IsNot Nothing) Then
                Dim trackName As String = comboTracks.SelectedItem.ToString
                If (trackName.Length > 0) Then
                    sql += " WHERE (track = '" + trackName + "')"
                    whereAdded = True
                End If
            End If
        End If

        If radioStartdate.Checked Then
            If (Not whereAdded) Then
                sql += " WHERE "
                whereAdded = True
            Else
                sql += " AND "
            End If
            sql += "(date >= " + DbConnection.DateToSqlString(dateStart.Value, DbConnection.DateFormatMode.DateOnly) + ")"
        End If

        If (Not radioIgnore.Checked) Then
            Dim autoStartValue As String

            If radioAuto.Checked Then
                autoStartValue = "TRUE"
            Else
                autoStartValue = "FALSE"
            End If

            If (Not whereAdded) Then
                sql += " WHERE "
                whereAdded = True
            Else
                sql += " AND "
            End If

            sql += "("

            If radioVolt.Checked Then
                sql += "NOT "
            End If

            sql += "auto_start)"
        End If

        If checkDataTable.Checked Then
            Dim dTable As DataTable = MyBase.DbConnection.ExecuteSql(sql)

            For rIndex As Integer = 0 To dTable.Rows.Count - 1
                Dim dRow As DataRow = dTable.Rows.Item(rIndex)
                Dim raceId As Integer = CType(dRow.Item("id"), Integer)
                BetRace(raceId, _BetAmount)
            Next
            dTable.Clear()
            dTable.Dispose()
        Else
            Dim raceReader As Npgsql.NpgsqlDataReader = MyBase.DbConnection.ExecuteSqlCommand(sql)

            While raceReader.Read
                Dim raceId As Integer = CType(raceReader.Item("id"), Integer)
                BetRace(raceId, _BetAmount)
            End While

            raceReader.Close()
        End If
        StopTimer()
        ShowTimer()

        textStatus.Text = "Completed"
        If (_ToBetAmount > 0) And (_TotWinAmount > 0) Then
            textWinFactor.Text = Decimal.Round(_TotWinAmount / _ToBetAmount, 4).ToString
        Else
            textWinFactor.Text = "0"
        End If
    End Sub

    Private Sub radioAllDates_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles radioAllDates.CheckedChanged, radioStartdate.CheckedChanged
        If _IsLoaded Then
            dateStart.Enabled = radioStartdate.Checked
        End If
    End Sub

    Private Sub radioAllTracks_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles radioAllTracks.CheckedChanged, radioSpecificTrack.CheckedChanged
        If _IsLoaded Then
            comboTracks.Enabled = radioSpecificTrack.Checked
            If radioSpecificTrack.Checked Then
                FillTracksComboBox()
            End If
        End If
    End Sub

    Private Sub FillTracksComboBox()
        If (Not _ComboIsFilled) Then
            comboTracks.BeginUpdate()
            comboTracks.Items.Clear()

            Dim sql As String = "SELECT DISTINCT track FROM race ORDER BY track"
            Dim trackReader As Npgsql.NpgsqlDataReader = MyBase.DbConnection.ExecuteSqlCommand(sql)

            While trackReader.Read
                Dim trackName As String = CType(trackReader.Item("track"), String)
                comboTracks.Items.Add(trackName)
            End While

            trackReader.Close()
            comboTracks.EndUpdate()
            _ComboIsFilled = True
        End If
    End Sub

    Private Sub checkStartPlaces_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles checkStartPlaces.CheckedChanged
        If _IsLoaded Then
            textStartPlaces.Enabled = checkStartPlaces.Checked
        End If
    End Sub

    Private Sub comboTracks_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles comboTracks.SelectedIndexChanged
        If _IsLoaded Then

        End If
    End Sub

    Private Sub TestForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        textAmount.Text = "100"
        radioAllDates.Checked = True
        dateStart.Enabled = False
        radioAllTracks.Checked = True
        comboTracks.Enabled = False
        checkStartPlaces.Checked = False
        textStartPlaces.Enabled = False
        radioIgnore.Checked = True
        textStatus.Text = "Not Started"
        checkDataTable.Checked = False
        radioLowWinOdds.Checked = True
        _IsLoaded = True
    End Sub

End Class
