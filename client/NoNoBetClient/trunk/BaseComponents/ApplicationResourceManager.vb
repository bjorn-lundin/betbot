Imports DbInterface
Imports NoNoBetConfig

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

  Public Sub New()
  End Sub
End Class
