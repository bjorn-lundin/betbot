Public MustInherit Class NavKey
  Private _Level As Integer

  Public ReadOnly Property Level As Integer
    Get
      Return _Level
    End Get
  End Property

  Public Sub New(level As Integer)
    _Level = level
  End Sub

End Class

Public Class NavKeyLevel0
  Inherits NavKey

  Private _StartTime As DateTime
  Private _MarketTypePlaceOption As Boolean
  Private _MarketTypeWinOption As Boolean

  Public ReadOnly Property StartTime As DateTime
    Get
      Return _StartTime
    End Get
  End Property

  Public ReadOnly Property MarketTypePlaceOption As Boolean
    Get
      Return _MarketTypePlaceOption
    End Get
  End Property

  Public ReadOnly Property MarketTypeWinOption As Boolean
    Get
      Return _MarketTypeWinOption
    End Get
  End Property

  Public Sub New(level As Integer, startTime As DateTime, marketTypePlaceOption As Boolean, marketTypeWinOption As Boolean)
    MyBase.New(level)
    _StartTime = startTime
    _MarketTypePlaceOption = marketTypePlaceOption
    _MarketTypeWinOption = marketTypeWinOption
  End Sub

End Class

Public Class NavKeyLevel1
  Inherits NavKeyLevel0

  Private _MarketId As String
  Private _MarketType As String

  Public ReadOnly Property MarketId As String
    Get
      Return _MarketId
    End Get
  End Property

  Public ReadOnly Property MarketType As String
    Get
      Return _MarketType
    End Get
  End Property

  Public Sub New(level As Integer, startTime As DateTime, marketTypePlaceOption As Boolean, marketTypeWinOption As Boolean, marketId As String, marketType As String)
    MyBase.New(level, startTime, marketTypePlaceOption, marketTypeWinOption)
    _MarketId = marketId
    _MarketType = marketType
  End Sub
End Class

Public Class NavKeyLevel2
  Inherits NavKeyLevel1

  Private _SelectionId As Integer

  Public ReadOnly Property SelectionId As Integer
    Get
      Return _SelectionId
    End Get
  End Property

  Public Sub New(level As Integer, startTime As DateTime, marketTypePlaceOption As Boolean, marketTypeWinOption As Boolean, marketId As String, marketType As String, selectionId As Integer)
    MyBase.New(level, startTime, marketTypePlaceOption, marketTypeWinOption, marketId, marketType)
    _SelectionId = selectionId
  End Sub
End Class