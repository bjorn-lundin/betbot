Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports Npgsql


Public Class PriceHistory
  Inherits BaseNavigatorForm

  Public Sub New(rManager As ApplicationResourceManager)
    MyBase.New()
    MyBase.ResourceManager = rManager
  End Sub

  Private Sub FillNavigator()
    Dim dbReader As Npgsql.NpgsqlDataReader
    Dim sql As String = "SELECT distinct startts FROM amarkets"

    MyBase.Navigator.Nodes.Clear()

    dbReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    While dbReader.Read
      Dim d As DateTime = ConvertToDate(dbReader.Item("startts"))

      MyBase.Navigator.Nodes.Add(d.ToString("yyyy-MM-dd HH:mm"))

    End While
  End Sub

  Private Sub PriceHistory_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    FillNavigator()
  End Sub
End Class
