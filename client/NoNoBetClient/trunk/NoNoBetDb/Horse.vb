Imports DbInterface
Imports NoNoBetResources

Public Class Horse

  Public Sub New()

  End Sub

  Public Shared Function GetHorseName(resourceManager As ApplicationResourceManager, horseId As Integer) As String
    Dim horseNameObj As Object
    Dim sql As String = "SELECT name FROM horse WHERE id = " & horseId

    horseNameObj = resourceManager.DbConnection.ExecuteSqlScalar(sql)

    If (horseNameObj IsNot Nothing) Then
      Return horseNameObj.ToString
    Else
      Return String.Empty
    End If
  End Function

End Class
