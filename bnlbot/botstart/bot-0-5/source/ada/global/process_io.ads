
package Process_Io is

  subtype Name_Type is String(1..15);

  type Process_Type is record
    Name : Name_Type := (others => ' ');
    Node : Name_Type := (others => ' ');
  end record;


  This_Process : constant Process_Type := ("some_bot       ","localhost      ");

end Process_Io;