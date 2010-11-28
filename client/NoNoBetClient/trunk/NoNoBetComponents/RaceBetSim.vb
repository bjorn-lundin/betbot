Imports System.Windows.Forms
Imports BaseComponents
Imports DbInterface

Public Class RaceBetSim
    Inherits BaseForm
    Friend WithEvents gridRaces As BaseComponents.BaseGrid
    Friend WithEvents groupTop As System.Windows.Forms.GroupBox
    Friend WithEvents groupTopBottom As System.Windows.Forms.GroupBox
    Friend WithEvents radioIgnore As System.Windows.Forms.RadioButton
    Friend WithEvents radioAuto As System.Windows.Forms.RadioButton
    Friend WithEvents radioVolt As System.Windows.Forms.RadioButton
    Friend WithEvents buttonShowRaces As System.Windows.Forms.Button
    Friend WithEvents labelEndDate As System.Windows.Forms.Label
    Friend WithEvents dpStartdate As System.Windows.Forms.DateTimePicker
    Friend WithEvents labelTrack As System.Windows.Forms.Label
    Friend WithEvents dpEndDate As System.Windows.Forms.DateTimePicker
    Friend WithEvents comboTracks As System.Windows.Forms.ComboBox
    Friend WithEvents labelStartDate As System.Windows.Forms.Label
    Friend WithEvents groupStartType As System.Windows.Forms.GroupBox
    Friend WithEvents groupSelectionType As System.Windows.Forms.GroupBox
    Friend WithEvents radioStartpos As System.Windows.Forms.RadioButton
    Friend WithEvents radioWinner As System.Windows.Forms.RadioButton
    Friend WithEvents radioPlace As System.Windows.Forms.RadioButton
    Friend WithEvents butttonBet As System.Windows.Forms.Button
    Friend WithEvents radioBetTypeWinner As System.Windows.Forms.RadioButton
    Friend WithEvents radioBetTypePlace As System.Windows.Forms.RadioButton
    Friend WithEvents groupBetType As System.Windows.Forms.GroupBox
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents textBetAmount As System.Windows.Forms.TextBox
    Friend WithEvents GroupBox1 As System.Windows.Forms.GroupBox
    Friend WithEvents textWinAmount As System.Windows.Forms.TextBox
    Friend WithEvents textNmbrWins As System.Windows.Forms.TextBox
    Friend WithEvents textSumBetAmount As System.Windows.Forms.TextBox
    Friend WithEvents textNmbrRaces As System.Windows.Forms.TextBox
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents GroupBox2 As System.Windows.Forms.GroupBox
    Friend WithEvents Label6 As System.Windows.Forms.Label
    Friend WithEvents textTotNmbrRaces As System.Windows.Forms.TextBox
    Friend WithEvents textWinPercent As System.Windows.Forms.TextBox
    Friend WithEvents textStartPos As System.Windows.Forms.TextBox

    Private Sub InitializeComponent()
        Dim DataGridViewCellStyle7 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Dim DataGridViewCellStyle8 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Dim DataGridViewCellStyle9 As System.Windows.Forms.DataGridViewCellStyle = New System.Windows.Forms.DataGridViewCellStyle()
        Me.groupTop = New System.Windows.Forms.GroupBox()
        Me.groupTopBottom = New System.Windows.Forms.GroupBox()
        Me.groupSelectionType = New System.Windows.Forms.GroupBox()
        Me.radioStartpos = New System.Windows.Forms.RadioButton()
        Me.radioWinner = New System.Windows.Forms.RadioButton()
        Me.radioPlace = New System.Windows.Forms.RadioButton()
        Me.groupStartType = New System.Windows.Forms.GroupBox()
        Me.radioAuto = New System.Windows.Forms.RadioButton()
        Me.radioIgnore = New System.Windows.Forms.RadioButton()
        Me.radioVolt = New System.Windows.Forms.RadioButton()
        Me.textStartPos = New System.Windows.Forms.TextBox()
        Me.buttonShowRaces = New System.Windows.Forms.Button()
        Me.labelEndDate = New System.Windows.Forms.Label()
        Me.dpStartdate = New System.Windows.Forms.DateTimePicker()
        Me.labelTrack = New System.Windows.Forms.Label()
        Me.dpEndDate = New System.Windows.Forms.DateTimePicker()
        Me.comboTracks = New System.Windows.Forms.ComboBox()
        Me.labelStartDate = New System.Windows.Forms.Label()
        Me.gridRaces = New BaseComponents.BaseGrid()
        Me.butttonBet = New System.Windows.Forms.Button()
        Me.radioBetTypeWinner = New System.Windows.Forms.RadioButton()
        Me.radioBetTypePlace = New System.Windows.Forms.RadioButton()
        Me.groupBetType = New System.Windows.Forms.GroupBox()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.textBetAmount = New System.Windows.Forms.TextBox()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.textWinAmount = New System.Windows.Forms.TextBox()
        Me.textNmbrWins = New System.Windows.Forms.TextBox()
        Me.textSumBetAmount = New System.Windows.Forms.TextBox()
        Me.textNmbrRaces = New System.Windows.Forms.TextBox()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.GroupBox2 = New System.Windows.Forms.GroupBox()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.textTotNmbrRaces = New System.Windows.Forms.TextBox()
        Me.textWinPercent = New System.Windows.Forms.TextBox()
        Me.groupTop.SuspendLayout()
        Me.groupTopBottom.SuspendLayout()
        Me.groupSelectionType.SuspendLayout()
        Me.groupStartType.SuspendLayout()
        CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.groupBetType.SuspendLayout()
        Me.GroupBox1.SuspendLayout()
        Me.GroupBox2.SuspendLayout()
        Me.SuspendLayout()
        '
        'groupTop
        '
        Me.groupTop.Controls.Add(Me.groupTopBottom)
        Me.groupTop.Controls.Add(Me.gridRaces)
        Me.groupTop.Dock = System.Windows.Forms.DockStyle.Fill
        Me.groupTop.Location = New System.Drawing.Point(0, 0)
        Me.groupTop.Name = "groupTop"
        Me.groupTop.Size = New System.Drawing.Size(996, 427)
        Me.groupTop.TabIndex = 0
        Me.groupTop.TabStop = False
        Me.groupTop.Text = "Ekipage urval"
        '
        'groupTopBottom
        '
        Me.groupTopBottom.Controls.Add(Me.groupSelectionType)
        Me.groupTopBottom.Controls.Add(Me.groupStartType)
        Me.groupTopBottom.Controls.Add(Me.textStartPos)
        Me.groupTopBottom.Controls.Add(Me.buttonShowRaces)
        Me.groupTopBottom.Controls.Add(Me.labelEndDate)
        Me.groupTopBottom.Controls.Add(Me.dpStartdate)
        Me.groupTopBottom.Controls.Add(Me.labelTrack)
        Me.groupTopBottom.Controls.Add(Me.dpEndDate)
        Me.groupTopBottom.Controls.Add(Me.comboTracks)
        Me.groupTopBottom.Controls.Add(Me.labelStartDate)
        Me.groupTopBottom.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.groupTopBottom.Location = New System.Drawing.Point(3, 260)
        Me.groupTopBottom.Name = "groupTopBottom"
        Me.groupTopBottom.Size = New System.Drawing.Size(990, 164)
        Me.groupTopBottom.TabIndex = 1
        Me.groupTopBottom.TabStop = False
        '
        'groupSelectionType
        '
        Me.groupSelectionType.Controls.Add(Me.radioStartpos)
        Me.groupSelectionType.Controls.Add(Me.radioWinner)
        Me.groupSelectionType.Controls.Add(Me.radioPlace)
        Me.groupSelectionType.Location = New System.Drawing.Point(520, 22)
        Me.groupSelectionType.Name = "groupSelectionType"
        Me.groupSelectionType.Size = New System.Drawing.Size(153, 117)
        Me.groupSelectionType.TabIndex = 25
        Me.groupSelectionType.TabStop = False
        Me.groupSelectionType.Text = "Urvalstyp"
        '
        'radioStartpos
        '
        Me.radioStartpos.AutoSize = True
        Me.radioStartpos.Location = New System.Drawing.Point(6, 25)
        Me.radioStartpos.Name = "radioStartpos"
        Me.radioStartpos.Size = New System.Drawing.Size(121, 21)
        Me.radioStartpos.TabIndex = 27
        Me.radioStartpos.TabStop = True
        Me.radioStartpos.Text = "Startpositioner"
        Me.radioStartpos.UseVisualStyleBackColor = True
        '
        'radioWinner
        '
        Me.radioWinner.AutoSize = True
        Me.radioWinner.Location = New System.Drawing.Point(6, 49)
        Me.radioWinner.Name = "radioWinner"
        Me.radioWinner.Size = New System.Drawing.Size(100, 21)
        Me.radioWinner.TabIndex = 26
        Me.radioWinner.TabStop = True
        Me.radioWinner.Text = "Vinnare (1)"
        Me.radioWinner.UseVisualStyleBackColor = True
        '
        'radioPlace
        '
        Me.radioPlace.AutoSize = True
        Me.radioPlace.Location = New System.Drawing.Point(6, 76)
        Me.radioPlace.Name = "radioPlace"
        Me.radioPlace.Size = New System.Drawing.Size(106, 21)
        Me.radioPlace.TabIndex = 25
        Me.radioPlace.TabStop = True
        Me.radioPlace.Text = "Plats (1,2,3)"
        Me.radioPlace.UseVisualStyleBackColor = True
        '
        'groupStartType
        '
        Me.groupStartType.Controls.Add(Me.radioAuto)
        Me.groupStartType.Controls.Add(Me.radioIgnore)
        Me.groupStartType.Controls.Add(Me.radioVolt)
        Me.groupStartType.Location = New System.Drawing.Point(400, 22)
        Me.groupStartType.Name = "groupStartType"
        Me.groupStartType.Size = New System.Drawing.Size(118, 117)
        Me.groupStartType.TabIndex = 24
        Me.groupStartType.TabStop = False
        Me.groupStartType.Text = "Start typ"
        '
        'radioAuto
        '
        Me.radioAuto.AutoSize = True
        Me.radioAuto.Location = New System.Drawing.Point(16, 49)
        Me.radioAuto.Name = "radioAuto"
        Me.radioAuto.Size = New System.Drawing.Size(58, 21)
        Me.radioAuto.TabIndex = 20
        Me.radioAuto.TabStop = True
        Me.radioAuto.Text = "Auto"
        Me.radioAuto.UseVisualStyleBackColor = True
        '
        'radioIgnore
        '
        Me.radioIgnore.AutoSize = True
        Me.radioIgnore.Location = New System.Drawing.Point(16, 73)
        Me.radioIgnore.Name = "radioIgnore"
        Me.radioIgnore.Size = New System.Drawing.Size(69, 21)
        Me.radioIgnore.TabIndex = 21
        Me.radioIgnore.TabStop = True
        Me.radioIgnore.Text = "Ignore"
        Me.radioIgnore.UseVisualStyleBackColor = True
        '
        'radioVolt
        '
        Me.radioVolt.AutoSize = True
        Me.radioVolt.Location = New System.Drawing.Point(16, 25)
        Me.radioVolt.Name = "radioVolt"
        Me.radioVolt.Size = New System.Drawing.Size(53, 21)
        Me.radioVolt.TabIndex = 19
        Me.radioVolt.TabStop = True
        Me.radioVolt.Text = "Volt"
        Me.radioVolt.UseVisualStyleBackColor = True
        '
        'textStartPos
        '
        Me.textStartPos.Location = New System.Drawing.Point(679, 46)
        Me.textStartPos.Name = "textStartPos"
        Me.textStartPos.Size = New System.Drawing.Size(147, 22)
        Me.textStartPos.TabIndex = 23
        '
        'buttonShowRaces
        '
        Me.buttonShowRaces.Location = New System.Drawing.Point(875, 135)
        Me.buttonShowRaces.Name = "buttonShowRaces"
        Me.buttonShowRaces.Size = New System.Drawing.Size(106, 23)
        Me.buttonShowRaces.TabIndex = 18
        Me.buttonShowRaces.Text = "Visa ekipage"
        Me.buttonShowRaces.UseVisualStyleBackColor = True
        '
        'labelEndDate
        '
        Me.labelEndDate.AutoSize = True
        Me.labelEndDate.Location = New System.Drawing.Point(191, 75)
        Me.labelEndDate.Name = "labelEndDate"
        Me.labelEndDate.Size = New System.Drawing.Size(75, 17)
        Me.labelEndDate.TabIndex = 17
        Me.labelEndDate.Text = "Slut datum"
        '
        'dpStartdate
        '
        Me.dpStartdate.Location = New System.Drawing.Point(194, 46)
        Me.dpStartdate.Name = "dpStartdate"
        Me.dpStartdate.Size = New System.Drawing.Size(200, 22)
        Me.dpStartdate.TabIndex = 14
        '
        'labelTrack
        '
        Me.labelTrack.AutoSize = True
        Me.labelTrack.Location = New System.Drawing.Point(12, 22)
        Me.labelTrack.Name = "labelTrack"
        Me.labelTrack.Size = New System.Drawing.Size(41, 17)
        Me.labelTrack.TabIndex = 13
        Me.labelTrack.Text = "Bana"
        '
        'dpEndDate
        '
        Me.dpEndDate.Location = New System.Drawing.Point(194, 95)
        Me.dpEndDate.Name = "dpEndDate"
        Me.dpEndDate.Size = New System.Drawing.Size(200, 22)
        Me.dpEndDate.TabIndex = 16
        '
        'comboTracks
        '
        Me.comboTracks.FormattingEnabled = True
        Me.comboTracks.Location = New System.Drawing.Point(12, 45)
        Me.comboTracks.Name = "comboTracks"
        Me.comboTracks.Size = New System.Drawing.Size(162, 24)
        Me.comboTracks.TabIndex = 12
        '
        'labelStartDate
        '
        Me.labelStartDate.AutoSize = True
        Me.labelStartDate.Location = New System.Drawing.Point(191, 22)
        Me.labelStartDate.Name = "labelStartDate"
        Me.labelStartDate.Size = New System.Drawing.Size(81, 17)
        Me.labelStartDate.TabIndex = 15
        Me.labelStartDate.Text = "Start datum"
        '
        'gridRaces
        '
        DataGridViewCellStyle7.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft
        DataGridViewCellStyle7.BackColor = System.Drawing.SystemColors.Control
        DataGridViewCellStyle7.Font = New System.Drawing.Font("Microsoft Sans Serif", 7.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        DataGridViewCellStyle7.ForeColor = System.Drawing.SystemColors.WindowText
        DataGridViewCellStyle7.SelectionBackColor = System.Drawing.SystemColors.Highlight
        DataGridViewCellStyle7.SelectionForeColor = System.Drawing.SystemColors.HighlightText
        DataGridViewCellStyle7.WrapMode = System.Windows.Forms.DataGridViewTriState.[True]
        Me.gridRaces.ColumnHeadersDefaultCellStyle = DataGridViewCellStyle7
        Me.gridRaces.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        DataGridViewCellStyle8.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft
        DataGridViewCellStyle8.BackColor = System.Drawing.SystemColors.Window
        DataGridViewCellStyle8.Font = New System.Drawing.Font("Microsoft Sans Serif", 7.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        DataGridViewCellStyle8.ForeColor = System.Drawing.SystemColors.ControlText
        DataGridViewCellStyle8.SelectionBackColor = System.Drawing.SystemColors.Highlight
        DataGridViewCellStyle8.SelectionForeColor = System.Drawing.SystemColors.HighlightText
        DataGridViewCellStyle8.WrapMode = System.Windows.Forms.DataGridViewTriState.[False]
        Me.gridRaces.DefaultCellStyle = DataGridViewCellStyle8
        Me.gridRaces.Dock = System.Windows.Forms.DockStyle.Fill
        Me.gridRaces.Location = New System.Drawing.Point(3, 18)
        Me.gridRaces.Name = "gridRaces"
        DataGridViewCellStyle9.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft
        DataGridViewCellStyle9.BackColor = System.Drawing.SystemColors.Control
        DataGridViewCellStyle9.Font = New System.Drawing.Font("Microsoft Sans Serif", 7.8!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        DataGridViewCellStyle9.ForeColor = System.Drawing.SystemColors.WindowText
        DataGridViewCellStyle9.SelectionBackColor = System.Drawing.SystemColors.Highlight
        DataGridViewCellStyle9.SelectionForeColor = System.Drawing.SystemColors.HighlightText
        DataGridViewCellStyle9.WrapMode = System.Windows.Forms.DataGridViewTriState.[True]
        Me.gridRaces.RowHeadersDefaultCellStyle = DataGridViewCellStyle9
        Me.gridRaces.RowTemplate.Height = 24
        Me.gridRaces.Size = New System.Drawing.Size(990, 406)
        Me.gridRaces.TabIndex = 0
        '
        'butttonBet
        '
        Me.butttonBet.Location = New System.Drawing.Point(878, 137)
        Me.butttonBet.Name = "butttonBet"
        Me.butttonBet.Size = New System.Drawing.Size(106, 23)
        Me.butttonBet.TabIndex = 19
        Me.butttonBet.Text = "Spela"
        Me.butttonBet.UseVisualStyleBackColor = True
        '
        'radioBetTypeWinner
        '
        Me.radioBetTypeWinner.AutoSize = True
        Me.radioBetTypeWinner.Location = New System.Drawing.Point(12, 36)
        Me.radioBetTypeWinner.Name = "radioBetTypeWinner"
        Me.radioBetTypeWinner.Size = New System.Drawing.Size(78, 21)
        Me.radioBetTypeWinner.TabIndex = 20
        Me.radioBetTypeWinner.TabStop = True
        Me.radioBetTypeWinner.Text = "Vinnare"
        Me.radioBetTypeWinner.UseVisualStyleBackColor = True
        '
        'radioBetTypePlace
        '
        Me.radioBetTypePlace.AutoSize = True
        Me.radioBetTypePlace.Location = New System.Drawing.Point(12, 66)
        Me.radioBetTypePlace.Name = "radioBetTypePlace"
        Me.radioBetTypePlace.Size = New System.Drawing.Size(60, 21)
        Me.radioBetTypePlace.TabIndex = 21
        Me.radioBetTypePlace.TabStop = True
        Me.radioBetTypePlace.Text = "Plats"
        Me.radioBetTypePlace.UseVisualStyleBackColor = True
        '
        'groupBetType
        '
        Me.groupBetType.Controls.Add(Me.radioBetTypeWinner)
        Me.groupBetType.Controls.Add(Me.radioBetTypePlace)
        Me.groupBetType.Dock = System.Windows.Forms.DockStyle.Left
        Me.groupBetType.Location = New System.Drawing.Point(3, 18)
        Me.groupBetType.Name = "groupBetType"
        Me.groupBetType.Size = New System.Drawing.Size(112, 156)
        Me.groupBetType.TabIndex = 22
        Me.groupBetType.TabStop = False
        Me.groupBetType.Text = "Speltyp"
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(288, 101)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(20, 17)
        Me.Label1.TabIndex = 23
        Me.Label1.Text = "%"
        '
        'textBetAmount
        '
        Me.textBetAmount.Location = New System.Drawing.Point(274, 88)
        Me.textBetAmount.Name = "textBetAmount"
        Me.textBetAmount.Size = New System.Drawing.Size(63, 22)
        Me.textBetAmount.TabIndex = 24
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.textWinPercent)
        Me.GroupBox1.Controls.Add(Me.textWinAmount)
        Me.GroupBox1.Controls.Add(Me.textNmbrWins)
        Me.GroupBox1.Controls.Add(Me.textSumBetAmount)
        Me.GroupBox1.Controls.Add(Me.textNmbrRaces)
        Me.GroupBox1.Controls.Add(Me.Label5)
        Me.GroupBox1.Controls.Add(Me.Label1)
        Me.GroupBox1.Controls.Add(Me.Label4)
        Me.GroupBox1.Controls.Add(Me.Label3)
        Me.GroupBox1.Controls.Add(Me.Label2)
        Me.GroupBox1.Location = New System.Drawing.Point(431, 36)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Size = New System.Drawing.Size(312, 145)
        Me.GroupBox1.TabIndex = 25
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "Resultat"
        '
        'textWinAmount
        '
        Me.textWinAmount.Location = New System.Drawing.Point(122, 102)
        Me.textWinAmount.Name = "textWinAmount"
        Me.textWinAmount.Size = New System.Drawing.Size(95, 22)
        Me.textWinAmount.TabIndex = 28
        '
        'textNmbrWins
        '
        Me.textNmbrWins.Location = New System.Drawing.Point(122, 74)
        Me.textNmbrWins.Name = "textNmbrWins"
        Me.textNmbrWins.Size = New System.Drawing.Size(95, 22)
        Me.textNmbrWins.TabIndex = 27
        '
        'textSumBetAmount
        '
        Me.textSumBetAmount.Location = New System.Drawing.Point(122, 50)
        Me.textSumBetAmount.Name = "textSumBetAmount"
        Me.textSumBetAmount.Size = New System.Drawing.Size(95, 22)
        Me.textSumBetAmount.TabIndex = 26
        '
        'textNmbrRaces
        '
        Me.textNmbrRaces.Location = New System.Drawing.Point(122, 21)
        Me.textNmbrRaces.Name = "textNmbrRaces"
        Me.textNmbrRaces.Size = New System.Drawing.Size(95, 22)
        Me.textNmbrRaces.TabIndex = 25
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(18, 74)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(90, 17)
        Me.Label5.TabIndex = 3
        Me.Label5.Text = "Antal vinster:"
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(18, 107)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(90, 17)
        Me.Label4.TabIndex = 2
        Me.Label4.Text = "Vinstbelopp: "
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(18, 50)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(103, 17)
        Me.Label3.TabIndex = 1
        Me.Label3.Text = "Spelat belopp: "
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(18, 22)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(99, 17)
        Me.Label2.TabIndex = 0
        Me.Label2.Text = "Spelade lopp: "
        '
        'GroupBox2
        '
        Me.GroupBox2.Controls.Add(Me.Label6)
        Me.GroupBox2.Controls.Add(Me.textTotNmbrRaces)
        Me.GroupBox2.Controls.Add(Me.groupBetType)
        Me.GroupBox2.Controls.Add(Me.GroupBox1)
        Me.GroupBox2.Controls.Add(Me.butttonBet)
        Me.GroupBox2.Controls.Add(Me.textBetAmount)
        Me.GroupBox2.Dock = System.Windows.Forms.DockStyle.Bottom
        Me.GroupBox2.Location = New System.Drawing.Point(0, 427)
        Me.GroupBox2.Name = "GroupBox2"
        Me.GroupBox2.Size = New System.Drawing.Size(996, 177)
        Me.GroupBox2.TabIndex = 26
        Me.GroupBox2.TabStop = False
        Me.GroupBox2.Text = "Spela"
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(192, 57)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(79, 17)
        Me.Label6.TabIndex = 27
        Me.Label6.Text = "Antal lopp: "
        '
        'textTotNmbrRaces
        '
        Me.textTotNmbrRaces.Location = New System.Drawing.Point(274, 53)
        Me.textTotNmbrRaces.Name = "textTotNmbrRaces"
        Me.textTotNmbrRaces.Size = New System.Drawing.Size(63, 22)
        Me.textTotNmbrRaces.TabIndex = 26
        '
        'textWinPercent
        '
        Me.textWinPercent.Location = New System.Drawing.Point(233, 101)
        Me.textWinPercent.Name = "textWinPercent"
        Me.textWinPercent.Size = New System.Drawing.Size(48, 22)
        Me.textWinPercent.TabIndex = 29
        '
        'RaceBetSim
        '
        Me.ClientSize = New System.Drawing.Size(996, 604)
        Me.Controls.Add(Me.groupTop)
        Me.Controls.Add(Me.GroupBox2)
        Me.Name = "RaceBetSim"
        Me.groupTop.ResumeLayout(False)
        Me.groupTopBottom.ResumeLayout(False)
        Me.groupTopBottom.PerformLayout()
        Me.groupSelectionType.ResumeLayout(False)
        Me.groupSelectionType.PerformLayout()
        Me.groupStartType.ResumeLayout(False)
        Me.groupStartType.PerformLayout()
        CType(Me.gridRaces, System.ComponentModel.ISupportInitialize).EndInit()
        Me.groupBetType.ResumeLayout(False)
        Me.groupBetType.PerformLayout()
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.GroupBox2.ResumeLayout(False)
        Me.GroupBox2.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Private _IsLoaded As Boolean = False
    Private _NmbrWinners As Integer = 0
    Private _NmbrBets As Integer = 0
    Private _BetAmount As Decimal = 0
    Private _SumBetAmount As Decimal = 0
    Private _WinAmount As Decimal = 0


    Public Enum RaceSelectionType
        Place
        Winner
        StartPos
    End Enum

    Public Enum BetType
        Place
        Winner
    End Enum

    Public Sub New()
        MyBase.New()
        InitializeComponent()
    End Sub

    Private Sub CheckEnableStartPosTextBox()
        textStartPos.Enabled = radioStartpos.Checked
    End Sub

    Private Function GetSelectionType() As RaceSelectionType
        If radioStartpos.Checked Then
            Return RaceSelectionType.StartPos
        ElseIf radioPlace.Checked Then
            Return RaceSelectionType.Place
        Else
            Return RaceSelectionType.Winner
        End If
    End Function

    Private Function GetBetType() As BetType
        If radioBetTypePlace.Checked Then
            Return BetType.Place
        Else
            Return BetType.Winner
        End If
    End Function

    Private Function GetStartType() As StatForm.StartType
        If radioAuto.Checked Then
            Return StatForm.StartType.Auto
        ElseIf radioVolt.Checked Then
            Return StatForm.StartType.Volt
        Else
            Return StatForm.StartType.Ignore
        End If
    End Function

    Private Sub buttonShowRaces_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonShowRaces.Click
        Dim sql As String = GetRaceSql(comboTracks.SelectedItem.ToString, dpStartdate.Value, dpEndDate.Value, GetSelectionType(), GetStartType(), textStartPos.Text)
        gridRaces.ExecuteSql(MyBase.DbConnection, sql)
        textTotNmbrRaces.Text = gridRaces.Rows.Count.ToString
    End Sub


    Private Function GetRaceSql(ByVal trackName As String, ByVal startDate As Date, ByVal endDate As Date, ByVal selType As RaceSelectionType, _
                                ByVal startType As StatForm.StartType, ByVal startPositions As String) As String
        Dim startTypeClause As String
        Dim sql As String = "SELECT race.date as RaceDate, race.track,race.id as RaceId,horse.name, ekipage.* FROM ekipage " & _
                             "JOIN race_ekipage ON (race_ekipage.ekipage_id = ekipage.id) " & _
                             "JOIN race ON (race_ekipage.race_id = race.id) " & _
                             "JOIN horse ON (ekipage.horse_id = horse.id) " & _
                             "WHERE (race.track = " & DbInterface.DbConnection.SqlBuildValueString(trackName) & ") " & _
                               "AND (race.date >= " & DbConnection.DateToSqlString(startDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ") " & _
                               "AND (race.date <= " & DbConnection.DateToSqlString(endDate, DbInterface.DbConnection.DateFormatMode.DateOnly) & ") "

        startTypeClause = StatForm.GetStartTypeClause(GetStartType())
        If (startTypeClause.Length > 0) Then
            sql &= "AND " & startTypeClause & " "
        End If

        Select Case selType
            Case RaceSelectionType.Place
                sql &= "AND (ekipage.finish_place in (1,2,3)) "
            Case RaceSelectionType.Winner
                sql &= "AND (ekipage.finish_place = 1) "
            Case RaceSelectionType.StartPos
                sql &= "AND (ekipage.start_place in (" & startPositions & ")) "
        End Select

        sql &= "ORDER BY race.date ASC, race.id,ekipage.start_place"

        Return sql
    End Function

    Private Sub ResetCounters()
        _SumBetAmount = 0
        _NmbrBets = 0
        _NmbrWinners = 0
        _WinAmount = 0
        textSumBetAmount.Text = ""
        textNmbrWins.Text = ""
        textNmbrRaces.Text = ""
        textWinAmount.Text = ""
    End Sub

    Private Sub BetRaces()
        Dim betType As BetType = GetBetType()

        For i = 0 To gridRaces.Rows.Count - 1
            Dim currRow As DataGridViewRow = gridRaces.Rows(i)
            Dim currCell As DataGridViewCell = Nothing

            currCell = currRow.Cells("raceid")
            Dim raceId As Integer = BaseGrid.GetCellIntValue(currCell)

            currCell = currRow.Cells("finish_place")
            Dim finishPlace As Integer = BaseGrid.GetCellIntValue(currCell)

            Dim odds As Decimal = 0
            Dim aWinner As Boolean = False
            Select Case betType
                Case betType.Winner
                    If (finishPlace = 1) Then
                        currCell = currRow.Cells("winner_odds")
                        odds = BaseGrid.GetCellDecimalValue(currCell)
                        aWinner = True
                    End If
                Case betType.Place
                    If (finishPlace >= 1) And (finishPlace <= 3) Then
                        currCell = currRow.Cells("place_odds")
                        odds = BaseGrid.GetCellDecimalValue(currCell)
                        aWinner = True
                    End If
            End Select

            _NmbrBets += 1
            textNmbrRaces.Text = _NmbrBets.ToString
            _SumBetAmount += _BetAmount
            textSumBetAmount.Text = _SumBetAmount.ToString

            If aWinner Then
                _NmbrWinners += 1
                textNmbrWins.Text = _NmbrWinners.ToString
                _WinAmount += (odds * _BetAmount)
                textWinAmount.Text = _WinAmount.ToString
            End If

            Application.DoEvents()
        Next
    End Sub

    Private Sub butttonBet_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butttonBet.Click
        ResetCounters()
        Dim bet As Decimal = CType(textBetAmount.Text, Decimal)
        If (bet > 0) Then
            _BetAmount = bet
            BetRaces()
            Dim winPercent As Decimal = 100.0 * (_WinAmount / _SumBetAmount)
            textWinPercent.Text = Decimal.Round(winPercent, 2).ToString
        End If
    End Sub

    Private Sub radioStartpos_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles radioStartpos.CheckedChanged
        If _IsLoaded Then
            CheckEnableStartPosTextBox()
        End If
    End Sub

    Private Sub radioWinner_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles radioWinner.CheckedChanged
        If _IsLoaded Then
            CheckEnableStartPosTextBox()
        End If
    End Sub

    Private Sub radioPlace_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles radioPlace.CheckedChanged
        If _IsLoaded Then
            CheckEnableStartPosTextBox()
        End If
    End Sub

    Private Sub RaceBetSim_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        StatForm.FillTracksComboBox(MyBase.DbConnection, comboTracks)
        comboTracks.SelectedIndex = 0
        dpEndDate.Value = Today
        dpStartdate.Value = Today
        radioVolt.Checked = True
        radioPlace.Checked = True
        radioBetTypePlace.Checked = True
        CheckEnableStartPosTextBox()
        textBetAmount.Text = "10"
        textNmbrRaces.Text = "0"
        textNmbrWins.Text = "0"
        textSumBetAmount.Text = "0"
        textWinAmount.Text = "0"
        textTotNmbrRaces.Text = "0"
        _IsLoaded = True
    End Sub

End Class
