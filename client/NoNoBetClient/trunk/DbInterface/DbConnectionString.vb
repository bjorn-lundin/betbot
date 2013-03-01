Imports System
Imports System.Data
Imports Microsoft.Win32

Public Class DbConnectionString

    Private _Server As String = "localhost"
    Private _Port As String = "5432"
    Private _UserId As String = ""
    Private _Password As String = ""
    Private _Database As String = ""
    Private _SSL As Boolean = True
    Private _PreloadReader As Boolean = True

    Public Const RegistrySubKeyName As String = "Software\NoNoBet\NoNoBetClient\DbAccess"

    Private Const _ServerParamName As String = "Server"
    Private Const _PortParamName As String = "Port"
    Private Const _UserIdParamName As String = "User Id"
    Private Const _PasswordParamName As String = "Password"
    Private Const _DatabaseParamName As String = "Database"
    Private Const _SSLParamName As String = "SSL"
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
            If (value Is Nothing) Then
                _Server = String.Empty
            Else
                _Server = value
            End If
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
            If (value Is Nothing) Then
                _Port = String.Empty
            Else
                _Port = value
            End If
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
            If (value Is Nothing) Then
                _UserId = String.Empty
            Else
                _UserId = value
            End If
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
            If (value Is Nothing) Then
                _Password = String.Empty
            Else
                _Password = value
            End If
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
            If (value Is Nothing) Then
                _Database = String.Empty
            Else
                _Database = value
            End If
        End Set
    End Property

    Public Property SSL() As Boolean
        Get
            Return _SSL
        End Get
        Set(value As Boolean)
            _SSL = value
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

    Public ReadOnly Property Name() As String
        Get
            Return _Server + ":" + _Database
        End Get
    End Property


    ''' <summary>
    ''' Create a new DbConnectionString object
    ''' </summary>
    ''' <remarks>
    ''' Intial values are loaded from Registry (if any)
    ''' </remarks>
    Public Sub New()
        ' LoadFromRegistry()
    End Sub

  Public Shared Function GetRegistryKeyObject() As RegistryKey
    Dim regSubKey As RegistryKey = Nothing
    Try
      regSubKey = Registry.CurrentUser.OpenSubKey(RegistrySubKeyName, True)
      Return regSubKey
    Catch ex As Exception
      Return Nothing
    End Try
  End Function

    Public Shared Sub ClearRegistry()
        Dim regSubKey As RegistryKey = GetRegistryKeyObject()

        For Each valName As String In regSubKey.GetValueNames
            regSubKey.DeleteValue(valName)
        Next

        For Each conName As String In regSubKey.GetSubKeyNames
            regSubKey.DeleteSubKeyTree(conName)
        Next
    End Sub


    Public Sub LoadFromRegistry(connectionName As String)
        Dim regSubKey As RegistryKey = GetRegistryKeyObject()

        If (regSubKey Is Nothing) Then
            'Nothing in Registry. Keep default values
            Return
        End If

        Dim connectionKey As RegistryKey = regSubKey.OpenSubKey(connectionName, True)

        If (connectionKey Is Nothing) Then
            'Sub key not found. Keep default values
            Return
        End If

        If (connectionKey.GetValue(_ServerParamName) IsNot Nothing) Then
            _Server = Convert.ToString(connectionKey.GetValue(_ServerParamName))
        End If

        If (connectionKey.GetValue(_PortParamName) IsNot Nothing) Then
            _Port = Convert.ToString(connectionKey.GetValue(_PortParamName))
        End If

        If (connectionKey.GetValue(_UserIdParamName) IsNot Nothing) Then
            _UserId = Convert.ToString(connectionKey.GetValue(_UserIdParamName))
        End If

        If (connectionKey.GetValue(_PasswordParamName) IsNot Nothing) Then
            _Password = Convert.ToString(connectionKey.GetValue(_PasswordParamName))
        End If

        If (connectionKey.GetValue(_DatabaseParamName) IsNot Nothing) Then
            _Database = Convert.ToString(connectionKey.GetValue(_DatabaseParamName))
        End If

        If (connectionKey.GetValue(_SSLParamName) IsNot Nothing) Then
            _SSL = Convert.ToBoolean(connectionKey.GetValue(_SSLParamName))
        End If

        If (connectionKey.GetValue(_PreloadReaderParamName) IsNot Nothing) Then
            _PreloadReader = Convert.ToBoolean(connectionKey.GetValue(_PreloadReaderParamName))
        End If
    End Sub

    ''' <summary>
    ''' Save current parameter values (in Registry)
    ''' </summary>
    ''' <remarks></remarks>
    Public Sub Save()
        Dim myRegistry As RegistryKey = Registry.CurrentUser
        Dim regSubKey As RegistryKey = myRegistry.OpenSubKey(RegistrySubKeyName, True)
        Dim connectionKey As RegistryKey = Nothing

        If (regSubKey Is Nothing) Then
            'Registry key does not exist. Create it!
            regSubKey = myRegistry.CreateSubKey(RegistrySubKeyName)
        End If

        connectionKey = regSubKey.CreateSubKey(Me.Name())
        connectionKey.SetValue(_ServerParamName, _Server)
        connectionKey.SetValue(_PortParamName, _Port)
        connectionKey.SetValue(_UserIdParamName, _UserId)
        connectionKey.SetValue(_PasswordParamName, _Password)
        connectionKey.SetValue(_DatabaseParamName, _Database)
        connectionKey.SetValue(_SSLParamName, _SSL)
        connectionKey.SetValue(_PreloadReaderParamName, _PreloadReader)
    End Sub

    Public Overrides Function ToString() As String
        Return Me.Name()
    End Function

    '"Server=localhost;Port=5432;User Id=test-db;Password=test-db;Database=test-db;Preload Reader=True;"

    ''' <summary>
    ''' Build a database connection string
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Function BuildConnectionString() As String
        Return _ServerParamName + "=" + _Server + ";" + _PortParamName + "=" + _Port + ";" + _UserIdParamName + "=" + _UserId + ";" + _
               _PasswordParamName + "=" + _Password + ";" + _DatabaseParamName + "=" + _Database + ";" + _SSLParamName + "=" + _SSL.ToString + ";" + _PreloadReaderParamName + "=" + _PreloadReader.ToString + ";"
    End Function

End Class
