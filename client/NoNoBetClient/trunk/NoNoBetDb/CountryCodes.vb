Imports System.Windows.Forms
Imports NoNoBetDbInterface
Imports NoNoBetBaseComponents
Imports NoNoBetResources

Public Class CountryCodes
  Inherits CodeObjects

  Public Sub New()
    MyBase.New()
  End Sub

  Public Shadows Function Item(index As Integer) As CountryCode
    Return CType(MyBase.Item(index), CountryCode)
  End Function

  Public Shadows Sub Add(cCode As CountryCode)
    MyBase.Add(CType(cCode, CodeObject))
  End Sub

  Public Sub LoadFromDb(resourceMan As ApplicationResourceManager)
    Dim sql As String = "SELECT DISTINCT country_code FROM raceday"
    Dim dr As Npgsql.NpgsqlDataReader = resourceMan.DbConnection.ExecuteSqlCommand(sql)

    While dr.Read
      Dim cCode As CountryCode = New CountryCode(dr.Item("country_code"), "")

      Me.Add(cCode)
    End While

    dr.Close()
  End Sub


  Public Sub FillCombo(cbo As ComboBox)
    Dim cCode As CountryCode = Nothing
    Dim cCodeSwe As CountryCode = Nothing

    cbo.Items.Clear()

    For index As Integer = 1 To MyBase.Count
      cCode = Me.Item(index)
      cbo.Items.Add(cCode)

      If (cCode.Code = "SE") Then
        cCodeSwe = cCode
      End If
    Next

    cbo.SelectedItem = cCodeSwe
  End Sub
End Class
