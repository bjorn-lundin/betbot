Imports System.Windows.Forms
Imports System.Drawing
Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports NoNoBetConfig
Imports NoNoBetResources


Public Class ConnectionManager
  Inherits BaseForm
  Friend WithEvents lblListView As System.Windows.Forms.Label
  Friend WithEvents lviewConnections As System.Windows.Forms.ListView
  Friend WithEvents pnlTop As System.Windows.Forms.Panel
  Friend WithEvents btnNewConnection As System.Windows.Forms.Button
  Friend WithEvents btnClose As System.Windows.Forms.Button
  Friend WithEvents btnExit As System.Windows.Forms.Button
  Friend WithEvents btnConnect As System.Windows.Forms.Button
  Friend WithEvents btnStart As System.Windows.Forms.Button
  Friend WithEvents btnTables As System.Windows.Forms.Button
  Friend WithEvents pnlBottom As System.Windows.Forms.Panel

  Private Sub InitializeComponent()
    Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(ConnectionManager))
    Me.pnlBottom = New System.Windows.Forms.Panel()
    Me.btnTables = New System.Windows.Forms.Button()
    Me.btnStart = New System.Windows.Forms.Button()
    Me.btnClose = New System.Windows.Forms.Button()
    Me.btnConnect = New System.Windows.Forms.Button()
    Me.btnExit = New System.Windows.Forms.Button()
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
    Me.pnlBottom.Controls.Add(Me.btnTables)
    Me.pnlBottom.Controls.Add(Me.btnStart)
    Me.pnlBottom.Controls.Add(Me.btnClose)
    Me.pnlBottom.Controls.Add(Me.btnConnect)
    Me.pnlBottom.Controls.Add(Me.btnExit)
    Me.pnlBottom.Controls.Add(Me.btnNewConnection)
    Me.pnlBottom.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.pnlBottom.Location = New System.Drawing.Point(0, 242)
    Me.pnlBottom.Name = "pnlBottom"
    Me.pnlBottom.Size = New System.Drawing.Size(466, 45)
    Me.pnlBottom.TabIndex = 0
    '
    'btnTables
    '
    Me.btnTables.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnTables.Location = New System.Drawing.Point(238, 13)
    Me.btnTables.Name = "btnTables"
    Me.btnTables.Size = New System.Drawing.Size(68, 23)
    Me.btnTables.TabIndex = 5
    Me.btnTables.Text = "Tables"
    Me.btnTables.UseVisualStyleBackColor = True
    '
    'btnStart
    '
    Me.btnStart.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnStart.Location = New System.Drawing.Point(312, 13)
    Me.btnStart.Name = "btnStart"
    Me.btnStart.Size = New System.Drawing.Size(68, 23)
    Me.btnStart.TabIndex = 4
    Me.btnStart.Text = "Start"
    Me.btnStart.UseVisualStyleBackColor = True
    '
    'btnClose
    '
    Me.btnClose.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.btnClose.Location = New System.Drawing.Point(92, 13)
    Me.btnClose.Name = "btnClose"
    Me.btnClose.Size = New System.Drawing.Size(73, 23)
    Me.btnClose.TabIndex = 1
    Me.btnClose.Text = "Disconnect"
    Me.btnClose.UseVisualStyleBackColor = True
    '
    'btnConnect
    '
    Me.btnConnect.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.btnConnect.Location = New System.Drawing.Point(12, 13)
    Me.btnConnect.Name = "btnConnect"
    Me.btnConnect.Size = New System.Drawing.Size(74, 23)
    Me.btnConnect.TabIndex = 3
    Me.btnConnect.Text = "Connect"
    Me.btnConnect.UseVisualStyleBackColor = True
    '
    'btnExit
    '
    Me.btnExit.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.btnExit.Location = New System.Drawing.Point(386, 13)
    Me.btnExit.Name = "btnExit"
    Me.btnExit.Size = New System.Drawing.Size(68, 23)
    Me.btnExit.TabIndex = 2
    Me.btnExit.Text = "Exit"
    Me.btnExit.UseVisualStyleBackColor = True
    '
    'btnNewConnection
    '
    Me.btnNewConnection.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.btnNewConnection.Location = New System.Drawing.Point(174, 13)
    Me.btnNewConnection.Name = "btnNewConnection"
    Me.btnNewConnection.Size = New System.Drawing.Size(58, 23)
    Me.btnNewConnection.TabIndex = 0
    Me.btnNewConnection.Text = "Edit"
    Me.btnNewConnection.UseVisualStyleBackColor = True
    '
    'pnlTop
    '
    Me.pnlTop.Controls.Add(Me.lviewConnections)
    Me.pnlTop.Controls.Add(Me.lblListView)
    Me.pnlTop.Dock = System.Windows.Forms.DockStyle.Fill
    Me.pnlTop.Location = New System.Drawing.Point(0, 0)
    Me.pnlTop.Name = "pnlTop"
    Me.pnlTop.Size = New System.Drawing.Size(466, 242)
    Me.pnlTop.TabIndex = 1
    '
    'lviewConnections
    '
    Me.lviewConnections.Dock = System.Windows.Forms.DockStyle.Fill
    Me.lviewConnections.Location = New System.Drawing.Point(0, 13)
    Me.lviewConnections.Name = "lviewConnections"
    Me.lviewConnections.Size = New System.Drawing.Size(466, 229)
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
    Me.ClientSize = New System.Drawing.Size(466, 287)
    Me.Controls.Add(Me.pnlTop)
    Me.Controls.Add(Me.pnlBottom)
    Me.FormTitle = "Connection Manager"
    Me.Icon = CType(resources.GetObject("$this.Icon"), System.Drawing.Icon)
    Me.Name = "ConnectionManager"
    Me.Text = "Connection Manager"
    Me.pnlBottom.ResumeLayout(False)
    Me.pnlTop.ResumeLayout(False)
    Me.pnlTop.PerformLayout()
    Me.ResumeLayout(False)

  End Sub

  Private _Translator As Translator

  Public Sub New()
    MyBase.New()
    InitializeComponent()
    _Translator = New Translator
  End Sub

  Public Class StartApplicationEventArgs
    Inherits System.EventArgs

    Private _ResourceMan As NoNoBetResources.ApplicationResourceManager

    Public Property ResourceManager As NoNoBetResources.ApplicationResourceManager
      Get
        Return _ResourceMan
      End Get
      Set(value As NoNoBetResources.ApplicationResourceManager)
        _ResourceMan = value
      End Set
    End Property

    Public Sub New()
      MyBase.New()
    End Sub
  End Class

