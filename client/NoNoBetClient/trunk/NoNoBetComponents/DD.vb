Imports DbInterface
Imports NoNoBetDb
Imports BaseComponents
Imports NoNoBetResources

Public Class DD
  Inherits BaseForm

  Friend WithEvents tabPageResult As System.Windows.Forms.TabPage
  Friend WithEvents gridDD2 As BaseComponents.BaseGrid
  Friend WithEvents gridDDResult As BaseComponents.BaseGrid
  Friend WithEvents tabPageDD2 As System.Windows.Forms.TabPage
  Friend WithEvents gridDD1 As BaseComponents.BaseGrid
  Friend WithEvents tabPageDD1 As System.Windows.Forms.TabPage
  Friend WithEvents TabControl As System.Windows.Forms.TabControl
  Friend WithEvents SplitContainer1 As System.Windows.Forms.SplitContainer

  Private Sub InitializeComponent()
    Me.SplitContainer1 = New System.Windows.Forms.SplitContainer()
    Me.TabControl = New System.Windows.Forms.TabControl()
    Me.tabPageDD1 = New System.Windows.Forms.TabPage()
    Me.tabPageDD2 = New System.Windows.Forms.TabPage()
    Me.tabPageResult = New System.Windows.Forms.TabPage()
    Me.gridDD1 = New BaseComponents.BaseGrid()
    Me.gridDD2 = New BaseComponents.BaseGrid()
    Me.gridDDResult = New BaseComponents.BaseGrid()
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer1.Panel2.SuspendLayout()
    Me.SplitContainer1.SuspendLayout()
    Me.TabControl.SuspendLayout()
    Me.tabPageDD1.SuspendLayout()
    Me.tabPageDD2.SuspendLayout()
    Me.tabPageResult.SuspendLayout()
    CType(Me.gridDD1, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.gridDD2, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.gridDDResult, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'SplitContainer1
    '
    Me.SplitContainer1.Dock = System.Windows.Forms.DockStyle.Fill
    Me.SplitContainer1.Location = New System.Drawing.Point(0, 0)
    Me.SplitContainer1.Name = "SplitContainer1"
    Me.SplitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'SplitContainer1.Panel2
    '
    Me.SplitContainer1.Panel2.Controls.Add(Me.TabControl)
    Me.SplitContainer1.Size = New System.Drawing.Size(284, 261)
    Me.SplitContainer1.SplitterDistance = 82
    Me.SplitContainer1.TabIndex = 0
    '
    'TabControl
    '
    Me.TabControl.Controls.Add(Me.tabPageDD1)
    Me.TabControl.Controls.Add(Me.tabPageDD2)
    Me.TabControl.Controls.Add(Me.tabPageResult)
    Me.TabControl.Dock = System.Windows.Forms.DockStyle.Fill
    Me.TabControl.Location = New System.Drawing.Point(0, 0)
    Me.TabControl.Name = "TabControl"
    Me.TabControl.SelectedIndex = 0
    Me.TabControl.Size = New System.Drawing.Size(284, 175)
    Me.TabControl.TabIndex = 0
    '
    'tabPageDD1
    '
    Me.tabPageDD1.Controls.Add(Me.gridDD1)
    Me.tabPageDD1.Location = New System.Drawing.Point(4, 22)
    Me.tabPageDD1.Name = "tabPageDD1"
    Me.tabPageDD1.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageDD1.Size = New System.Drawing.Size(276, 149)
    Me.tabPageDD1.TabIndex = 0
    Me.tabPageDD1.Text = "DD-1"
    Me.tabPageDD1.UseVisualStyleBackColor = True
    '
    'tabPageDD2
    '
    Me.tabPageDD2.Controls.Add(Me.gridDD2)
    Me.tabPageDD2.Location = New System.Drawing.Point(4, 22)
    Me.tabPageDD2.Name = "tabPageDD2"
    Me.tabPageDD2.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageDD2.Size = New System.Drawing.Size(276, 149)
    Me.tabPageDD2.TabIndex = 1
    Me.tabPageDD2.Text = "DD-2"
    Me.tabPageDD2.UseVisualStyleBackColor = True
    '
    'tabPageResult
    '
    Me.tabPageResult.Controls.Add(Me.gridDDResult)
    Me.tabPageResult.Location = New System.Drawing.Point(4, 22)
    Me.tabPageResult.Name = "tabPageResult"
    Me.tabPageResult.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageResult.Size = New System.Drawing.Size(276, 149)
    Me.tabPageResult.TabIndex = 2
    Me.tabPageResult.Text = "Resultat"
    Me.tabPageResult.UseVisualStyleBackColor = True
    '
    'gridDD1
    '
    Me.gridDD1.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridDD1.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridDD1.Id = Nothing
    Me.gridDD1.Location = New System.Drawing.Point(3, 3)
    Me.gridDD1.Name = "gridDD1"
    Me.gridDD1.Size = New System.Drawing.Size(270, 143)
    Me.gridDD1.TabIndex = 0
    '
    'gridDD2
    '
    Me.gridDD2.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridDD2.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridDD2.Id = Nothing
    Me.gridDD2.Location = New System.Drawing.Point(3, 3)
    Me.gridDD2.Name = "gridDD2"
    Me.gridDD2.Size = New System.Drawing.Size(270, 143)
    Me.gridDD2.TabIndex = 0
    '
    'gridDDResult
    '
    Me.gridDDResult.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridDDResult.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridDDResult.Id = Nothing
    Me.gridDDResult.Location = New System.Drawing.Point(3, 3)
    Me.gridDDResult.Name = "gridDDResult"
    Me.gridDDResult.Size = New System.Drawing.Size(270, 143)
    Me.gridDDResult.TabIndex = 0
    '
    'DD
    '
    Me.ClientSize = New System.Drawing.Size(284, 261)
    Me.Controls.Add(Me.SplitContainer1)
    Me.Name = "DD"
    Me.SplitContainer1.Panel2.ResumeLayout(False)
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.ResumeLayout(False)
    Me.TabControl.ResumeLayout(False)
    Me.tabPageDD1.ResumeLayout(False)
    Me.tabPageDD2.ResumeLayout(False)
    Me.tabPageResult.ResumeLayout(False)
    CType(Me.gridDD1, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.gridDD2, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.gridDDResult, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Private _Raceday_id As Integer

  Public Shadows Sub StartForm(raceday_id As Integer, asDialog As Boolean, resourceMan As ApplicationResourceManager)
    _Raceday_id = raceday_id
    MyBase.StartForm(asDialog, resourceMan)
  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub


  Private Sub tabPageDD1_GotFocus(sender As Object, e As System.EventArgs) Handles tabPageDD1.GotFocus

  End Sub

  Private Sub tabPageDD2_GotFocus(sender As Object, e As System.EventArgs) Handles tabPageDD2.GotFocus

  End Sub

  Private Sub tabPageResult_GotFocus(sender As Object, e As System.EventArgs) Handles tabPageResult.GotFocus

  End Sub

  Private Sub DD_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    gridDD1.SetReadOnlyMode()
    gridDD1.AutoResizeRows()
    gridDD2.SetReadOnlyMode()
    gridDD2.AutoResizeRows()
    gridDDResult.SetReadOnlyMode()
    gridDDResult.AutoResizeRows()
  End Sub
End Class
