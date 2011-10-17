Imports System.Windows.Forms

Public Class BetType

    Public Enum eBetType As Integer
        V75 = 1
        V65
        V64
        V5
        V4
        V3
        DD
        LD
        TVILLING
        ANY
    End Enum

    Private _BetType As eBetType
    Private _BetTypeStr As String


    Public ReadOnly Property Value() As eBetType
        Get
            Return _BetType
        End Get
    End Property


    Public Sub New(ByVal betType As eBetType)
        _BetType = betType

        Select Case betType
            Case eBetType.V75
                _BetTypeStr = "V75"
            Case eBetType.V65
                _BetTypeStr = "V65"
            Case eBetType.V64
                _BetTypeStr = "V64"
            Case eBetType.V5
                _BetTypeStr = "V5"
            Case eBetType.V4
                _BetTypeStr = "V4"
            Case eBetType.V3
                _BetTypeStr = "V3"
            Case eBetType.LD
                _BetTypeStr = "LD"
            Case eBetType.DD
                _BetTypeStr = "DD"
            Case eBetType.TVILLING
                _BetTypeStr = "Tvilling"
            Case eBetType.ANY
                _BetTypeStr = "Any"
        End Select
    End Sub

    Public Shared Sub FillCombo(ByVal cbo As ComboBox)
        cbo.BeginUpdate()
        cbo.Items.Clear()
        cbo.Items.Add(New BetType(BetType.eBetType.V75))
        cbo.Items.Add(New BetType(BetType.eBetType.V64))
        cbo.Items.Add(New BetType(BetType.eBetType.V5))
        cbo.Items.Add(New BetType(BetType.eBetType.V4))
        cbo.Items.Add(New BetType(BetType.eBetType.V3))
        cbo.Items.Add(New BetType(BetType.eBetType.LD))
        cbo.Items.Add(New BetType(BetType.eBetType.DD))
        cbo.Items.Add(New BetType(BetType.eBetType.TVILLING))
        cbo.Items.Add(New BetType(BetType.eBetType.ANY))
        cbo.EndUpdate()
        cbo.SelectedIndex = 0
    End Sub

    Public Overrides Function ToString() As String
        Return _BetTypeStr
    End Function
End Class
