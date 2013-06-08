Imports BaseComponents
Imports System.Windows.Forms.DataVisualization.Charting
Imports System.Drawing
Imports NoNoBetResources

Public Class ChartTest
  Inherits BaseForm
  Friend WithEvents Chart1 As System.Windows.Forms.DataVisualization.Charting.Chart

  Private Sub InitializeComponent()
    Dim ChartArea1 As System.Windows.Forms.DataVisualization.Charting.ChartArea = New System.Windows.Forms.DataVisualization.Charting.ChartArea()
    Dim Legend1 As System.Windows.Forms.DataVisualization.Charting.Legend = New System.Windows.Forms.DataVisualization.Charting.Legend()
    Dim Series1 As System.Windows.Forms.DataVisualization.Charting.Series = New System.Windows.Forms.DataVisualization.Charting.Series()
    Me.Chart1 = New System.Windows.Forms.DataVisualization.Charting.Chart()
    CType(Me.Chart1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'Chart1
    '
    ChartArea1.Name = "ChartArea1"
    Me.Chart1.ChartAreas.Add(ChartArea1)
    Me.Chart1.Dock = System.Windows.Forms.DockStyle.Fill
    Legend1.Name = "Legend1"
    Me.Chart1.Legends.Add(Legend1)
    Me.Chart1.Location = New System.Drawing.Point(0, 0)
    Me.Chart1.Name = "Chart1"
    Series1.ChartArea = "ChartArea1"
    Series1.Legend = "Legend1"
    Series1.Name = "Series1"
    Me.Chart1.Series.Add(Series1)
    Me.Chart1.Size = New System.Drawing.Size(284, 261)
    Me.Chart1.TabIndex = 0
    Me.Chart1.Text = "Horse Chart"
    '
    'ChartTest
    '
    Me.ClientSize = New System.Drawing.Size(284, 261)
    Me.Controls.Add(Me.Chart1)
    Me.Name = "ChartTest"
    CType(Me.Chart1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Shadows Sub StartForm(resourceManager As ApplicationResourceManager)
    MyBase.StartForm(True, resourceManager)
  End Sub

  Private Sub ChartTest_Load(sender As Object, e As System.EventArgs) Handles Me.Load

    Me.FormTitle = "Horse Chart"
    Dim currDate As Date = New Date(2013, 2, 1)

    Dim s1 As Series
    Dim s2 As Series
    Dim p As DataPoint

    Chart1.Series.Clear()

    s1 = Chart1.Series.Add("Start")
    s2 = Chart1.Series.Add("Result")
    s1.XValueType = ChartValueType.Date
    s2.XValueType = ChartValueType.Date

    s1.ChartType = SeriesChartType.Line
    s2.ChartType = SeriesChartType.Line
    s1.BorderDashStyle = ChartDashStyle.Solid
    s2.BorderDashStyle = ChartDashStyle.Solid
    s1.BorderWidth = 3
    s2.BorderWidth = 3

    s1.MarkerStyle = MarkerStyle.Circle
    s2.MarkerStyle = MarkerStyle.Circle
    s1.MarkerColor = Color.Black
    s2.MarkerColor = Color.Black
    s1.MarkerSize = 10
    s2.MarkerSize = 10

    s1.Color = Color.Green
    s2.Color = Color.Red

    p = New DataPoint(currDate.ToOADate, 1)
    s1.Points.Add(p)
    p = New DataPoint(currDate.ToOADate, 2)
    s2.Points.Add(p)

    currDate = currDate.AddDays(7)

    p = New DataPoint(currDate.ToOADate, 2)
    s1.Points.Add(p)
    p = New DataPoint(currDate.ToOADate, 5)
    s2.Points.Add(p)

    currDate = currDate.AddDays(7)

    p = New DataPoint(currDate.ToOADate, 4)
    s1.Points.Add(p)
    p = New DataPoint(currDate.ToOADate, 1)
    s2.Points.Add(p)

    currDate = currDate.AddDays(7)

    p = New DataPoint(currDate.ToOADate, 1)
    s1.Points.Add(p)
    p = New DataPoint(currDate.ToOADate, 1)
    s2.Points.Add(p)

  End Sub
End Class
