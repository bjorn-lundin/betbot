Public Interface IBaseForm
    Inherits IBaseComponent

    Property FormTitle As String

    Sub StartForm()
    Sub StartForm(ByVal dbConnection As DbInterface.DbConnection)
    Sub EndForm()

End Interface
