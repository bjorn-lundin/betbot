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
    Friend WithEvents groupTop As System.Windows.Forms.GroupBox

    Private Sub InitializeComponent()
        Me.groupTop = New System.Windows.Forms.GroupBox()
        Me.textTotRaces = New System.Windows.Forms.TextBox()
        Me.buttonTotRaces = New System.Windows.Forms.Button()
        Me.groupTotEcuipages = New System.Windows.Forms.GroupBox()
        Me.buttonTotEquipages = New System.Windows.Forms.Button()
        Me.textTotEquipages = New System.Windows.Forms.TextBox()
        Me.groupTotWinEquipages = New System.Windows.Forms.GroupBox()
        Me.buttonTotWinEquipages = New System.Windows.Forms.Button()
        Me.textToWinEquipages = New System.Windows.Forms.TextBox()
        Me.groupTop.SuspendLayout()
        Me.groupTotEcuipages.SuspendLayout()
        Me.groupTotWinEquipages.SuspendLayout()
        Me.SuspendLayout()
        '
        'groupTop
        '
        Me.groupTop.Controls.Add(Me.buttonTotRaces)
        Me.groupTop.Controls.Add(Me.textTotRaces)
        Me.groupTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTop.Location = New System.Drawing.Point(0, 0)
        Me.groupTop.Name = "groupTop"
        Me.groupTop.Size = New System.Drawing.Size(577, 100)
        Me.groupTop.TabIndex = 0
        Me.groupTop.TabStop = False
        Me.groupTop.Text = "Total number races"
        '
        'textTotRaces
        '
        Me.textTotRaces.Location = New System.Drawing.Point(32, 44)
        Me.textTotRaces.Name = "textTotRaces"
        Me.textTotRaces.Size = New System.Drawing.Size(181, 22)
        Me.textTotRaces.TabIndex = 0
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
        'groupTotEcuipages
        '
        Me.groupTotEcuipages.Controls.Add(Me.buttonTotEquipages)
        Me.groupTotEcuipages.Controls.Add(Me.textTotEquipages)
        Me.groupTotEcuipages.Dock = System.Windows.Forms.DockStyle.Top
        Me.groupTotEcuipages.Location = New System.Drawing.Point(0, 100)
        Me.groupTotEcuipages.Name = "groupTotEcuipages"
        Me.groupTotEcuipages.Size = New System.Drawing.Size(577, 100)
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
        Me.groupTotWinEquipages.Location = New System.Drawing.Point(0, 200)
        Me.groupTotWinEquipages.Name = "groupTotWinEquipages"
        Me.groupTotWinEquipages.Size = New System.Drawing.Size(577, 100)
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
        'StatForm
        '
        Me.ClientSize = New System.Drawing.Size(577, 349)
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

    Private Sub StatForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

End Class
