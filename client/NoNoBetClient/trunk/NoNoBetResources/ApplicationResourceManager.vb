Imports NoNoBetDbInterface
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


  Public Shared Function ConvertToInteger(value As Object) As Integer
    If (value Is Nothing) Then
      Return 0
    Else
      Return Convert.ToInt32(value)
    End If
  End Function

  Public Shared Function ConvertToString(value As Object) As String
    If (value Is Nothing) Then
      Return String.Empty
    Else
      Return Convert.ToString(value)
    End If
  End Function

  Public Shared Function ConvertToDecimal(value As Object) As Decimal
    If (value Is Nothing) Then
      Return Decimal.Zero
    Else
      Return Convert.ToDecimal(value)
    End If
  End Function

  Public Shared Function ConvertToDouble(value As Object) As Double
    If (value Is Nothing) Then
      Return ConvertToDouble(0)
    Else
      Return Convert.ToDouble(value)
    End If
  End Function

  ''' <summary>
  ''' Get cell value as String
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as String</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellStringValue(ByVal cell As DataGridViewCell) As String
    If IsDBNull(cell.Value) Then
      Return String.Empty
    Else
      Return ConvertToString(cell.Value)
    End If
  End Function

  ''' <summary>
  ''' Get cell value as Integer
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as Integer</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellIntValue(ByVal cell As DataGridViewCell) As Integer
    If IsDBNull(cell.Value) Then
      Return 0
    Else
      Return ConvertToInteger(cell.Value)
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
      Return Decimal.Zero
    Else
      Return ConvertToDecimal(cell.Value)
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
      Return Convert.ToDouble(0)
    Else
      Return ConvertToDouble(cell.Value)
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

  ''' <summary>
  ''' Get column value as Integer
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnIntValue(ByVal row As DataGridViewRow, ByVal colName As String) As Integer
    If (row IsNot Nothing) Then
      Return GetCellIntValue(row.Cells(colName))
    Else
      Return 0
    End If
  End Function

  ''' <summary>
  ''' Get column value as Integer
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnIntValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As Integer
    If (row IsNot Nothing) Then
      Return GetCellIntValue(row.Cells(colIndex))
    Else
      Return 0
    End If
  End Function

  ''' <summary>
  ''' Get column value as Decimal
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDecimalValue(ByVal row As DataGridViewRow, ByVal colName As String) As Decimal
    If (row IsNot Nothing) Then
      Return GetCellDecimalValue(row.Cells(colName))
    Else
      Return Decimal.Zero
    End If
  End Function

  ''' <summary>
  ''' Get column value as Decimal
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDecimalValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As Decimal
    If (row IsNot Nothing) Then
      Return GetCellDecimalValue(row.Cells(colIndex))
    Else
      Return Decimal.Zero
    End If
  End Function

  ''' <summary>
  ''' Get column value as Double
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDoubleValue(ByVal row As DataGridViewRow, ByVal colName As String) As Double
    If (row IsNot Nothing) Then
      Return GetCellDoubleValue(row.Cells(colName))
    Else
      Return Convert.ToDouble(0)
    End If
  End Function

  ''' <summary>
  ''' Get column value as Double
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDoubleValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As Double
    If (row IsNot Nothing) Then
      Return GetCellDoubleValue(row.Cells(colIndex))
    Else
      Return Convert.ToDouble(0)
    End If
  End Function

  ''' <summary>
  ''' Get column value as String
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnStringValue(ByVal row As DataGridViewRow, ByVal colName As String) As String
    If (row IsNot Nothing) Then
      Return GetCellStringValue(row.Cells(colName))
    Else
      Return String.Empty
    End If
  End Function

  ''' <summary>
  ''' Get column value as String
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnStringValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As String
    If (row IsNot Nothing) Then
      Return GetCellStringValue(row.Cells(colIndex))
    Else
      Return String.Empty
    End If
  End Function

  Public Sub New()
  End Sub
End Class
