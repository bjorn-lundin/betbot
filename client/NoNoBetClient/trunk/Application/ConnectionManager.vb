Imports BaseComponents
Imports DbInterface

Public Class ConnectionManager
  Inherits BaseForm
  Friend WithEvents lblListView As System.Windows.Forms.Label
  Friend WithEvents lviewConnections As System.Windows.Forms.ListView
  Friend WithEvents pnlTop As System.Windows.Forms.Panel
  Friend WithEvents btnNewConnection As System.Windows.Forms.Button
  Friend WithEvents btnClose As System.Windows.Forms.Button
  Friend WithEvents btnExit As System.Windows.Forms.Button
  Friend WithEvents pnlBottom As System.Windows.Forms.Panel

  Private Sub InitializeComponent()
    Me.pnlBottom = New System.Windows.Forms.Panel()
    Me.btnExit = New System.Windows.Forms.Button()
    Me.btnClose = New System.Windows.Forms.Button()
    Me.btnNewConnection = New System.Windows.Forms.Button()
    Me.pnlTop = New System.Windows.Forms.Panel()
    Me.lviewConnections = New System.Windows.Forms.ListView()
    Me.lblListView = New System.Windows.Forms.Label()
    Me.pnlBottom.SuspendLayout()
    Me.pnlTop.SuspendLayout()
    Me.SuspendLayout()
    '
    'pnlBottom
    '
    Me.pnlBottom.Controls.Add(Me.btnExit)
    Me.pnlBottom.Controls.Add(Me.btnClose)
    Me.pnlBottom.Controls.Add(Me.btnNewConnection)
    Me.pnlBottom.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.pnlBottom.Location = New System.Drawing.Point(0, 216)
    Me.pnlBottom.Name = "pnlBottom"
    Me.pnlBottom.Size = New System.Drawing.Size(284, 45)
    Me.pnlBottom.TabIndex = 0
    '
    'btnExit
    '
    Me.btnExit.Anchor = CType(((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnExit.Location = New System.Drawing.Point(197, 13)
    Me.btnExit.Name = "btnExit"
    Me.btnExit.Size = New System.Drawing.Size(75, 23)
    Me.btnExit.TabIndex = 2
    Me.btnExit.Text = "Exit"
    Me.btnExit.UseVisualStyleBackColor = True
    '
    'btnClose
    '
    Me.btnClose.Anchor = CType(((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnClose.Location = New System.Drawing.Point(95, 13)
    Me.btnClose.Name = "btnClose"
    Me.btnClose.Size = New System.Drawing.Size(75, 23)
    Me.btnClose.TabIndex = 1
    Me.btnClose.Text = "Close"
    Me.btnClose.UseVisualStyleBackColor = True
    '
    'btnNewConnection
    '
    Me.btnNewConnection.Anchor = CType(((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left) _
            Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnNewConnection.Location = New System.Drawing.Point(13, 13)
    Me.btnNewConnection.Name = "btnNewConnection"
    Me.btnNewConnection.Size = New System.Drawing.Size(67, 23)
    Me.btnNewConnection.TabIndex = 0
    Me.btnNewConnection.Text = "New"
    Me.btnNewConnection.UseVisualStyleBackColor = True
    '
    'pnlTop
    '
    Me.pnlTop.Controls.Add(Me.lviewConnections)
    Me.pnlTop.Controls.Add(Me.lblListView)
    Me.pnlTop.Dock = System.Windows.Forms.DockStyle.Fill
    Me.pnlTop.Location = New System.Drawing.Point(0, 0)
    Me.pnlTop.Name = "pnlTop"
    Me.pnlTop.Size = New System.Drawing.Size(284, 216)
    Me.pnlTop.TabIndex = 1
    '
    'lviewConnections
    '
    Me.lviewConnections.Dock = System.Windows.Forms.DockStyle.Fill
    Me.lviewConnections.Location = New System.Drawing.Point(0, 13)
    Me.lviewConnections.Name = "lviewConnections"
    Me.lviewConnections.Size = New System.Drawing.Size(284, 203)
    Me.lviewConnections.TabIndex = 1
    Me.lviewConnections.UseCompatibleStateImageBehavior = False
    '
    'lblListView
    '
    Me.lblListView.AutoSize = True
    Me.lblListView.Dock = System.Windows.Forms.DockStyle.Top
    Me.lblListView.Location = New System.Drawing.Point(0, 0)
    Me.lblListView.Name = "lblListView"
    Me.lblListView.Size = New System.Drawing.Size(66, 13)
    Me.lblListView.TabIndex = 0
    Me.lblListView.Text = "Connections"
    '
    'ConnectionManager
    '
    Me.ClientSize = New System.Drawing.Size(284, 261)
    Me.Controls.Add(Me.pnlTop)
    Me.Controls.Add(Me.pnlBottom)
    Me.FormTitle = "Connection Manager"
    Me.Name = "ConnectionManager"
    Me.Text = "Connection Manager"
    Me.pnlBottom.ResumeLayout(False)
    Me.pnlTop.ResumeLayout(False)
    Me.pnlTop.PerformLayout()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Private Sub btnNewConnection_Click(sender As System.Object, e As System.EventArgs) Handles btnNewConnection.Click

  End Sub

  Private Sub btnExit_Click(sender As System.Object, e As System.EventArgs) Handles btnExit.Click
    MyBase.EndForm()
  End Sub

  Private Sub btnClose_Click(sender As System.Object, e As System.EventArgs) Handles btnClose.Click

  End Sub

  Private Sub InitListView()
    Dim item As ListViewItem
    Dim subItem As ListViewItem.ListViewSubItem

    lviewConnections.View = View.Details
    lviewConnections.GridLines = True
    lviewConnections.FullRowSelect = True
    lviewConnections.MultiSelect = False

    lviewConnections.Columns.Add("Name", 10)
    lviewConnections.Columns.Add("Connection string", 20)
    lviewConnections.Columns.Add("Status")

    item = New ListViewItem("Dummy1")

    subItem = New ListViewItem.ListViewSubItem
    subItem.Text = "Connection 1"

    item.SubItems.Add(subItem)

    subItem = New ListViewItem.ListViewSubItem
    subItem.Text = " ### "
    'subItem.ForeColor = Color.Red
    subItem.BackColor = Color.Red

    item.SubItems.Add(subItem)

    lviewConnections.Items.Add(item)


    item = New ListViewItem("Dummy2")

    subItem = New ListViewItem.ListViewSubItem
    subItem.Text = "Connection 2"

    item.SubItems.Add(subItem)

    subItem = New ListViewItem.ListViewSubItem
    subItem.Text = " ### "
    'subItem.ForeColor = Color.Green
    subItem.BackColor = Color.Green

    item.SubItems.Add(subItem)

    lviewConnections.Items.Add(item)

    lviewConnections.AutoResizeColumns(ColumnHeaderAutoResizeStyle.HeaderSize)
  End Sub

  Private Function GetSelectedItem() As DbConnection
    If (lviewConnections.SelectedItems IsNot Nothing) Then
      If (lviewConnections.SelectedItems.Item(0) IsNot Nothing) Then
        Return CType(lviewConnections.SelectedItems.Item(0).Tag, DbConnection)
      Else
        Return Nothing
      End If
    Else
      Return Nothing
    End If
  End Function

  Private Sub AddConnection(db As DbConnection)

  End Sub
  Private Sub ConnectionManager_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    InitListView()
  End Sub

End Class
