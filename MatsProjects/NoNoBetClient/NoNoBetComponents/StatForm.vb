Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface

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
        Me.gridStartPosStats = New BaseComponents.BaseGrid()
        Me.comboTracks = New System.Windows.Forms.ComboBox()
        Me.labelTrack = New System.Windows.Forms.Label()
        Me.buttonStartPosStats = New System.Windows.Forms.Button()
        Me.groupTop.SuspendLayout()
        Me.groupTotEcuipages.SuspendLayout()
        Me.groupTotWinEquipages.SuspendLayout()
        Me.groupStartPosStat.SuspendLayout()
        CType(Me.gridStartPosStats, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        '
        'groupTop
        '
        Me.groupTop.Controls.Add(Me.buttonTotRaces)
        Me.groupTop.Controls.Add(Me.textTotRaces)
        Me.groupTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTop.Location = New System.Drawing.Point(0, 0)
        Me.groupTop.Name = "groupTop"
        Me.groupTop.Size = New System.Drawing.Size(577, 84)
        Me.groupTop.TabIndex = 0
        Me.groupTop.TabStop = False
        Me.groupTop.Text = "Total number races"
        '
        'buttonTotRaces
        '
        Me.buttonTotRaces.Location = New System.Drawing.Point(433, 42)
        Me.buttonTotRaces.Name = "buttonTotRaces"
        Me.buttonTotRaces.Size = New System.Drawing.Size(75, 23)
        Me.buttonTotRaces.TabIndex = 1
        Me.buttonTotRaces.Text = "Show"
        Me.buttonTotRaces.UseVisualStyleBackColor = True
        '
        'textTotRaces
        '
        Me.textTotRaces.Location = New System.Drawing.Point(32, 44)
        Me.textTotRaces.Name = "textTotRaces"
        Me.textTotRaces.Size = New System.Drawing.Size(181, 22)
        Me.textTotRaces.TabIndex = 0
        '
        'groupTotEcuipages
        '
        Me.groupTotEcuipages.Controls.Add(Me.buttonTotEquipages)
        Me.groupTotEcuipages.Controls.Add(Me.textTotEquipages)
        Me.groupTotEcuipages.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTotEcuipages.Location = New System.Drawing.Point(0, 84)
        Me.groupTotEcuipages.Name = "groupTotEcuipages"
        Me.groupTotEcuipages.Size = New System.Drawing.Size(577, 86)
        Me.groupTotEcuipages.TabIndex = 1
        Me.groupTotEcuipages.TabStop = False
        Me.groupTotEcuipages.Text = "Total number equipages"
        '
        'buttonTotEquipages
        '
        Me.buttonTotEquipages.Location = New System.Drawing.Point(433, 39)
        Me.buttonTotEquipages.Name = "buttonTotEquipages"
        Me.buttonTotEquipages.Size = New System.Drawing.Size(75, 23)
        Me.buttonTotEquipages.TabIndex = 3
        Me.buttonTotEquipages.Text = "Show"
        Me.buttonTotEquipages.UseVisualStyleBackColor = True
        '
        'textTotEquipages
        '
        Me.textTotEquipages.Location = New System.Drawing.Point(32, 41)
        Me.textTotEquipages.Name = "textTotEquipages"
        Me.textTotEquipages.Size = New System.Drawing.Size(181, 22)
        Me.textTotEquipages.TabIndex = 2
        '
        'groupTotWinEquipages
        '
        Me.groupTotWinEquipages.Controls.Add(Me.buttonTotWinEquipages)
        Me.groupTotWinEquipages.Controls.Add(Me.textToWinEquipages)
        Me.groupTotWinEquipages.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTotWinEquipages.Location = New System.Drawing.Point(0, 170)
        Me.groupTotWinEquipages.Name = "groupTotWinEquipages"
        Me.groupTotWinEquipages.Size = New System.Drawing.Size(577, 85)
        Me.groupTotWinEquipages.TabIndex = 2
        Me.groupTotWinEquipages.TabStop = False
        Me.groupTotWinEquipages.Text = "Total number winning equipages"
        '
        'buttonTotWinEquipages
        '
        Me.buttonTotWinEquipages.Location = New System.Drawing.Point(433, 41)
        Me.buttonTotWinEquipages.Name = "buttonTotWinEquipages"
        Me.buttonTotWinEquipages.Size = New System.Drawing.Size(75, 23)
        Me.buttonTotWinEquipages.TabIndex = 5
        Me.buttonTotWinEquipages.Text = "Show"
        Me.buttonTotWinEquipages.UseVisualStyleBackColor = True
        '
        'textToWinEquipages
        '
        Me.textToWinEquipages.Location = New System.Drawing.Point(32, 43)
        Me.textToWinEquipages.Name = "textToWinEquipages"
        Me.textToWinEquipages.Size = New System.Drawing.Size(181, 22)
        Me.textToWinEquipages.TabIndex = 4
        '
        'groupStartPosStat
        '
        Me.groupStartPosStat.Controls.Add(Me.buttonStartPosStats)
        Me.groupStartPosStat.Controls.Add(Me.labelTrack)
        Me.groupStartPosStat.Controls.Add(Me.comboTracks)
        Me.groupStartPosStat.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupStartPosStat.Location = New System.Drawing.Point(0, 255)
        Me.groupStartPosStat.Name = "groupStartPosStat"
        Me.groupStartPosStat.Size = New System.Drawing.Size(577, 100)
        Me.groupStartPosStat.TabIndex = 3
        Me.groupStartPosStat.TabStop = False
        Me.groupStartPosStat.Text = "Start position statistics"
        '
        'gridStartPosStats
        '
        Me.gridStartPosStats.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.gridStartPosStats.Dock = System.Windows.Forms.DockStyle.Fill
        Me.gridStartPosStats.Location = New System.Drawing.Point(0, 355)
        Me.gridStartPosStats.Name = "gridStartPosStats"
        Me.gridStartPosStats.RowTemplate.Height = 24
        Me.gridStartPosStats.Size = New System.Drawing.Size(577, 219)
        Me.gridStartPosStats.TabIndex = 0
        '
        'comboTracks
        '
        Me.comboTracks.FormattingEnabled = True
        Me.comboTracks.Location = New System.Drawing.Point(12, 52)
        Me.comboTracks.Name = "comboTracks"
        Me.comboTracks.Size = New System.Drawing.Size(162, 24)
        Me.comboTracks.TabIndex = 1
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
        'buttonStartPosStats
        '
        Me.buttonStartPosStats.Location = New System.Drawing.Point(433, 52)
        Me.buttonStartPosStats.Name = "buttonStartPosStats"
        Me.buttonStartPosStats.Size = New System.Drawing.Size(75, 23)
        Me.buttonStartPosStats.TabIndex = 6
        Me.buttonStartPosStats.Text = "Show"
        Me.buttonStartPosStats.UseVisualStyleBackColor = True
        '
        'StatForm
        '
        Me.ClientSize = New System.Drawing.Size(577, 574)
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
        Me.ResumeLayout(False)

    End Sub

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub buttonTotEquipages_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotEquipages.Click
        textTotEquipages.Text = MyBase.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM ekipage").ToString
    End Sub

    Private Sub buttonTotRaces_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotRaces.Click
        textTotRaces.Text = MyBase.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM race").ToString
    End Sub

    Private Sub buttonTotWinEquipages_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles buttonTotWinEquipages.Click
        textToWinEquipages.Text = MyBase.DbConnection.ExecuteSqlScalar("SELECT count(id) FROM ekipage WHERE finish_place = 1").ToString
    End Sub

    Private Sub FillTracksComboBox()
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
    End Sub

    Private Sub buttonStartPosStats_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonStartPosStats.Click
        Dim sql As String

        'sql = "SELECT ekipage.start_place, count(*) as cnt, race.track FROM ekipage " + _
        '      "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
        '      "JOIN race ON (race.id = race_ekipage.race_id) " + _
        '      "WHERE (ekipage.finish_place = 1) "

        sql = "SELECT * FROM (" + _
                "SELECT TrackLineRec.track ""Track"",TrackLineRec.start_place ""StartPos"",TrackLineRec.cnt ""NmbrWinners"",ROUND(100.0*TrackLineRec.cnt/TrackRec.cnt) ""%Winners"" FROM " + _
                  "(SELECT race.track,count(*) as cnt FROM ekipage " + _
                   "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
                   "JOIN race ON (race.id = race_ekipage.race_id) " + _
                   "WHERE (ekipage.finish_place = 1) " + _
                   "GROUP BY race.track) TrackRec " + _
                "JOIN " + _
                  "(SELECT ekipage.start_place,race.track,count(*) as cnt FROM ekipage " + _
                   "JOIN race_ekipage ON (ekipage.id = race_ekipage.ekipage_id) " + _
                   "JOIN race ON (race.id = race_ekipage.race_id) " + _
                   "WHERE (ekipage.finish_place = 1) " + _
                   "GROUP BY race.track,ekipage.start_place) TrackLineRec " + _
                "ON (TrackLineRec.track = TrackRec.track) " + _
              ")TrackView "


        If (comboTracks.SelectedItem IsNot Nothing) Then
            Dim track As String = CType(comboTracks.SelectedItem, String)
            'sql += "AND (race.track = '" + track + "') "
            sql += "WHERE (""Track"" = '" + track + "') "
        End If

        'sql += "GROUP BY race.track,ekipage.start_place " + _
        '       "ORDER BY race.track,cnt DESC"
        sql += "ORDER BY ""Track"",""NmbrWinners"" DESC"
        gridStartPosStats.ExecuteSql(MyBase.DbConnection, sql)

    End Sub

    Private Sub StatForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        FillTracksComboBox()
    End Sub

End Class
