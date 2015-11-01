Public Class Form1

  Private Function CreateDateNode(d As Date) As TreeNode
    Dim dateNode As TreeNode = New TreeNode

    dateNode.Tag = d
    dateNode.Text = d.ToShortDateString

    Return dateNode
  End Function

  Private Sub Form1_Load(sender As Object, e As System.EventArgs) Handles Me.Load
    Dim topNode As TreeNode = New TreeNode
    Dim dateNode As TreeNode

    topNode.Name = "TopNode"
    topNode.Text = "MaMa"

    TreeView1.Nodes.Add(topNode)


    dateNode = CreateDateNode(Today)
    topNode.Nodes.Add(dateNode)
    dateNode.Nodes.Add("MAMA race")
    dateNode.Nodes.Add("BNL race")

    topNode.Nodes.Add(CreateDateNode(Today.AddDays(1)))
    topNode.Nodes.Add(CreateDateNode(Today.AddDays(2)))


  End Sub

  Private Sub TreeView1_AfterSelect(sender As Object, e As System.Windows.Forms.TreeViewEventArgs) Handles TreeView1.AfterSelect
    If (sender IsNot Nothing) Then
      Dim s As TreeNode = e.Node
    End If

  End Sub

  Private Sub TreeView1_Click(sender As Object, e As System.EventArgs) Handles TreeView1.Click
    If (sender IsNot Nothing) Then
      Dim s As TreeNode = CType(sender, TreeView).SelectedNode
    End If
  End Sub
End Class
