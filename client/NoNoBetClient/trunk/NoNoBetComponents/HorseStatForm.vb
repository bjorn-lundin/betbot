Public Class HorseStatForm
    Inherits BaseComponents.BaseForm
    Friend WithEvents Grid As BaseComponents.BaseGrid
    Friend WithEvents TopPanel As System.Windows.Forms.Panel
    Friend WithEvents HorseNameLabel As System.Windows.Forms.Label
    Friend WithEvents HorseIdLabel As System.Windows.Forms.Label
    Friend WithEvents HorseNameText As System.Windows.Forms.TextBox
    Friend WithEvents HorseIdText As System.Windows.Forms.TextBox

    Private _HorseId As Integer = 0
    Private _Loaded As Boolean = False
    Private Const _BaseSql As String = "SELECT race.date,race.track,race.auto_start as auto,ekipage.finish_place as finish," + _
                               "ekipage.start_place as start,ekipage.distance as dist," + _
                               "ekipage.winner_odds winner,ekipage.place_odds as place,race.trio_odds as trio,race.tvilling_odds as tvilling,ekipage.time,ekipage.time_comment note," + _
                               "ekipage.shoes_front,ekipage.shoes_rear,driver.name as driver " + _
                        "FROM ekipage " + _
                        "JOIN horse ON (ekipage.horse_id = horse.id) " + _
                        "JOIN driver ON (ekipage.driver_id = driver.id) " + _
                        "JOIN race_ekipage ON (race_ekipage.ekipage_id = ekipage.id) " +
                        "JOIN race ON (race.id = race_ekipage.race_id) "

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Public Overloads Sub StartForm(ByVal dbCon As DbInterface.DbConnection, ByVal horseId As Integer)
        _HorseId = horseId
        MyBase.StartForm(dbCon)
    End Sub

    Private Sub InitializeComponent()
        Me.Grid = New BaseComponents.BaseGrid()
        Me.TopPanel = New System.Windows.Forms.Panel()
        Me.HorseNameLabel = New System.Windows.Forms.Label()
        Me.HorseIdLabel = New System.Windows.Forms.Label()
        Me.HorseNameText = New System.Windows.Forms.TextBox()
        Me.HorseIdText = New System.Windows.Forms.TextBox()
        CType(Me.Grid, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.TopPanel.SuspendLayout()
        Me.SuspendLayout()
        '
        'Grid
        '
        Me.Grid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.Grid.Dock = System.Windows.Forms.DockStyle.Fill
        Me.Grid.Location = New System.Drawing.Point(0, 88)
        Me.Grid.Name = "Grid"
        Me.Grid.RowTemplate.Height = 24
        Me.Grid.Size = New System.Drawing.Size(444, 203)
        Me.Grid.TabIndex = 0
        '
        'TopPanel
        '
        Me.TopPanel.Controls.Add(Me.HorseNameLabel)
        Me.TopPanel.Controls.Add(Me.HorseIdLabel)
        Me.TopPanel.Controls.Add(Me.HorseNameText)
        Me.TopPanel.Controls.Add(Me.HorseIdText)
        Me.TopPanel.Dock = System.Windows.Forms.DockStyle.Top
        Me.TopPanel.Location = New System.Drawing.Point(0, 0)
        Me.TopPanel.Name = "TopPanel"
        Me.TopPanel.Size = New System.Drawing.Size(444, 88)
        Me.TopPanel.TabIndex = 1
        '
        'HorseNameLabel
        '
        Me.HorseNameLabel.AutoSize = True
        Me.HorseNameLabel.Location = New System.Drawing.Point(82, 4)
        Me.HorseNameLabel.Name = "HorseNameLabel"
        Me.HorseNameLabel.Size = New System.Drawing.Size(85, 17)
        Me.HorseNameLabel.TabIndex = 3
        Me.HorseNameLabel.Text = "Horse name"
        '
        'HorseIdLabel
        '
        Me.HorseIdLabel.AutoSize = True
        Me.HorseIdLabel.Location = New System.Drawing.Point(7, 4)
        Me.HorseIdLabel.Name = "HorseIdLabel"
        Me.HorseIdLabel.Size = New System.Drawing.Size(61, 17)
        Me.HorseIdLabel.TabIndex = 2
        Me.HorseIdLabel.Text = "Horse id"
        '
        'HorseNameText
        '
        Me.HorseNameText.Location = New System.Drawing.Point(82, 24)
        Me.HorseNameText.Name = "HorseNameText"
        Me.HorseNameText.Size = New System.Drawing.Size(194, 22)
        Me.HorseNameText.TabIndex = 1
        '
        'HorseIdText
        '
        Me.HorseIdText.Location = New System.Drawing.Point(10, 24)
        Me.HorseIdText.Name = "HorseIdText"
        Me.HorseIdText.Size = New System.Drawing.Size(58, 22)
        Me.HorseIdText.TabIndex = 0
        '
        'HorseStatForm
        '
        Me.ClientSize = New System.Drawing.Size(444, 291)
        Me.Controls.Add(Me.Grid)
        Me.Controls.Add(Me.TopPanel)
        Me.Name = "HorseStatForm"
        CType(Me.Grid, System.ComponentModel.ISupportInitialize).EndInit()
        Me.TopPanel.ResumeLayout(False)
        Me.TopPanel.PerformLayout()
        Me.ResumeLayout(False)

    End Sub


    Private Sub FillHorseData()
        Dim sql As String = "SELECT name FROM horse WHERE id = " & GetHorseId()
        Dim dr As Npgsql.NpgsqlDataReader = DbConnection.ExecuteSqlCommand(sql)

        If dr.Read Then
            HorseNameText.Text = CType(dr.Item("name"), String)
        Else
            HorseNameText.Text = String.Empty
        End If

        dr.Close()
        dr = Nothing
    End Sub

    Private Sub FillGrid()
        Dim horseId As Integer = GetHorseId()
        Dim sql As String = Nothing

        If (horseId > 0) Then
            sql = _BaseSql + "WHERE ekipage.horse_id = " & horseId & " ORDER BY race.date desc"
        Else
            sql = _BaseSql + "WHERE null = null"
        End If

        Grid.ExecuteSql(DbConnection, sql)
    End Sub

    Private Sub HorseStatForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Me.Text = "Horse statistics"
        Grid.SetReadOnlyMode()

        If (_HorseId > 0) Then
            HorseIdText.Text = _HorseId.ToString
        End If

        FillHorseData()
        FillGrid()
        _Loaded = True
    End Sub

    Private Function GetHorseId() As Integer
        If (HorseIdText.Text IsNot Nothing) Then
            If (HorseIdText.Text.Trim.Length > 0) Then
                Dim i As Integer = 0
                Try
                    i = CType(HorseIdText.Text.Trim, Integer)
                Catch ex As Exception

                End Try
                Return i
            End If
        End If
        Return 0
    End Function

    Private Sub HorseIdText_TextChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles HorseIdText.TextChanged
        If _Loaded Then
            FillHorseData()
            FillGrid()
        End If
    End Sub
End Class
