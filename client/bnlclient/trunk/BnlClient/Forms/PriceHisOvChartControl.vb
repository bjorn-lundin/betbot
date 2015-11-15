Imports NoNoBetBaseComponents
Imports NoNoBetResources

Public Class PriceHisOvChartControl
  Inherits Form
  Implements IBaseComponent
  Implements IOverviewComponent
  Friend WithEvents PriceHisOvChartCtrl As BnlClient.PriceHisOvChart
  Friend WithEvents lblYmin As System.Windows.Forms.Label
  Public WithEvents txtYmin As System.Windows.Forms.TextBox
  Friend WithEvents lblYmax As System.Windows.Forms.Label
  Public WithEvents txtYmax As System.Windows.Forms.TextBox
  Friend WithEvents pnlChartCtrlBottom As System.Windows.Forms.Panel

  Private _ResourceManager As NoNoBetResources.ApplicationResourceManager = Nothing
  Private _IsLoaded As Boolean = False
  Private _IsUpdatingText As Boolean = False

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Property ResourceManager As NoNoBetResources.ApplicationResourceManager Implements NoNoBetBaseComponents.IBaseComponent.ResourceManager
    Get
      Return _ResourceManager
    End Get
    Set(value As NoNoBetResources.ApplicationResourceManager)
      _ResourceManager = value
      PriceHisOvChartCtrl.ResourceManager = value
    End Set
  End Property

  Public Sub NodeChangeHandler(nodeLevel As Integer, keyObject As Object) Implements NoNoBetBaseComponents.IOverviewComponent.NodeChangeHandler
    PriceHisOvChartCtrl.NodeChangeHandler(nodeLevel, keyObject)
  End Sub

  Private Sub InitializeComponent()
    Dim ChartArea1 As System.Windows.Forms.DataVisualization.Charting.ChartArea = New System.Windows.Forms.DataVisualization.Charting.ChartArea()
    Dim Legend1 As System.Windows.Forms.DataVisualization.Charting.Legend = New System.Windows.Forms.DataVisualization.Charting.Legend()
    Dim Series1 As System.Windows.Forms.DataVisualization.Charting.Series = New System.Windows.Forms.DataVisualization.Charting.Series()
    Me.pnlChartCtrlBottom = New System.Windows.Forms.Panel()
    Me.PriceHisOvChartCtrl = New BnlClient.PriceHisOvChart()
    Me.txtYmax = New System.Windows.Forms.TextBox()
    Me.lblYmax = New System.Windows.Forms.Label()
    Me.lblYmin = New System.Windows.Forms.Label()
    Me.txtYmin = New System.Windows.Forms.TextBox()
    Me.pnlChartCtrlBottom.SuspendLayout()
    CType(Me.PriceHisOvChartCtrl, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'pnlChartCtrlBottom
    '
    Me.pnlChartCtrlBottom.Controls.Add(Me.lblYmin)
    Me.pnlChartCtrlBottom.Controls.Add(Me.txtYmin)
    Me.pnlChartCtrlBottom.Controls.Add(Me.lblYmax)
    Me.pnlChartCtrlBottom.Controls.Add(Me.txtYmax)
    Me.pnlChartCtrlBottom.Dock = System.Windows.Forms.DockStyle.Bottom
    Me.pnlChartCtrlBottom.Location = New System.Drawing.Point(0, 284)
    Me.pnlChartCtrlBottom.Name = "pnlChartCtrlBottom"
    Me.pnlChartCtrlBottom.Size = New System.Drawing.Size(360, 49)
    Me.pnlChartCtrlBottom.TabIndex = 0
    '
    'PriceHisOvChartCtrl
    '
    ChartArea1.Name = "ChartArea1"
    Me.PriceHisOvChartCtrl.ChartAreas.Add(ChartArea1)
    Me.PriceHisOvChartCtrl.Dock = System.Windows.Forms.DockStyle.Fill
    Legend1.Name = "Legend1"
    Me.PriceHisOvChartCtrl.Legends.Add(Legend1)
    Me.PriceHisOvChartCtrl.Location = New System.Drawing.Point(0, 0)
    Me.PriceHisOvChartCtrl.Name = "PriceHisOvChartCtrl"
    Me.PriceHisOvChartCtrl.ResourceManager = Nothing
    Series1.ChartArea = "ChartArea1"
    Series1.Legend = "Legend1"
    Series1.Name = "Series1"
    Me.PriceHisOvChartCtrl.Series.Add(Series1)
    Me.PriceHisOvChartCtrl.Size = New System.Drawing.Size(360, 284)
    Me.PriceHisOvChartCtrl.TabIndex = 1
    Me.PriceHisOvChartCtrl.Text = "PriceHisOvChart1"
    '
    'txtYmax
    '
    Me.txtYmax.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.txtYmax.Location = New System.Drawing.Point(12, 26)
    Me.txtYmax.Name = "txtYmax"
    Me.txtYmax.Size = New System.Drawing.Size(69, 20)
    Me.txtYmax.TabIndex = 0
    '
    'lblYmax
    '
    Me.lblYmax.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.lblYmax.AutoSize = True
    Me.lblYmax.Location = New System.Drawing.Point(13, 7)
    Me.lblYmax.Name = "lblYmax"
    Me.lblYmax.Size = New System.Drawing.Size(36, 13)
    Me.lblYmax.TabIndex = 1
    Me.lblYmax.Text = "Y-max"
    '
    'lblYmin
    '
    Me.lblYmin.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.lblYmin.AutoSize = True
    Me.lblYmin.Location = New System.Drawing.Point(85, 7)
    Me.lblYmin.Name = "lblYmin"
    Me.lblYmin.Size = New System.Drawing.Size(33, 13)
    Me.lblYmin.TabIndex = 3
    Me.lblYmin.Text = "Y-min"
    '
    'txtYmin
    '
    Me.txtYmin.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.txtYmin.Location = New System.Drawing.Point(84, 26)
    Me.txtYmin.Name = "txtYmin"
    Me.txtYmin.Size = New System.Drawing.Size(69, 20)
    Me.txtYmin.TabIndex = 2
    '
    'PriceHisOvChartControl
    '
    Me.ClientSize = New System.Drawing.Size(360, 333)
    Me.ControlBox = False
    Me.Controls.Add(Me.PriceHisOvChartCtrl)
    Me.Controls.Add(Me.pnlChartCtrlBottom)
    Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None
    Me.Name = "PriceHisOvChartControl"
    Me.ShowIcon = False
    Me.ShowInTaskbar = False
    Me.pnlChartCtrlBottom.ResumeLayout(False)
    Me.pnlChartCtrlBottom.PerformLayout()
    CType(Me.PriceHisOvChartCtrl, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Private Sub PriceHisOvChartCtrl_ChartDrawn(sender As Object, e As System.EventArgs) Handles PriceHisOvChartCtrl.ChartDrawn
    _IsUpdatingText = True
    txtYmax.Text = PriceHisOvChartCtrl.MaxYaxis.ToString
    txtYmin.Text = PriceHisOvChartCtrl.MinYaxis.ToString
    _IsUpdatingText = False
  End Sub

  Private Sub txtYmax_TextChanged(sender As Object, e As System.EventArgs) Handles txtYmax.TextChanged
    If (_IsLoaded And (Not _IsUpdatingText)) Then
      PriceHisOvChartCtrl.MaxYaxis = ApplicationResourceManager.ConvertToDouble(txtYmax)
    End If
  End Sub

  Private Sub txtYmin_TextChanged(sender As Object, e As System.EventArgs) Handles txtYmin.TextChanged
    If (_IsLoaded And (Not _IsUpdatingText)) Then
      PriceHisOvChartCtrl.MinYaxis = ApplicationResourceManager.ConvertToDouble(txtYmin)
    End If
  End Sub

  Private Sub PriceHisOvChartControl_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    _IsLoaded = True
  End Sub
End Class
