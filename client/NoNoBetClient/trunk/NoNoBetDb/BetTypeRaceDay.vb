
Public Class BetTypeRaceDay

    Private _BetType As BetType
    Private _RaceDay As Date
    Private _Track As String

    Public ReadOnly Property BetType As BetType
        Get
            Return _BetType
        End Get
    End Property

    Public ReadOnly Property Track As String
        Get
            Return _Track
        End Get
    End Property

    Public ReadOnly Property RaceDay As Date
        Get
            Return _RaceDay
        End Get
    End Property

    Public Sub New(ByVal betType As BetType, ByVal raceDay As Date, ByVal track As String)
        _BetType = betType
        _RaceDay = raceDay
        _Track = track
    End Sub

    Public Overrides Function ToString() As String
        Return _RaceDay.ToShortDateString + " " + _Track + " " + _BetType.ToString
    End Function
End Class
