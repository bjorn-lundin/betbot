Imports System.Windows.Forms
Imports NoNoBetResources

Public Class BaseForm
  Inherits Form
  Implements IBaseForm

  Private _ResourceManager As ApplicationResourceManager

  Public Sub New()
    MyBase.New()
  End Sub

  Public Property FormTitle As String Implements IBaseForm.FormTitle
    Get
      Return Me.Text
    End Get
    Set(ByVal value As String)
      Me.Text = value
    End Set
  End Property

  Public Overridable Property ResourceManager As ApplicationResourceManager Implements IBaseComponent.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property

  ''' <summary>
  ''' Start the BaseForm
  ''' </summary>
  ''' <remarks>Default StartPosition is CenterScreen</remarks>
  Public Sub StartForm(asDialog As Boolean) Implements IBaseForm.StartForm
    Me.StartPosition = FormStartPosition.CenterScreen
    If (asDialog) Then
      Me.ShowDialog()
    Else
      Me.Show()
    End If
  End Sub

  ''' <summary>
  ''' Start the BaseForm
  ''' </summary>
  ''' <param name="resourceMan">Application Resource Manager object</param>
  ''' <remarks>Default StartPosition is CenterScreen</remarks>
  Public Overridable Sub StartForm(asDialog As Boolean, ByVal resourceMan As ApplicationResourceManager) Implements IBaseForm.StartForm
    _ResourceManager = resourceMan
    StartForm(asDialog)
  End Sub

  ''' <summary>
  ''' End (close) the BaseForm
  ''' </summary>
  ''' <remarks></remarks>
  Public Overloads Sub EndForm() Implements IBaseForm.EndForm
    MyBase.Close()
  End Sub

  Private Sub BaseForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

  End Sub

End Class
