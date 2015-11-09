Imports NoNoBetResources
Imports NoNoBetBaseComponents

Public Class BaseOverviewGrid
  Inherits BaseGrid
  Implements IBaseComponent
  Implements IOverviewComponent

  Private _ResourceManager As ApplicationResourceManager

  Public Property ResourceManager As ApplicationResourceManager Implements IBaseComponent.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property

  Public Overridable Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object) Implements IOverviewComponent.NodeChangeHandler

  End Sub

End Class
