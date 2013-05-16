Imports DbInterface
Imports NoNoBetDb

Public Class RacedaySelector
  Inherits BaseComponents.BaseForm
  Friend WithEvents gridRacedays As BaseComponents.BaseGrid
  Friend WithEvents dtpFrom As System.Windows.Forms.DateTimePicker
  Friend WithEvents dtpTo As System.Windows.Forms.DateTimePicker
  Friend WithEvents cboCountry As System.Windows.Forms.ComboBox
  Friend WithEvents btnShow As System.Windows.Forms.Button
  Friend WithEvents grpTop As System.Windows.Forms.GroupBox
  Friend WithEvents SplitContainer1 As System.Windows.Forms.SplitContainer

  Private Sub InitializeComponent()
    Me.SplitContainer1 = New System.Windows.Forms.SplitContainer()
    Me.grpTop = New System.Windows.Forms.GroupBox()
    Me.btnShow = New System.Windows.Forms.Button()
    Me.cboCountry = New System.Windows.Forms.ComboBox()
    Me.dtpTo = New System.Windows.Forms.DateTimePicker()
    Me.dtpFrom = New System.Windows.Forms.DateTimePicker()
    Me.gridRacedays = New BaseComponents.BaseGrid()
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer1.Panel1.SuspendLayout()
    Me.SplitContainer1.SuspendLayout()
    Me.grpTop.SuspendLayout()
    CType(Me.gridRacedays, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'SplitContainer1
    '
    Me.SplitContainer1.Dock = System.Windows.Forms.DockStyle.Fill
    Me.SplitContainer1.Location = New System.Drawing.Point(0, 0)
    Me.SplitContainer1.Name = "SplitContainer1"
    Me.SplitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'SplitContainer1.Panel1
    '
    Me.SplitContainer1.Panel1.Controls.Add(Me.gridRacedays)
    Me.SplitContainer1.Panel1.Controls.Add(Me.grpTop)
    Me.SplitContainer1.Size = New System.Drawing.Size(456, 343)
    Me.SplitContainer1.SplitterDistance = 153
    Me.SplitContainer1.TabIndex = 0
    '
    'grpTop
    '
    Me.grpTop.Controls.Add(Me.btnShow)
    Me.grpTop.Controls.Add(Me.cboCountry)
    Me.grpTop.Controls.Add(Me.dtpTo)
    Me.grpTop.Controls.Add(Me.dtpFrom)
    Me.grpTop.Dock = System.Windows.Forms.DockStyle.Top
    Me.grpTop.Location = New System.Drawing.Point(0, 0)
    Me.grpTop.Name = "grpTop"
    Me.grpTop.Size = New System.Drawing.Size(456, 43)
    Me.grpTop.TabIndex = 0
    Me.grpTop.TabStop = False
    Me.grpTop.Text = "Select Raceday"
    '
    'btnShow
    '
    Me.btnShow.Location = New System.Drawing.Point(375, 15)
    Me.btnShow.Name = "btnShow"
    Me.btnShow.Size = New System.Drawing.Size(75, 23)
    Me.btnShow.TabIndex = 3
    Me.btnShow.Text = "Show"
    Me.btnShow.UseVisualStyleBackColor = True
    '
    'cboCountry
    '
    Me.cboCountry.FormattingEnabled = True
    Me.cboCountry.Location = New System.Drawing.Point(284, 17)
    Me.cboCountry.Name = "cboCountry"
    Me.cboCountry.Size = New System.Drawing.Size(70, 21)
    Me.cboCountry.TabIndex = 2
    '
    'dtpTo
    '
    Me.dtpTo.Location = New System.Drawing.Point(149, 17)
    Me.dtpTo.Name = "dtpTo"
    Me.dtpTo.Size = New System.Drawing.Size(104, 20)
    Me.dtpTo.TabIndex = 1
    '
    'dtpFrom
    '
    Me.dtpFrom.Location = New System.Drawing.Point(13, 17)
    Me.dtpFrom.Name = "dtpFrom"
    Me.dtpFrom.Size = New System.Drawing.Size(104, 20)
    Me.dtpFrom.TabIndex = 0
    '
    'gridRacedays
    '
    Me.gridRacedays.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridRacedays.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridRacedays.Id = Nothing
    Me.gridRacedays.Location = New System.Drawing.Point(0, 43)
    Me.gridRacedays.Name = "gridRacedays"
    Me.gridRacedays.Size = New System.Drawing.Size(456, 110)
    Me.gridRacedays.TabIndex = 1
    '
    'RacedaySelector
    '
    Me.ClientSize = New System.Drawing.Size(456, 343)
    Me.Controls.Add(Me.SplitContainer1)
    Me.Name = "RacedaySelector"
    Me.SplitContainer1.Panel1.ResumeLayout(False)
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.ResumeLayout(False)
    Me.grpTop.ResumeLayout(False)
    CType(Me.gridRacedays, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New(dbCon As DbConnection)
    MyBase.New()
    MyBase.DbConnection = dbCon
    InitializeComponent()
  End Sub

  Private Sub btnShow_Click(sender As System.Object, e As System.EventArgs) Handles btnShow.Click
    Dim sql As String = "SELECT raceday.raceday_date,raceday.first_race_posttime_time,track.domestic_text FROM raceday " +
                        "JOIN track ON (track.id = raceday.track_id) " +
                        "WHERE raceday.country_code = '" & CType(cboCountry.SelectedItem, CountryCode).Code + "'"
    gridRacedays.ExecuteSql(MyBase.DbConnection, sql)
  End Sub

  Private Sub RacedaySelector_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    Dim cCodes As CountryCodes = New CountryCodes

    cCodes.LoadFromDb(MyBase.DbConnection)
    cCodes.FillCombo(cboCountry)

    gridRacedays.SetReadOnlyMode()
    gridRacedays.AutoResizeRows()
  End Sub

End Class
