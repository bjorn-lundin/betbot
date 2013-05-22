Public Interface IBaseForm
  Inherits IBaseComponent

  Property FormTitle As String

  Sub StartForm(asDialog As Boolean)
  Sub StartForm(asDialog As Boolean, ByVal resourceMan As ApplicationResourceManager)
  Sub EndForm()

End Interface
