Imports BaseComponents

Public Class MainForm
  Inherits BaseForm

  Friend WithEvents TableGrid As BaseComponents.BaseGrid

  Private Sub InitializeComponent()
    Me.TableGrid = New BaseComponents.BaseGrid()
    CType(Me.TableGrid, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'TableGrid
    '
    Me.TableGrid.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.TableGrid.Dock = System.Windows.Forms.DockStyle.Top
    Me.TableGrid.Id = Nothing
    Me.TableGrid.Location = New System.Drawing.Point(0, 0)
    Me.TableGrid.Name = "TableGrid"
    Me.TableGrid.Size = New System.Drawing.Size(585, 195)
    Me.TableGrid.TabIndex = 0
    '
    'MainForm
    '
    Me.ClientSize = New System.Drawing.Size(585, 286)
    Me.Controls.Add(Me.TableGrid)
    Me.Name = "MainForm"
    CType(Me.TableGrid, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub


  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Sub MainForm_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    Dim sql As String = "SELECT * FROM information_schema.tables WHERE information_schema.tables.table_schema = 'public'"
    MyBase.FormTitle = "Main Form: " + MyBase.ResourceManager.DbConnection.ConnectionString.Name
    TableGrid.SetReadOnlyMode()
    TableGrid.ExecuteSql(MyBase.ResourceManager, sql)
  End Sub
End Class
