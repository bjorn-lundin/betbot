Public Interface IBaseForm
    Inherits IBaseComponent

    Sub StartForm()
    Sub StartForm(ByVal dbConnection As DbInterface.DbConnection)
    Sub EndForm()

End Interface
