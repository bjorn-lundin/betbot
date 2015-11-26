Imports NoNoBetDbInterface
Imports NoNoBetConfig
Imports System.Windows.Forms
Imports System.Xml
Imports System.Reflection

Public Class ApplicationResourceManager

  Public Const MenuHandlersConfigFileName As String = "MenuHandlersConfig.xml"

  Private _DbConnection As DbConnection
  Private _Translator As Translator
  Private Shared _LogFile As IO.StreamWriter = Nothing

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

  Public Shared Function ConvertToInteger(value As String) As Integer
    If (String.IsNullOrWhiteSpace(value)) Then
      Return 0
    Else
      Return Convert.ToInt32(value)
    End If
  End Function

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

  Public Shared Function ConvertToDecimal(value As String) As Decimal
    If (String.IsNullOrWhiteSpace(value)) Then
      Return Decimal.Zero
    Else
      Return Convert.ToDecimal(value)
    End If
  End Function

  Public Shared Function ConvertToDecimal(value As Object) As Decimal
    If (value Is Nothing) Then
      Return Decimal.Zero
    Else
      Return Convert.ToDecimal(value)
    End If
  End Function

  Public Shared Function ConvertToDouble(value As String) As Double
    If (String.IsNullOrWhiteSpace(value)) Then
      Return 0.0
    Else
      Return Convert.ToDouble(value)
    End If
  End Function

  Public Shared Function ConvertToDouble(value As Object) As Double
    If (value Is Nothing) Then
      Return ConvertToDouble(0)
    Else
      Return Convert.ToDouble(value)
    End If
  End Function

  Public Shared Function ConvertToDate(value As Object) As DateTime
    Return Convert.ToDateTime(value)
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
  ''' Get cell values as DateTime
  ''' </summary>
  ''' <param name="cell">Grid cell object</param>
  ''' <returns>Value as DateTime</returns>
  ''' <remarks></remarks>
  Public Shared Function GetCellDateValue(ByVal cell As DataGridViewCell) As DateTime
    If IsDBNull(cell.Value) Then
      Return ConvertToDate(Nothing)
    Else
      Return ConvertToDate(cell.Value)
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

  ''' <summary>
  ''' Get column value as DateTime
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colName">Column name</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDateValue(ByVal row As DataGridViewRow, ByVal colName As String) As DateTime
    If (row IsNot Nothing) Then
      Return GetCellDateValue(row.Cells(colName))
    Else
      Return ConvertToDate(Nothing)
    End If
  End Function

  ''' <summary>
  ''' Get column value as DateTime
  ''' </summary>
  ''' <param name="row">Grid row object</param>
  ''' <param name="colIndex">Column index</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function GetRowColumnDateValue(ByVal row As DataGridViewRow, ByVal colIndex As Integer) As DateTime
    If (row IsNot Nothing) Then
      Return GetCellDateValue(row.Cells(colIndex))
    Else
      Return ConvertToDate(Nothing)
    End If
  End Function

  ''' <summary>
  ''' Load MenuHandler specified by name
  ''' </summary>
  ''' <param name="name">Name of MenuHandler</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Shared Function LoadMenuHandler(name As String) As Object
    Dim configFileName As String = IO.Path.Combine(Application.StartupPath, MenuHandlersConfigFileName)

    If IO.File.Exists(configFileName) Then
      Dim fullFileName As String
      Dim menuHandlersNodeList As XmlNodeList = Nothing
      Dim node As XmlNode = Nothing
      Dim xmlDoc As XmlDocument = New XmlDocument

      'Load the XML document
      xmlDoc.Load(configFileName)
      'Select the /menuhandlers/menuhandler node list in XML document
      menuHandlersNodeList = xmlDoc.SelectNodes("/menuhandlers/menuhandler")

      'Loop all MenuHandler nodes
      For i As Integer = 0 To menuHandlersNodeList.Count - 1
        Dim fileName As String = String.Empty
        Dim className As String = String.Empty
        Dim handlerName As String = String.Empty

        node = menuHandlersNodeList.Item(i)

        If (node IsNot Nothing) Then
          Dim a As Assembly
          Dim t As Type
          Dim o As Object

          'Get the name of MenuHandler
          handlerName = node.Attributes.GetNamedItem("name").Value

          'Any name specified?
          If (Not String.IsNullOrEmpty(handlerName)) Then
            'Is this the requested MenuHandler?
            If (handlerName = name) Then
              fileName = node.Attributes.GetNamedItem("file").Value
              className = node.Attributes.GetNamedItem("class").Value
              fullFileName = IO.Path.Combine(Application.StartupPath, fileName)
              'Load the MenuHandler from DLL
              a = Assembly.LoadFile(fullFileName)
              t = a.GetType(IO.Path.GetFileNameWithoutExtension(fileName) + "." + className)
              'Create an instance of the MenuHandler
              o = Activator.CreateInstance(t)
              Return o
            End If
          End If
        End If
      Next

    End If
    Return Nothing
  End Function

  Private Const DefaultLogFileName As String = "NoNoBetClient"

  Private Shared Sub CreateLogFile(appName As String)
    If (_LogFile Is Nothing) Then
      Dim lFileName As String = IO.Path.Combine(Application.StartupPath, appName + ".log")
      _LogFile = New IO.StreamWriter(lFileName)
      LogFile(MethodBase.GetCurrentMethod.DeclaringType.FullName, MethodBase.GetCurrentMethod.Name, "Log file created")
    End If
  End Sub

  Public Shared Sub SetLoggingOn(appName As String)
    CreateLogFile(appName)
  End Sub

  Public Shared Sub SetLoggingOn()
    CreateLogFile(DefaultLogFileName)
  End Sub

  Public Shared Sub SetLoggingOff()
    If (_LogFile IsNot Nothing) Then
      _LogFile.Close()
      _LogFile.Dispose()
      _LogFile = Nothing
    End If
  End Sub

  Public Shared Sub LogFile(moduleName As String, functionName As String, logText As String)
    If (_LogFile IsNot Nothing) Then
      _LogFile.WriteLine(Now.ToString("yy-MM-dd hh:mm:ss") + " " + moduleName + "." + functionName + ": " + logText)
      _LogFile.Flush()
    End If
  End Sub

  Public Sub New()
  End Sub
End Class
