Imports NoNoBetResources
Imports NoNoBetBaseComponents

Public Class BaseOverviewChart
  Inherits BaseChart
  Implements IBaseComponent
  Implements IOverviewComponent

  Private _ResourceManager As ApplicationResourceManager

  Public Property ResourceManager As NoNoBetResources.ApplicationResourceManager Implements IBaseComponent.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As NoNoBetResources.ApplicationResourceManager)
      _ResourceManager = value
    End Set
  End Property

  Public Overridable Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object) Implements IOverviewComponent.NodeChangeHandler

  End Sub
End Class
