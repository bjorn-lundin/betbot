Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface

Public Class PriceHisOv
  Inherits BaseOverviewGrid

  Public Sub New()
    MyBase.New()
  End Sub

  Private Const PriceHistorySelectClause As String = "SELECT selectionid,pricets,backprice FROM apriceshistory "
  Private Const PriceHistoryGroupByClause As String = " GROUP BY selectionid,pricets,backprice "
  Private Const PriceHistoryOrderByClause As String = " ORDER BY selectionid,pricets,backprice "

  Public Shared Function BuildLevel2Sql(marketId As String, selectionId As Integer) As String
    Dim sql As String = PriceHistorySelectClause
    sql += " WHERE marketid = " + DbConnection.SqlBuildValueString(marketId) +
           " AND selectionid = " + selectionId.ToString +
           PriceHistoryGroupByClause +
           PriceHistoryOrderByClause
    Return sql
  End Function

  Public Shared Function BuildLevel1Sql(marketId As String) As String
    Dim sql As String = PriceHistorySelectClause
    sql += " WHERE marketid = " + DbConnection.SqlBuildValueString(marketId) +
           PriceHistoryGroupByClause +
           PriceHistoryOrderByClause
    Return sql
  End Function

  Public Overrides Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object)
    Dim sql As String

    If (TypeOf keyObject Is NavKeyLevel2) Then
      Dim key As NavKeyLevel2 = CType(keyObject, NavKeyLevel2)
      sql = BuildLevel2Sql(key.MarketId, key.SelectionId)
    ElseIf (TypeOf keyObject Is NavKeyLevel1) Then
      Dim key As NavKeyLevel1 = CType(keyObject, NavKeyLevel1)
      sql = BuildLevel1Sql(key.MarketId)
    ElseIf (TypeOf keyObject Is NavKeyLevel0) Then
      sql = PriceHistorySelectClause + " WHERE null = null "
    Else
      sql = PriceHistorySelectClause + " WHERE null = null "
    End If

    MyBase.ExecuteSql(MyBase.ResourceManager, sql)
  End Sub

End Class
