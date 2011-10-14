Public Interface IBaseGridForm

    Sub StartForm(ByVal dbConnection As DbInterface.DbConnection, ByVal gridSql As String)
    Sub StartForm(ByVal dbConnection As DbInterface.DbConnection, ByVal gridSql As String, ByVal gridId As String)

End Interface
