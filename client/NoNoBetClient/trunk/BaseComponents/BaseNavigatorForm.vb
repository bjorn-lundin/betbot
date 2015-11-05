Imports System.Windows.Forms

Public Class BaseNavigatorForm
  Inherits BaseForm
  Friend WithEvents tabPageDetail1 As System.Windows.Forms.TabPage
  Friend WithEvents containerMain As System.Windows.Forms.SplitContainer
  Friend WithEvents tabControlDetail As System.Windows.Forms.TabControl
  Friend WithEvents tabPageOverview1 As System.Windows.Forms.TabPage
  Friend WithEvents tabControlOverview As System.Windows.Forms.TabControl
  Friend WithEvents containerTabs As System.Windows.Forms.SplitContainer
  Friend WithEvents Navigator As NoNoBetBaseComponents.BaseTree
  Friend WithEvents containerNavigator As System.Windows.Forms.SplitContainer

  Private Sub InitializeComponent()
    Me.containerNavigator = New System.Windows.Forms.SplitContainer()
    Me.Navigator = New NoNoBetBaseComponents.BaseTree()
    Me.containerTabs = New System.Windows.Forms.SplitContainer()
    Me.tabControlOverview = New System.Windows.Forms.TabControl()
    Me.tabPageOverview1 = New System.Windows.Forms.TabPage()
    Me.tabControlDetail = New System.Windows.Forms.TabControl()
    Me.tabPageDetail1 = New System.Windows.Forms.TabPage()
    Me.containerMain = New System.Windows.Forms.SplitContainer()
    CType(Me.containerNavigator, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerNavigator.Panel1.SuspendLayout()
    Me.containerNavigator.SuspendLayout()
    CType(Me.containerTabs, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerTabs.Panel1.SuspendLayout()
    Me.containerTabs.Panel2.SuspendLayout()
    Me.containerTabs.SuspendLayout()
    Me.tabControlOverview.SuspendLayout()
    Me.tabControlDetail.SuspendLayout()
    CType(Me.containerMain, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.containerMain.Panel1.SuspendLayout()
    Me.containerMain.Panel2.SuspendLayout()
    Me.containerMain.SuspendLayout()
    Me.SuspendLayout()
    '
    'containerNavigator
    '
    Me.containerNavigator.Dock = System.Windows.Forms.DockStyle.Fill
    Me.containerNavigator.Location = New System.Drawing.Point(0, 0)
    Me.containerNavigator.Name = "containerNavigator"
    Me.containerNavigator.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'containerNavigator.Panel1
    '
    Me.containerNavigator.Panel1.Controls.Add(Me.Navigator)
    Me.containerNavigator.Size = New System.Drawing.Size(163, 393)
    Me.containerNavigator.SplitterDistance = 309
    Me.containerNavigator.SplitterWidth = 8
    Me.containerNavigator.TabIndex = 0
    '
    'Navigator
    '
    Me.Navigator.Dock = System.Windows.Forms.DockStyle.Fill
    Me.Navigator.Location = New System.Drawing.Point(0, 0)
    Me.Navigator.Name = "Navigator"
    Me.Navigator.Size = New System.Drawing.Size(163, 309)
    Me.Navigator.TabIndex = 0
    '
    'containerTabs
    '
    Me.containerTabs.Dock = System.Windows.Forms.DockStyle.Fill
    Me.containerTabs.Location = New System.Drawing.Point(0, 0)
    Me.containerTabs.Name = "containerTabs"
    Me.containerTabs.Orientation = System.Windows.Forms.Orientation.Horizontal
    '
    'containerTabs.Panel1
    '
    Me.containerTabs.Panel1.Controls.Add(Me.tabControlOverview)
    '
    'containerTabs.Panel2
    '
    Me.containerTabs.Panel2.Controls.Add(Me.tabControlDetail)
    Me.containerTabs.Size = New System.Drawing.Size(533, 393)
    Me.containerTabs.SplitterDistance = 220
    Me.containerTabs.SplitterWidth = 8
    Me.containerTabs.TabIndex = 1
    '
    'tabControlOverview
    '
    Me.tabControlOverview.Controls.Add(Me.tabPageOverview1)
    Me.tabControlOverview.Dock = System.Windows.Forms.DockStyle.Fill
    Me.tabControlOverview.Location = New System.Drawing.Point(0, 0)
    Me.tabControlOverview.Name = "tabControlOverview"
    Me.tabControlOverview.SelectedIndex = 0
    Me.tabControlOverview.Size = New System.Drawing.Size(533, 220)
    Me.tabControlOverview.TabIndex = 0
    '
    'tabPageOverview1
    '
    Me.tabPageOverview1.Location = New System.Drawing.Point(4, 22)
    Me.tabPageOverview1.Name = "tabPageOverview1"
    Me.tabPageOverview1.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageOverview1.Size = New System.Drawing.Size(525, 194)
    Me.tabPageOverview1.TabIndex = 0
    Me.tabPageOverview1.Text = "tabPageOverview1"
    Me.tabPageOverview1.UseVisualStyleBackColor = True
    '
    'tabControlDetail
    '
    Me.tabControlDetail.Controls.Add(Me.tabPageDetail1)
    Me.tabControlDetail.Dock = System.Windows.Forms.DockStyle.Fill
    Me.tabControlDetail.Location = New System.Drawing.Point(0, 0)
    Me.tabControlDetail.Name = "tabControlDetail"
    Me.tabControlDetail.SelectedIndex = 0
    Me.tabControlDetail.Size = New System.Drawing.Size(533, 165)
    Me.tabControlDetail.TabIndex = 0
    '
    'tabPageDetail1
    '
    Me.tabPageDetail1.Location = New System.Drawing.Point(4, 22)
    Me.tabPageDetail1.Name = "tabPageDetail1"
    Me.tabPageDetail1.Padding = New System.Windows.Forms.Padding(3)
    Me.tabPageDetail1.Size = New System.Drawing.Size(525, 139)
    Me.tabPageDetail1.TabIndex = 0
    Me.tabPageDetail1.Text = "tabPageDetail1"
    Me.tabPageDetail1.UseVisualStyleBackColor = True
    '
    'containerMain
    '
    Me.containerMain.Dock = System.Windows.Forms.DockStyle.Fill
    Me.containerMain.Location = New System.Drawing.Point(0, 0)
    Me.containerMain.Name = "containerMain"
    '
    'containerMain.Panel1
    '
    Me.containerMain.Panel1.Controls.Add(Me.containerNavigator)
    '
    'containerMain.Panel2
    '
    Me.containerMain.Panel2.Controls.Add(Me.containerTabs)
    Me.containerMain.Size = New System.Drawing.Size(704, 393)
    Me.containerMain.SplitterDistance = 163
    Me.containerMain.SplitterWidth = 8
    Me.containerMain.TabIndex = 2
    '
    'BaseNavigatorForm
    '
    Me.ClientSize = New System.Drawing.Size(704, 393)
    Me.Controls.Add(Me.containerMain)
    Me.Name = "BaseNavigatorForm"
    Me.containerNavigator.Panel1.ResumeLayout(False)
    CType(Me.containerNavigator, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerNavigator.ResumeLayout(False)
    Me.containerTabs.Panel1.ResumeLayout(False)
    Me.containerTabs.Panel2.ResumeLayout(False)
    CType(Me.containerTabs, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerTabs.ResumeLayout(False)
    Me.tabControlOverview.ResumeLayout(False)
    Me.tabControlDetail.ResumeLayout(False)
    Me.containerMain.Panel1.ResumeLayout(False)
    Me.containerMain.Panel2.ResumeLayout(False)
    CType(Me.containerMain, System.ComponentModel.ISupportInitialize).EndInit()
    Me.containerMain.ResumeLayout(False)
    Me.ResumeLayout(False)

  End Sub

  Private _CurrOverviewRowChangeObject As DataGridViewRow
  Private _CurrDetailRowChangeObject As DataGridViewRow

  Public Sub New()
    MyBase.New()
    InitializeComponent()
  End Sub

  Public Class RowChangeEventArgs
    Inherits EventArgs

    Private _RowObject As DataGridViewRow

    Public Property RowObject As DataGridViewRow
      Get
        Return _RowObject
      End Get
      Set(value As DataGridViewRow)
        _RowObject = value
      End Set
    End Property

    Public Sub New(rowObject As DataGridViewRow)
      MyBase.New()
      _RowObject = rowObject
    End Sub
  End Class

  Public Event OverviewRowChange(sender As Object, e As RowChangeEventArgs)
  Public Event DetailRowChange(sender As Object, e As RowChangeEventArgs)

  ''' <summary>
  ''' Handle NodeChange event from Navigator tree
  ''' </summary>
  ''' <param name="sender"></param>
  ''' <param name="e"></param>
  ''' <remarks></remarks>
  Private Sub Navigator_NodeChange(sender As Object, e As BaseTree.NodeChangeEventArgs) Handles Navigator.NodeChange
    Dim o As IOverviewComponent = GetFocusedOverviewComponent()

    If (o IsNot Nothing) Then
      o.NodeChangeHandler(0, e.KeyObject)
    End If
  End Sub

  Private Sub HandleOverviewRowChange(rowObject As DataGridViewRow)
    Dim d As IDetailComponent = GetFocusedDetailComponent()

    If (d IsNot Nothing) Then
      d.RowChangeHandler(rowObject)
    End If
  End Sub

  Private Sub HandleDetailRowChange(rowObject As DataGridViewRow)

  End Sub

  Public Function GetCurrentOverviewRowChangeObject() As DataGridViewRow
    Return _CurrOverviewRowChangeObject
  End Function


  Private Sub BaseNavigatorForm_OverviewRowChange(sender As Object, e As RowChangeEventArgs) Handles Me.OverviewRowChange
    _CurrOverviewRowChangeObject = e.RowObject
    HandleOverviewRowChange(e.RowObject)
  End Sub

  Private Sub BaseNavigatorForm_DetailRowChange(sender As Object, e As RowChangeEventArgs) Handles Me.DetailRowChange
    _CurrDetailRowChangeObject = e.RowObject
    HandleDetailRowChange(e.RowObject)
  End Sub

  Private Function GetFocusedDetailComponent() As IDetailComponent
    Dim selectedTabPage As TabPage = tabControlOverview.SelectedTab

    For Each ctrl As Control In selectedTabPage.Controls
      If (TypeOf ctrl Is IDetailComponent) Then
        Return CType(ctrl, IDetailComponent)
      End If
    Next

    Return Nothing
  End Function

  Private Function GetFocusedOverviewComponent() As IOverviewComponent
    Dim selectedTabPage As TabPage = tabControlOverview.SelectedTab

    For Each ctrl As Control In selectedTabPage.Controls
      If (TypeOf ctrl Is IOverviewComponent) Then
        Return CType(ctrl, IOverviewComponent)
      End If
    Next

    Return Nothing
  End Function
End Class
