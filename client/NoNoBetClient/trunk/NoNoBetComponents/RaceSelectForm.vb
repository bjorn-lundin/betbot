Imports System
Imports System.Windows
Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface
Imports DbInterface.DbConnection
Imports NoNoBetComponents
Imports NoNoBetDb

Public Class RaceSelectForm
  Inherits BaseForm
  Friend WithEvents ComboBetTypes As System.Windows.Forms.ComboBox
  Friend WithEvents LabelRaceType As System.Windows.Forms.Label
  Friend WithEvents TopPanel As System.Windows.Forms.Panel
  Friend WithEvents ButtonSearch As System.Windows.Forms.Button
  Friend WithEvents LabelFromDate As System.Windows.Forms.Label
  Friend WithEvents FromDate As System.Windows.Forms.DateTimePicker
  Friend WithEvents GridRaces As BaseComponents.BaseGrid

  Private _Loaded As Boolean = False

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Sub ButtonSearch_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ButtonSearch.Click
    If _Loaded Then
      GridRaces.ExecuteSql(MyBase.ResourceManager, BuildSql(GetSelectedRaceType, FromDate.Value))
    End If
  End Sub

  Private Shared Function BuildSql(ByVal bType As BetType.eBetType, ByVal fromDate As Date) As String
    Dim sql As String = Nothing

    Select Case bType
      Case BetType.eBetType.V75
        sql = Race.BuildV75RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.V65
        sql = Race.BuildV65RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.V64
        sql = Race.BuildV64RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.V5
        sql = Race.BuildV5RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.V4
        sql = Race.BuildV4RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.V3
        sql = Race.BuildV3RacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.DD
        sql = Race.BuildDDRacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.LD
        sql = Race.BuildLDRacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.TVILLING
        sql = Race.BuildTvillingRacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.TRIO
        sql = Race.BuildTrioRacedaysSelectSql(fromDate, Today, True)
      Case BetType.eBetType.ANY
        sql = Race.BuildAnyRacedaysSelectSql(fromDate, Today, True)

    End Select

    Return sql
  End Function

  Function GetSelectedRaceType() As BetType.eBetType
    If (ComboBetTypes.SelectedItem IsNot Nothing) Then
      Dim betTypeObj As BetType = CType(ComboBetTypes.SelectedItem, BetType)
      Return betTypeObj.Value
    Else
      Return BetType.eBetType.ANY
    End If
  End Function

  Private Sub RaceSelectForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    MyBase.FormTitle = "Race Selector"

    FromDate.Value = Today
    BetType.FillCombo(ComboBetTypes)
    GridRaces.SetReadOnlyMode()
    _Loaded = True
  End Sub

  Private Sub InitializeComponent()
    Me.TopPanel = New System.Windows.Forms.Panel()
    Me.LabelRaceType = New System.Windows.Forms.Label()
    Me.ComboBetTypes = New System.Windows.Forms.ComboBox()
    Me.FromDate = New System.Windows.Forms.DateTimePicker()
    Me.LabelFromDate = New System.Windows.Forms.Label()
    Me.ButtonSearch = New System.Windows.Forms.Button()
    Me.GridRaces = New BaseComponents.BaseGrid()
    Me.TopPanel.SuspendLayout()
    CType(Me.GridRaces, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'TopPanel
    '
    Me.TopPanel.Controls.Add(Me.ButtonSearch)
    Me.TopPanel.Controls.Add(Me.LabelFromDate)
    Me.TopPanel.Controls.Add(Me.FromDate)
    Me.TopPanel.Controls.Add(Me.LabelRaceType)
    Me.TopPanel.Controls.Add(Me.ComboBetTypes)
    Me.TopPanel.Dock = System.Windows.Forms.DockStyle.Top
    Me.TopPanel.Location = New System.Drawing.Point(0, 0)
    Me.TopPanel.Name = "TopPanel"
    Me.TopPanel.Size = New System.Drawing.Size(813, 68)
    Me.TopPanel.TabIndex = 0
    '
    'LabelRaceType
    '
    Me.LabelRaceType.AutoSize = True
    Me.LabelRaceType.Location = New System.Drawing.Point(12, 9)
    Me.LabelRaceType.Name = "LabelRaceType"
    Me.LabelRaceType.Size = New System.Drawing.Size(77, 17)
    Me.LabelRaceType.TabIndex = 3
    Me.LabelRaceType.Text = "Race Type"
    '
    'ComboBetTypes
    '
    Me.ComboBetTypes.FormattingEnabled = True
    Me.ComboBetTypes.Location = New System.Drawing.Point(12, 32)
    Me.ComboBetTypes.Name = "ComboBetTypes"
    Me.ComboBetTypes.Size = New System.Drawing.Size(121, 24)
    Me.ComboBetTypes.TabIndex = 2
    '
    'FromDate
    '
    Me.FromDate.Location = New System.Drawing.Point(219, 32)
    Me.FromDate.Name = "FromDate"
    Me.FromDate.Size = New System.Drawing.Size(200, 22)
    Me.FromDate.TabIndex = 4
    '
    'LabelFromDate
    '
    Me.LabelFromDate.AutoSize = True
    Me.LabelFromDate.Location = New System.Drawing.Point(216, 9)
    Me.LabelFromDate.Name = "LabelFromDate"
    Me.LabelFromDate.Size = New System.Drawing.Size(72, 17)
    Me.LabelFromDate.TabIndex = 5
    Me.LabelFromDate.Text = "From date"
    '
    'ButtonSearch
    '
    Me.ButtonSearch.Location = New System.Drawing.Point(698, 31)
    Me.ButtonSearch.Name = "ButtonSearch"
    Me.ButtonSearch.Size = New System.Drawing.Size(75, 23)
    Me.ButtonSearch.TabIndex = 6
    Me.ButtonSearch.Text = "Search"
    Me.ButtonSearch.UseVisualStyleBackColor = True
    '
    'GridRaces
    '
    Me.GridRaces.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.GridRaces.Dock = System.Windows.Forms.DockStyle.Fill
    Me.GridRaces.Id = Nothing
    Me.GridRaces.Location = New System.Drawing.Point(0, 68)
    Me.GridRaces.Name = "GridRaces"
    Me.GridRaces.RowTemplate.Height = 24
    Me.GridRaces.Size = New System.Drawing.Size(813, 402)
    Me.GridRaces.TabIndex = 1
    '
    'RaceSelectForm
    '
    Me.ClientSize = New System.Drawing.Size(813, 470)
    Me.Controls.Add(Me.GridRaces)
    Me.Controls.Add(Me.TopPanel)
    Me.Name = "RaceSelectForm"
    Me.TopPanel.ResumeLayout(False)
    Me.TopPanel.PerformLayout()
    CType(Me.GridRaces, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

End Class
