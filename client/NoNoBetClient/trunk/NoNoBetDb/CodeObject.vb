Public Class CodeObject

  Private _Code As String
  Private _Description As String

  Public ReadOnly Property Code As String
    Get
      Return _Code
    End Get
  End Property

  Public ReadOnly Property Description As String
    Get
      Return _Description
    End Get
  End Property


  Public Sub New(code As String, desc As String)
    _Code = code
    _Description = desc
  End Sub

  Public Overrides Function ToString() As String
    Return _Code
  End Function

End Class
