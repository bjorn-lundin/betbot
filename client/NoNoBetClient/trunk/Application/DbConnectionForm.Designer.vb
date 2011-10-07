<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class DbConnectionForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.Label8 = New System.Windows.Forms.Label()
        Me.txtVersionByProp = New System.Windows.Forms.TextBox()
        Me.btnDisconnect = New System.Windows.Forms.Button()
        Me.Label7 = New System.Windows.Forms.Label()
        Me.txtVersionBySql = New System.Windows.Forms.TextBox()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.txtPID = New System.Windows.Forms.TextBox()
        Me.txtInfo = New System.Windows.Forms.TextBox()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.txtCondition = New System.Windows.Forms.TextBox()
        Me.btnConnect = New System.Windows.Forms.Button()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.cboConnection = New System.Windows.Forms.ComboBox()
        Me.txtHeader = New System.Windows.Forms.TextBox()
        Me.GroupBox2 = New System.Windows.Forms.GroupBox()
        Me.buttonBetSim = New System.Windows.Forms.Button()
        Me.buttonStats = New System.Windows.Forms.Button()
        Me.buttonClose = New System.Windows.Forms.Button()
        Me.btnTest = New System.Windows.Forms.Button()
        Me.btnBrowse = New System.Windows.Forms.Button()
        Me.GroupBox3 = New System.Windows.Forms.GroupBox()
        Me.btnRaceDays = New System.Windows.Forms.Button()
        Me.GroupBox1.SuspendLayout()
        Me.GroupBox2.SuspendLayout()
        Me.GroupBox3.SuspendLayout()
        Me.SuspendLayout()
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.Label8)
        Me.GroupBox1.Controls.Add(Me.txtVersionByProp)
        Me.GroupBox1.Controls.Add(Me.btnDisconnect)
        Me.GroupBox1.Controls.Add(Me.Label7)
        Me.GroupBox1.Controls.Add(Me.txtVersionBySql)
        Me.GroupBox1.Controls.Add(Me.Label6)
        Me.GroupBox1.Controls.Add(Me.Label5)
        Me.GroupBox1.Controls.Add(Me.txtPID)
        Me.GroupBox1.Controls.Add(Me.txtInfo)
        Me.GroupBox1.Controls.Add(Me.Label4)
        Me.GroupBox1.Controls.Add(Me.txtCondition)
        Me.GroupBox1.Controls.Add(Me.btnConnect)
        Me.GroupBox1.Controls.Add(Me.Label3)
        Me.GroupBox1.Controls.Add(Me.cboConnection)
        Me.GroupBox1.Dock = System.Windows.Forms.DockStyle.Top
        Me.GroupBox1.Location = New System.Drawing.Point(0, 0)
        Me.GroupBox1.Margin = New System.Windows.Forms.Padding(4)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Padding = New System.Windows.Forms.Padding(4)
        Me.GroupBox1.Size = New System.Drawing.Size(578, 249)
        Me.GroupBox1.TabIndex = 4
        Me.GroupBox1.TabStop = False
        '
        'Label8
        '
        Me.Label8.AutoSize = True
        Me.Label8.Location = New System.Drawing.Point(10, 193)
        Me.Label8.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label8.Name = "Label8"
        Me.Label8.Size = New System.Drawing.Size(133, 17)
        Me.Label8.TabIndex = 23
        Me.Label8.Text = "Version by Property"
        '
        'txtVersionByProp
        '
        Me.txtVersionByProp.Location = New System.Drawing.Point(8, 214)
        Me.txtVersionByProp.Margin = New System.Windows.Forms.Padding(4)
        Me.txtVersionByProp.Name = "txtVersionByProp"
        Me.txtVersionByProp.Size = New System.Drawing.Size(560, 22)
        Me.txtVersionByProp.TabIndex = 22
        '
        'btnDisconnect
        '
        Me.btnDisconnect.Location = New System.Drawing.Point(7, 109)
        Me.btnDisconnect.Margin = New System.Windows.Forms.Padding(4)
        Me.btnDisconnect.Name = "btnDisconnect"
        Me.btnDisconnect.Size = New System.Drawing.Size(128, 28)
        Me.btnDisconnect.TabIndex = 21
        Me.btnDisconnect.Text = "Disconnect"
        Me.btnDisconnect.UseVisualStyleBackColor = True
        '
        'Label7
        '
        Me.Label7.AutoSize = True
        Me.Label7.Location = New System.Drawing.Point(13, 146)
        Me.Label7.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label7.Name = "Label7"
        Me.Label7.Size = New System.Drawing.Size(107, 17)
        Me.Label7.TabIndex = 20
        Me.Label7.Text = "Version by SQL"
        '
        'txtVersionBySql
        '
        Me.txtVersionBySql.Location = New System.Drawing.Point(11, 167)
        Me.txtVersionBySql.Margin = New System.Windows.Forms.Padding(4)
        Me.txtVersionBySql.Name = "txtVersionBySql"
        Me.txtVersionBySql.Size = New System.Drawing.Size(560, 22)
        Me.txtVersionBySql.TabIndex = 19
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(194, 133)
        Me.Label6.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(67, 17)
        Me.Label6.TabIndex = 18
        Me.Label6.Text = "Condition"
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(217, 100)
        Me.Label5.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(31, 17)
        Me.Label5.TabIndex = 17
        Me.Label5.Text = "Info"
        '
        'txtPID
        '
        Me.txtPID.Location = New System.Drawing.Point(269, 70)
        Me.txtPID.Margin = New System.Windows.Forms.Padding(4)
        Me.txtPID.Name = "txtPID"
        Me.txtPID.Size = New System.Drawing.Size(302, 22)
        Me.txtPID.TabIndex = 16
        '
        'txtInfo
        '
        Me.txtInfo.Location = New System.Drawing.Point(269, 100)
        Me.txtInfo.Margin = New System.Windows.Forms.Padding(4)
        Me.txtInfo.Name = "txtInfo"
        Me.txtInfo.Size = New System.Drawing.Size(304, 22)
        Me.txtInfo.TabIndex = 15
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(217, 73)
        Me.Label4.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(30, 17)
        Me.Label4.TabIndex = 14
        Me.Label4.Text = "PID"
        '
        'txtCondition
        '
        Me.txtCondition.Location = New System.Drawing.Point(269, 130)
        Me.txtCondition.Margin = New System.Windows.Forms.Padding(4)
        Me.txtCondition.Name = "txtCondition"
        Me.txtCondition.Size = New System.Drawing.Size(304, 22)
        Me.txtCondition.TabIndex = 13
        '
        'btnConnect
        '
        Me.btnConnect.Location = New System.Drawing.Point(8, 73)
        Me.btnConnect.Margin = New System.Windows.Forms.Padding(4)
        Me.btnConnect.Name = "btnConnect"
        Me.btnConnect.Size = New System.Drawing.Size(128, 28)
        Me.btnConnect.TabIndex = 12
        Me.btnConnect.Text = "Connect"
        Me.btnConnect.UseVisualStyleBackColor = True
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(8, 11)
        Me.Label3.Margin = New System.Windows.Forms.Padding(4, 0, 4, 0)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(118, 17)
        Me.Label3.TabIndex = 11
        Me.Label3.Text = "Connection string"
        '
        'cboConnection
        '
        Me.cboConnection.FormattingEnabled = True
        Me.cboConnection.Location = New System.Drawing.Point(7, 31)
        Me.cboConnection.Name = "cboConnection"
        Me.cboConnection.Size = New System.Drawing.Size(564, 24)
        Me.cboConnection.TabIndex = 2
        '
        'txtHeader
        '
        Me.txtHeader.Location = New System.Drawing.Point(8, 14)
        Me.txtHeader.Margin = New System.Windows.Forms.Padding(4)
        Me.txtHeader.Name = "txtHeader"
        Me.txtHeader.Size = New System.Drawing.Size(457, 22)
        Me.txtHeader.TabIndex = 2
        '
        'GroupBox2
        '
        Me.GroupBox2.Controls.Add(Me.btnRaceDays)
        Me.GroupBox2.Controls.Add(Me.buttonBetSim)
        Me.GroupBox2.Controls.Add(Me.buttonStats)
        Me.GroupBox2.Controls.Add(Me.buttonClose)
        Me.GroupBox2.Controls.Add(Me.btnTest)
        Me.GroupBox2.Controls.Add(Me.btnBrowse)
        Me.GroupBox2.Dock = System.Windows.Forms.DockStyle.Fill
        Me.GroupBox2.Location = New System.Drawing.Point(0, 249)
        Me.GroupBox2.Margin = New System.Windows.Forms.Padding(4)
        Me.GroupBox2.Name = "GroupBox2"
        Me.GroupBox2.Padding = New System.Windows.Forms.Padding(4)
        Me.GroupBox2.Size = New System.Drawing.Size(578, 163)
        Me.GroupBox2.TabIndex = 5
        Me.GroupBox2.TabStop = False
        '
        'buttonBetSim
        '
        Me.buttonBetSim.Location = New System.Drawing.Point(334, 23)
        Me.buttonBetSim.Margin = New System.Windows.Forms.Padding(4)
        Me.buttonBetSim.Name = "buttonBetSim"
        Me.buttonBetSim.Size = New System.Drawing.Size(114, 28)
        Me.buttonBetSim.TabIndex = 19
        Me.buttonBetSim.Text = "Bet simulator"
        Me.buttonBetSim.UseVisualStyleBackColor = True
        '
        'buttonStats
        '
        Me.buttonStats.Location = New System.Drawing.Point(234, 23)
        Me.buttonStats.Margin = New System.Windows.Forms.Padding(4)
        Me.buttonStats.Name = "buttonStats"
        Me.buttonStats.Size = New System.Drawing.Size(92, 28)
        Me.buttonStats.TabIndex = 18
        Me.buttonStats.Text = "Stats"
        Me.buttonStats.UseVisualStyleBackColor = True
        '
        'buttonClose
        '
        Me.buttonClose.DialogResult = System.Windows.Forms.DialogResult.Cancel
        Me.buttonClose.Location = New System.Drawing.Point(476, 62)
        Me.buttonClose.Margin = New System.Windows.Forms.Padding(4)
        Me.buttonClose.Name = "buttonClose"
        Me.buttonClose.Size = New System.Drawing.Size(92, 28)
        Me.buttonClose.TabIndex = 17
        Me.buttonClose.Text = "Close"
        Me.buttonClose.UseVisualStyleBackColor = True
        '
        'btnTest
        '
        Me.btnTest.Location = New System.Drawing.Point(126, 23)
        Me.btnTest.Margin = New System.Windows.Forms.Padding(4)
        Me.btnTest.Name = "btnTest"
        Me.btnTest.Size = New System.Drawing.Size(87, 28)
        Me.btnTest.TabIndex = 16
        Me.btnTest.Text = "Runt Test"
        Me.btnTest.UseVisualStyleBackColor = True
        '
        'btnBrowse
        '
        Me.btnBrowse.Location = New System.Drawing.Point(16, 23)
        Me.btnBrowse.Margin = New System.Windows.Forms.Padding(4)
        Me.btnBrowse.Name = "btnBrowse"
        Me.btnBrowse.Size = New System.Drawing.Size(92, 28)
        Me.btnBrowse.TabIndex = 15
        Me.btnBrowse.Text = "Browse"
        Me.btnBrowse.UseVisualStyleBackColor = True
        '
        'GroupBox3
        '
        Me.GroupBox3.Controls.Add(Me.txtHeader)
        Me.GroupBox3.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.GroupBox3.Location = New System.Drawing.Point(0, 363)
        Me.GroupBox3.Name = "GroupBox3"
        Me.GroupBox3.Size = New System.Drawing.Size(578, 49)
        Me.GroupBox3.TabIndex = 6
        Me.GroupBox3.TabStop = False
        '
        'btnRaceDays
        '
        Me.btnRaceDays.Location = New System.Drawing.Point(476, 23)
        Me.btnRaceDays.Name = "btnRaceDays"
        Me.btnRaceDays.Size = New System.Drawing.Size(90, 23)
        Me.btnRaceDays.TabIndex = 20
        Me.btnRaceDays.Text = "RaceDays"
        Me.btnRaceDays.UseVisualStyleBackColor = True
        '
        'DbConnectionForm
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(8.0!, 16.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.CancelButton = Me.buttonClose
        Me.ClientSize = New System.Drawing.Size(578, 412)
        Me.Controls.Add(Me.GroupBox3)
        Me.Controls.Add(Me.GroupBox2)
        Me.Controls.Add(Me.GroupBox1)
        Me.Margin = New System.Windows.Forms.Padding(4)
        Me.Name = "DbConnectionForm"
        Me.Text = "Database Connection"
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.GroupBox2.ResumeLayout(False)
        Me.GroupBox3.ResumeLayout(False)
        Me.GroupBox3.PerformLayout()
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents GroupBox1 As System.Windows.Forms.GroupBox
    Friend WithEvents GroupBox2 As System.Windows.Forms.GroupBox
    Friend WithEvents txtHeader As System.Windows.Forms.TextBox
    Friend WithEvents cboConnection As System.Windows.Forms.ComboBox
    Friend WithEvents GroupBox3 As System.Windows.Forms.GroupBox
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents btnConnect As System.Windows.Forms.Button
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents txtCondition As System.Windows.Forms.TextBox
    Friend WithEvents txtPID As System.Windows.Forms.TextBox
    Friend WithEvents txtInfo As System.Windows.Forms.TextBox
    Friend WithEvents Label6 As System.Windows.Forms.Label
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents Label7 As System.Windows.Forms.Label
    Friend WithEvents txtVersionBySql As System.Windows.Forms.TextBox
    Friend WithEvents btnDisconnect As System.Windows.Forms.Button
    Friend WithEvents Label8 As System.Windows.Forms.Label
    Friend WithEvents txtVersionByProp As System.Windows.Forms.TextBox
    Friend WithEvents btnBrowse As System.Windows.Forms.Button
    Friend WithEvents btnTest As System.Windows.Forms.Button
    Friend WithEvents buttonClose As System.Windows.Forms.Button
    Friend WithEvents buttonStats As System.Windows.Forms.Button
    Friend WithEvents buttonBetSim As System.Windows.Forms.Button
    Friend WithEvents btnRaceDays As System.Windows.Forms.Button
End Class
