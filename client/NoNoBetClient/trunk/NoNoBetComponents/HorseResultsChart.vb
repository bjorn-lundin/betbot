Imports BaseComponents
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetDb
Imports System.Windows.Forms.DataVisualization.Charting
Imports System.Drawing
Imports Npgsql

Public Class HorseResultsChart
  Inherits BaseForm
  Friend WithEvents horseChart As System.Windows.Forms.DataVisualization.Charting.Chart

  Private Sub InitializeComponent()
    Dim ChartArea1 As System.Windows.Forms.DataVisualization.Charting.ChartArea = New System.Windows.Forms.DataVisualization.Charting.ChartArea()
    Dim Legend1 As System.Windows.Forms.DataVisualization.Charting.Legend = New System.Windows.Forms.DataVisualization.Charting.Legend()
    Dim Series1 As System.Windows.Forms.DataVisualization.Charting.Series = New System.Windows.Forms.DataVisualization.Charting.Series()
    Me.Panel1 = New System.Windows.Forms.Panel()
    Me.horseChart = New System.Windows.Forms.DataVisualization.Charting.Chart()
    CType(Me.horseChart, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'Panel1
    '
    Me.Panel1.Dock = System.Windows.Forms.DockStyle.Top
    Me.Panel1.Location = New System.Drawing.Point(0, 0)
    Me.Panel1.Name = "Panel1"
    Me.Panel1.Size = New System.Drawing.Size(284, 35)
    Me.Panel1.TabIndex = 0
    '
    'horseChart
    '
    ChartArea1.Name = "ChartArea1"
    Me.horseChart.ChartAreas.Add(ChartArea1)
    Me.horseChart.Dock = System.Windows.Forms.DockStyle.Fill
    Legend1.Name = "Legend1"
    Me.horseChart.Legends.Add(Legend1)
    Me.horseChart.Location = New System.Drawing.Point(0, 35)
    Me.horseChart.Name = "horseChart"
    Series1.ChartArea = "ChartArea1"
    Series1.Legend = "Legend1"
    Series1.Name = "Series1"
    Me.horseChart.Series.Add(Series1)
    Me.horseChart.Size = New System.Drawing.Size(284, 226)
    Me.horseChart.TabIndex = 1
    Me.horseChart.Text = "Chart1"
    '
    'HorseResultsChart
    '
    Me.ClientSize = New System.Drawing.Size(284, 261)
    Me.Controls.Add(Me.horseChart)
    Me.Controls.Add(Me.Panel1)
    Me.Name = "HorseResultsChart"
    CType(Me.horseChart, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub
  Friend WithEvents Panel1 As System.Windows.Forms.Panel

  Private _HorseId As Integer
  Private _ExpectedSeries As Series
  Private _ResultSeries As Series

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Shadows Sub StartForm(asDialog As Boolean, horseId As Integer, resourceMan As NoNoBetResources.ApplicationResourceManager)
    _HorseId = horseId
    MyBase.StartForm(asDialog, resourceMan)
  End Sub

  Private Function GetFinalPos(raceId As Integer, startNmbr As Integer) As Integer
    Dim finalPosObj As Object
    Dim sql As String

    sql = "SELECT tote_place FROM vpraceresult WHERE race_Id = " & raceId &
          " AND start_nr = " & startNmbr

    finalPosObj = MyBase.ResourceManager.DbConnection.ExecuteSqlScalar(sql)


    Return ConvertToInteger(finalPosObj)
  End Function

  Private Sub FillChart()
    Dim sql1 As String
    Dim sql2 As String
    Dim dbReader1 As Npgsql.NpgsqlDataReader
    Dim dbReader2 As Npgsql.NpgsqlDataReader


    sql1 = "SELECT race_id,start_nr FROM race_horse_startnumber WHERE horse_id = " & _HorseId

    dbReader1 = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql1)

    While dbReader1.Read
      Dim rank As Integer = 0
      Dim raceDate As Date
      Dim raceId As Integer = ConvertToInteger(dbReader1.Item("race_id"))
      Dim startNo As Integer = ConvertToInteger(dbReader1.Item("start_nr"))

      sql2 = "SELECT * FROM racestartpositions WHERE id = " & raceId & " ORDER BY win_odds"
      dbReader2 = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql2)

      While dbReader2.Read
        rank += 1
        Dim horseId As Integer = ConvertToInteger(dbReader2.Item("horse_id"))

        If (horseId = _HorseId) Then
          raceDate = CType(dbReader2.Item("raceday_date"), Date)
          _ExpectedSeries.Points.Add(New DataPoint(raceDate.ToOADate, rank))
          '_ExpectedSeries.Points.Add(New DataPoint(rank, raceDate.ToOADate))
          Exit While
        End If
      End While

      dbReader2.Close()
      dbReader2 = Nothing

      _ResultSeries.Points.Add(New DataPoint(raceDate.ToOADate, GetFinalPos(raceId, startNo)))
      '_ResultSeries.Points.Add(New DataPoint(GetFinalPos(raceId, startNo), raceDate.ToOADate))
    End While
  End Sub

  Private Sub InitChart()
    'Create Series
    horseChart.Series.Clear()

    _ExpectedSeries = horseChart.Series.Add("Förväntad placering")
    _ResultSeries = horseChart.Series.Add("Slutplacering")

    'Line chart type
    '_ExpectedSeries.ChartType = SeriesChartType.Line
    '_ResultSeries.ChartType = SeriesChartType.Line
    _ExpectedSeries.ChartType = SeriesChartType.Column
    _ResultSeries.ChartType = SeriesChartType.Column


    'Line color
    _ExpectedSeries.Color = Color.Green
    _ResultSeries.Color = Color.Red

    'Expected value types for the X-Axis, Date
    _ExpectedSeries.XValueType = ChartValueType.Date
    _ResultSeries.XValueType = ChartValueType.Date
    'Expected value types for the Y-Axis, Date
    '_ExpectedSeries.YValueType = ChartValueType.Date
    '_ResultSeries.YValueType = ChartValueType.Date


    'horseChart.ChartAreas(0).AxisX
    _ExpectedSeries.BorderDashStyle = ChartDashStyle.Solid
    _ResultSeries.BorderDashStyle = ChartDashStyle.Solid
    _ExpectedSeries.BorderWidth = 3
    _ResultSeries.BorderWidth = 3

    'Point Marker attributes
    '_ExpectedSeries.MarkerStyle = MarkerStyle.Circle
    '_ResultSeries.MarkerStyle = MarkerStyle.Circle
    '_ExpectedSeries.MarkerColor = Color.Black
    '_ResultSeries.MarkerColor = Color.Black
    '_ExpectedSeries.MarkerSize = 10
    '_ResultSeries.MarkerSize = 10


    'Axis titles
    horseChart.ChartAreas(0).AxisY.Title = "Datum"
    horseChart.ChartAreas(0).AxisX.Title = "Placering"

  End Sub

  Private Sub HorseResultsChart_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    MyBase.FormTitle = "Resultat för " + Horse.GetHorseName(MyBase.ResourceManager, _HorseId)

    InitChart()
    FillChart()
  End Sub
End Class