#Region "Button handling"

  ''' <summary>
  ''' Handle New Connection button
  ''' Start Manage Connections dialog
  ''' </summary>
  ''' <param name="sender"></param>
  ''' <param name="e"></param>
  ''' <remarks></remarks>
  Private Sub btnNewConnection_Click(sender As System.Object, e As System.EventArgs) Handles btnNewConnection.Click
    Dim dbConDialog As DbConnectionDialog = New DbConnectionDialog
    dbConDialog.StartDialog()
    UpdateListView()
  End Sub

  Private Sub btnExit_Click(sender As System.Object, e As System.EventArgs) Handles btnExit.Click
    MyBase.EndForm()
  End Sub

  Private Sub btnConnect_Click(sender As System.Object, e As System.EventArgs) Handles btnConnect.Click
    Cursor = Cursors.WaitCursor
    ConnectSelectedItem()
    Cursor = Cursors.Default
  End Sub

  Private Sub btnClose_Click(sender As System.Object, e As System.EventArgs) Handles btnClose.Click
    Cursor = Cursors.WaitCursor
    DisconnectSelectedItem()
    Cursor = Cursors.Default
  End Sub

  Private Sub btnStart_Click(sender As System.Object, e As System.EventArgs) Handles btnStart.Click
    Dim item As ListViewItem = GetSelectedItem()

    If IsListItemConnectionOpen(item) Then
      Dim resourceMan As ApplicationResourceManager = New ApplicationResourceManager
      Dim startAppEventArgs As StartApplicationEventArgs = New StartApplicationEventArgs

      resourceMan.Translator = _Translator
      resourceMan.DbConnection = CType(item.Tag, DbConnection)

      startAppEventArgs.ResourceManager = resourceMan
      RaiseEvent StartApplication(Me, startAppEventArgs)

      'Dim rSelector As RacedaySelector = New RacedaySelector(resourceMan)
      'rSelector.StartForm(False)
    End If
  End Sub

  Private Sub btnTables_Click(sender As System.Object, e As System.EventArgs) Handles btnTables.Click
    Dim item As ListViewItem = GetSelectedItem()

    If IsListItemConnectionOpen(item) Then
      Dim tableBrowser As Tables = New Tables
      Dim resourceMan As ApplicationResourceManager = New ApplicationResourceManager
      resourceMan.Translator = _Translator
      resourceMan.DbConnection = CType(item.Tag, DbConnection)
      tableBrowser.ResourceManager = resourceMan
      tableBrowser.StartForm(False)
    End If
  End Sub

#End Region

  Public Event StartApplication(sender As Object, e As StartApplicationEventArgs)

  Private Function CreateItem(dbConStr As DbConnectionString) As ListViewItem
    Dim item As ListViewItem
    Dim subItem As ListViewItem.ListViewSubItem
    item = New ListViewItem(dbConStr.Name)
    item.Name = dbConStr.Name
    item.Tag = dbConStr
    item.UseItemStyleForSubItems = False
    'Status column
    subItem = New ListViewItem.ListViewSubItem()
    item.SubItems.Add(subItem)
    SetItemStatusClosed(item)
    Return item
  End Function

  Private Sub SetItemStatusOpen(item As ListViewItem)
    item.SubItems.Item(1).Text = "Open"
    item.SubItems.Item(1).ForeColor = Color.Green
  End Sub

  Private Sub SetItemStatusClosed(item As ListViewItem)
    item.SubItems.Item(1).Text = "Closed"
    item.SubItems.Item(1).ForeColor = Color.Red
  End Sub

  Private Function IsListItemConnectionOpen(item As ListViewItem) As Boolean
    If (item.Tag IsNot Nothing) Then
      If (TypeOf (item.Tag) Is DbConnection) Then
        Return CType(item.Tag, DbConnection).State = ConnectionState.Open
      ElseIf (TypeOf (item.Tag) Is DbConnectionString) Then
        Return False
      End If
    End If
    Return False
  End Function

  Private Sub ConnectItem(item As ListViewItem)
    If (item IsNot Nothing) Then
      If (item.Tag IsNot Nothing) Then
        If (TypeOf (item.Tag) Is DbConnection) Then
          Dim itemTag As DbConnection = CType(item.Tag, DbConnection)
          If (itemTag.State <> ConnectionState.Open) Then
            itemTag.Open()
          End If
        ElseIf (TypeOf (item.Tag) Is DbConnectionString) Then
          Dim itemTag As DbConnectionString = CType(item.Tag, DbConnectionString)
          Dim dbCon As DbConnection = New DbConnection(itemTag)
          dbCon.Open()
          item.Tag = dbCon
        End If
        UpdateItemStatus(item)
      End If
    End If
  End Sub

  Private Sub DisconnectItem(item As ListViewItem)
    If (item IsNot Nothing) Then
      If (item.Tag IsNot Nothing) Then
        If (TypeOf (item.Tag) Is DbConnection) Then
          Dim itemTag As DbConnection = CType(item.Tag, DbConnection)
          If (itemTag.State = ConnectionState.Open) Then
            itemTag.Close()
          End If
          UpdateItemStatus(item)
        End If
      End If
    End If
  End Sub

  Private Sub DisconnectSelectedItem()
    DisconnectItem(GetSelectedItem())
  End Sub

  Private Sub ConnectSelectedItem()
    ConnectItem(GetSelectedItem())
  End Sub

  Private Sub StartSelectedItem()
    Dim item As ListViewItem = GetSelectedItem()

    If IsListItemConnectionOpen(item) Then
      Dim tableBrowser As Tables = New Tables
      Dim resourceMan As ApplicationResourceManager = New ApplicationResourceManager
      resourceMan.Translator = _Translator
      resourceMan.DbConnection = CType(item.Tag, DbConnection)

      tableBrowser.ResourceManager = resourceMan
      tableBrowser.StartForm(False)

      'Dim mainFrm As MainForm = New MainForm
      'mainFrm.DbConnection = CType(item.Tag, DbConnection)
      'mainFrm.StartForm(False)
    End If
  End Sub

  Private Sub InitListView()
    Dim dbConStrList As List(Of DbConnectionString) = DbConnectionString.GetSavedDbConnectionStrings()

    lviewConnections.View = View.Details
    lviewConnections.GridLines = True
    lviewConnections.FullRowSelect = True
    lviewConnections.MultiSelect = False

    lviewConnections.Columns.Add("Name")
    lviewConnections.Columns.Add("Status")

    For i As Integer = 0 To dbConStrList.Count - 1
      lviewConnections.Items.Add(CreateItem(dbConStrList.Item(i)))
    Next

    lviewConnections.AutoResizeColumns(ColumnHeaderAutoResizeStyle.HeaderSize)
  End Sub

  Private Sub UpdateListView()
    'Dim item As ListViewItem

    For Each item As ListViewItem In lviewConnections.Items
      If (item IsNot Nothing) Then
        If (item.Tag IsNot Nothing) Then
          If TypeOf (item.Tag) Is DbConnection Then
            Continue For
          End If
        End If
        item.Remove()
      End If
    Next

    Dim dbConStrList As List(Of DbConnectionString) = DbConnectionString.GetSavedDbConnectionStrings()
    For i As Integer = 0 To dbConStrList.Count - 1
      If (lviewConnections.Items.IndexOfKey(dbConStrList.Item(i).Name) < 0) Then
        lviewConnections.Items.Add(CreateItem(dbConStrList.Item(i)))
      End If
    Next

  End Sub

  'Private Function GetSelectedItem() As DbConnection
  '  If (lviewConnections.SelectedItems IsNot Nothing) Then
  '    If (lviewConnections.SelectedItems.Item(0) IsNot Nothing) Then
  '      Return CType(lviewConnections.SelectedItems.Item(0).Tag, DbConnection)
  '    Else
  '      Return Nothing
  '    End If
  '  Else
  '    Return Nothing
  '  End If
  'End Function

  Private Function GetSelectedItem() As ListViewItem
    If (lviewConnections.SelectedItems IsNot Nothing) Then
      If (lviewConnections.SelectedItems.Count > 0) Then
        Return lviewConnections.SelectedItems.Item(0)
      End If
    End If
    Return Nothing
  End Function

  Private Sub UpdateItemStatus(item As ListViewItem)
    If (item IsNot Nothing) Then
      If IsListItemConnectionOpen(item) Then
        SetItemStatusOpen(item)
      Else
        SetItemStatusClosed(item)
      End If
    End If
  End Sub

  Private Sub lviewConnections_SelectedIndexChanged(sender As System.Object, e As System.EventArgs) Handles lviewConnections.SelectedIndexChanged
    UpdateItemStatus(GetSelectedItem())
  End Sub

  Private Sub AddConnection(db As DbConnection)

  End Sub
  Private Sub ConnectionManager_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    InitListView()
  End Sub

End Class
