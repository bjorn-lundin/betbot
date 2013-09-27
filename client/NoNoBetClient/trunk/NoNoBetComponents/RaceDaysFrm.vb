Imports System
Imports System.Windows
Imports System.Windows.Forms
Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports NoNoBetDbInterface.DbConnection
Imports NoNoBetComponents
Imports NoNoBetDb

Public Class RaceDaysFrm
    Inherits BaseForm
    Friend WithEvents ComboBetTypes As System.Windows.Forms.ComboBox
    Friend WithEvents LabelRaceType As System.Windows.Forms.Label
    Friend WithEvents ComboBetTypeRaceDays As System.Windows.Forms.ComboBox
    Friend WithEvents PanelTop As System.Windows.Forms.Panel

    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LabelRaceType = New System.Windows.Forms.Label()
        Me.ComboBetTypes = New System.Windows.Forms.ComboBox()
        Me.ComboBetTypeRaceDays = New System.Windows.Forms.ComboBox()
        Me.PanelTop.SuspendLayout()
        Me.SuspendLayout()
        '
        'PanelTop
        '
        Me.PanelTop.Controls.Add(Me.ComboBetTypeRaceDays)
        Me.PanelTop.Controls.Add(Me.LabelRaceType)
        Me.PanelTop.Controls.Add(Me.ComboBetTypes)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Location = New System.Drawing.Point(0, 0)
        Me.PanelTop.Name = "PanelTop"
        Me.PanelTop.Size = New System.Drawing.Size(997, 125)
        Me.PanelTop.TabIndex = 0
        '
        'LabelRaceType
        '
        Me.LabelRaceType.AutoSize = True
        Me.LabelRaceType.Location = New System.Drawing.Point(32, 32)
        Me.LabelRaceType.Name = "LabelRaceType"
        Me.LabelRaceType.Size = New System.Drawing.Size(77, 17)
        Me.LabelRaceType.TabIndex = 1
        Me.LabelRaceType.Text = "Race Type"
        '
        'ComboBetTypes
        '
        Me.ComboBetTypes.FormattingEnabled = True
        Me.ComboBetTypes.Location = New System.Drawing.Point(32, 55)
        Me.ComboBetTypes.Name = "ComboBetTypes"
        Me.ComboBetTypes.Size = New System.Drawing.Size(121, 24)
        Me.ComboBetTypes.TabIndex = 0
        '
        'ComboBetTypeRaceDays
        '
        Me.ComboBetTypeRaceDays.FormattingEnabled = True
        Me.ComboBetTypeRaceDays.Location = New System.Drawing.Point(179, 55)
        Me.ComboBetTypeRaceDays.Name = "ComboBetTypeRaceDays"
        Me.ComboBetTypeRaceDays.Size = New System.Drawing.Size(215, 24)
        Me.ComboBetTypeRaceDays.TabIndex = 2
        '
        'RaceDaysFrm
        '
        Me.ClientSize = New System.Drawing.Size(997, 527)
        Me.Controls.Add(Me.PanelTop)
        Me.Name = "RaceDaysFrm"
        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Private _BetType As BetType
    Private _Loaded As Boolean = False

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub InitComboBetTypes()
        BetType.FillCombo(ComboBetTypes)
    End Sub

    Private Sub ComboBetTypes_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ComboBetTypes.SelectedIndexChanged
        If _Loaded Then
            If (ComboBetTypes.SelectedItem IsNot Nothing) Then
                _BetType = CType(ComboBetTypes.SelectedItem, BetType)
            End If
        End If
    End Sub

    Private Sub InitComboBetTypeRaceDays()
        Dim sql As String = Nothing

        Select Case _BetType.Value
            Case BetType.eBetType.V75
                sql = Race.BuildV75RacedaysSelectSql(True)
            Case BetType.eBetType.V64
                sql = Race.BuildV64RacedaysSelectSql(True)
            Case BetType.eBetType.V5
                sql = Race.BuildV5RacedaysSelectSql(True)
            Case BetType.eBetType.V4
                sql = Race.BuildV4RacedaysSelectSql(True)
            Case BetType.eBetType.V3
                sql = Race.BuildV3RacedaysSelectSql(True)
            Case BetType.eBetType.LD
                sql = Race.BuildLDRacedaysSelectSql(True)
            Case BetType.eBetType.DD
                sql = Race.BuildDDRacedaysSelectSql(True)
        End Select
    End Sub

    Private Sub RaceDaysFrm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        InitComboBetTypes()
        _Loaded = True
    End Sub

End Class
