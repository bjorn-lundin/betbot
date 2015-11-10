Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface

Public Class PriceHisOv
  Inherits BaseOverviewGrid

  Public Sub New()
    MyBase.New()
  End Sub

  Private Const PriceHistorySelectClause As String = "SELECT pricets,selectionid,backprice FROM apriceshistory "
  Private Const PriceHistoryGroupByClause As String = " GROUP BY pricets,selectionid,backprice "
  Private Const PriceHistoryOrderByClause As String = " ORDER BY pricets,selectionid,backprice "

  Public Overrides Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object)
    Dim sql As String = PriceHistorySelectClause

    If (TypeOf keyObject Is NavKeyLevel2) Then
      sql += " WHERE marketid = " + DbConnection.SqlBuildValueString(CType(keyObject, NavKeyLevel2).MarketId.ToString) +
             " AND selectionid = " + CType(keyObject, NavKeyLevel2).SelectionId.ToString
      sql += PriceHistoryGroupByClause + PriceHistoryOrderByClause
    ElseIf (TypeOf keyObject Is NavKeyLevel1) Then
      sql += " WHERE marketid = " + DbConnection.SqlBuildValueString(CType(keyObject, NavKeyLevel1).MarketId.ToString)
      sql += PriceHistoryGroupByClause + PriceHistoryOrderByClause
    ElseIf (TypeOf keyObject Is NavKeyLevel0) Then
      sql += " WHERE null = null "
    Else
      sql += " WHERE null = null "
    End If

    MyBase.ExecuteSql(MyBase.ResourceManager, sql)
  End Sub

End Class
