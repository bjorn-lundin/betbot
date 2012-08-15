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
        Me.buttonClearRegistry = New System.Windows.Forms.Button()
        Me.chkSSL = New System.Windows.Forms.CheckBox()
        Me.ButtonSaveParams = New System.Windows.Forms.Button()
        Me.grpConnectionTest = New System.Windows.Forms.GroupBox()
        Me.DisconnectButton = New System.Windows.Forms.Button()
        Me.labelCondition = New System.Windows.Forms.Label()
        Me.labelInfo = New System.Windows.Forms.Label()
        Me.txtPID = New System.Windows.Forms.TextBox()
        Me.txtInfo = New System.Windows.Forms.TextBox()
        Me.labelPID = New System.Windows.Forms.Label()
        Me.txtCondition = New System.Windows.Forms.TextBox()
        Me.labelConnectionString = New System.Windows.Forms.Label()
        Me.panelBottom.SuspendLayout()
        Me.grpConnectionParams.SuspendLayout()
        Me.grpConnectionTest.SuspendLayout()
        Me.SuspendLayout()
        '
        'panelBottom
        '
        Me.panelBottom.Controls.Add(Me.ButtonCancel)
        Me.panelBottom.Controls.Add(Me.OkButton)
        Me.panelBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.panelBottom.Location = New System.Drawing.Point(0, 418)
        Me.panelBottom.Name = "panelBottom"
        Me.panelBottom.Size = New System.Drawing.Size(590, 52)
        Me.panelBottom.TabIndex = 0
        '
        'ButtonCancel
        '
        Me.ButtonCancel.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.ButtonCancel.Location = New System.Drawing.Point(402, 17)
        Me.ButtonCancel.Name = "ButtonCancel"
        Me.ButtonCancel.Size = New System.Drawing.Size(75, 23)
        Me.ButtonCancel.TabIndex = 3
        Me.ButtonCancel.Text = "Cancel"
        Me.ButtonCancel.UseVisualStyleBackColor = True
        '
        'OkButton
        '
        Me.OkButton.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right), System.Windows.Forms.AnchorStyles)
        Me.OkButton.Location = New System.Drawing.Point(503, 17)
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
        Me.grpConnectionParams.Controls.Add(Me.chkSSL)
        Me.grpConnectionParams.Controls.Add(Me.txtPort)
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
        Me.grpConnectionParams.Location = New System.Drawing.Point(0, 0)
        Me.grpConnectionParams.Name = "grpConnectionParams"
        Me.grpConnectionParams.Size = New System.Drawing.Size(590, 201)
        Me.grpConnectionParams.TabIndex = 14
        Me.grpConnectionParams.TabStop = False
        Me.grpConnectionParams.Text = "Connection parameters"
        '
        'buttonClearRegistry
        '
        Me.buttonClearRegistry.Location = New System.Drawing.Point(433, 179)
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
        'ButtonSaveParams
        '
        Me.ButtonSaveParams.Location = New System.Drawing.Point(286, 179)
        Me.ButtonSaveParams.Name = "ButtonSaveParams"
        Me.ButtonSaveParams.Size = New System.Drawing.Size(111, 23)
        Me.ButtonSaveParams.TabIndex = 12
        Me.ButtonSaveParams.Text = "Save Connection"
        Me.ButtonSaveParams.UseVisualStyleBackColor = True
        '
        'grpConnectionTest
        '
        Me.grpConnectionTest.Controls.Add(Me.buttonClearRegistry)
        Me.grpConnectionTest.Controls.Add(Me.DisconnectButton)
        Me.grpConnectionTest.Controls.Add(Me.ButtonSaveParams)
        Me.grpConnectionTest.Controls.Add(Me.labelCondition)
        Me.grpConnectionTest.Controls.Add(Me.labelInfo)
        Me.grpConnectionTest.Controls.Add(Me.txtPID)
        Me.grpConnectionTest.Controls.Add(Me.txtInfo)
        Me.grpConnectionTest.Controls.Add(Me.labelPID)
        Me.grpConnectionTest.Controls.Add(Me.txtCondition)
        Me.grpConnectionTest.Controls.Add(Me.labelConnectionString)
        Me.grpConnectionTest.Controls.Add(Me.ConnectButton)
        Me.grpConnectionTest.Controls.Add(Me.txtConnectionString)
        Me.grpConnectionTest.Dock = System.Windows.Forms.DockStyle.Top
        Me.grpConnectionTest.Location = New System.Drawing.Point(0, 201)
        Me.grpConnectionTest.Name = "grpConnectionTest"
        Me.grpConnectionTest.Size = New System.Drawing.Size(590, 217)
        Me.grpConnectionTest.TabIndex = 15
        Me.grpConnectionTest.TabStop = False
        Me.grpConnectionTest.Text = "Connection test"
        '
        'DisconnectButton
        '
        Me.DisconnectButton.Location = New System.Drawing.Point(137, 179)
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
        'DbConnectionDialog
        '
        Me.ClientSize = New System.Drawing.Size(590, 470)
        Me.Controls.Add(Me.grpConnectionTest)
        Me.Controls.Add(Me.grpConnectionParams)
        Me.Controls.Add(Me.panelBottom)
        Me.FormTitle = "Manage Database Connections"
        Me.Icon = CType(resources.GetObject("$this.Icon"), System.Drawing.Icon)
        Me.Name = "DbConnectionDialog"
        Me.Text = "Manage Database Connections"
        Me.panelBottom.ResumeLayout(False)
        Me.grpConnectionParams.ResumeLayout(False)
        Me.grpConnectionParams.PerformLayout()
        Me.grpConnectionTest.ResumeLayout(False)
        Me.grpConnectionTest.PerformLayout()
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

    Private _DbConnectionString As DbInterface.DbConnectionString
    Private _DbConnection As DbInterface.DbConnection
    Friend WithEvents grpConnectionParams As System.Windows.Forms.GroupBox
    Friend WithEvents ButtonSaveParams As System.Windows.Forms.Button
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
    Private _DialogResult As Boolean = False

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Public Function StartDialog(ByRef dbConStr As DbInterface.DbConnectionString) As Boolean
        _DbConnectionString = dbConStr
        MyBase.StartForm()
        Return _DialogResult
    End Function

    Public Function GetDbConnectionString() As DbInterface.DbConnectionString
        Return _DbConnectionString
    End Function

    Public Function GetDbConnection() As DbInterface.DbConnection
        Return _DbConnection
    End Function

    Private Sub OkButton_Click(sender As System.Object, e As System.EventArgs) Handles OkButton.Click
        'Save input to ConnectionStringObject
        SaveToConnectionStringObject()
        _DialogResult = True
        MyBase.EndForm()
    End Sub

    Private Sub ButtonCancel_Click(sender As System.Object, e As System.EventArgs) Handles ButtonCancel.Click
        _DialogResult = False
        MyBase.EndForm()
    End Sub

    Private Sub SaveButton_Click(sender As System.Object, e As System.EventArgs)
        'Save input to ConnectionStringObject
        SaveToConnectionStringObject()
        'Save to Registry
        _DbConnectionString.Save()
    End Sub

    Private Function ConnectDb() As Boolean
        If Not (_DbConnection Is Nothing) Then
            _DbConnection.Close()
            _DbConnection.Dispose()
            _DbConnection = Nothing
        End If

        _DbConnection = New DbInterface.DbConnection(_DbConnectionString.BuildConnectionString)

        Return _DbConnection.Open()
    End Function

    Private Sub DisconnectDb()
        If (_DbConnection IsNot Nothing) Then
            _DbConnection.Close()
        End If
    End Sub

    Private Sub UpdateConnectionInfo()
        txtConnectionString.Text = _DbConnectionString.BuildConnectionString

        If (_DbConnection Is Nothing) Then
            txtPID.Text = String.Empty
            txtCondition.Text = String.Empty
            txtInfo.Text = String.Empty
        Else
            txtPID.Text = _DbConnection.PID.ToString
            txtCondition.Text = _DbConnection.State.ToString
            txtInfo.Text = _DbConnection.VersionLong
        End If
    End Sub

    Private Sub ButtonSaveParams_Click(sender As System.Object, e As System.EventArgs) Handles ButtonSaveParams.Click
        'Save input to ConnectionStringObject
        SaveToConnectionStringObject()
        'Save to Registry
        _DbConnectionString.Save()
    End Sub

    Private Sub ConnectButton_Click(sender As System.Object, e As System.EventArgs) Handles ConnectButton.Click
        SaveToConnectionStringObject()
        ConnectDb()
        UpdateConnectionInfo()
    End Sub

    Private Sub InitDialog()
        txtServer.Text = _DbConnectionString.Server
        txtPort.Text = _DbConnectionString.Port
        txtDatabase.Text = _DbConnectionString.Database
        txtPassword.Text = _DbConnectionString.Password
        txtUserId.Text = _DbConnectionString.UserId
        chkSSL.Checked = _DbConnectionString.SSL
        txtConnectionString.Text = String.Empty
    End Sub

    Private Sub SaveToConnectionStringObject()
        _DbConnectionString.Server = txtServer.Text.Trim
        _DbConnectionString.Port = txtPort.Text.Trim
        _DbConnectionString.Database = txtDatabase.Text.Trim
        _DbConnectionString.UserId = txtUserId.Text.Trim
        _DbConnectionString.Password = txtPassword.Text
        _DbConnectionString.SSL = chkSSL.Checked
    End Sub

    Private Sub DbConnectionDialog_Load(sender As Object, e As System.EventArgs) Handles Me.Load
        InitDialog()
    End Sub

    Private Sub DisconnectButton_Click(sender As System.Object, e As System.EventArgs) Handles DisconnectButton.Click
        DisconnectDb()
        UpdateConnectionInfo()
    End Sub

    Private Sub buttonClearRegistry_Click(sender As System.Object, e As System.EventArgs) Handles buttonClearRegistry.Click
        DbConnectionString.ClearRegistry()
    End Sub
End Class
