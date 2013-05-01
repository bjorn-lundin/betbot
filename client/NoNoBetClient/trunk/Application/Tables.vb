Imports BaseComponents

Public Class Tables
  Inherits BaseForm
  Friend WithEvents cboTables As System.Windows.Forms.ComboBox
  Friend WithEvents btnShow As System.Windows.Forms.Button
  Friend WithEvents grpBottom As System.Windows.Forms.GroupBox
  Friend WithEvents gridTable As BaseComponents.BaseGrid
  Friend WithEvents grpTop As System.Windows.Forms.GroupBox

  Private Sub InitializeComponent()
    Me.grpTop = New System.Windows.Forms.GroupBox()
    Me.gridTable = New BaseComponents.BaseGrid()
    Me.grpBottom = New System.Windows.Forms.GroupBox()
    Me.btnShow = New System.Windows.Forms.Button()
    Me.cboTables = New System.Windows.Forms.ComboBox()
    Me.grpTop.SuspendLayout()
    CType(Me.gridTable, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.grpBottom.SuspendLayout()
    Me.SuspendLayout()
    '
    'grpTop
    '
    Me.grpTop.Controls.Add(Me.gridTable)
    Me.grpTop.Dock = System.Windows.Forms.DockStyle.Fill
    Me.grpTop.Location = New System.Drawing.Point(0, 0)
    Me.grpTop.Name = "grpTop"
    Me.grpTop.Size = New System.Drawing.Size(284, 198)
    Me.grpTop.TabIndex = 0
    Me.grpTop.TabStop = False
    Me.grpTop.Text = "Table content"
    '
    'gridTable
    '
    Me.gridTable.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.gridTable.Dock = System.Windows.Forms.DockStyle.Fill
    Me.gridTable.Id = Nothing
    Me.gridTable.Location = New System.Drawing.Point(3, 16)
    Me.gridTable.Name = "gridTable"
    Me.gridTable.Size = New System.Drawing.Size(278, 179)
    Me.gridTable.TabIndex = 0
    '
    'grpBottom
    '
    Me.grpBottom.Controls.Add(Me.btnShow)
    Me.grpBottom.Controls.Add(Me.cboTables)
    Me.grpBottom.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.grpBottom.Location = New System.Drawing.Point(0, 198)
    Me.grpBottom.Name = "grpBottom"
    Me.grpBottom.Size = New System.Drawing.Size(284, 63)
    Me.grpBottom.TabIndex = 1
    Me.grpBottom.TabStop = False
    Me.grpBottom.Text = "Select table"
    '
    'btnShow
    '
    Me.btnShow.Location = New System.Drawing.Point(187, 25)
    Me.btnShow.Name = "btnShow"
    Me.btnShow.Size = New System.Drawing.Size(85, 23)
    Me.btnShow.TabIndex = 1
    Me.btnShow.Text = "Show content"
    Me.btnShow.UseVisualStyleBackColor = True
    '
    'cboTables
    '
    Me.cboTables.FormattingEnabled = True
    Me.cboTables.Location = New System.Drawing.Point(12, 25)
    Me.cboTables.Name = "cboTables"
    Me.cboTables.Size = New System.Drawing.Size(138, 21)
    Me.cboTables.TabIndex = 0
    '
    'Tables
    '
    Me.ClientSize = New System.Drawing.Size(284, 261)
    Me.Controls.Add(Me.grpTop)
    Me.Controls.Add(Me.grpBottom)
    Me.Name = "Tables"
    Me.grpTop.ResumeLayout(False)
    CType(Me.gridTable, System.ComponentModel.ISupportInitialize).EndInit()
    Me.grpBottom.ResumeLayout(False)
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Sub btnShow_Click(sender As System.Object, e As System.EventArgs) Handles btnShow.Click
    Dim tableName As String = GetSelectedTable()

    If String.IsNullOrEmpty(tableName) Then
      gridTable.Clear()
    Else
      Cursor = Cursors.WaitCursor
      gridTable.ExecuteSql(MyBase.DbConnection, "SELECT * FROM " + tableName)
      Cursor = Cursors.Default
    End If
  End Sub

  Private Function GetSelectedTable() As String
    If cboTables.SelectedItem IsNot Nothing Then
      Return cboTables.SelectedItem.ToString
    End If
    Return String.Empty
  End Function

  Private Sub FillTablesCombo()
    Dim tList As List(Of String) = MyBase.DbConnection.GetAllTablesList()
    cboTables.Items.Clear()

    For i As Integer = 0 To (tList.Count - 1)
      cboTables.Items.Add(tList.Item(i))
    Next

    cboTables.SelectedIndex = 0
  End Sub

  Private Sub Tables_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    MyBase.FormTitle = "Tables: " + MyBase.DbConnection.ConnectionString.Name
    FillTablesCombo()
    gridTable.Clear()
    gridTable.SetReadOnlyMode()
    gridTable.AutoResizeRows()
  End Sub
End Class
