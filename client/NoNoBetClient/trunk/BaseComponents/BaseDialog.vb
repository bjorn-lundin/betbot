Imports System.Windows.Forms
Imports NoNoBetResources

Public Class BaseDialog
  Inherits Form
  Implements IBaseDialog


  Private _ResourceManager As ApplicationResourceManager

  Public Event OkButtonPressed(ByVal sender As Object, ByVal e As System.EventArgs)
  Public Event CancelButtonPressed(ByVal sender As Object, ByVal e As System.EventArgs)

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  'Public Property DbConnection As DbInterface.DbConnection Implements IBaseComponent.DbConnection
  '    Get
  '        Return _DbConnection
  '    End Get
  '    Set(ByVal value As DbInterface.DbConnection)
  '        _DbConnection = value
  '    End Set
  'End Property

  Public Property ResourceManager As ApplicationResourceManager Implements IBaseComponent.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property

  Public Property DialogTitle As String Implements IBaseDialog.DialogTitle
    Get
      Return Me.Text
    End Get
    Set(ByVal value As String)
      Me.Text = value
    End Set
  End Property

  Public Property PageTitle As String Implements IBaseDialog.PageTitle
    Get
      Return Me.TabPage.Text
    End Get
    Set(ByVal value As String)
      Me.TabPage.Text = value
    End Set
  End Property

  Private Sub InitializeComponent()
    Me.PanelButtons = New System.Windows.Forms.Panel()
    Me.ButtonCancel = New System.Windows.Forms.Button()
    Me.OkButton = New System.Windows.Forms.Button()
    Me.TabControl = New System.Windows.Forms.TabControl()
    Me.TabPage = New System.Windows.Forms.TabPage()
    Me.PanelButtons.SuspendLayout()
    Me.TabControl.SuspendLayout()
    Me.SuspendLayout()
    '
    'PanelButtons
    '
    Me.PanelButtons.Controls.Add(Me.ButtonCancel)
    Me.PanelButtons.Controls.Add(Me.OkButton)
    Me.PanelButtons.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.PanelButtons.Location = New System.Drawing.Point(0, 210)
    Me.PanelButtons.Name = "PanelButtons"
    Me.PanelButtons.Size = New System.Drawing.Size(282, 45)
    Me.PanelButtons.TabIndex = 0
    '
    'ButtonCancel
    '
    Me.ButtonCancel.Location = New System.Drawing.Point(95, 13)
    Me.ButtonCancel.Name = "ButtonCancel"
    Me.ButtonCancel.Size = New System.Drawing.Size(75, 23)
    Me.ButtonCancel.TabIndex = 1
    Me.ButtonCancel.Text = "Cancel"
    Me.ButtonCancel.UseVisualStyleBackColor = True
    '
    'OkButton
    '
    Me.OkButton.Location = New System.Drawing.Point(195, 13)
    Me.OkButton.Name = "OkButton"
    Me.OkButton.Size = New System.Drawing.Size(75, 23)
    Me.OkButton.TabIndex = 0
    Me.OkButton.Text = "Ok"
    Me.OkButton.UseVisualStyleBackColor = True
    '
    'TabControl
    '
    Me.TabControl.Controls.Add(Me.TabPage)
    Me.TabControl.Dock = System.Windows.Forms.DockStyle.Fill
    Me.TabControl.Location = New System.Drawing.Point(0, 0)
    Me.TabControl.Name = "TabControl"
    Me.TabControl.SelectedIndex = 0
    Me.TabControl.Size = New System.Drawing.Size(282, 210)
    Me.TabControl.TabIndex = 1
    '
    'TabPage
    '
    Me.TabPage.Location = New System.Drawing.Point(4, 25)
    Me.TabPage.Name = "TabPage"
    Me.TabPage.Padding = New System.Windows.Forms.Padding(3)
    Me.TabPage.Size = New System.Drawing.Size(274, 181)
    Me.TabPage.TabIndex = 0
    Me.TabPage.UseVisualStyleBackColor = True
    '
    'BaseDialog
    '
    Me.ClientSize = New System.Drawing.Size(282, 255)
    Me.Controls.Add(Me.TabControl)
    Me.Controls.Add(Me.PanelButtons)
    Me.Name = "BaseDialog"
    Me.PanelButtons.ResumeLayout(False)
    Me.TabControl.ResumeLayout(False)
    Me.ResumeLayout(False)

  End Sub
  Friend WithEvents PanelButtons As System.Windows.Forms.Panel
  Friend WithEvents ButtonCancel As System.Windows.Forms.Button
  Friend WithEvents TabControl As System.Windows.Forms.TabControl
  Friend WithEvents TabPage As System.Windows.Forms.TabPage
  Friend WithEvents OkButton As System.Windows.Forms.Button

  Private Sub ButtonCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ButtonCancel.Click
    RaiseEvent CancelButtonPressed(sender, e)
  End Sub

  Private Sub OkButton_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OkButton.Click
    RaiseEvent OkButtonPressed(sender, e)
  End Sub

End Class
