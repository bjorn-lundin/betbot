Imports DbInterface
Imports NoNoBetConfig
Imports System.Windows.Forms

Public Class ApplicationResourceManager

  Private _DbConnection As DbConnection
  Private _Translator As Translator

  Public Property DbConnection As DbConnection
    Get
      Return _DbConnection
    End Get
    Set(value As DbConnection)
      _DbConnection = value
    End Set
  End Property

  Public Property Translator As Translator
    Get
      Return _Translator
    End Get
    Set(value As Translator)
      _Translator = value
    End Set
  End Property

  ''' <summary>
  ''' Get cell value as Integer
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as integer</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellIntValue(ByVal cell As DataGridViewCell) As Integer
    If IsDBNull(cell.Value) Then
      Return 0
    Else
      Return CType(cell.Value, Integer)
    End If
  End Function

  ''' <summary>
  ''' Get cell value as Decimal
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as Decimal</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellDecimalValue(ByVal cell As DataGridViewCell) As Decimal
    If IsDBNull(cell.Value) Then
      Return CType(0, Decimal)
    Else
      Return CType(cell.Value, Decimal)
    End If
  End Function

  ''' <summary>
  ''' Get cell value as Double
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as Double</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellDoubleValue(ByVal cell As DataGridViewCell) As Double
    If IsDBNull(cell.Value) Then
      Return CType(0, Double)
    Else
      Return CType(cell.Value, Double)
    End If
  End Function

  ''' <summary>
  ''' Get column value as Object
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnValue(ByVal row As DataGridViewRow, ByVal colName As String) As Object
    If (row IsNot Nothing) Then
      Dim rowCell As DataGridViewCell = row.Cells(colName)
      If (rowCell IsNot Nothing) Then
        Return rowCell.Value
      End If
    End If
    Return Nothing
  End Function

  ''' <summary>
  ''' Get column value as Object
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As Object
    If (row IsNot Nothing) Then
      Dim rowCell As DataGridViewCell = row.Cells(colIndex)
      If (rowCell IsNot Nothing) Then
        Return rowCell.Value
      End If
    End If
    Return Nothing
  End Function

  Public Sub New()
  End Sub
End Class
