Imports System.Windows.Forms
Imports DbInterface
Imports BaseComponents

Public Class CountryCodes

  Private _ContryCodes As Collection

  Public Sub New()
    _ContryCodes = New Collection
  End Sub

  Public Function Count() As Integer
    Return _ContryCodes.Count
  End Function

  Public Function Item(index As Integer) As CountryCode
    If (index >= 0 And index < _ContryCodes.Count) Then
      Return CType(_ContryCodes.Item(index), CountryCode)
    Else
      Return Nothing
    End If
  End Function

  Public Sub Add(cCode As CountryCode)
    If (Not _ContryCodes.Contains(cCode.Code)) Then
      _ContryCodes.Add(cCode, cCode.Code)
    End If
  End Sub

  Public Sub LoadFromDb(resourceMan As ApplicationResourceManager)
    Dim sql As String = "SELECT DISTINCT country_code,country_english_text,country_domestic_text FROM raceday"
    Dim dr As Npgsql.NpgsqlDataReader = resourceMan.DbConnection.ExecuteSqlCommand(sql)

    While dr.Read
      Dim cCode As CountryCode = New CountryCode(dr.Item("country_code"), dr.Item("country_domestic_text"), dr.Item("country_english_text"))

      Me.Add(cCode)

    End While

    dr.Close()

  End Sub

  Public Sub FillCombo(cbo As ComboBox)
    Dim cCodeSwe As CountryCode = Nothing
    cbo.Items.Clear()

    For Each cCode As CountryCode In _ContryCodes
      cbo.Items.Add(cCode)

      If (cCode.Code = "SE") Then
        cCodeSwe = cCode
      End If
    Next

    cbo.SelectedItem = cCodeSwe
  End Sub
End Class
