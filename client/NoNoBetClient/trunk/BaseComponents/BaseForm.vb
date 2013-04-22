Imports System.Windows.Forms

Public Class BaseForm
    Inherits Form
    Implements IBaseForm


    Private _DbConnection As DbInterface.DbConnection

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

    Public Property DbConnection As DbInterface.DbConnection Implements IBaseComponent.DbConnection
        Get
            Return _DbConnection
        End Get
        Set(ByVal value As DbInterface.DbConnection)
            _DbConnection = value
        End Set
    End Property

    ''' <summary>
    ''' Start the BaseForm
    ''' </summary>
    ''' <remarks>Default StartPosition is CenterScreen</remarks>
    Public Sub StartForm() Implements IBaseForm.StartForm
        Me.StartPosition = FormStartPosition.CenterScreen
        'Me.ShowDialog()
        Me.Show()
    End Sub

    ''' <summary>
    ''' Start the BaseForm
    ''' </summary>
    ''' <param name="dbCon">Database connection object</param>
    ''' <remarks>Default StartPosition is CenterScreen</remarks>
    Public Overridable Sub StartForm(ByVal dbCon As DbInterface.DbConnection) Implements IBaseForm.StartForm
        _DbConnection = dbCon
        StartForm()
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
