Public Class CountryCode

  Private _Code As String
  Private _TextSwe As String
  Private _TextEng As String

  Public ReadOnly Property Code As String
    Get
      Return _Code
    End Get
  End Property

  Public ReadOnly Property TextSwe As String
    Get
      Return _TextSwe
    End Get
  End Property

  Public ReadOnly Property TextEng As String
    Get
      Return _TextEng
    End Get
  End Property

  Public Sub New(code As String, textSwe As String, textEng As String)
    _Code = code
    _TextSwe = textSwe
    _TextEng = textEng
  End Sub

  Public Overrides Function ToString() As String
    'Return _Code + " - " + _TextSwe
    Return _TextSwe
  End Function
End Class
