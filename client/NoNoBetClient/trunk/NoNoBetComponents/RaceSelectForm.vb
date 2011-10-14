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

    Private _Loaded As Boolean = False

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub RaceSelectForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        MyBase.FormTitle = "Race Selector"

        BetType.FillCombo(ComboBetTypes)
    End Sub

    Private Sub InitializeComponent()
        Me.TopPanel = New System.Windows.Forms.Panel()
        Me.LabelRaceType = New System.Windows.Forms.Label()
        Me.ComboBetTypes = New System.Windows.Forms.ComboBox()
        Me.TopPanel.SuspendLayout()
        Me.SuspendLayout()
        '
        'TopPanel
        '
        Me.TopPanel.Controls.Add(Me.LabelRaceType)
        Me.TopPanel.Controls.Add(Me.ComboBetTypes)
        Me.TopPanel.Dock = System.Windows.Forms.DockStyle.Top
        Me.TopPanel.Location = New System.Drawing.Point(0, 0)
        Me.TopPanel.Name = "TopPanel"
        Me.TopPanel.Size = New System.Drawing.Size(813, 100)
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
        'RaceSelectForm
        '
        Me.ClientSize = New System.Drawing.Size(813, 470)
        Me.Controls.Add(Me.TopPanel)
        Me.Name = "RaceSelectForm"
        Me.TopPanel.ResumeLayout(False)
        Me.TopPanel.PerformLayout()
        Me.ResumeLayout(False)

    End Sub
End Class
