Public MustInherit Class BaseOverviewGrid
  Inherits BaseGrid
  Implements IOverviewComponent

  Public Sub New()
    MyBase.New()
  End Sub

  Public MustOverride Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object) Implements IOverviewComponent.NodeChangeHandler

End Class
