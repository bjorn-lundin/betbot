Imports System.Windows.Forms

Public Class BaseDialog
    Inherits Form
    Implements IBaseDialog

    Private _DbConnection As DbInterface.DbConnection

    Public Event OkButtonPressed(ByVal sender As Object, ByVal e As System.EventArgs)
    Public Event CancelButtonPressed(ByVal sender As Object, ByVal e As System.EventArgs)

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Public Property DbConnection As DbInterface.DbConnection Implements IBaseComponent.DbConnection
        Get
            Return _DbConnection
        End Get
        Set(ByVal value As DbInterface.DbConnection)
            _DbConnection = value
        End Set
    End Property

    Public Property Title As String Implements IBaseDialog.Title
        Get
            Return Me.Text
        End Get
        Set(ByVal value As String)
            Me.Text = value
        End Set
    End Property

    Private Sub InitializeComponent()
        Me.PanelButtons = New System.Windows.Forms.Panel()
        Me.OkButton = New System.Windows.Forms.Button()
        Me.ButtonCancel = New System.Windows.Forms.Button()
        Me.PanelButtons.SuspendLayout()
        Me.SuspendLayout()
        '
        'PanelButtons
        '
        Me.PanelButtons.Controls.Add(Me.ButtonCancel)
        Me.PanelButtons.Controls.Add(Me.OkButton)
        Me.PanelButtons.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.PanelButtons.Location = New System.Drawing.Point(0, 185)
        Me.PanelButtons.Name = "PanelButtons"
        Me.PanelButtons.Size = New System.Drawing.Size(282, 70)
        Me.PanelButtons.TabIndex = 0
        '
        'OkButton
        '
        Me.OkButton.Location = New System.Drawing.Point(195, 35)
        Me.OkButton.Name = "OkButton"
        Me.OkButton.Size = New System.Drawing.Size(75, 23)
        Me.OkButton.TabIndex = 0
        Me.OkButton.Text = "Ok"
        Me.OkButton.UseVisualStyleBackColor = True
        '
        'ButtonCancel
        '
        Me.ButtonCancel.Location = New System.Drawing.Point(95, 35)
        Me.ButtonCancel.Name = "ButtonCancel"
        Me.ButtonCancel.Size = New System.Drawing.Size(75, 23)
        Me.ButtonCancel.TabIndex = 1
        Me.ButtonCancel.Text = "Cancel"
        Me.ButtonCancel.UseVisualStyleBackColor = True
        '
        'BaseDialog
        '
        Me.ClientSize = New System.Drawing.Size(282, 255)
        Me.Controls.Add(Me.PanelButtons)
        Me.Name = "BaseDialog"
        Me.PanelButtons.ResumeLayout(False)
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents PanelButtons As System.Windows.Forms.Panel
    Friend WithEvents ButtonCancel As System.Windows.Forms.Button
    Friend WithEvents OkButton As System.Windows.Forms.Button

    Private Sub ButtonCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ButtonCancel.Click
        RaiseEvent CancelButtonPressed(sender, e)
    End Sub

    Private Sub OkButton_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OkButton.Click
        RaiseEvent OkButtonPressed(sender, e)
    End Sub
End Class
