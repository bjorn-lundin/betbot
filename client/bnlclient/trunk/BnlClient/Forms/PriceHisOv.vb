Imports NoNoBetBaseComponents

Public Class PriceHisOv
  Inherits BaseOverviewGrid

  Public Overrides Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object)
    MyBase.ExecuteSql(MyBase.ResourceManager, "SELECT * FROM amarkets WHERE null = null")

  End Sub

End Class
