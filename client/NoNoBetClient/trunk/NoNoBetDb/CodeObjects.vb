Imports System.Windows.Forms
Imports DbInterface
Imports BaseComponents

Public Class CodeObjects

  Private _Codes As Collection

  Public Sub New()
    _Codes = New Collection
  End Sub

  Public Function Count() As Integer
    Return _Codes.Count
  End Function

  Public Function Item(index As Integer) As CodeObject
    If (index > 0 And index <= _Codes.Count) Then
      Return CType(_Codes.Item(index), CodeObject)
    Else
      Return Nothing
    End If
  End Function

  Public Sub Add(cCode As CodeObject)
    If (Not _Codes.Contains(cCode.Code)) Then
      _Codes.Add(cCode, cCode.Code)
    End If
  End Sub

End Class
