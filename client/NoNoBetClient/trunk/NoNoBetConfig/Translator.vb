Imports System.Xml

Public Class Translator

  Private _Terms As XmlDocument = Nothing
  Private _TermsNode As XmlNodeList
  Private _AllTerms As XmlNode
  Public Const TermsConfigFileName As String = "TermsConfig.xml"

  Public Sub New()
    _Terms = New XmlDocument
    _Terms.Load(TermsConfigFileName)
    _TermsNode = _Terms.GetElementsByTagName("Terms")
    _AllTerms = _Terms.SelectSingleNode("/terms")
  End Sub

End Class
