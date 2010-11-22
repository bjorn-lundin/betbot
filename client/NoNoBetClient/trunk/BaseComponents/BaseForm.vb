Imports System.Windows.Forms

Public Class BaseForm
    Inherits Form

    Private _DbConnection As DbInterface.DbConnection

    Public Sub New()
        MyBase.New()
    End Sub

    Public ReadOnly Property DbConnection As DbInterface.DbConnection
        Get
            Return _DbConnection
        End Get
    End Property

    ''' <summary>
    ''' Start the BaseForm
    ''' </summary>
    ''' <remarks>Default StartPosition is CenterScreen</remarks>
    Public Sub StartForm()
        Me.StartPosition = FormStartPosition.CenterScreen
        'Me.ShowDialog()
        Me.Show()
    End Sub

    ''' <summary>
    ''' Start the BaseForm
    ''' </summary>
    ''' <param name="dbCon">Database connection object</param>
    ''' <remarks>Default StartPosition is CenterScreen</remarks>
    Public Sub StartForm(ByVal dbCon As DbInterface.DbConnection)
        _DbConnection = dbCon
        StartForm()
    End Sub

    ''' <summary>
    ''' End (close) the BaseForm
    ''' </summary>
    ''' <remarks></remarks>
    Public Sub EndForm()
        MyBase.Close()
    End Sub

    Private Sub BaseForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub
End Class
