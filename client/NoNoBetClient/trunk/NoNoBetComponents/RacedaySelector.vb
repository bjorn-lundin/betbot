Imports DbInterface
Imports NoNoBetDb
Imports BaseComponents
Imports NoNoBetResources

Public Class RacedaySelector
  Inherits BaseComponents.BaseForm
  Friend WithEvents gridRacedays As BaseComponents.BaseGrid
  Friend WithEvents dtpFrom As System.Windows.Forms.DateTimePicker
  Friend WithEvents dtpTo As System.Windows.Forms.DateTimePicker
  Friend WithEvents cboCountry As System.Windows.Forms.ComboBox
  Friend WithEvents btnShow As System.Windows.Forms.Button
  Friend WithEvents grpTop As System.Windows.Forms.GroupBox
  Friend WithEvents Label1 As System.Windows.Forms.Label
  Friend WithEvents lblTo As System.Windows.Forms.Label
  Friend WithEvents lblFrom As System.Windows.Forms.Label
  Friend WithEvents grpBottom As System.Windows.Forms.GroupBox
  Friend WithEvents gridBottom As BaseComponents.BaseGrid
  Friend WithEvents SplitContainer1 As System.Windows.Forms.SplitContainer

  Private Sub InitializeComponent()
    Me.SplitContainer1 = New System.Windows.Forms.SplitContainer()
    Me.gridRacedays = New BaseComponents.BaseGrid()
    Me.grpTop = New System.Windows.Forms.GroupBox()
    Me.Label1 = New System.Windows.Forms.Label()
    Me.lblTo = New System.Windows.Forms.Label()
    Me.lblFrom = New System.Windows.Forms.Label()
    Me.btnShow = New System.Windows.Forms.Button()
    Me.cboCountry = New System.Windows.Forms.ComboBox()
    Me.dtpTo = New System.Windows.Forms.DateTimePicker()
    Me.dtpFrom = New System.Windows.Forms.DateTimePicker()
    Me.grpBottom = New System.Windows.Forms.GroupBox()
    Me.gridBottom = New BaseComponents.BaseGrid()
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer1.Panel1.SuspendLayout()
    Me.SplitContainer1.Panel2.SuspendLayout()
    Me.SplitContainer1.SuspendLayout()
    CType(Me.gridRacedays, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.grpTop.SuspendLayout()
    Me.grpBottom.SuspendLayout()
    CType(Me.gridBottom, System.ComponentModel.ISupportInitialize).BeginInit()
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
    '
    'SplitContainer1.Panel2
    '
    Me.SplitContainer1.Panel2.Controls.Add(Me.grpBottom)
    Me.SplitContainer1.Size = New System.Drawing.Size(464, 436)
    Me.SplitContainer1.SplitterDistance = 194
    Me.SplitContainer1.TabIndex = 0
    '
    'gridRacedays
    '
    Me.gridRacedays.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridRacedays.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridRacedays.Id = Nothing
    Me.gridRacedays.Location = New System.Drawing.Point(0, 65)
    Me.gridRacedays.Name = "gridRacedays"
    Me.gridRacedays.Size = New System.Drawing.Size(464, 129)
    Me.gridRacedays.TabIndex = 1
    '
    'grpTop
    '
    Me.grpTop.Controls.Add(Me.Label1)
    Me.grpTop.Controls.Add(Me.lblTo)
    Me.grpTop.Controls.Add(Me.lblFrom)
    Me.grpTop.Controls.Add(Me.btnShow)
    Me.grpTop.Controls.Add(Me.cboCountry)
    Me.grpTop.Controls.Add(Me.dtpTo)
    Me.grpTop.Controls.Add(Me.dtpFrom)
    Me.grpTop.Dock = System.Windows.Forms.DockStyle.Top
    Me.grpTop.Location = New System.Drawing.Point(0, 0)
    Me.grpTop.Name = "grpTop"
    Me.grpTop.Size = New System.Drawing.Size(464, 65)
    Me.grpTop.TabIndex = 0
    Me.grpTop.TabStop = False
    Me.grpTop.Text = "Välj tävlingsdag"
    '
    'Label1
    '
    Me.Label1.AutoSize = True
    Me.Label1.Location = New System.Drawing.Point(240, 16)
    Me.Label1.Name = "Label1"
    Me.Label1.Size = New System.Drawing.Size(31, 13)
    Me.Label1.TabIndex = 6
    Me.Label1.Text = "Land"
    '
    'lblTo
    '
    Me.lblTo.AutoSize = True
    Me.lblTo.Location = New System.Drawing.Point(121, 19)
    Me.lblTo.Name = "lblTo"
    Me.lblTo.Size = New System.Drawing.Size(20, 13)
    Me.lblTo.TabIndex = 5
    Me.lblTo.Text = "Till"
    '
    'lblFrom
    '
    Me.lblFrom.AutoSize = True
    Me.lblFrom.Location = New System.Drawing.Point(6, 19)
    Me.lblFrom.Name = "lblFrom"
    Me.lblFrom.Size = New System.Drawing.Size(28, 13)
    Me.lblFrom.TabIndex = 4
    Me.lblFrom.Text = "Från"
    '
    'btnShow
    '
    Me.btnShow.Location = New System.Drawing.Point(341, 36)
    Me.btnShow.Name = "btnShow"
    Me.btnShow.Size = New System.Drawing.Size(75, 23)
    Me.btnShow.TabIndex = 3
    Me.btnShow.Text = "Visa"
    Me.btnShow.UseVisualStyleBackColor = True
    '
    'cboCountry
    '
    Me.cboCountry.FormattingEnabled = True
    Me.cboCountry.Location = New System.Drawing.Point(243, 38)
    Me.cboCountry.Name = "cboCountry"
    Me.cboCountry.Size = New System.Drawing.Size(81, 21)
    Me.cboCountry.TabIndex = 2
    '
    'dtpTo
    '
    Me.dtpTo.Location = New System.Drawing.Point(124, 39)
    Me.dtpTo.Name = "dtpTo"
    Me.dtpTo.Size = New System.Drawing.Size(104, 20)
    Me.dtpTo.TabIndex = 1
    '
    'dtpFrom
    '
    Me.dtpFrom.Location = New System.Drawing.Point(9, 39)
    Me.dtpFrom.Name = "dtpFrom"
    Me.dtpFrom.Size = New System.Drawing.Size(104, 20)
    Me.dtpFrom.TabIndex = 0
    '
    'grpBottom
    '
    Me.grpBottom.Controls.Add(Me.gridBottom)
    Me.grpBottom.Dock = System.Windows.Forms.DockStyle.Fill
    Me.grpBottom.Location = New System.Drawing.Point(0, 0)
    Me.grpBottom.Name = "grpBottom"
    Me.grpBottom.Size = New System.Drawing.Size(464, 238)
    Me.grpBottom.TabIndex = 0
    Me.grpBottom.TabStop = False
    Me.grpBottom.Text = "Spel"
    '
    'gridBottom
    '
    Me.gridBottom.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridBottom.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridBottom.Id = Nothing
    Me.gridBottom.Location = New System.Drawing.Point(3, 16)
    Me.gridBottom.Name = "gridBottom"
    Me.gridBottom.Size = New System.Drawing.Size(458, 219)
    Me.gridBottom.TabIndex = 2
    '
    'RacedaySelector
    '
    Me.ClientSize = New System.Drawing.Size(464, 436)
    Me.Controls.Add(Me.SplitContainer1)
    Me.FormTitle = "Tävlingsnavigator"
    Me.Name = "RacedaySelector"
    Me.Text = "Tävlingsnavigator"
    Me.SplitContainer1.Panel1.ResumeLayout(False)
    Me.SplitContainer1.Panel2.ResumeLayout(False)
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.ResumeLayout(False)
    CType(Me.gridRacedays, System.ComponentModel.ISupportInitialize).EndInit()
    Me.grpTop.ResumeLayout(False)
    Me.grpTop.PerformLayout()
    Me.grpBottom.ResumeLayout(False)
    CType(Me.gridBottom, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Private _IsLoaded As Boolean = False

  Public Sub New(resourceMan As ApplicationResourceManager)
    MyBase.New()
    MyBase.ResourceManager = resourceMan
    InitializeComponent()
  End Sub

  Private Function GetShortDateSQLString(dt As DateTime) As String
    Return "'" + dt.ToShortDateString + "'"
  End Function

  Private Sub btnShow_Click(sender As System.Object, e As System.EventArgs) Handles btnShow.Click
    Dim sql As String = "SELECT raceday.raceday_date,raceday.first_race_posttime_time,track.domestic_text,raceday.id FROM raceday" +
                        " JOIN track ON (track.id = raceday.track_id)" +
                        " WHERE raceday.raceday_date >= " + GetShortDateSQLString(dtpFrom.Value) + " AND raceday.raceday_date < " + GetShortDateSQLString(dtpTo.Value.AddDays(1)) +
                               " AND raceday.country_code = '" & CType(cboCountry.SelectedItem, CountryCode).Code + "'" +
                        " ORDER BY raceday.raceday_date, raceday.first_race_posttime_time, track.domestic_text"
    'gridRacedays.Clear()
    gridRacedays.ExecuteSql(MyBase.ResourceManager, sql)
  End Sub

  Private Sub gridRacedays_RowChange(sender As Object, e As BaseComponents.BaseGrid.RowChangeEventArgs) Handles gridRacedays.RowChange
    If _IsLoaded Then
      Dim sql As String

      If (e.Row IsNot Nothing) Then
        Dim raceday_id As Integer = CType(ApplicationResourceManager.GetRowColumnValue(e.Row, "id"), Integer)
        sql = "SELECT * FROM RacedayMainBettypes WHERE raceday_id = " & raceday_id
      Else
        sql = "SELECT * FROM RacedayMainBettypes WHERE null = null"
      End If
      gridBottom.ExecuteSql(Me.ResourceManager, sql)
    End If
  End Sub

  Private Sub RacedaySelector_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    Dim cCodes As CountryCodes = New CountryCodes

    dtpFrom.Format = Windows.Forms.DateTimePickerFormat.Short
    dtpFrom.Value = Today
    dtpTo.Format = Windows.Forms.DateTimePickerFormat.Short
    dtpTo.Value = Today

    cboCountry.DropDownStyle = Windows.Forms.ComboBoxStyle.DropDownList
    cCodes.LoadFromDb(MyBase.ResourceManager)
    cCodes.FillCombo(cboCountry)

    gridRacedays.Id = "RaceDays"
    gridRacedays.SetReadOnlyMode()
    gridRacedays.AutoResizeRows()
    gridBottom.Id = "RacedayBettypes"
    gridBottom.SetReadOnlyMode()
    gridBottom.AutoResizeRows()

    _IsLoaded = True
  End Sub

End Class
