Imports System.Windows.Forms
Imports System.Windows.Forms.DataGridView

Public Class BaseGrid
    Inherits DataGridView

    Private _Sql As String

    Public Sub New()
        MyBase.New()
    End Sub

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

    Function GetCurrentRowCellValue(ByVal colName As String) As Object
        Return GetRowColumnValue(Me.CurrentRow, colName)
    End Function

    Function GetCurrentRowCellValue(ByVal colIndex As Integer) As Object
        Return GetRowColumnValue(Me.CurrentRow, colIndex)
    End Function

    ''' <summary>
    ''' Execute specified SQL and bind the result to grid
    ''' </summary>
    ''' <param name="dbCon"></param>
    ''' <param name="sql"></param>
    ''' <remarks></remarks>
    Public Sub ExecuteSql(ByVal dbCon As DbInterface.DbConnection, ByVal sql As String)
        Cursor = Cursors.WaitCursor
        _Sql = sql
        Me.AutoGenerateColumns = True
        MyBase.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill

        Me.SelectionMode = DataGridViewSelectionMode.FullRowSelect

        Dim bindSource As BindingSource = New BindingSource

        bindSource.DataSource = dbCon.ExecuteSql(sql)
        Me.DataSource = bindSource
        Cursor = Cursors.Default
    End Sub

    ''' <summary>
    ''' Clear all rows in grid
    ''' </summary>
    ''' <remarks></remarks>
    Public Sub Clear()
        MyBase.Rows.Clear()
    End Sub

    Private Sub BaseGrid_MouseDoubleClick(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles Me.MouseDoubleClick
        If (_Sql IsNot Nothing) Then
            MessageBox.Show("SQL: " + _Sql, Me.Name)
        Else
            MessageBox.Show("SQL: ", Me.Name)
        End If
    End Sub
End Class
