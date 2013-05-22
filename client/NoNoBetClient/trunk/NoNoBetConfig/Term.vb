Public Class Term

  Private _Name As String
  Private _Translation As String
  Private _Lang As String
  Private _Description As String

  Public ReadOnly Property Name As String
    Get
      Return _Name
    End Get
  End Property

  Public ReadOnly Property Translation As String
    Get
      Return _Translation
    End Get
  End Property

  Public ReadOnly Property Lang As String
    Get
      Return _Lang
    End Get
  End Property

  Public ReadOnly Property Description As String
    Get
      Return _Description
    End Get
  End Property

  Public Sub New(name As String, translation As String, lang As String, description As String)
    _Name = name
    _Translation = translation
    _Lang = lang
    _Description = description
  End Sub

  Public Overrides Function ToString() As String
    Return _Name + " : " + _Translation + " : " + _Description
  End Function
End Class
