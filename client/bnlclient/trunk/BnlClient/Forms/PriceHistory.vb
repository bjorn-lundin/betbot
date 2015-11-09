Imports NoNoBetResources
Imports NoNoBetResources.ApplicationResourceManager
Imports NoNoBetBaseComponents
Imports NoNoBetDbInterface
Imports Npgsql


Public Class PriceHistory
  Inherits BaseNavigatorForm

  Friend WithEvents chkPlace As System.Windows.Forms.CheckBox
  Friend WithEvents chkWin As System.Windows.Forms.CheckBox
  Friend WithEvents ovPriceHis As BnlClient.PriceHisOv

  Private _IsLoaded As Boolean = False

  Private Sub InitializeComponent()
    Me.chkWin = New System.Windows.Forms.CheckBox()
    Me.chkPlace = New System.Windows.Forms.CheckBox()
    Me.ovPriceHis = New BnlClient.PriceHisOv()
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
    CType(Me.ovPriceHis, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'tabPageDetail1
    '
    Me.tabPageDetail1.Size = New System.Drawing.Size(373, 231)
    '
    'containerMain
    '
    Me.containerMain.Size = New System.Drawing.Size(704, 645)
    Me.containerMain.SplitterDistance = 315
    '
    'tabControlDetail
    '
    Me.tabControlDetail.Size = New System.Drawing.Size(381, 257)
    '
    'tabPageOverview1
    '
    Me.tabPageOverview1.Controls.Add(Me.ovPriceHis)
    Me.tabPageOverview1.Size = New System.Drawing.Size(373, 354)
    '
    'tabControlOverview
    '
    Me.tabControlOverview.Size = New System.Drawing.Size(381, 380)
    '
    'containerTabs
    '
    Me.containerTabs.Size = New System.Drawing.Size(381, 645)
    Me.containerTabs.SplitterDistance = 380
    '
    'Navigator
    '
    Me.Navigator.LineColor = System.Drawing.Color.Black
    Me.Navigator.Size = New System.Drawing.Size(315, 578)
    '
    'containerNavigator
    '
    Me.containerNavigator.FixedPanel = System.Windows.Forms.FixedPanel.Panel2
    Me.containerNavigator.IsSplitterFixed = True
    '
    'containerNavigator.Panel2
    '
    Me.containerNavigator.Panel2.Controls.Add(Me.chkPlace)
    Me.containerNavigator.Panel2.Controls.Add(Me.chkWin)
    Me.containerNavigator.Size = New System.Drawing.Size(315, 645)
    Me.containerNavigator.SplitterDistance = 578
    Me.containerNavigator.SplitterWidth = 8
    '
    'chkWin
    '
    Me.chkWin.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.chkWin.AutoSize = True
    Me.chkWin.Location = New System.Drawing.Point(13, 11)
    Me.chkWin.Name = "chkWin"
    Me.chkWin.Size = New System.Drawing.Size(45, 17)
    Me.chkWin.TabIndex = 0
    Me.chkWin.Text = "Win"
    Me.chkWin.UseVisualStyleBackColor = True
    '
    'chkPlace
    '
    Me.chkPlace.Anchor = CType((System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left), System.Windows.Forms.AnchorStyles)
    Me.chkPlace.AutoSize = True
    Me.chkPlace.Location = New System.Drawing.Point(13, 34)
    Me.chkPlace.Name = "chkPlace"
    Me.chkPlace.Size = New System.Drawing.Size(53, 17)
    Me.chkPlace.TabIndex = 1
    Me.chkPlace.Text = "Place"
    Me.chkPlace.UseVisualStyleBackColor = True
    '
    'ovPriceHis
    '
    Me.ovPriceHis.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
    Me.ovPriceHis.Dock = System.Windows.Forms.DockStyle.Fill
    Me.ovPriceHis.Id = Nothing
    Me.ovPriceHis.Location = New System.Drawing.Point(3, 3)
    Me.ovPriceHis.Name = "ovPriceHis"
    Me.ovPriceHis.ResourceManager = Nothing
    Me.ovPriceHis.Size = New System.Drawing.Size(367, 348)
    Me.ovPriceHis.TabIndex = 0
    '
    'PriceHistory
    '
    Me.ClientSize = New System.Drawing.Size(704, 645)
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
    CType(Me.ovPriceHis, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)

  End Sub

  Public Sub New(rManager As ApplicationResourceManager)
    MyBase.New()
    InitializeComponent()
    MyBase.ResourceManager = rManager
    Me.ovPriceHis.ResourceManager = rManager
  End Sub

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

  Private Function DateToDbString(d As DateTime) As String
    Return "'" + DateToDbFormat(d) + "'"
  End Function

  Private Function DateToDbFormat(d As DateTime) As String
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
    FillNavigator()
    _IsLoaded = True
  End Sub

End Class
