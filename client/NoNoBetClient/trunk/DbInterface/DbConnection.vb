Imports System
Imports System.ComponentModel
Imports Npgsql

Public Class DbConnection
  Implements IDisposable

  Private _DbConnectionString As DbConnectionString

  Private WithEvents _Connection As NpgsqlConnection

  Public Enum DateFormatMode
    DateOnly
    DateAndTime
    TimeOnly
  End Enum
  ''' <summary>
  ''' Convert specified DateTime object to a String (to be used in a SQL statement)
  ''' </summary>
  ''' <param name="dateObject">Date object</param>
  ''' <param name="dateFormat">Output format</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function DateToSqlString(ByVal dateObject As DateTime, ByVal dateFormat As DateFormatMode) As String
    Dim dateStr As String = Nothing
    Select Case dateFormat
      Case DateFormatMode.DateOnly
        dateStr = String.Format("{0:yyyy-MM-dd}", dateObject)
      Case DateFormatMode.DateAndTime
        dateStr = String.Format("{0:yyyy-MM-dd HH:mm:ss}", dateObject)
      Case DateFormatMode.TimeOnly
        dateStr = String.Format("{0:HH:mm:ss}", dateObject)
      Case Else
        dateStr = String.Format("{0:yyyy-MM-dd HH:mm:ss}", dateObject)
    End Select

    Return "'" + dateStr + "'"
  End Function

  Public Shared Function SqlBuildNameString(ByVal s As String) As String
    Return """" & s & """"
  End Function

  Public Shared Function SqlBuildValueString(ByVal s As String) As String
    Return "'" & s & "'"
  End Function

  Public Shared Function SqlBuildInsertIntoTableString(ByVal tableName As String) As String
    Return "INSERT INTO " & SqlBuildNameString(tableName) & " "
  End Function

  Public Shared Function SqlBuildSelectFromTableString(ByVal tableName As String, ByVal ParamArray columns() As String) As String
    Dim columnsStr As String = String.Empty

    If (columns Is Nothing) Then
      columnsStr = "*"
    Else
      Dim firstTime As Boolean = True
      For i As Integer = 0 To UBound(columns, 1)
        If (Not firstTime) Then
          columnsStr += ","
        End If
        columnsStr += columns(i)
        firstTime = False
      Next
    End If

    Return "SELECT " + columnsStr + " FROM " & SqlBuildNameString(tableName)
  End Function

  ''' <summary>
  ''' Build column names clause for specified column names
  ''' </summary>
  ''' <param name="columns">"ColName1","ColName2","ColName3"...</param>
  ''' <returns>"("ColName1","ColName2","ColName3"...)"</returns>
  ''' <remarks></remarks>
  Public Shared Function SqlBuildColumnNamesString(ByVal ParamArray columns() As String) As String
    Dim s As String = String.Empty

    For i As Integer = 0 To UBound(columns, 1)
      s += "," + SqlBuildNameString(columns(i))
    Next
    Return "(" + s + ")"
  End Function

  ''' <summary>
  ''' Build VALUES clause for specified value objects
  ''' </summary>
  ''' <param name="columnValues">ValueObj1,ValueObj2,ValueObj3...</param>
  ''' <returns>"VALUES IN (Value1,Value2,Value3...)"</returns>
  ''' <remarks></remarks>
  Public Shared Function SqlBuildColumnValuesString(ByVal ParamArray columnValues() As Object) As String
    Dim s As String = String.Empty

    For i As Integer = 0 To UBound(columnValues, 1)
      If (i > 0) Then
        s += ","
      End If

      If (columnValues(i).GetType Is GetType(String)) Then
        s += SqlBuildValueString(CType(columnValues(i), String))
      Else
        s += columnValues(i).ToString
      End If
    Next
    Return "VALUES (" + s + ")"
  End Function

  Public Class DbNotificationEventArgs
    Inherits System.EventArgs

    Private _Condition As String
    Private _Information As String
    Private _PID As Integer

    Public ReadOnly Property Condition() As String
      Get
        Return _Condition
      End Get
    End Property

    Public ReadOnly Property Information() As String
      Get
        Return _Information
      End Get
    End Property

    Public ReadOnly Property PID() As Integer
      Get
        Return _PID
      End Get
    End Property

    Public Sub New(ByVal condition As String, ByVal information As String, ByVal pid As Integer)
      MyBase.New()
      _Condition = condition
      _Information = information
      _PID = pid
    End Sub
  End Class

  Public Event Notification(ByVal sender As Object, ByVal e As DbNotificationEventArgs)
  Public Event StateChange(ByVal sender As Object, ByVal e As System.Data.StateChangeEventArgs)

  Public ReadOnly Property ConnectionString() As DbConnectionString
    Get
      Return _DbConnectionString
    End Get
  End Property

  Public ReadOnly Property PID() As Integer
    Get
      If (_Connection Is Nothing) Then
        Return (-1)
      Else
        If (_Connection.State <> ConnectionState.Broken) And (_Connection.State <> ConnectionState.Closed) Then
          Return _Connection.ProcessID
        Else
          Return (-1)
        End If
      End If
    End Get
  End Property

  Public ReadOnly Property State() As ConnectionState
    Get
      If (_Connection Is Nothing) Then
        Return ConnectionState.Closed
      Else
        Return _Connection.State
      End If

    End Get
  End Property

  Public ReadOnly Property VersionShort As String
    Get
      Return _Connection.PostgreSqlVersion.ToString
    End Get
  End Property

  Public ReadOnly Property VersionLong As String
    Get
      If (_Connection Is Nothing) Then
        Return String.Empty
      Else
        If (_Connection.State <> ConnectionState.Broken) And (_Connection.State <> ConnectionState.Closed) Then
          Return GetVersionLong()
        Else
          Return String.Empty
        End If
      End If
    End Get
  End Property

  Public Sub New(ByVal dbConStr As DbConnectionString)
    _DbConnectionString = dbConStr
    Try
      _Connection = New NpgsqlConnection(_DbConnectionString.BuildConnectionString)
    Catch ex As Exception
      MsgBox("Connection create error: " + ex.Message)
    End Try
  End Sub

  'Public Sub New(ByVal connectionString As String)
  '  _ConnectionString = connectionString
  '  Try
  '    _Connection = New NpgsqlConnection(_ConnectionString)
  '  Catch ex As Exception
  '    MsgBox("Connection create error: " + ex.Message)
  '  End Try
  'End Sub

  Private Function GetVersionLong() As String
    Dim verStr As String
    Dim dbCmd As NpgsqlCommand = Me.NewCommand("SELECT version()")
    Try
      verStr = dbCmd.ExecuteScalar().ToString()
    Catch ex As Exception
      MsgBox("Execute command error: " + ex.Message)
      verStr = String.Empty
    Finally
      dbCmd.Dispose()
      dbCmd = Nothing
    End Try

    Return verStr
  End Function


  Public Function Open() As Boolean
    If Not (_Connection Is Nothing) Then
      Try
        _Connection.Open()
      Catch ex As Exception
        MsgBox("Connection open error: " + ex.Message)
        _Connection = Nothing
        Return False
      End Try
    Else
      Return False
    End If
    Return True
  End Function

  Public Sub Close()
    If Not (_Connection Is Nothing) Then
      _Connection.Close()
    End If
  End Sub

  Public Function NewCommand(ByVal sql As String) As NpgsqlCommand
    Dim cmd As NpgsqlCommand = Nothing

    Try
      cmd = New NpgsqlCommand(sql, _Connection)
    Catch ex As Exception
      MsgBox("Sql command error, sql=" + sql + ", message=" + ex.Message)
    End Try
    Return cmd
  End Function

  Public Function ExecuteSqlCommand(ByVal sql As String) As NpgsqlDataReader
    Dim cmd As NpgsqlCommand = NewCommand(sql)
    Dim dr As NpgsqlDataReader = Nothing

    Try
      dr = cmd.ExecuteReader()
    Catch ex As Exception
      MsgBox("ExecuteSqlCommand error, sql=" + sql + ", message=" + ex.Message)
    End Try

    Return dr
  End Function

  Public Function ExecuteSql(ByVal sql As String) As DataTable
    Dim dataAdapter As NpgsqlDataAdapter = Nothing
    Dim dt As DataTable = New DataTable()

    Try
      dataAdapter = New NpgsqlDataAdapter(sql, Me._Connection)
    Catch ex As Exception
      MsgBox("ExecuteSql error, sql=" + sql + ", message=" + ex.Message)
      Return Nothing
    End Try

    Try
      dataAdapter.Fill(dt)
    Catch ex As Exception
      MsgBox("ExecuteSql error, sql=" + sql + ", message=" + ex.Message)
      Return Nothing
    End Try

    Return dt
  End Function

  Public Function ExecuteSqlScalar(ByVal sql As String) As Object
    Dim cmd As NpgsqlCommand = NewCommand(sql)
    Dim columnObj As Object = Nothing

    Try
      columnObj = cmd.ExecuteScalar()
    Catch ex As Exception
      MsgBox("ExecuteSqlScalar error, sql=" + sql + ", message=" + ex.Message)
    End Try

    Return columnObj
  End Function

  Public Sub Dispose() Implements System.IDisposable.Dispose
    If _Connection Is Nothing Then
      Return
    End If
    _Connection.Dispose()
    _Connection = Nothing
  End Sub

  Private Sub _Connection_Notification(ByVal sender As Object, ByVal e As Npgsql.NpgsqlNotificationEventArgs) Handles _Connection.Notification
    RaiseEvent Notification(Me, New DbNotificationEventArgs(e.Condition, e.AdditionalInformation, e.PID))
  End Sub

  Private Sub _Connection_StateChange(ByVal sender As Object, ByVal e As System.Data.StateChangeEventArgs) Handles _Connection.StateChange
    RaiseEvent StateChange(sender, e)
  End Sub
End Class
