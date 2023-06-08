Public Class MainForm
    Public oraconn
    Public orarec
    Private sqlz As String
    Private row_iterator As Integer

    Private Sub mainForm_Load(sender As Object, e As EventArgs) Handles MyBase.Load

        myNewSub()

    End Sub

    Private Sub myNewSub()

        Initialize_connection()
        orarec.Open(My.Resources.sql1_Неупаковані_лотки, oraconn)
        row_iterator = 0
        Do Until orarec.EOF
            DataGridView1.Rows.Add(orarec.Fields("day2").Value,
                                   orarec.Fields("dep").Value,
                                   orarec.Fields("not_lotok").Value,
                                   orarec.Fields("lotok").Value,
                                   orarec.Fields("otobr_not_upak").Value,
                                   orarec.Fields("otobr_upak").Value,
                                   orarec.Fields("vsego").Value)
            If orarec.Fields("prosr").Value = 1 Then DataGridView1.Rows(row_iterator).DefaultCellStyle.BackColor = Color.Yellow
            If orarec.Fields("dep").Value Is DBNull.Value Then DataGridView1.Rows(row_iterator).DefaultCellStyle.BackColor = Color.Cyan
            row_iterator = row_iterator + 1
            orarec.MoveNext()
        Loop
        Me.DataGridView1.Refresh()
        DataGridView1.AllowUserToAddRows = False

        orarec.Close()
        oraconn.close()


    End Sub

    Private Sub Initialize_connection()
        oraconn = CreateObject("ADODB.Connection")
        orarec = CreateObject("ADODB.Recordset")
        oraconn.Open(My.Resources.db_path)
    End Sub



End Class
