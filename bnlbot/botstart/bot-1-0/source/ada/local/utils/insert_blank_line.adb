with Stacktrace;
with Types; use Types;
--with General_Routines; use General_Routines;
with GNAT; use GNAT;
with GNAT.AWK;
with Text_Io; use Text_Io;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;

procedure Insert_Blank_Line is
  Computer_File : AWK.Session_Type;
  Config        : Command_Line_Configuration;
  Sa_Par_Infile   : aliased Gnat.Strings.String_Access; 
  Last_Value : FLoat_8 := 0.0;  
  -----------------------------------------------------    
begin
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Infile'access,
     Long_Switch => "--input_file=",
     Help        => "what file to read from");
     
  Getopt (Config);  -- process the command line
  
  if Sa_Par_Infile.all = "" then
    Display_Help (Config);
    return;
  end if;
     
  AWK.Set_Current (Computer_File);
  AWK.Open (Separators => "|",  
            Filename   => Sa_Par_Infile.all);
 
  while not AWK.End_Of_File loop
    AWK.Get_Line;
    if Trim(AWK.Field(1)) /= "" and then Float_8'Value(AWK.Field(1)) < Last_Value then
      Put_Line("");  
      Last_Value := 0.0;   
    else
      Last_Value := Float_8'Value(AWK.Field(1));   
    end if;  
    Put_Line(AWK.Field(0)); -- whole line      
  end loop;  
  AWK.Close (Computer_File);
exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Insert_Blank_Line;
