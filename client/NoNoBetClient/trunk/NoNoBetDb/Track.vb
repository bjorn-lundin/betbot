Imports NoNoBetDbInterface
Imports NoNoBetResources

Public Class Track

  Public Sub New()

  End Sub

  Public Shared Function GetTrackNameForRaceDay(resourceManager As ApplicationResourceManager, raceDayId As Integer) As String
    Dim trackNameObj As Object
    Dim sql As String = "SELECT track.domestic_text FROM raceday " +
                        "JOIN track ON track.id = raceday.track_id " +
                        "WHERE raceday.id = " & raceDayId
    trackNameObj = resourceManager.DbConnection.ExecuteSqlScalar(sql)

    If trackNameObj IsNot Nothing Then
      Return trackNameObj.ToString
    Else
      Return String.Empty
    End If
  End Function
End Class
