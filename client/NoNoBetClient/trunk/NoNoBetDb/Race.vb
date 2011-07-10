Imports DbInterface.DbConnection
Public Class Race
    Private Const _TableName As String = "race"
    Private Const _RacesSelect As String = "SELECT date,track FROM " & _TableName
    Private Const _RacesDistinctSelect As String = "SELECT DISTINCT date,track FROM " & _TableName
    Private Const _TrackRacesSelect As String = "SELECT id,date,track FROM " & _TableName
    Private Const _OrderByDateTrackClause As String = " ORDER BY date,track"
    Private Const _OrderByDateTrackIdClause As String = " ORDER BY date,track,id"
    Private Const _OrderByIdClause As String = " ORDER BY id"
    Private Const _WhereNullClause As String = " WHERE null = null"

    ''' <summary>
    ''' Build: SELECT DISTINCT date,track FROM race ORDER BY date,track
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildRacesSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _RacesDistinctSelect

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    ''' <summary>
    ''' Build: SELECT DISTINCT id,date,track FROM race WHERE track = "trackName" ORDER BY date,id
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildTrackRacesSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrackRacesSelect

        If addOrderBy Then
            s += _OrderByDateTrackIdClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrackRacesSelectSql(ByVal raceDate As Date, ByVal trackName As String, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrackRacesSelect + " WHERE track = " + SqlBuildValueString(trackName) + _
                                              " AND date = " + DateToSqlString(raceDate, DateFormatMode.DateOnly)

        If addOrderBy Then
            s += _OrderByIdClause
        End If

        Return s
    End Function

    ''' <summary>
    ''' Build: SELECT DISTINCT date,track FROM race WHERE date >= "startDate" ORDER BY date,track
    ''' </summary>
    ''' <param name="startDate">Start date</param>
    ''' <param name="addOrderBy">Add ORDER BY clause?</param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildRacesSelectSql(ByVal startDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _RacesDistinctSelect & " WHERE date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrackRacesSelectSql(ByVal trackName As String, ByVal startDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrackRacesSelect + " WHERE track = " + SqlBuildValueString(trackName) + _
                                              " AND date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly)
        If addOrderBy Then
            s += _OrderByDateTrackIdClause
        End If

        Return s
    End Function

    ''' <summary>
    ''' Build: SELECT DISTINCT date,track FROM race WHERE date >= "startDate" AND date &lt;= "endDate" ORDER BY date,track
    ''' </summary>
    ''' <param name="startDate">Start date</param>
    ''' <param name="endDate">End date</param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildRacesSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _RacesSelect + " WHERE date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly) + _
                                         " AND date <= " + DateToSqlString(endDate, DateFormatMode.DateOnly)
        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrackRacesSelectSql(ByVal trackName As String, ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrackRacesSelect + " WHERE track = " + SqlBuildValueString(trackName) + _
                                              " AND date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly) + _
                                              " AND date <= " + DateToSqlString(endDate, DateFormatMode.DateOnly)
        If addOrderBy Then
            s += _OrderByDateTrackIdClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrackRacesSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrackRacesSelect + " WHERE date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly) + _
                                              " AND date <= " + DateToSqlString(endDate, DateFormatMode.DateOnly)
        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    ''' <summary>
    ''' Build: SELECT date,track FROM race WHERE null=null
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildNullRacesSelectSql() As String
        Return _RacesSelect + _WhereNullClause
    End Function

    ''' <summary>
    ''' Build: SELECT id,date,track FROM race WHERE null=null
    ''' </summary>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function BuildNullTrackRacesSelectSql() As String
        Return _TrackRacesSelect + _WhereNullClause
    End Function

End Class
