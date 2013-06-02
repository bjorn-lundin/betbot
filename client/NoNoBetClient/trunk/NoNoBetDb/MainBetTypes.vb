Imports System.Windows.Forms
Imports DbInterface
Imports BaseComponents
Imports NoNoBetResources

Public Class MainBetTypes
  Inherits CodeObjects

  Public Sub New()
    MyBase.New()
  End Sub

  Public Shadows Function Item(index As Integer) As MainBetType
    Return CType(MyBase.Item(index), MainBetType)
  End Function

  Public Shadows Sub Add(cCode As MainBetType)
    MyBase.Add(CType(cCode, CodeObject))
  End Sub

  Public Sub LoadFromDb(resourceMan As ApplicationResourceManager)
    Dim sql As String = "SELECT DISTINCT name_code FROM bettype"
    Dim dr As Npgsql.NpgsqlDataReader = resourceMan.DbConnection.ExecuteSqlCommand(sql)

    While dr.Read
      Dim betType As MainBetType = New MainBetType(dr.Item("name_code"), "")

      Me.Add(betType)
    End While

    dr.Close()
  End Sub


  Public Sub FillCombo(cbo As ComboBox)
    Dim betType As MainBetType = Nothing

    cbo.Items.Clear()

    For index As Integer = 1 To MyBase.Count
      betType = Me.Item(index)
      cbo.Items.Add(betType)
    Next

    cbo.SelectedIndex = 0
  End Sub

End Class
