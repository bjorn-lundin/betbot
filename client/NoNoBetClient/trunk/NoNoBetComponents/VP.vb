Imports DbInterface
Imports NoNoBetDb
Imports BaseComponents
Imports NoNoBetResources

Public Class VP
  Inherits BaseForm

  Friend WithEvents gridTop As BaseComponents.BaseGrid
  Friend WithEvents tabControl As System.Windows.Forms.TabControl
  Friend WithEvents tabPageStart As System.Windows.Forms.TabPage
  Friend WithEvents gridStart As BaseComponents.BaseGrid
  Friend WithEvents tabPageResult As System.Windows.Forms.TabPage
  Friend WithEvents gridResult As BaseComponents.BaseGrid
  Friend WithEvents SplitContainer1 As System.Windows.Forms.SplitContainer

  Private _Raceday_Id As Integer
  Private _IsLoaded As Boolean = False

  Private Sub InitializeComponent()
    Me.SplitContainer1 = New System.Windows.Forms.SplitContainer()
    Me.gridTop = New BaseComponents.BaseGrid()
    Me.tabControl = New System.Windows.Forms.TabControl()
    Me.tabPageStart = New System.Windows.Forms.TabPage()
    Me.tabPageResult = New System.Windows.Forms.TabPage()
    Me.gridStart = New BaseComponents.BaseGrid()
    Me.gridResult = New BaseComponents.BaseGrid()
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SplitContainer1.Panel1.SuspendLayout()
    Me.SplitContainer1.Panel2.SuspendLayout()
    Me.SplitContainer1.SuspendLayout()
    CType(Me.gridTop, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.tabControl.SuspendLayout()
    Me.tabPageStart.SuspendLayout()
    Me.tabPageResult.SuspendLayout()
    CType(Me.gridStart, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.gridResult, System.ComponentModel.ISupportInitialize).BeginInit()
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
    Me.SplitContainer1.Panel1.Controls.Add(Me.gridTop)
    '
    'SplitContainer1.Panel2
    '
    Me.SplitContainer1.Panel2.Controls.Add(Me.tabControl)
    Me.SplitContainer1.Size = New System.Drawing.Size(453, 415)
    Me.SplitContainer1.SplitterDistance = 212
    Me.SplitContainer1.TabIndex = 0
    '
    'gridTop
    '
    Me.gridTop.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridTop.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridTop.Id = Nothing
    Me.gridTop.Location = New System.Drawing.Point(0, 0)
    Me.gridTop.Name = "gridTop"
    Me.gridTop.Size = New System.Drawing.Size(453, 212)
    Me.gridTop.TabIndex = 0
    '
    'tabControl
    '
    Me.tabControl.Controls.Add(Me.tabPageStart)
    Me.tabControl.Controls.Add(Me.tabPageResult)
    Me.tabControl.Dock = System.Windows.Forms.DockStyle.Fill
    Me.tabControl.Location = New System.Drawing.Point(0, 0)
    Me.tabControl.Name = "tabControl"
    Me.tabControl.SelectedIndex = 0
    Me.tabControl.Size = New System.Drawing.Size(453, 199)
    Me.tabControl.TabIndex = 0
    '
    'tabPageStart
    '
    Me.tabPageStart.Controls.Add(Me.gridStart)
    Me.tabPageStart.Location = New System.Drawing.Point(4, 22)
    Me.tabPageStart.Name = "tabPageStart"
    Me.tabPageStart.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageStart.Size = New System.Drawing.Size(445, 173)
    Me.tabPageStart.TabIndex = 0
    Me.tabPageStart.Text = "Start"
    Me.tabPageStart.UseVisualStyleBackColor = True
    '
    'tabPageResult
    '
    Me.tabPageResult.Controls.Add(Me.gridResult)
    Me.tabPageResult.Location = New System.Drawing.Point(4, 22)
    Me.tabPageResult.Name = "tabPageResult"
    Me.tabPageResult.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageResult.Size = New System.Drawing.Size(445, 173)
    Me.tabPageResult.TabIndex = 1
    Me.tabPageResult.Text = "Result"
    Me.tabPageResult.UseVisualStyleBackColor = True
    '
    'gridStart
    '
    Me.gridStart.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridStart.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridStart.Id = Nothing
    Me.gridStart.Location = New System.Drawing.Point(3, 3)
    Me.gridStart.Name = "gridStart"
    Me.gridStart.Size = New System.Drawing.Size(439, 167)
    Me.gridStart.TabIndex = 0
    '
    'gridResult
    '
    Me.gridResult.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridResult.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridResult.Id = Nothing
    Me.gridResult.Location = New System.Drawing.Point(3, 3)
    Me.gridResult.Name = "gridResult"
    Me.gridResult.Size = New System.Drawing.Size(439, 167)
    Me.gridResult.TabIndex = 0
    '
    'VP
    '
    Me.ClientSize = New System.Drawing.Size(453, 415)
    Me.Controls.Add(Me.SplitContainer1)
    Me.Name = "VP"
    Me.SplitContainer1.Panel1.ResumeLayout(False)
    Me.SplitContainer1.Panel2.ResumeLayout(False)
    CType(Me.SplitContainer1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.SplitContainer1.ResumeLayout(False)
    CType(Me.gridTop, System.ComponentModel.ISupportInitialize).EndInit()
    Me.tabControl.ResumeLayout(False)
    Me.tabPageStart.ResumeLayout(False)
    Me.tabPageResult.ResumeLayout(False)
    CType(Me.gridStart, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.gridResult, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Shadows Sub StartForm(asDialog As Boolean, resourceMan As ApplicationResourceManager, raceday_id As Integer)
    _Raceday_Id = raceday_id
    MyBase.StartForm(asDialog, resourceMan)
  End Sub


  Private Sub VP_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    gridTop.SetReadOnlyMode()
    gridTop.AutoResizeRows()
    gridStart.SetReadOnlyMode()
    gridStart.AutoResizeRows()
    gridResult.SetReadOnlyMode()
    gridResult.AutoResizeRows()
    _IsLoaded = True
    gridTop.ExecuteSql(Me.ResourceManager, "SELECT * FROM VPRaces WHERE raceday_id = " & _Raceday_Id)
  End Sub
End Class
