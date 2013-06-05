Imports System.Xml
Imports System.Windows.Forms

''' <summary>
''' Handling translation of terms
''' </summary>
''' <remarks>Loads translations from XML file and caches them in a hashtable</remarks>
Public Class Translator

  Private _Terms As XmlDocument = Nothing
  Private _AllTermsNodeList As XmlNodeList = Nothing
  Private _TermsCache As Hashtable
  Private _ReadFromCache As Boolean = False

  Public Const TermsConfigFileName As String = "TermsConfig.xml"


  Public Sub New()
    _TermsCache = New Hashtable
    _Terms = New XmlDocument
    'Load the XML file into a XML document
    LoadConfigFile()
    _ReadFromCache = True
  End Sub

  Private Sub LoadConfigFile()
    Dim fullName As String = IO.Path.Combine(Application.StartupPath, TermsConfigFileName)

    If IO.File.Exists(fullName) Then
      _Terms.Load(fullName)
      'Select the /terms/term node list in XML document
      _AllTermsNodeList = _Terms.SelectNodes("/terms/term")
      'Cache all translations
      If (_AllTermsNodeList IsNot Nothing) Then
        LoadTermsCache("swe", "eng")
      End If
    End If

  End Sub

  ''' <summary>
  ''' Load all terms translations into a hashtable
  ''' </summary>
  ''' <param name="lang1"></param>
  ''' <param name="lang2"></param>
  ''' <remarks></remarks>
  Public Sub LoadTermsCache(lang1 As String, lang2 As String)
    Dim name As String = Nothing
    Dim langElem As XmlElement = Nothing
    Dim transl As String = Nothing
    Dim lang As String = Nothing

    For Each node As XmlNode In _AllTermsNodeList
      name = node.Attributes.GetNamedItem("name").Value

      'Try lang1 
      langElem = node.Item(lang1)
      If (langElem IsNot Nothing) Then
        transl = langElem.InnerText
        lang = lang1
      End If

      If String.IsNullOrEmpty(transl) Then
        'Try lang2
        langElem = node.Item(lang2)

        If (langElem IsNot Nothing) Then
          transl = langElem.InnerText
          lang = lang2
        End If
      End If

      If (Not String.IsNullOrEmpty(transl)) Then
        Dim t As Term = New Term(name, transl, lang, "")
        'Add term to cache
        _TermsCache.Add(t.Name, t)
      End If
    Next

  End Sub
  ''' <summary>
  ''' Translate specified term
  ''' </summary>
  ''' <param name="termName">Name of term</param>
  ''' <param name="lang1">Language 1</param>
  ''' <param name="lang2">Language 2 (fall back if lang1 does not exist</param>
  ''' <param name="termTranslation">Translation of term</param>
  ''' <param name="termDescription">Description of term</param>
  ''' <returns></returns>
  ''' <remarks></remarks>
  Public Function TranslateTerm(termName As String, lang1 As String, lang2 As String, ByRef termTranslation As String, ByRef termDescription As String) As Boolean
    If _ReadFromCache Then
      Return TranslateTermFromCache(termName, lang1, lang2, termTranslation, termDescription)
    Else
      Return TranslateTermFromXml(termName, lang1, lang2, termTranslation, termDescription)
    End If
  End Function

  Private Function TranslateTermFromCache(termName As String, lang1 As String, lang2 As String, ByRef termTranslation As String, ByRef termDescription As String) As Boolean
    Dim t As Term = _TermsCache.Item(termName)

    If (t IsNot Nothing) Then
      termTranslation = t.Translation
      termDescription = t.Description
      Return True
    End If

    Return False
  End Function

  Private Function TranslateTermFromXml(termName As String, lang1 As String, lang2 As String, ByRef termTranslation As String, ByRef termDescription As String) As Boolean
    Dim name As String
    For Each node As XmlNode In _AllTermsNodeList
      name = node.Attributes.GetNamedItem("name").Value

      If name.Equals(termName) Then
        Dim langElem As XmlElement
        Dim transl As String = Nothing
        'Try lang1 
        langElem = node.Item(lang1)
        If (langElem IsNot Nothing) Then
          transl = langElem.InnerText
        End If

        If String.IsNullOrEmpty(transl) Then
          'Try lang2
          langElem = node.Item(lang2)

          If (langElem IsNot Nothing) Then
            transl = langElem.InnerText
          End If
        End If

        If (Not String.IsNullOrEmpty(transl)) Then
          termTranslation = transl
          termDescription = String.Empty
          Return True
        End If
      End If
    Next
    Return False
  End Function
End Class
