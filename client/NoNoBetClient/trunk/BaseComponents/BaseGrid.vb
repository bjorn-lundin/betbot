Imports System.Windows.Forms
Imports System.Windows.Forms.DataGridView

Public Class BaseGrid
  Inherits DataGridView

  Private Shared _MenuHandler As BaseGridMenuHandler = Nothing

  Private _Sql As String = Nothing
  Private _Id As String = Nothing
  Private _Menu As ContextMenuStrip = Nothing
  Private _ResourceManager As ApplicationResourceManager

  Private Sub InitGrid()
    If (_MenuHandler Is Nothing) Then
      _MenuHandler = New BaseGridMenuHandler
    End If
  End Sub

  Public Sub New()
    MyBase.New()
    InitGrid()
  End Sub

  Public Sub New(ByVal id As String)
    MyBase.New()
    _Id = id
    InitGrid()
  End Sub

  ''' <summary>
  ''' Grid id (name). Couples Grid to a menu
  ''' </summary>
  ''' <value></value>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Property Id() As String
    Get
      Return _Id
    End Get
    Set(ByVal value As String)
      _Id = value
    End Set
  End Property


  Public Shared Function GetCellIntValue(ByVal cell As DataGridViewCell) As Integer
    If IsDBNull(cell.Value) Then
      Return 0
    Else
      Return CType(cell.Value, Integer)
    End If
  End Function

  Public Shared Function GetCellDecimalValue(ByVal cell As DataGridViewCell) As Decimal
    If IsDBNull(cell.Value) Then
      Return CType(0, Decimal)
    Else
      Return CType(cell.Value, Decimal)
    End If
  End Function

  Public Shared Function GetCellDoubleValue(ByVal cell As DataGridViewCell) As Double
    If IsDBNull(cell.Value) Then
      Return CType(0, Double)
    Else
      Return CType(cell.Value, Double)
    End If
  End Function

  Public Function GetColumnValueType(ByVal colName As String) As System.Type
    If (Me.Columns IsNot Nothing) Then
      Dim col As DataGridViewColumn = Me.Columns.Item(colName)
      If (col IsNot Nothing) Then
        Return col.ValueType
      End If
    End If
    Return Nothing
  End Function

  Public Function GetColumnValueType(ByVal colIndex As Integer) As System.Type
    If (Me.Columns IsNot Nothing) Then
      Dim col As DataGridViewColumn = Me.Columns.Item(colIndex)
      If (col IsNot Nothing) Then
        Return col.ValueType
      End If
    End If
    Return Nothing
  End Function

  Public Shared Function GetRowColumnValue(ByVal row As DataGridViewRow, ByVal colName As String) As Object
    If (row IsNot Nothing) Then
      Dim rowCell As DataGridViewCell = row.Cells(colName)
      If (rowCell IsNot Nothing) Then
        Return rowCell.Value
      End If
    End If
    Return Nothing
  End Function

  Public Shared Function GetRowColumnValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As Object
    If (row IsNot Nothing) Then
      Dim rowCell As DataGridViewCell = row.Cells(colIndex)
      If (rowCell IsNot Nothing) Then
        Return rowCell.Value
      End If
    End If
    Return Nothing
  End Function

  Public Function GetCurrentRowCellValue(ByVal colName As String) As Object
    Return GetRowColumnValue(Me.CurrentRow, colName)
  End Function

  Public Function GetCurrentRowCellValue(ByVal colIndex As Integer) As Object
    Return GetRowColumnValue(Me.CurrentRow, colIndex)
  End Function

  Public Sub SetReadOnlyMode()
    Me.ReadOnly = True
    Me.AllowUserToAddRows = False
    Me.AllowUserToDeleteRows = False
  End Sub

  ''' <summary>
  ''' Execute specified SQL and bind the result to grid
  ''' </summary>
  ''' <param name="resourceMan">Application Resource Manager object</param>
  ''' <param name="sql"></param>
  ''' <remarks></remarks>
  Public Sub ExecuteSql(resourceMan As ApplicationResourceManager, ByVal sql As String)
    Cursor = Cursors.WaitCursor
    _ResourceManager = resourceMan
    _Sql = sql
    'Me.Clear()
    Me.AutoGenerateColumns = True
    MyBase.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill

    Me.SelectionMode = DataGridViewSelectionMode.FullRowSelect

    Dim bindSource As BindingSource = New BindingSource

    bindSource.DataSource = _ResourceManager.DbConnection.ExecuteSql(sql)
    Me.DataSource = bindSource
    Cursor = Cursors.Default
  End Sub

  ''' <summary>
  ''' Clear all rows in grid
  ''' </summary>
  ''' <remarks></remarks>
  Public Sub Clear()
    If (Me.Rows IsNot Nothing) Then
      If (Me.Rows.Count > 0) Then
        Me.Rows.Clear()
      End If
    End If
  End Sub

  ''' <summary>
  ''' Set visibility of specified column
  ''' </summary>
  ''' <param name="columnName">Column name</param>
  ''' <param name="visible">True/False</param>
  ''' <remarks></remarks>
  Public Sub SetColumnVisible(ByVal columnName As String, ByVal visible As Boolean)
    If Me.Columns.Contains(columnName) Then
      Me.Columns(columnName).Visible = visible
    End If
  End Sub

  ''' <summary>
  ''' Hide specified column (equal to SetColumnVisible(columnNane, False)) 
  ''' </summary>
  ''' <param name="columnName">Column name</param>
  ''' <remarks></remarks>
  Public Sub HideColumn(ByVal columnName As String)
    Me.SetColumnVisible(columnName, False)
  End Sub

  ''' <summary>
  ''' Hide specified columns
  ''' </summary>
  ''' <param name="columnNames">Array of column names</param>
  ''' <remarks></remarks>
  Public Sub HideColumns(ByVal columnNames() As String)
    For i As Integer = 0 To UBound(columnNames)
      Me.HideColumn(columnNames(i))
    Next
  End Sub

  ''' <summary>
  ''' Set width of specified column
  ''' </summary>
  ''' <param name="columnName">Column name</param>
  ''' <param name="width">The width, in pixels, of the column. The default is 100</param>
  ''' <remarks></remarks>
  Public Sub SetColumnWidth(ByVal columnName As String, ByVal width As Integer)
    If Me.Columns.Contains(columnName) Then
      Me.Columns(columnName).Width = width
    End If
  End Sub

  Private Sub ShowInternalMessage()
    Dim msg As String = ""
    Dim GridIdStr As String = "Grid Id: "
    Dim GridSqlStr As String = "Grid SQL: "

    If (_Id IsNot Nothing) Then
      GridIdStr += _Id
    End If

    If (_Sql IsNot Nothing) Then
      GridSqlStr += _Sql
    End If

    msg += GridIdStr
    msg += vbCrLf + vbCrLf + GridSqlStr
    msg += vbCrLf + vbCrLf + "Number rows: " & Me.RowCount
    msg += vbCrLf + vbCrLf + "ReadOnly: " + Me.ReadOnly.ToString
    msg += vbCrLf + "AllowUserToAddRows: " + Me.AllowUserToAddRows.ToString
    msg += vbCrLf + "AllowUserToDeleteRows: " + Me.AllowUserToDeleteRows.ToString


    MessageBox.Show(msg, Me.Name)
  End Sub

  Private Sub BaseGrid_CellFormatting(sender As Object, e As System.Windows.Forms.DataGridViewCellFormattingEventArgs) Handles Me.CellFormatting
    Dim col As DataGridViewColumn = Me.Columns.Item(e.ColumnIndex)

    'Only columns of type DateTime
    If (col.ValueType Is GetType(System.DateTime)) Then
      'If column name end with "_time", only time part of the DateTime value should be shown
      If col.Name.EndsWith("_time") Then
        e.Value = String.Format("{0:t}", e.Value)
      End If
    End If
  End Sub

  Private Sub BaseGrid_ColumnAdded(sender As Object, e As System.Windows.Forms.DataGridViewColumnEventArgs) Handles Me.ColumnAdded
    Dim termTranslation As String = Nothing
    Dim termDescription As String = Nothing

    If _ResourceManager.Translator.TranslateTerm(e.Column.Name, "swe", "eng", termTranslation, termDescription) Then
      e.Column.HeaderText = termTranslation
    End If

  End Sub

  Private Sub BaseGrid_KeyDown(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyEventArgs) Handles Me.KeyDown
    If (e.KeyCode = Keys.F1) Then
      ShowInternalMessage()
      e.Handled = True
    End If
  End Sub

  Private Sub BaseGrid_MouseClick(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles Me.MouseClick
    If (e.Button = MouseButtons.Right) Then
      If (_Menu Is Nothing) Then
        _Menu = BaseGridMenuHandler.MenuCreate(_Id)
      End If

      If (_Menu IsNot Nothing) Then
        'Dim p As System.Drawing.Point = Me.PointToClient(e.Location)
        Dim p As System.Drawing.Point = Me.PointToScreen(e.Location)
        BaseGridMenuHandler.MenuShow(_Menu, Me.CurrentRow, p)
      End If

    End If
  End Sub
End Class
