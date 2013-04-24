Public Interface IBaseForm
  Inherits IBaseComponent

  Property FormTitle As String

  Sub StartForm(asDialog As Boolean)
  Sub StartForm(asDialog As Boolean, ByVal dbConnection As DbInterface.DbConnection)
  Sub EndForm()

End Interface
