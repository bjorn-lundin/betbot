with Stacktrace;
with Types; use Types;
with Calendar2; use Calendar2;
--with General_Routines; use General_Routines;
with Ada.Directories; use Ada.Directories;

with GNAT; use GNAT;
with GNAT.AWK;
with Text_Io; use Text_Io;

--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

procedure Prepare_Lay_All_G4_For_Gnuplot is
  ----------------------------------------------
  procedure Treat_File(Filename : String) is
    Computer_File : AWK.Session_Type;
    Some_Date     : Time_Type         := Time_Type_First;
    Sum           : Float_8           := 0.0;
    Path          : String            := Containing_Directory(Filename);
    Output_File : Text_io.File_Type;
  begin
    Text_Io.Put_Line(Text_Io.Standard_Error, Base_Name(Filename));
    AWK.Set_Current (Computer_File);
    AWK.Open (Separators => "|", Filename => Filename);
    Text_Io.Create (File => Output_File,
                    Name => Path & "/dats/" & Base_Name(Filename) & ".dat");
    while not AWK.End_Of_File loop
      AWK.Get_Line;
      declare
        F1 : String := AWK.Field(1);
      begin  
      
        if F1'length >=3 and then F1(1..3) = "Day" then
          declare
            F2 : String := Trim(AWK.Field(2));
          begin  
            Some_Date := To_Time_Type(F1(5..15), "");
            Sum := Sum + Float_8'Value(F2);
            Text_Io.Put_Line(Output_File, String_Date_Iso(Some_Date) & "|" & 
                                          F8_Image(Sum) & "|" & 
                                          F2);
          end;   
        end if;      
      end;           
    end loop;  
    AWK.Close (Computer_File);
    Text_Io.Close (File => Output_File);
  end Treat_File;
  
  -------------------------------  

  Dir_Ent     : Directory_Entry_Type;
  The_Search  : Search_Type;
begin
  Start_Search(Search    => The_Search,
               Directory => "/home/bnl/bnlbot/botstart/bot-1-0/script/bash/log",
               Pattern   => "*.log");
  loop
    exit when not More_Entries(Search => The_Search);
    Get_Next_Entry(Search          => The_Search,
                   Directory_Entry => Dir_Ent);
    Treat_File(Full_Name(Dir_Ent));
  end loop;
  End_Search (Search => The_Search);
exception
  when E: others => Stacktrace.Tracebackinfo(E);  
end Prepare_Lay_All_G4_For_Gnuplot;
