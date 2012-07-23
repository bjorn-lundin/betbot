Imports System
Imports System.Data
Imports Microsoft.Win32

Public Class DbConnectionString

    Private _Server As String = "localhost"
    Private _Port As String = "5432"
    Private _UserId As String = ""
    Private _Password As String = ""
    Private _Database As String = ""
    Private _PreloadReader As Boolean = True

    Private Const _RegistrySubKeyName As String = "Software\NoNoBet\NoNoBetClient\DbAccess"
    Private Const _ServerParamName As String = "Server"
    Private Const _PortParamName As String = "Port"
    Private Const _UserIdParamName As String = "User Id"
    Private Const _PasswordParamName As String = "Password"
    Private Const _DatabaseParamName As String = "Database"
    Private Const _PreloadReaderParamName As String = "Preload Reader"

    ''' <summary>
    ''' Value of "Server" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property Server() As String
        Get
            Return _Server
        End Get
        Set(value As String)
            _Server = value
        End Set
    End Property

    ''' <summary>
    ''' Value of "Port" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property Port() As String
        Get
            Return _Port
        End Get
        Set(value As String)
            _Port = value
        End Set
    End Property

    ''' <summary>
    ''' Value of "User Id" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property UserId() As String
        Get
            Return _UserId
        End Get
        Set(value As String)
            _UserId = value
        End Set
    End Property

    ''' <summary>
    ''' Value of "Password" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property Password() As String
        Get
            Return _Password
        End Get
        Set(value As String)
            _Password = value
        End Set
    End Property

    ''' <summary>
    ''' Value of "Database" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property Database() As String
        Get
            Return _Database
        End Get
        Set(value As String)
            _Database = value
        End Set
    End Property

    ''' <summary>
    ''' Value of "Preload Reader" parameter in connection string
    ''' </summary>
    ''' <value></value>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Property PreloadReader() As Boolean
        Get
            Return _PreloadReader
        End Get
        Set(value As Boolean)
            _PreloadReader = value
        End Set
    End Property

    ''' <summary>
    ''' Create a new DbConnectionString object
    ''' </summary>
    ''' <remarks>
    ''' Intial values are loaded from Registry (if any)
    ''' </remarks>
    Public Sub New()
        LoadFromRegistry()
    End Sub

    Private Sub LoadFromRegistry()
        Dim myRegistry As RegistryKey = Registry.CurrentUser
        Dim regSubKey As RegistryKey = myRegistry.OpenSubKey(_RegistrySubKeyName, True)

        If (regSubKey Is Nothing) Then
            'Nothing in Registry. Keep default values
            Return
        End If

        If (regSubKey.GetValue(_ServerParamName) IsNot Nothing) Then
            _Server = Convert.ToString(regSubKey.GetValue(_ServerParamName))
        End If

        If (regSubKey.GetValue(_PortParamName) Is Nothing) Then
            _Port = Convert.ToString(regSubKey.GetValue(_PortParamName))
        End If

        If (regSubKey.GetValue(_UserIdParamName) Is Nothing) Then
            _UserId = Convert.ToString(regSubKey.GetValue(_UserIdParamName))
        End If

        If (regSubKey.GetValue(_PasswordParamName) Is Nothing) Then
            _Password = Convert.ToString(regSubKey.GetValue(_PasswordParamName))
        End If

        If (regSubKey.GetValue(_DatabaseParamName) Is Nothing) Then
            _Database = Convert.ToString(regSubKey.GetValue(_DatabaseParamName))
        End If

        If (regSubKey.GetValue(_PreloadReaderParamName) Is Nothing) Then
            _PreloadReader = Convert.ToBoolean(regSubKey.GetValue(_PreloadReaderParamName))
        End If

    End Sub

    ''' <summary>
    ''' Save current parameter values (in Registry)
    ''' </summary>
    ''' <remarks></remarks>
    Public Sub Save()
        Dim myRegistry As RegistryKey = Registry.CurrentUser
        Dim regSubKey As RegistryKey = myRegistry.OpenSubKey(_RegistrySubKeyName, True)

        If (regSubKey Is Nothing) Then
            'Registry key does not exist. Create it!
            regSubKey = myRegistry.CreateSubKey(_RegistrySubKeyName)
        End If

        regSubKey.SetValue(_ServerParamName, _Server)
        regSubKey.SetValue(_PortParamName, _Port)
        regSubKey.SetValue(_UserIdParamName, _UserId)
        regSubKey.SetValue(_PasswordParamName, _Password)
        regSubKey.SetValue(_DatabaseParamName, _Database)
        regSubKey.SetValue(_PreloadReaderParamName, _PreloadReader)
    End Sub

    '"Server=localhost;Port=5432;User Id=test-db;Password=test-db;Database=test-db;Preload Reader=True;"

    ''' <summary>
    ''' Build a database connection string
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Function BuildConnectionString() As String
        Return _ServerParamName + "=" + _Server + ";" + _PortParamName + "=" + _Port + ";" + _UserIdParamName + "=" + _UserId + ";" + _
               _PasswordParamName + "=" + _Password + ";" + _DatabaseParamName + "=" + _Database + ";" + _PreloadReaderParamName + "=" + _PreloadReader.ToString + ";"
    End Function

End Class
