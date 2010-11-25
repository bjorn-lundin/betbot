Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface

Public Class RaceBetSim
    Inherits BaseForm
    Friend WithEvents gridRaces As BaseComponents.BaseGrid
    Friend WithEvents groupTop As System.Windows.Forms.GroupBox
    Friend WithEvents groupTopBottom As System.Windows.Forms.GroupBox
    Friend WithEvents radioIgnore As System.Windows.Forms.RadioButton
    Friend WithEvents radioAuto As System.Windows.Forms.RadioButton
    Friend WithEvents radioVolt As System.Windows.Forms.RadioButton
    Friend WithEvents buttonShowRaces As System.Windows.Forms.Button
    Friend WithEvents labelEndDate As System.Windows.Forms.Label
    Friend WithEvents dpStartdate As System.Windows.Forms.DateTimePicker
    Friend WithEvents labelTrack As System.Windows.Forms.Label
    Friend WithEvents dpEndDate As System.Windows.Forms.DateTimePicker
    Friend WithEvents comboTracks As System.Windows.Forms.ComboBox
    Friend WithEvents labelStartDate As System.Windows.Forms.Label
    Friend WithEvents checkByStartPos As System.Windows.Forms.CheckBox
    Friend WithEvents textStartPos As System.Windows.Forms.TextBox

    Private Sub InitializeComponent()
        Me.groupTop = New System.Windows.Forms.GroupBox()
        Me.gridRaces = New BaseComponents.BaseGrid()
        Me.labelEndDate = New System.Windows.Forms.Label()
        Me.dpEndDate = New System.Windows.Forms.DateTimePicker()
        Me.labelStartDate = New System.Windows.Forms.Label()
        Me.dpStartdate = New System.Windows.Forms.DateTimePicker()
        Me.labelTrack = New System.Windows.Forms.Label()
        Me.comboTracks = New System.Windows.Forms.ComboBox()
        Me.groupTopBottom = New System.Windows.Forms.GroupBox()
        Me.buttonShowRaces = New System.Windows.Forms.Button()
        Me.radioVolt = New System.Windows.Forms.RadioButton()
        Me.radioAuto = New System.Windows.Forms.RadioButton()
        Me.radioIgnore = New System.Windows.Forms.RadioButton()
        Me.checkByStartPos = New System.Windows.Forms.CheckBox()
        Me.textStartPos = New System.Windows.Forms.TextBox()
        Me.groupTop.SuspendLayout()
        CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.groupTopBottom.SuspendLayout()
        Me.SuspendLayout()
        '
        'groupTop
        '
        Me.groupTop.Controls.Add(Me.groupTopBottom)
        Me.groupTop.Controls.Add(Me.gridRaces)
        Me.groupTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTop.Location = New System.Drawing.Point(0, 0)
        Me.groupTop.Name = "groupTop"
        Me.groupTop.Size = New System.Drawing.Size(841, 381)
        Me.groupTop.TabIndex = 0
        Me.groupTop.TabStop = False
        Me.groupTop.Text = "Race Selection"
        '
        'gridRaces
        '
        Me.gridRaces.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.gridRaces.Dock = System.Windows.Forms.DockStyle.Top
        Me.gridRaces.Location = New System.Drawing.Point(3, 18)
        Me.gridRaces.Name = "gridRaces"
        Me.gridRaces.RowTemplate.Height = 24
        Me.gridRaces.Size = New System.Drawing.Size(835, 190)
        Me.gridRaces.TabIndex = 0
        '
        'labelEndDate
        '
        Me.labelEndDate.AutoSize = True
        Me.labelEndDate.Location = New System.Drawing.Point(191, 71)
        Me.labelEndDate.Name = "labelEndDate"
        Me.labelEndDate.Size = New System.Drawing.Size(65, 17)
        Me.labelEndDate.TabIndex = 17
        Me.labelEndDate.Text = "End date"
        '
        'dpEndDate
        '
        Me.dpEndDate.Location = New System.Drawing.Point(194, 95)
        Me.dpEndDate.Name = "dpEndDate"
        Me.dpEndDate.Size = New System.Drawing.Size(200, 22)
        Me.dpEndDate.TabIndex = 16
        '
        'labelStartDate
        '
        Me.labelStartDate.AutoSize = True
        Me.labelStartDate.Location = New System.Drawing.Point(191, 22)
        Me.labelStartDate.Name = "labelStartDate"
        Me.labelStartDate.Size = New System.Drawing.Size(70, 17)
        Me.labelStartDate.TabIndex = 15
        Me.labelStartDate.Text = "Start date"
        '
        'dpStartdate
        '
        Me.dpStartdate.Location = New System.Drawing.Point(194, 46)
        Me.dpStartdate.Name = "dpStartdate"
        Me.dpStartdate.Size = New System.Drawing.Size(200, 22)
        Me.dpStartdate.TabIndex = 14
        '
        'labelTrack
        '
        Me.labelTrack.AutoSize = True
        Me.labelTrack.Location = New System.Drawing.Point(12, 22)
        Me.labelTrack.Name = "labelTrack"
        Me.labelTrack.Size = New System.Drawing.Size(44, 17)
        Me.labelTrack.TabIndex = 13
        Me.labelTrack.Text = "Track"
        '
        'comboTracks
        '
        Me.comboTracks.FormattingEnabled = True
        Me.comboTracks.Location = New System.Drawing.Point(12, 45)
        Me.comboTracks.Name = "comboTracks"
        Me.comboTracks.Size = New System.Drawing.Size(162, 24)
        Me.comboTracks.TabIndex = 12
        '
        'groupTopBottom
        '
        Me.groupTopBottom.Controls.Add(Me.textStartPos)
        Me.groupTopBottom.Controls.Add(Me.checkByStartPos)
        Me.groupTopBottom.Controls.Add(Me.radioIgnore)
        Me.groupTopBottom.Controls.Add(Me.radioAuto)
        Me.groupTopBottom.Controls.Add(Me.radioVolt)
        Me.groupTopBottom.Controls.Add(Me.buttonShowRaces)
        Me.groupTopBottom.Controls.Add(Me.labelEndDate)
        Me.groupTopBottom.Controls.Add(Me.dpStartdate)
        Me.groupTopBottom.Controls.Add(Me.labelTrack)
        Me.groupTopBottom.Controls.Add(Me.dpEndDate)
        Me.groupTopBottom.Controls.Add(Me.comboTracks)
        Me.groupTopBottom.Controls.Add(Me.labelStartDate)
        Me.groupTopBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.groupTopBottom.Location = New System.Drawing.Point(3, 233)
        Me.groupTopBottom.Name = "groupTopBottom"
        Me.groupTopBottom.Size = New System.Drawing.Size(835, 145)
        Me.groupTopBottom.TabIndex = 1
        Me.groupTopBottom.TabStop = False
        '
        'buttonShowRaces
        '
        Me.buttonShowRaces.Location = New System.Drawing.Point(720, 116)
        Me.buttonShowRaces.Name = "buttonShowRaces"
        Me.buttonShowRaces.Size = New System.Drawing.Size(106, 23)
        Me.buttonShowRaces.TabIndex = 18
        Me.buttonShowRaces.Text = "Show Races"
        Me.buttonShowRaces.UseVisualStyleBackColor = True
        '
        'radioVolt
        '
        Me.radioVolt.AutoSize = True
        Me.radioVolt.Location = New System.Drawing.Point(460, 45)
        Me.radioVolt.Name = "radioVolt"
        Me.radioVolt.Size = New System.Drawing.Size(53, 21)
        Me.radioVolt.TabIndex = 19
        Me.radioVolt.TabStop = True
        Me.radioVolt.Text = "Volt"
        Me.radioVolt.UseVisualStyleBackColor = True
        '
        'radioAuto
        '
        Me.radioAuto.AutoSize = True
        Me.radioAuto.Location = New System.Drawing.Point(460, 69)
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
        Me.radioIgnore.Location = New System.Drawing.Point(460, 93)
        Me.radioIgnore.Name = "radioIgnore"
        Me.radioIgnore.Size = New System.Drawing.Size(69, 21)
        Me.radioIgnore.TabIndex = 21
        Me.radioIgnore.TabStop = True
        Me.radioIgnore.Text = "Ignore"
        Me.radioIgnore.UseVisualStyleBackColor = True
        '
        'checkByStartPos
        '
        Me.checkByStartPos.AutoSize = True
        Me.checkByStartPos.Location = New System.Drawing.Point(557, 45)
        Me.checkByStartPos.Name = "checkByStartPos"
        Me.checkByStartPos.Size = New System.Drawing.Size(104, 21)
        Me.checkByStartPos.TabIndex = 22
        Me.checkByStartPos.Text = "By StartPos"
        Me.checkByStartPos.UseVisualStyleBackColor = True
        '
        'textStartPos
        '
        Me.textStartPos.Location = New System.Drawing.Point(679, 46)
        Me.textStartPos.Name = "textStartPos"
        Me.textStartPos.Size = New System.Drawing.Size(147, 22)
        Me.textStartPos.TabIndex = 23
        '
        'RaceBetSim
        '
        Me.ClientSize = New System.Drawing.Size(841, 511)
        Me.Controls.Add(Me.groupTop)
        Me.Name = "RaceBetSim"
        Me.groupTop.ResumeLayout(False)
        CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).EndInit()
        Me.groupTopBottom.ResumeLayout(False)
        Me.groupTopBottom.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Private _IsLoaded As Boolean = False

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub CheckEnableStartPosTextBox()
        textStartPos.Enabled = checkByStartPos.Checked
    End Sub

    Private Sub buttonShowRaces_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonShowRaces.Click
        Dim sql As String = GetRaceSql(comboTracks.SelectedItem.ToString, dpStartdate.Value, dpEndDate.Value, checkByStartPos.Checked, textStartPos.Text)
        gridRaces.ExecuteSql(MyBase.DbConnection, sql)
    End Sub

    Private Sub checkByStartPos_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles checkByStartPos.CheckedChanged
        If _IsLoaded Then
            CheckEnableStartPosTextBox()
        End If
    End Sub

    Private Function GetRaceSql(ByVal trackName As String, ByVal startDate As Date, ByVal endDate As Date, ByVal useStartPos As Boolean, ByVal startPositions As String) As String
        Dim sql As String = "SELECT race.date as RaceDate, race.track,race.id as RaceId, ekipage.* FROM ekipage " & _
                             "JOIN race_ekipage ON (race_ekipage.ekipage_id = ekipage.id) " & _
                             "JOIN race ON (race_ekipage.race_id = race.id) " & _
                             "WHERE (race.track = " & DbInterface.DbConnection.SqlBuildValueString(trackName) & ") " & _
                               "AND (race.date >= " & DbConnection.DateToSqlString(startDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ") " & _
                               "AND (race.date <= " & DbConnection.DateToSqlString(endDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ") "
        If useStartPos Then
            sql &= "AND (ekipage.start_place in (" & startPositions & ")) "
        End If

        sql &= "ORDER BY race.date ASC, race.id"

        Return sql
    End Function

    Private Sub RaceBetSim_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        StatForm.FillTracksComboBox(MyBase.DbConnection, comboTracks)
        comboTracks.SelectedIndex = 0
        dpEndDate.Value = Today
        dpStartdate.Value = Today
        radioVolt.Checked = True
        checkByStartPos.Checked = False
        CheckEnableStartPosTextBox()
        _IsLoaded = True
    End Sub

End Class
