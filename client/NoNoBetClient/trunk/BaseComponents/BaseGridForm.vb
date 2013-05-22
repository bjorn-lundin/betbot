Public Class BaseGridForm
  Inherits BaseForm
  Implements IBaseGridForm


  Friend WithEvents Grid As BaseComponents.BaseGrid

  Private Sub InitializeComponent()
    Me.Grid = New BaseComponents.BaseGrid()
    CType(Me.Grid, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'Grid
    '
    Me.Grid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.Grid.Dock = System.Windows.Forms.DockStyle.Fill
    Me.Grid.Location = New System.Drawing.Point(0, 0)
    Me.Grid.Name = "Grid"
    Me.Grid.RowTemplate.Height = 24
    Me.Grid.Size = New System.Drawing.Size(282, 255)
    Me.Grid.TabIndex = 0
    '
    'BaseGridForm
    '
    Me.ClientSize = New System.Drawing.Size(282, 255)
    Me.Controls.Add(Me.Grid)
    Me.Name = "BaseGridForm"
    CType(Me.Grid, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Private _GridSql As String
  Private _GridId As String

  Public Overloads Sub StartForm(resourceMan As ApplicationResourceManager, gridSql As String) Implements IBaseGridForm.StartForm
    _GridSql = gridSql
    MyBase.StartForm(True, resourceMan)
  End Sub

  Public Overloads Sub StartForm(resourceMan As ApplicationResourceManager, gridSql As String, gridId As String) Implements IBaseGridForm.StartForm
    _GridSql = gridSql
    _GridId = gridId
    MyBase.StartForm(True, resourceMan)
  End Sub

  Private Sub BaseGridForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    Grid.Id = _GridId
    Grid.ExecuteSql(MyBase.ResourceManager, _GridSql)
  End Sub

End Class
