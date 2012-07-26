Imports BaseComponents
Imports NoNoBetComponents
Imports System
Imports System.Data
Imports System.Windows.Forms
Imports System.Xml
Imports System.IO
Imports Npgsql
Imports DbInterface
Imports DbInterface.DbConnection
Imports Microsoft.Win32

Public Class DbConnectionForm

    Private _IsLoaded As Boolean
    Private _XmlReadar As XmlReader
    Private _XmlWriter As XmlWriter
    Private _ApplicationPath As String
    Private _ResultOk As Boolean = False
    Private _DbConnectionString1 As String = "Server=127.0.0.1;Port=5432;User Id=pokerheroes;Password=pokerheroes;Database=pokerheroes;"
    Private _DbConnectionString2 As String = "Server=Db.nonobet.com;Port=5432;User Id=kalle;Password=kalle;Database=kalle;"
    Private _DbConnectionString3 As String = "Server=nonobet.com;Port=5432;User Id=nonobetmats;Password=nonoBET0088;Database=mats_test_01;SSL=True;"
    Private _DbConnectionString4 As String = "Server=nonobet.com;Port=5432;User Id=nonobetmats;Password=nonoBET0088;Database=nonobet_data;SSL=True;Preload Reader=True;"
    Private _DbConnectionString5 As String = "Server=localhost;Port=5432;User Id=test-db;Password=test-db;Database=test-db;Preload Reader=True;"
    Private WithEvents _DbConn As DbConnection

    Public ReadOnly Property GetDbConnection As DbConnection
        Get
            Return _DbConn
        End Get
    End Property

    Public Function ExeceuteDialog(ByVal applicationPath As String) As Boolean
        _ApplicationPath = applicationPath
        Me.StartPosition = FormStartPosition.CenterScreen
        Me.ShowDialog()

        If _ResultOk And (_DbConn IsNot Nothing) Then
            Return True
        End If
        '_DbConn.Close()
        '_DbConn.Dispose()
        '_DbConn = Nothing
    End Function



    Private Sub GetVersion()
        'Dim dbCmd As NpgsqlCommand = _DbConn.NewCommand("SELECT version()")
        Try
            txtVersionBySql.Text = _DbConn.VersionLong
            txtVersionByProp.Text = _DbConn.VersionShort
        Catch ex As Exception
            MsgBox("Execute command error: " + ex.Message)
            txtVersionBySql.Text = ""
        Finally
        End Try

    End Sub

    Private Sub UpdateConnectionData()
        If (_DbConn IsNot Nothing) Then
            If ((_DbConn.State <> ConnectionState.Closed) And _
                (_DbConn.State <> ConnectionState.Broken)) Then

                txtCondition.Text = _DbConn.State.ToString
                txtPID.Text = _DbConn.PID.ToString
                GetVersion()
                Return
            End If
        End If

        txtCondition.Text = ""
        txtPID.Text = ""
        txtVersionBySql.Text = ""
    End Sub

    Private Sub btnConnect_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnConnect.Click
        If Not (_DbConn Is Nothing) Then
            _DbConn.Close()
            _DbConn.Dispose()
            _DbConn = Nothing
        End If
        Dim conStr As String = "Server=localhost;Port=5432;User Id=nonobetmats;Password=nonobet0088;Database=nonobet-testdb;Preload Reader=True;"
        _DbConn = New DbConnection(conStr)
        '_DbConn = New DbConnection(CType(cboConnection.SelectedItem, String))
        _DbConn.Open()
        UpdateConnectionData()
    End Sub

    Private Sub _DbConn_Notification(ByVal sender As Object, ByVal e As DbInterface.DbConnection.DbNotificationEventArgs) Handles _DbConn.Notification
        txtCondition.Text = e.Condition
        txtInfo.Text = e.Information
        txtPID.Text = e.PID.ToString
    End Sub

    Private Sub _DbConn_StateChange(ByVal sender As Object, ByVal e As System.Data.StateChangeEventArgs) Handles _DbConn.StateChange
        MsgBox("DbServer state change! Current state = " & e.CurrentState)
    End Sub

    Private Sub CloseConnection()
        If (_DbConn IsNot Nothing) Then
            _DbConn.Close()
        End If
        UpdateConnectionData()
    End Sub

    Private Sub btnDisconnect_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnDisconnect.Click
        CloseConnection()
    End Sub

    Private Sub btnBrowse_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnBrowse.Click
        Dim raceDaysFrm As RaceDaysForm = New RaceDaysForm
        raceDaysFrm.StartForm(_DbConn)

    End Sub

    Private Sub btnTest_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnTest.Click
        Dim testFrm As TestForm = New TestForm
        testFrm.StartForm(_DbConn)

    End Sub

    Private Sub buttonStats_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonStats.Click
        Dim statFrm As StatForm = New StatForm
        statFrm.StartForm(_DbConn)
    End Sub

    Private Sub buttonClose_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonClose.Click
        CloseConnection()
        Me.Close()
    End Sub

    Private Sub DbConnectionForm_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        txtHeader.Text = "Application path: " + _ApplicationPath
        cboConnection.Items.Add(_DbConnectionString5)
        cboConnection.Items.Add(_DbConnectionString4)
        cboConnection.Items.Add(_DbConnectionString3)
        cboConnection.Items.Add(_DbConnectionString2)
        cboConnection.Items.Add(_DbConnectionString1)
        cboConnection.SelectedIndex = 0
        txtCondition.Text = ""
        txtInfo.Text = ""
        txtPID.Text = ""
        'LoadSites()

        Dim conString As DbConnectionString = New DbConnectionString
        Dim dbConDialog As DbConnectionDialog = New DbConnectionDialog
        dbConDialog.StartDialog(conString)


        _IsLoaded = True
    End Sub

    Private Sub buttonBetSim_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles buttonBetSim.Click
        Dim betSimForm As RaceBetSim = New RaceBetSim
        betSimForm.StartForm(_DbConn)
    End Sub

    Private Sub btnRaceDays_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnRaceDays.Click
        Dim rFrm As RaceSelectForm = New RaceSelectForm
        rFrm.StartForm(_DbConn)
    End Sub
End Class