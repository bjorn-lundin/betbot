Public MustInherit Class BaseDetailGrid
  Inherits BaseGrid
  Implements IDetailComponent

  Public MustOverride Sub RowChangeHandler(row As System.Windows.Forms.DataGridViewRow) Implements IDetailComponent.RowChangeHandler

End Class
