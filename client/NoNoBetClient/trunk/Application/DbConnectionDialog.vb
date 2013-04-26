Imports Microsoft.Win32
Imports DbInterface

Public Class DbConnectionDialog
  Inherits BaseComponents.BaseForm

  Private Sub InitializeComponent()
    Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(DbConnectionDialog))
    Me.panelBottom = New System.Windows.Forms.Panel()
    Me.ButtonCancel = New System.Windows.Forms.Button()
    Me.OkButton = New System.Windows.Forms.Button()
    Me.labelServer = New System.Windows.Forms.Label()
    Me.txtServer = New System.Windows.Forms.TextBox()
    Me.txtPort = New System.Windows.Forms.TextBox()
    Me.labelPort = New System.Windows.Forms.Label()
    Me.txtUserId = New System.Windows.Forms.TextBox()
    Me.labelUserId = New System.Windows.Forms.Label()
    Me.txtPassword = New System.Windows.Forms.TextBox()
    Me.labelPassword = New System.Windows.Forms.Label()
    Me.txtDatabase = New System.Windows.Forms.TextBox()
    Me.labelDatabase = New System.Windows.Forms.Label()
    Me.ConnectButton = New System.Windows.Forms.Button()
    Me.txtConnectionString = New System.Windows.Forms.TextBox()
    Me.grpConnectionParams = New System.Windows.Forms.GroupBox()
    Me.btnClearParams = New System.Windows.Forms.Button()
    Me.btnRemoveParams = New System.Windows.Forms.Button()
    Me.buttonClearRegistry = New System.Windows.Forms.Button()
    Me.chkSSL = New System.Windows.Forms.CheckBox()
    Me.btnSaveParams = New System.Windows.Forms.Button()
    Me.grpConnectionTest = New System.Windows.Forms.GroupBox()
    Me.DisconnectButton = New System.Windows.Forms.Button()
    Me.labelCondition = New System.Windows.Forms.Label()
    Me.labelInfo = New System.Windows.Forms.Label()
    Me.txtPID = New System.Windows.Forms.TextBox()
    Me.txtInfo = New System.Windows.Forms.TextBox()
    Me.labelPID = New System.Windows.Forms.Label()
    Me.txtCondition = New System.Windows.Forms.TextBox()
    Me.labelConnectionString = New System.Windows.Forms.Label()
    Me.grpSavedConnections = New System.Windows.Forms.GroupBox()
    Me.cboConnection = New System.Windows.Forms.ComboBox()
    Me.ButtonSaveParams = New System.Windows.Forms.Button()
    Me.panelBottom.SuspendLayout()
    Me.grpConnectionParams.SuspendLayout()
    Me.grpConnectionTest.SuspendLayout()
    Me.grpSavedConnections.SuspendLayout()
    Me.SuspendLayout()
    '
    'panelBottom
    '
    Me.panelBottom.Controls.Add(Me.ButtonCancel)
    Me.panelBottom.Controls.Add(Me.OkButton)
    Me.panelBottom.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.panelBottom.Location = New System.Drawing.Point(0, 538)
    Me.panelBottom.Name = "panelBottom"
    Me.panelBottom.Size = New System.Drawing.Size(592, 52)
    Me.panelBottom.TabIndex = 0
    '
    'ButtonCancel
    '
    Me.ButtonCancel.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.ButtonCancel.Location = New System.Drawing.Point(404, 17)
    Me.ButtonCancel.Name = "ButtonCancel"
    Me.ButtonCancel.Size = New System.Drawing.Size(75, 23)
    Me.ButtonCancel.TabIndex = 3
    Me.ButtonCancel.Text = "Cancel"
    Me.ButtonCancel.UseVisualStyleBackColor = True
    '
    'OkButton
    '
    Me.OkButton.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
    Me.OkButton.Location = New System.Drawing.Point(505, 17)
    Me.OkButton.Name = "OkButton"
    Me.OkButton.Size = New System.Drawing.Size(75, 23)
    Me.OkButton.TabIndex = 2
    Me.OkButton.Text = "Ok"
    Me.OkButton.UseVisualStyleBackColor = True
    '
    'labelServer
    '
    Me.labelServer.AutoSize = True
    Me.labelServer.Location = New System.Drawing.Point(10, 29)
    Me.labelServer.Name = "labelServer"
    Me.labelServer.Size = New System.Drawing.Size(38, 13)
    Me.labelServer.TabIndex = 1
    Me.labelServer.Text = "Server"
    '
    'txtServer
    '
    Me.txtServer.Location = New System.Drawing.Point(64, 26)
    Me.txtServer.Name = "txtServer"
    Me.txtServer.Size = New System.Drawing.Size(216, 20)
    Me.txtServer.TabIndex = 2
    '
    'txtPort
    '
    Me.txtPort.Location = New System.Drawing.Point(64, 52)
    Me.txtPort.Name = "txtPort"
    Me.txtPort.Size = New System.Drawing.Size(60, 20)
    Me.txtPort.TabIndex = 4
    '
    'labelPort
    '
    Me.labelPort.AutoSize = True
    Me.labelPort.Location = New System.Drawing.Point(10, 55)
    Me.labelPort.Name = "labelPort"
    Me.labelPort.Size = New System.Drawing.Size(26, 13)
    Me.labelPort.TabIndex = 3
    Me.labelPort.Text = "Port"
    '
    'txtUserId
    '
    Me.txtUserId.Location = New System.Drawing.Point(64, 81)
    Me.txtUserId.Name = "txtUserId"
    Me.txtUserId.Size = New System.Drawing.Size(216, 20)
    Me.txtUserId.TabIndex = 6
    '
    'labelUserId
    '
    Me.labelUserId.AutoSize = True
    Me.labelUserId.Location = New System.Drawing.Point(10, 84)
    Me.labelUserId.Name = "labelUserId"
    Me.labelUserId.Size = New System.Drawing.Size(41, 13)
    Me.labelUserId.TabIndex = 5
    Me.labelUserId.Text = "User Id"
    '
    'txtPassword
    '
    Me.txtPassword.Location = New System.Drawing.Point(64, 107)
    Me.txtPassword.Name = "txtPassword"
    Me.txtPassword.Size = New System.Drawing.Size(216, 20)
    Me.txtPassword.TabIndex = 8
    '
    'labelPassword
    '
    Me.labelPassword.AutoSize = True
    Me.labelPassword.Location = New System.Drawing.Point(10, 110)
    Me.labelPassword.Name = "labelPassword"
    Me.labelPassword.Size = New System.Drawing.Size(53, 13)
    Me.labelPassword.TabIndex = 7
    Me.labelPassword.Text = "Password"
    '
    'txtDatabase
    '
    Me.txtDatabase.Location = New System.Drawing.Point(64, 133)
    Me.txtDatabase.Name = "txtDatabase"
    Me.txtDatabase.Size = New System.Drawing.Size(216, 20)
    Me.txtDatabase.TabIndex = 10
    '
    'labelDatabase
    '
    Me.labelDatabase.AutoSize = True
    Me.labelDatabase.Location = New System.Drawing.Point(10, 136)
    Me.labelDatabase.Name = "labelDatabase"
    Me.labelDatabase.Size = New System.Drawing.Size(53, 13)
    Me.labelDatabase.TabIndex = 9
    Me.labelDatabase.Text = "Database"
    '
    'ConnectButton
    '
    Me.ConnectButton.Location = New System.Drawing.Point(15, 179)
    Me.ConnectButton.Name = "ConnectButton"
    Me.ConnectButton.Size = New System.Drawing.Size(97, 23)
    Me.ConnectButton.TabIndex = 12
    Me.ConnectButton.Text = "Connect"
    Me.ConnectButton.UseVisualStyleBackColor = True
    '
    'txtConnectionString
    '
    Me.txtConnectionString.Location = New System.Drawing.Point(9, 48)
    Me.txtConnectionString.Name = "txtConnectionString"
    Me.txtConnectionString.ReadOnly = True
    Me.txtConnectionString.Size = New System.Drawing.Size(569, 20)
    Me.txtConnectionString.TabIndex = 13
    '
    'grpConnectionParams
    '
    Me.grpConnectionParams.Controls.Add(Me.btnClearParams)
    Me.grpConnectionParams.Controls.Add(Me.btnRemoveParams)
    Me.grpConnectionParams.Controls.Add(Me.buttonClearRegistry)
    Me.grpConnectionParams.Controls.Add(Me.chkSSL)
    Me.grpConnectionParams.Controls.Add(Me.txtPort)
    Me.grpConnectionParams.Controls.Add(Me.btnSaveParams)
    Me.grpConnectionParams.Controls.Add(Me.labelServer)
    Me.grpConnectionParams.Controls.Add(Me.txtServer)
    Me.grpConnectionParams.Controls.Add(Me.labelPort)
    Me.grpConnectionParams.Controls.Add(Me.txtDatabase)
    Me.grpConnectionParams.Controls.Add(Me.labelUserId)
    Me.grpConnectionParams.Controls.Add(Me.labelDatabase)
    Me.grpConnectionParams.Controls.Add(Me.txtUserId)
    Me.grpConnectionParams.Controls.Add(Me.txtPassword)
    Me.grpConnectionParams.Controls.Add(Me.labelPassword)
    Me.grpConnectionParams.Dock = System.Windows.Forms.DockStyle.Top
    Me.grpConnectionParams.Location = New System.Drawing.Point(0, 69)
    Me.grpConnectionParams.Name = "grpConnectionParams"
    Me.grpConnectionParams.Size = New System.Drawing.Size(592, 252)
    Me.grpConnectionParams.TabIndex = 14
    Me.grpConnectionParams.TabStop = False
    Me.grpConnectionParams.Text = "Connection parameters"
    '
    'btnClearParams
    '
    Me.btnClearParams.Location = New System.Drawing.Point(418, 26)
    Me.btnClearParams.Name = "btnClearParams"
    Me.btnClearParams.Size = New System.Drawing.Size(67, 23)
    Me.btnClearParams.TabIndex = 28
    Me.btnClearParams.Text = "Clear"
    Me.btnClearParams.UseVisualStyleBackColor = True
    '
    'btnRemoveParams
    '
    Me.btnRemoveParams.Location = New System.Drawing.Point(168, 213)
    Me.btnRemoveParams.Name = "btnRemoveParams"
    Me.btnRemoveParams.Size = New System.Drawing.Size(125, 23)
    Me.btnRemoveParams.TabIndex = 27
    Me.btnRemoveParams.Text = "Remove Connection"
    Me.btnRemoveParams.UseVisualStyleBackColor = True
    '
    'buttonClearRegistry
    '
    Me.buttonClearRegistry.Location = New System.Drawing.Point(418, 213)
    Me.buttonClearRegistry.Name = "buttonClearRegistry"
    Me.buttonClearRegistry.Size = New System.Drawing.Size(145, 23)
    Me.buttonClearRegistry.TabIndex = 26
    Me.buttonClearRegistry.Text = "Clear Saved Connections"
    Me.buttonClearRegistry.UseVisualStyleBackColor = True
    '
    'chkSSL
    '
    Me.chkSSL.AutoSize = True
    Me.chkSSL.Location = New System.Drawing.Point(64, 163)
    Me.chkSSL.Name = "chkSSL"
    Me.chkSSL.Size = New System.Drawing.Size(46, 17)
    Me.chkSSL.TabIndex = 13
    Me.chkSSL.Text = "SSL"
    Me.chkSSL.UseVisualStyleBackColor = True
    '
    'btnSaveParams
    '
    Me.btnSaveParams.Location = New System.Drawing.Point(12, 213)
    Me.btnSaveParams.Name = "btnSaveParams"
    Me.btnSaveParams.Size = New System.Drawing.Size(111, 23)
    Me.btnSaveParams.TabIndex = 12
    Me.btnSaveParams.Text = "Save Connection"
    Me.btnSaveParams.UseVisualStyleBackColor = True
    '
    'grpConnectionTest
    '
    Me.grpConnectionTest.Controls.Add(Me.DisconnectButton)
    Me.grpConnectionTest.Controls.Add(Me.labelCondition)
    Me.grpConnectionTest.Controls.Add(Me.labelInfo)
    Me.grpConnectionTest.Controls.Add(Me.txtPID)
    Me.grpConnectionTest.Controls.Add(Me.txtInfo)
    Me.grpConnectionTest.Controls.Add(Me.labelPID)
    Me.grpConnectionTest.Controls.Add(Me.txtCondition)
    Me.grpConnectionTest.Controls.Add(Me.labelConnectionString)
    Me.grpConnectionTest.Controls.Add(Me.ConnectButton)
    Me.grpConnectionTest.Controls.Add(Me.txtConnectionString)
    Me.grpConnectionTest.Dock = System.Windows.Forms.DockStyle.Fill
    Me.grpConnectionTest.Location = New System.Drawing.Point(0, 321)
    Me.grpConnectionTest.Name = "grpConnectionTest"
    Me.grpConnectionTest.Size = New System.Drawing.Size(592, 269)
    Me.grpConnectionTest.TabIndex = 15
    Me.grpConnectionTest.TabStop = False
    Me.grpConnectionTest.Text = "Connection test"
    '
    'DisconnectButton
    '
    Me.DisconnectButton.Location = New System.Drawing.Point(125, 179)
    Me.DisconnectButton.Name = "DisconnectButton"
    Me.DisconnectButton.Size = New System.Drawing.Size(97, 23)
    Me.DisconnectButton.TabIndex = 25
    Me.DisconnectButton.Text = "Disconnect"
    Me.DisconnectButton.UseVisualStyleBackColor = True
    '
    'labelCondition
    '
    Me.labelCondition.AutoSize = True
    Me.labelCondition.Location = New System.Drawing.Point(12, 147)
    Me.labelCondition.Name = "labelCondition"
    Me.labelCondition.Size = New System.Drawing.Size(51, 13)
    Me.labelCondition.TabIndex = 24
    Me.labelCondition.Text = "Condition"
    '
    'labelInfo
    '
    Me.labelInfo.AutoSize = True
    Me.labelInfo.Location = New System.Drawing.Point(10, 114)
    Me.labelInfo.Name = "labelInfo"
    Me.labelInfo.Size = New System.Drawing.Size(63, 13)
    Me.labelInfo.TabIndex = 23
    Me.labelInfo.Text = "Version Info"
    '
    'txtPID
    '
    Me.txtPID.Location = New System.Drawing.Point(82, 79)
    Me.txtPID.Name = "txtPID"
    Me.txtPID.ReadOnly = True
    Me.txtPID.Size = New System.Drawing.Size(71, 20)
    Me.txtPID.TabIndex = 22
    '
    'txtInfo
    '
    Me.txtInfo.Location = New System.Drawing.Point(82, 107)
    Me.txtInfo.Name = "txtInfo"
    Me.txtInfo.ReadOnly = True
    Me.txtInfo.Size = New System.Drawing.Size(481, 20)
    Me.txtInfo.TabIndex = 21
    '
    'labelPID
    '
    Me.labelPID.AutoSize = True
    Me.labelPID.Location = New System.Drawing.Point(10, 82)
    Me.labelPID.Name = "labelPID"
    Me.labelPID.Size = New System.Drawing.Size(25, 13)
    Me.labelPID.TabIndex = 20
    Me.labelPID.Text = "PID"
    '
    'txtCondition
    '
    Me.txtCondition.Location = New System.Drawing.Point(82, 140)
    Me.txtCondition.Name = "txtCondition"
    Me.txtCondition.ReadOnly = True
    Me.txtCondition.Size = New System.Drawing.Size(229, 20)
    Me.txtCondition.TabIndex = 19
    '
    'labelConnectionString
    '
    Me.labelConnectionString.AutoSize = True
    Me.labelConnectionString.Location = New System.Drawing.Point(6, 25)
    Me.labelConnectionString.Name = "labelConnectionString"
    Me.labelConnectionString.Size = New System.Drawing.Size(115, 13)
    Me.labelConnectionString.TabIndex = 14
    Me.labelConnectionString.Text = "Connection string used"
    '
    'grpSavedConnections
    '
    Me.grpSavedConnections.Controls.Add(Me.cboConnection)
    Me.grpSavedConnections.Dock = System.Windows.Forms.DockStyle.Top
    Me.grpSavedConnections.Location = New System.Drawing.Point(0, 0)
    Me.grpSavedConnections.Name = "grpSavedConnections"
    Me.grpSavedConnections.Size = New System.Drawing.Size(592, 69)
    Me.grpSavedConnections.TabIndex = 16
    Me.grpSavedConnections.TabStop = False
    Me.grpSavedConnections.Text = "Saved connections"
    '
    'cboConnection
    '
    Me.cboConnection.FormattingEnabled = True
    Me.cboConnection.Location = New System.Drawing.Point(5, 29)
    Me.cboConnection.Margin = New System.Windows.Forms.Padding(2)
    Me.cboConnection.Name = "cboConnection"
    Me.cboConnection.Size = New System.Drawing.Size(424, 21)
    Me.cboConnection.TabIndex = 3
    '
    'ButtonSaveParams
    '
    Me.ButtonSaveParams.Location = New System.Drawing.Point(12, 213)
    Me.ButtonSaveParams.Name = "ButtonSaveParams"
    Me.ButtonSaveParams.Size = New System.Drawing.Size(111, 23)
    Me.ButtonSaveParams.TabIndex = 12
    Me.ButtonSaveParams.Text = "Save Connection"
    Me.ButtonSaveParams.UseVisualStyleBackColor = True
    '
    'DbConnectionDialog
    '
    Me.ClientSize = New System.Drawing.Size(592, 590)
    Me.Controls.Add(Me.panelBottom)
    Me.Controls.Add(Me.grpConnectionTest)
    Me.Controls.Add(Me.grpConnectionParams)
    Me.Controls.Add(Me.grpSavedConnections)
    Me.FormTitle = "Manage Database Connections"
    Me.Icon = CType(resources.GetObject("$this.Icon"), System.Drawing.Icon)
    Me.Name = "DbConnectionDialog"
    Me.Text = "Manage Database Connections"
    Me.panelBottom.ResumeLayout(False)
    Me.grpConnectionParams.ResumeLayout(False)
    Me.grpConnectionParams.PerformLayout()
    Me.grpConnectionTest.ResumeLayout(False)
    Me.grpConnectionTest.PerformLayout()
    Me.grpSavedConnections.ResumeLayout(False)
    Me.ResumeLayout(False)

  End Sub
  Friend WithEvents panelBottom As System.Windows.Forms.Panel
  Friend WithEvents ButtonCancel As System.Windows.Forms.Button
  Friend WithEvents OkButton As System.Windows.Forms.Button
  Friend WithEvents labelServer As System.Windows.Forms.Label
  Friend WithEvents txtServer As System.Windows.Forms.TextBox
  Friend WithEvents txtPort As System.Windows.Forms.TextBox
  Friend WithEvents labelPort As System.Windows.Forms.Label
  Friend WithEvents txtUserId As System.Windows.Forms.TextBox
  Friend WithEvents labelUserId As System.Windows.Forms.Label
  Friend WithEvents txtPassword As System.Windows.Forms.TextBox
  Friend WithEvents labelPassword As System.Windows.Forms.Label
  Friend WithEvents txtDatabase As System.Windows.Forms.TextBox
  Friend WithEvents labelDatabase As System.Windows.Forms.Label
  Friend WithEvents ConnectButton As System.Windows.Forms.Button
  Friend WithEvents txtConnectionString As System.Windows.Forms.TextBox
  Friend WithEvents grpConnectionParams As System.Windows.Forms.GroupBox
  Friend WithEvents btnSaveParams As System.Windows.Forms.Button
  Friend WithEvents grpConnectionTest As System.Windows.Forms.GroupBox
  Friend WithEvents labelConnectionString As System.Windows.Forms.Label
  Friend WithEvents labelCondition As System.Windows.Forms.Label
  Friend WithEvents labelInfo As System.Windows.Forms.Label
  Friend WithEvents txtPID As System.Windows.Forms.TextBox
  Friend WithEvents txtInfo As System.Windows.Forms.TextBox
  Friend WithEvents labelPID As System.Windows.Forms.Label
  Friend WithEvents txtCondition As System.Windows.Forms.TextBox
  Friend WithEvents DisconnectButton As System.Windows.Forms.Button
  Friend WithEvents chkSSL As System.Windows.Forms.CheckBox
  Friend WithEvents buttonClearRegistry As System.Windows.Forms.Button
  Friend WithEvents grpSavedConnections As System.Windows.Forms.GroupBox
  Friend WithEvents cboConnection As System.Windows.Forms.ComboBox
  Friend WithEvents btnClearParams As System.Windows.Forms.Button
  Friend WithEvents btnRemoveParams As System.Windows.Forms.Button
  Friend WithEvents ButtonSaveParams As System.Windows.Forms.Button

  ''Private _DbConnectionString As DbInterface.DbConnectionString
  Private _DbConnection As DbInterface.DbConnection
  Private _DialogResult As Boolean = False

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Function StartDialog() As Boolean
    MyBase.StartForm(True)
    Return _DialogResult
  End Function

  'Public Function GetDbConnectionString() As DbInterface.DbConnectionString
  '  Return _DbConnectionString
  'End Function

  Public Function GetDbConnection() As DbInterface.DbConnection
    Return _DbConnection
  End Function

  Private Sub OkButton_Click(sender As System.Object, e As System.EventArgs) Handles OkButton.Click
    'Save input to ConnectionStringObject
    'SaveToConnectionStringObject()
    _DialogResult = True
    MyBase.EndForm()
  End Sub

  Private Sub ButtonCancel_Click(sender As System.Object, e As System.EventArgs) Handles ButtonCancel.Click
    _DialogResult = False
    MyBase.EndForm()
  End Sub

  Private Sub SaveButton_Click(sender As System.Object, e As System.EventArgs)
    Dim dbConStr As DbConnectionString = New DbConnectionString
    'Save input to ConnectionStringObject
    SaveToConnectionStringObject(dbConStr)
    'Save to Registry
    dbConStr.Save()
    dbConStr = Nothing
    LoadCombo()
  End Sub

  Private Function ConnectDb(dbConStr As DbConnectionString) As Boolean
    If Not (_DbConnection Is Nothing) Then
      _DbConnection.Close()
      _DbConnection.Dispose()
      _DbConnection = Nothing
    End If

    _DbConnection = New DbInterface.DbConnection(dbConStr)

    Return _DbConnection.Open()
  End Function

  Private Sub DisconnectDb()
    If (_DbConnection IsNot Nothing) Then
      _DbConnection.Close()
    End If
  End Sub

  Private Sub UpdateConnectionInfo(dbConStr As DbConnectionString)
    If (_DbConnection Is Nothing) Then
      txtPID.Text = String.Empty
      txtCondition.Text = String.Empty
      txtInfo.Text = String.Empty
      txtConnectionString.Text = String.Empty

    Else
      txtConnectionString.Text = _DbConnection.ConnectionString.BuildConnectionString
      txtPID.Text = _DbConnection.PID.ToString
      txtCondition.Text = _DbConnection.State.ToString
      txtInfo.Text = _DbConnection.VersionLong
    End If
  End Sub

  Private Sub ButtonSaveParams_Click(sender As System.Object, e As System.EventArgs) Handles btnSaveParams.Click, ButtonSaveParams.Click
    Dim dbConStr As DbConnectionString = New DbConnectionString
    'Save input to ConnectionStringObject
    SaveToConnectionStringObject(dbConStr)
    'Save to Registry
    dbConStr.Save()
    LoadCombo()
  End Sub

  Private Sub ConnectButton_Click(sender As System.Object, e As System.EventArgs) Handles ConnectButton.Click
    Dim dbConStr As DbConnectionString = New DbConnectionString
    SaveToConnectionStringObject(dbConStr)
    ConnectDb(dbConStr)
    UpdateConnectionInfo(dbConStr)
  End Sub

  Private Sub DisconnectButton_Click(sender As System.Object, e As System.EventArgs) Handles DisconnectButton.Click
    DisconnectDb()
    UpdateConnectionInfo(Nothing)
  End Sub

  Private Sub buttonClearRegistry_Click(sender As System.Object, e As System.EventArgs) Handles buttonClearRegistry.Click
    DbConnectionString.DeleteAllFromRegistry()
  End Sub

  Private Sub btnClearParams_Click(sender As System.Object, e As System.EventArgs) Handles btnClearParams.Click
    cboConnection.SelectedItem = Nothing
    InitDialog()
  End Sub

  Private Sub btnRemoveParams_Click(sender As System.Object, e As System.EventArgs) Handles btnRemoveParams.Click
    Dim selectedConnection As DbConnectionString = GetSelectedConnection()

    If (selectedConnection IsNot Nothing) Then
      DbConnectionString.DeleteFromRegistryKey(selectedConnection.Name)
    End If
    LoadCombo()
    InitDialog()
  End Sub

  Private Sub InitDialog()
    Dim selectedConnection As DbConnectionString = GetSelectedConnection()

    If (selectedConnection IsNot Nothing) Then
      txtServer.Text = selectedConnection.Server
      txtPort.Text = selectedConnection.Port
      txtDatabase.Text = selectedConnection.Database
      txtPassword.Text = selectedConnection.Password
      txtUserId.Text = selectedConnection.UserId
      chkSSL.Checked = selectedConnection.SSL
      txtConnectionString.Text = String.Empty
    Else
      txtServer.Text = String.Empty
      txtPort.Text = String.Empty
      txtDatabase.Text = String.Empty
      txtPassword.Text = String.Empty
      txtUserId.Text = String.Empty
      chkSSL.Checked = False
      txtConnectionString.Text = String.Empty
    End If
  End Sub

  Private Sub SaveToConnectionStringObject(dbConStr As DbConnectionString)
    dbConStr.Server = txtServer.Text.Trim
    dbConStr.Port = txtPort.Text.Trim
    dbConStr.Database = txtDatabase.Text.Trim
    dbConStr.UserId = txtUserId.Text.Trim
    dbConStr.Password = txtPassword.Text
    dbConStr.SSL = chkSSL.Checked
  End Sub

  Private Sub LoadCombo()
    DbConnectionString.LoadDbConnectionStringsCombo(cboConnection)
  End Sub

  Private Function GetSelectedConnection() As DbConnectionString
    If (cboConnection.SelectedItem IsNot Nothing) Then
      Return CType(cboConnection.SelectedItem, DbConnectionString)
    Else
      Return Nothing
    End If
  End Function

  Private Sub cboConnection_SelectedIndexChanged(sender As System.Object, e As System.EventArgs) Handles cboConnection.SelectedIndexChanged
    InitDialog()
  End Sub


  Private Sub DbConnectionDialog_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    LoadCombo()
    InitDialog()
  End Sub

End Class
