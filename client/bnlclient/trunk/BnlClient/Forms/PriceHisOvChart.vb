Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports NoNoBetResources.ApplicationResourceManager
Imports System.Windows.Forms.DataVisualization
Imports System.Windows.Forms.DataVisualization.Charting

Public Class PriceHisOvChart
  Inherits BaseOverviewChart

  Private _IsInitiated As Boolean = False

  Public Sub New()
    MyBase.new()
  End Sub


  Public Overrides Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object)
    Dim sql As String

    If (Not _IsInitiated) Then
      InitChart()
      _IsInitiated = True
    End If

    If (TypeOf keyObject Is NavKeyLevel2) Then
      Dim key As NavKeyLevel2 = CType(keyObject, NavKeyLevel2)
      sql = PriceHisOv.BuildLevel2Sql(key.MarketId, key.SelectionId)
      BuildLevel2Chart(sql, key.MarketId)
    ElseIf (TypeOf keyObject Is NavKeyLevel1) Then
      Dim key As NavKeyLevel1 = CType(keyObject, NavKeyLevel1)
      sql = PriceHisOv.BuildLevel1Sql(key.MarketId)
      BuildLevel1Chart(sql, key.MarketId)
    ElseIf (TypeOf keyObject Is NavKeyLevel0) Then

    Else

    End If
  End Sub

  Private Function GetStatusForSelectionId(marketId As String, selectionId As Integer) As String
    Dim sql As String = "SELECT status FROM arunners WHERE marketid = " + NoNoBetDbInterface.DbConnection.SqlBuildValueString(marketId) + " AND selectionid = " + selectionId.ToString
    Dim o As Object
    o = MyBase.ResourceManager.DbConnection.ExecuteSqlScalar(sql)

    If (o IsNot Nothing) Then
      Return o.ToString
    End If

    Return String.Empty
  End Function

  Private Sub BuildChart(sql As String, marketId As String)
    Dim dbReader As Npgsql.NpgsqlDataReader
    Dim currSeries As Charting.Series = Nothing
    Dim currSelectionId As Integer = -1

    dbReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    While dbReader.Read
      Dim selectionId As Integer = ConvertToInteger(dbReader.Item("selectionid"))
      Dim timeStamp As DateTime = ConvertToDate(dbReader.Item("pricets"))
      Dim backPrice As Decimal = ConvertToDecimal(dbReader.Item("backprice"))

      If (selectionId <> currSelectionId) Then
        currSeries = CreateNewSeries(selectionId.ToString, SelectionIdStatusToColor(GetStatusForSelectionId(marketId, selectionId)))
        currSelectionId = selectionId
      End If

      currSeries.Points.Add(New DataPoint(timeStamp.ToOADate, backPrice))
    End While

    dbReader.Close()
  End Sub

  Private Sub BuildLevel2Chart(sql As String, marketId As String)
    MyBase.Series.Clear()
    BuildChart(sql, marketId)
  End Sub

  Private Sub BuildLevel1Chart(sql As String, marketId As String)
    MyBase.Series.Clear()
    BuildChart(sql, marketId)
  End Sub

  Private Sub InitChart()
    MyBase.Series.Clear()
    MyBase.ChartAreas(0).AxisX.Title = "Time"
    MyBase.ChartAreas(0).AxisY.Title = "Odds"
    MyBase.ChartAreas(0).AxisY.Maximum = 100
    'MyBase.ChartAreas(0).AxisY.Interval = 0.5

  End Sub

  Private Function SelectionIdStatusToColor(status As String) As Color
    Select Case status
      Case "WINNER"
        Return Color.Green
      Case "LOSER"
        Return Color.Red
      Case Else
        Return Color.Yellow
    End Select
  End Function

  Private Function CreateNewSeries(name As String, lineColour As Color) As Charting.Series
    Dim s As Charting.Series = MyBase.Series.Add(name)
    s.Color = lineColour
    s.ChartType = Charting.SeriesChartType.Line
    s.XValueType = Charting.ChartValueType.Time
    Return (s)
  End Function

End Class
