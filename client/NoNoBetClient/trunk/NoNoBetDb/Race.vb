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
    Private Const _v75_types As String = "'v75-1','v75-2','v75-3','v75-4','v75-5','v75-6','v75-7'"
    Private Const _v65_types As String = "'v65-1','v65-2','v65-3','v65-4','v65-5','v65-6'"
    Private Const _v64_types As String = "'v64-1','v64-2','v64-3','v64-4','v64-5','v64-6'"
    Private Const _v3_types As String = "'v3-1','v3-2','v3-3'"
    Private Const _v4_types As String = "'v4-1','v4-2','v4-3','v4-4'"
    Private Const _v5_types As String = "'v5-1','v5-2','v5-3','v5-4','v5-5'"
    Private Const _dd_types As String = "'dd-1','dd-2'"
    Private Const _ld_types As String = "'ld-1','ld-2'"

    Private Const _BetTypeRaceDaySelectSql As String = "SELECT DISTINCT date,track FROM view_racebettype "
    Private Const _AnyBetTypeRaceDaySelectSql As String = "SELECT DISTINCT date,track,bettype FROM view_racebettype "

    Private Const _V75RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v75')"
    Private Const _V65RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v65')"
    Private Const _V64RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v64')"
    Private Const _V5RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v5')"
    Private Const _V4RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v4')"
    Private Const _V3RaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'v3')"
    Private Const _LDRaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'ld')"
    Private Const _DDRaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                    "WHERE (bettype = 'dd')"
    Private Const _TvillingRaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                         "WHERE (bettype = 'tvilling')"
    Private Const _TrioRaceDaysSelectSql As String = _BetTypeRaceDaySelectSql + _
                                                         "WHERE (bettype = 'trio')"
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

    'Private Shared Function BuildWhereDateClause(ByVal startDate As Date, ByVal endDate As Date) As String
    '    Return " AND (date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly) + ")" + _
    '           " AND (date <= " + DateToSqlString(endDate, DateFormatMode.DateOnly) + ")"

    'End Function

    Private Shared Function BuildWhereDateClause(ByVal addWhere As Boolean, ByVal startDate As Date, ByVal endDate As Date) As String
        Dim sql As String

        If addWhere Then
            sql = " WHERE"
        Else
            sql = " AND"
        End If

        Return sql + " (date >= " + DateToSqlString(startDate, DateFormatMode.DateOnly) + ")" + _
               "   AND (date <= " + DateToSqlString(endDate, DateFormatMode.DateOnly) + ")"

    End Function

    Public Shared Function BuildV75RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V75RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        's = "SELECT DISTINCT date,track FROM view_racebettype WHERE bettype = 'v75' ORDER BY date,track"
        's = _V75RaceDaysSelectSql + BuildWhereDateClause(startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV75RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V75RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV65RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V65RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV65RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V65RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV64RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V64RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV64RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V64RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV5RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V5RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV5RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V5RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV4RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V4RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV4RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V4RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV3RacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _V3RaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildV3RacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _V3RaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildDDRacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _DDRaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildDDRacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _DDRaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildLDRacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _LDRaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildLDRacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _LDRaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTvillingRacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TvillingRaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTvillingRacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _TvillingRaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrioRacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrioRaceDaysSelectSql + BuildWhereDateClause(False, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildTrioRacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _TrioRaceDaysSelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause
        End If

        Return s
    End Function

    Public Shared Function BuildAnyRacedaysSelectSql(ByVal startDate As Date, ByVal endDate As Date, ByVal addOrderBy As Boolean) As String
        Dim s As String = _AnyBetTypeRaceDaySelectSql + BuildWhereDateClause(True, startDate, endDate)

        If addOrderBy Then
            s += _OrderByDateTrackClause + ",bettype"
        End If

        Return s
    End Function

    Public Shared Function BuildAnyRacedaysSelectSql(ByVal addOrderBy As Boolean) As String
        Dim s As String = _AnyBetTypeRaceDaySelectSql

        If addOrderBy Then
            s += _OrderByDateTrackClause + ",bettype"
        End If

        Return s
    End Function

End Class
