Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports Npgsql
Imports BnlClient


Public Class PriceHistory
  Inherits BaseNavigatorForm

  Friend WithEvents chkPlace As System.Windows.Forms.CheckBox
  Friend WithEvents chkWin As System.Windows.Forms.CheckBox
  Public WithEvents PriceHisOv1 As BnlClient.PriceHisOv
  Friend WithEvents tabPageOverview2 As System.Windows.Forms.TabPage
  Friend WithEvents PriceHisOvChartCtrl As BnlClient.PriceHisOvChart

  Private _IsLoaded As Boolean = False

  Private Sub InitializeComponent()
    Dim ChartArea1 As System.Windows.Forms.DataVisualization.Charting.ChartArea = New System.Windows.Forms.DataVisualization.Charting.ChartArea()
    Dim Legend1 As System.Windows.Forms.DataVisualization.Charting.Legend = New System.Windows.Forms.DataVisualization.Charting.Legend()
    Dim Series1 As System.Windows.Forms.DataVisualization.Charting.Series = New System.Windows.Forms.DataVisualization.Charting.Series()
    Me.chkWin = New System.Windows.Forms.CheckBox()
    Me.chkPlace = New System.Windows.Forms.CheckBox()
    Me.PriceHisOv1 = New BnlClient.PriceHisOv()
    Me.tabPageOverview2 = New System.Windows.Forms.TabPage()
    Me.PriceHisOvChartCtrl = New BnlClient.PriceHisOvChart()
    CType(Me.containerMain, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerMain.Panel1.SuspendLayout()
    Me.containerMain.Panel2.SuspendLayout()
    Me.containerMain.SuspendLayout()
    Me.tabControlDetail.SuspendLayout()
    Me.tabPageOverview1.SuspendLayout()
    Me.tabControlOverview.SuspendLayout()
    CType(Me.containerTabs, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerTabs.Panel1.SuspendLayout()
    Me.containerTabs.Panel2.SuspendLayout()
    Me.containerTabs.SuspendLayout()
    CType(Me.containerNavigator, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerNavigator.Panel1.SuspendLayout()
    Me.containerNavigator.Panel2.SuspendLayout()
    Me.containerNavigator.SuspendLayout()
    CType(Me.PriceHisOv1, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.tabPageOverview2.SuspendLayout()
    CType(Me.PriceHisOvChartCtrl, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'tabPageDetail1
    '
    Me.tabPageDetail1.Size = New System.Drawing.Size(688, 15)
    '
    'containerMain
    '
    Me.containerMain.Size = New System.Drawing.Size(1041, 668)
    Me.containerMain.SplitterDistance = 337
    '
    'tabControlDetail
    '
    Me.tabControlDetail.Size = New System.Drawing.Size(696, 41)
    '
    'tabPageOverview1
    '
    Me.tabPageOverview1.Controls.Add(Me.PriceHisOv1)
    Me.tabPageOverview1.Size = New System.Drawing.Size(688, 593)
    '
    'tabControlOverview
    '
    Me.tabControlOverview.Controls.Add(Me.tabPageOverview2)
    Me.tabControlOverview.Size = New System.Drawing.Size(696, 619)
    Me.tabControlOverview.Controls.SetChildIndex(Me.tabPageOverview2, 0)
    Me.tabControlOverview.Controls.SetChildIndex(Me.tabPageOverview1, 0)
    '
    'containerTabs
    '
    Me.containerTabs.Size = New System.Drawing.Size(696, 668)
    Me.containerTabs.SplitterDistance = 619
    '
    'Navigator
    '
    Me.Navigator.LineColor = System.Drawing.Color.Black
    Me.Navigator.Size = New System.Drawing.Size(337, 616)
    '
    'containerNavigator
    '
    '
    'containerNavigator.Panel2
    '
    Me.containerNavigator.Panel2.Controls.Add(Me.chkPlace)
    Me.containerNavigator.Panel2.Controls.Add(Me.chkWin)
    Me.containerNavigator.Size = New System.Drawing.Size(337, 668)
    Me.containerNavigator.SplitterDistance = 616
    Me.containerNavigator.SplitterWidth = 8
    '
    'chkWin
    '
    Me.chkWin.AutoSize = True
    Me.chkWin.Location = New System.Drawing.Point(12, 14)
    Me.chkWin.Name = "chkWin"
    Me.chkWin.Size = New System.Drawing.Size(45, 17)
    Me.chkWin.TabIndex = 0
    Me.chkWin.Text = "Win"
    Me.chkWin.UseVisualStyleBackColor = True
    '
    'chkPlace
    '
    Me.chkPlace.AutoSize = True
    Me.chkPlace.Location = New System.Drawing.Point(12, 37)
    Me.chkPlace.Name = "chkPlace"
    Me.chkPlace.Size = New System.Drawing.Size(53, 17)
    Me.chkPlace.TabIndex = 1
    Me.chkPlace.Text = "Place"
    Me.chkPlace.UseVisualStyleBackColor = True
    '
    'PriceHisOv1
    '
    Me.PriceHisOv1.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.PriceHisOv1.Dock = System.Windows.Forms.DockStyle.Fill
    Me.PriceHisOv1.Id = Nothing
    Me.PriceHisOv1.Location = New System.Drawing.Point(3, 3)
    Me.PriceHisOv1.Name = "PriceHisOv1"
    Me.PriceHisOv1.ResourceManager = Nothing
    Me.PriceHisOv1.Size = New System.Drawing.Size(682, 587)
    Me.PriceHisOv1.TabIndex = 0
    '
    'tabPageOverview2
    '
    Me.tabPageOverview2.Controls.Add(Me.PriceHisOvChartCtrl)
    Me.tabPageOverview2.Location = New System.Drawing.Point(4, 22)
    Me.tabPageOverview2.Name = "tabPageOverview2"
    Me.tabPageOverview2.Size = New System.Drawing.Size(461, 227)
    Me.tabPageOverview2.TabIndex = 1
    Me.tabPageOverview2.Text = "tabPageOverview2"
    Me.tabPageOverview2.UseVisualStyleBackColor = True
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
    Me.PriceHisOvChartCtrl.Size = New System.Drawing.Size(461, 227)
    Me.PriceHisOvChartCtrl.TabIndex = 0
    Me.PriceHisOvChartCtrl.Text = "PriceHisOvChartCtrl"
    '
    'PriceHistory
    '
    Me.ClientSize = New System.Drawing.Size(1041, 668)
    Me.Name = "PriceHistory"
    Me.containerMain.Panel1.ResumeLayout(False)
    Me.containerMain.Panel2.ResumeLayout(False)
    CType(Me.containerMain, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerMain.ResumeLayout(False)
    Me.tabControlDetail.ResumeLayout(False)
    Me.tabPageOverview1.ResumeLayout(False)
    Me.tabControlOverview.ResumeLayout(False)
    Me.containerTabs.Panel1.ResumeLayout(False)
    Me.containerTabs.Panel2.ResumeLayout(False)
    CType(Me.containerTabs, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerTabs.ResumeLayout(False)
    Me.containerNavigator.Panel1.ResumeLayout(False)
    Me.containerNavigator.Panel2.ResumeLayout(False)
    Me.containerNavigator.Panel2.PerformLayout()
    CType(Me.containerNavigator, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerNavigator.ResumeLayout(False)
    CType(Me.PriceHisOv1, System.ComponentModel.ISupportInitialize).EndInit()
    Me.tabPageOverview2.ResumeLayout(False)
    CType(Me.PriceHisOvChartCtrl, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Overrides Property ResourceManager As NoNoBetResources.ApplicationResourceManager
    Get
      Return MyBase.ResourceManager
    End Get
    Set(value As NoNoBetResources.ApplicationResourceManager)
      MyBase.ResourceManager = value
      PriceHisOv1.ResourceManager = value
      PriceHisOvChartCtrl.ResourceManager = value
    End Set
  End Property

  Private Function BuildLevel0Sql() As String
    Dim sql As String = "SELECT distinct startts FROM amarkets "

    If (chkWin.Checked And chkPlace.Checked) Then
      sql += "WHERE (markettype = 'WIN' OR markettype = 'PLACE')"
    ElseIf (chkWin.Checked) Then
      sql += "WHERE (markettype = 'WIN')"
    ElseIf (chkPlace.Checked) Then
      sql += "WHERE (markettype = 'PLACE')"
    End If

    sql += " ORDER BY startts"
    Return sql
  End Function

  Private Function BuildMarkettypeWhereClause() As String
    Dim whereClause As String = String.Empty

    If (chkWin.Checked And chkPlace.Checked) Then
      whereClause = "(markettype = 'WIN' OR markettype = 'PLACE')"
    ElseIf (chkWin.Checked) Then
      whereClause = "(markettype = 'WIN')"
    ElseIf (chkPlace.Checked) Then
      whereClause = "(markettype = 'PLACE')"
    End If

    Return whereClause
  End Function

  Private Function BuildLevel1Sql(d As DateTime) As String
    Dim sql As String = "SELECT marketid,marketname,markettype FROM amarkets "
    Dim whereClause As String = BuildMarkettypeWhereClause()

    If (String.IsNullOrEmpty(whereClause)) Then
      sql += "WHERE startts = " + DateToDbString(d)
    Else
      sql += "WHERE startts = " + DateToDbString(d) + " AND " + whereClause
    End If

    sql += " ORDER BY marketid"
    Return sql
  End Function

  Private Function BuildLevel2Sql(marketId As String) As String
    Dim sql As String = "SELECT marketid,selectionid,runnername,sortprio,status FROM arunners WHERE marketid = '" + marketId + "' ORDER BY sortprio"

    Return sql
  End Function

  Private Sub BuildLevel1Nodes(parentNode As TreeNode, d As DateTime)
    Dim parentKey As NavKeyLevel0 = CType(parentNode.Tag, NavKeyLevel0)
    Dim dbReader As Npgsql.NpgsqlDataReader
    Dim sql As String = BuildLevel1Sql(d)

    dbReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    While dbReader.Read
      Dim marketId As String = ConvertToString(dbReader.Item("marketid"))
      Dim marketName As String = ConvertToString(dbReader.Item("marketname"))
      Dim marketType As String = ConvertToString(dbReader.Item("markettype"))
      Dim n As TreeNode = New TreeNode(marketId + " - " + marketName + " - " + marketType)
      n.Tag = New NavKeyLevel1(1, d, parentKey.MarketTypePlaceOption, parentKey.MarketTypeWinOption, marketId, marketType)
      BuildDummyChildNode(n)
      parentNode.Nodes.Add(n)

      'BuildLevel2Nodes(n, marketId)
    End While

  End Sub

  Private Sub BuildLevel2Nodes(parentNode As TreeNode, marketId As String)
    Dim parentKey As NavKeyLevel1 = CType(parentNode.Tag, NavKeyLevel1)
    Dim dbReader As Npgsql.NpgsqlDataReader
    Dim sql As String = BuildLevel2Sql(marketId)

    dbReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    While dbReader.Read
      Dim selectionId As Integer = ConvertToInteger(dbReader.Item("selectionid"))
      Dim runnerName As String = ConvertToString(dbReader.Item("runnername"))
      Dim sortPrio As Integer = ConvertToInteger(dbReader.Item("sortprio"))
      Dim status As String = ConvertToString(dbReader.Item("status"))

      Dim n As TreeNode = New TreeNode(sortPrio.ToString + " - " + selectionId.ToString + " - " + runnerName + " - " + status)
      n.Tag = New NavKeyLevel2(2, parentKey.StartTime, parentKey.MarketTypePlaceOption, parentKey.MarketTypeWinOption, parentKey.MarketId, parentKey.MarketType, selectionId, runnerName)
      parentNode.Nodes.Add(n)
    End While
  End Sub

  Private Sub BuildDummyChildNode(node As TreeNode)
    node.Nodes.Add(New TreeNode("?"))
  End Sub

  Public Shared Function DateToDbString(d As DateTime) As String
    Return NoNoBetDbInterface.DbConnection.SqlBuildValueString(DateToDbFormat(d))
  End Function

  Public Shared Function DateToDbFormat(d As DateTime) As String
    Return d.ToString("yyyy-MM-dd HH:mm")
  End Function

  Private Sub FillNavigator()
    Dim dbReader As Npgsql.NpgsqlDataReader
    Dim sql As String = BuildLevel0Sql()

    MyBase.Navigator.Nodes.Clear()

    dbReader = MyBase.ResourceManager.DbConnection.ExecuteSqlCommand(sql)

    While dbReader.Read
      Dim d As DateTime = ConvertToDate(dbReader.Item("startts"))
      Dim n As TreeNode = New TreeNode(DateToDbFormat(d))
      n.Tag = New NavKeyLevel0(0, d, chkPlace.Checked, chkWin.Checked)
      BuildDummyChildNode(n)
      MyBase.Navigator.Nodes.Add(n)

      'BuildLevel1Nodes(n, d)

    End While
  End Sub


  Private Sub chkPlace_CheckedChanged(sender As Object, e As System.EventArgs) Handles chkPlace.CheckedChanged
    If _IsLoaded Then
      FillNavigator()
    End If
  End Sub

  Private Sub chkWin_CheckedChanged(sender As Object, e As System.EventArgs) Handles chkWin.CheckedChanged
    If _IsLoaded Then
      FillNavigator()
    End If
  End Sub

  Private Sub PriceHistory_NavigatorNodeExpand(sender As Object, e As NoNoBetBaseComponents.BaseTree.NodeChangeEventArgs) Handles Me.NavigatorNodeExpand
    If (Not _IsLoaded) Then
      Return
    End If

    Select Case e.NodeChangeObject.NodeLevel
      Case 0
        If (TypeOf e.NodeChangeObject.KeyObject Is NavKeyLevel0) Then
          Dim key As NavKeyLevel0 = CType(e.NodeChangeObject.KeyObject, NavKeyLevel0)
          e.Node.Nodes.Clear()
          BuildLevel1Nodes(e.Node, key.StartTime)
        End If
      Case 1
        If (TypeOf e.NodeChangeObject.KeyObject Is NavKeyLevel1) Then
          Dim key As NavKeyLevel1 = CType(e.NodeChangeObject.KeyObject, NavKeyLevel1)
          e.Node.Nodes.Clear()
          BuildLevel2Nodes(e.Node, key.MarketId)
        End If
      Case 2

    End Select
  End Sub

  Private Sub PriceHistory_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    If (Not Me.DesignMode) Then
      FillNavigator()
      _IsLoaded = True
    End If
  End Sub

End Class
