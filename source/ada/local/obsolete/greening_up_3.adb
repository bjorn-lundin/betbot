
with Types; use Types;
with Calendar2; use Calendar2;
--with General_Routines; use General_Routines;
with Ada.Command_Line;      use Ada.Command_Line;

with GNAT; use GNAT;
with GNAT.AWK;
with Text_Io; use Text_Io;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

procedure Greening_Up_3 is
  Computer_File : AWK.Session_Type;
  Race_Start, Old_Race_Start : Calendar2.Time_Type := Calendar2.Time_Type_First;
  Global_Profit, Race_Profit , Runner_Profit : Float_8 := 0.0;
  Count : Integer_4 := 0;
  Is_First_Line : Boolean := True;
  
  Sa_File_Name : aliased Gnat.Strings.String_Access;
  Config : Command_Line_Configuration;

  -----------------------------------------------------  
  function To_Time(S2: String) return Calendar2.Time_Type is
    
    Tmp : Time_Type;
    S : String (1 .. S2'Last - S2'First + 1) := S2; 
    
  begin
    -- '22-01-2013 11:09:06'  
    
    Tmp.Year  := Year_Type'Value (S (1 .. 4));
    Tmp.Month := Month_Type'Value (S (6 .. 7));
    Tmp.Day   := Day_Type'Value (S (9 .. 10));

    Tmp.Hour   := Hour_Type'Value (S (12 .. 13));
    Tmp.Minute := Minute_Type'Value (S (15 .. 16));
    if S'length >= 19 then
      Tmp.Second := Second_Type'Value (S (18 .. 19));
    else
      Tmp.Second := 0;
    end if;  
    Tmp.Millisecond := 0;
    return Tmp;
  end To_Time;
  -----------------------------------------------------  
  
begin

  Define_Switch
    (Config,
     Sa_File_Name'access,
     Long_Switch => "--filename=",
     Help    => "File to open");

  Getopt (Config); -- process the command line
   
  if Sa_File_Name.all = "" then
    Display_Help(Config);
    Set_Exit_Status(Failure);
    return;
  end if;
   
  AWK.Set_Current (Computer_File);
  AWK.Open (Separators => "|",  
            Filename   => Sa_File_Name.all);

  while not AWK.End_Of_File loop
    AWK.Get_Line;
    Race_Start := To_Time(Trim(AWK.Field(1)));
    
    if Is_First_Line then   
      Old_Race_Start := Race_Start;    
      Is_First_Line := False;
    end if;

    Runner_Profit := Float_8'Value(Trim(AWK.Field(12)));
    
    if Race_Start /= Old_Race_Start then
      -- new race/date       
      Put_Line(Calendar2.String_Date_Time_ISO(Old_Race_Start, T => " ", TZ => "") & " | " &   
               Count'Img             & " | " &     
               F8_Image(Race_Profit) & " | " &     
               F8_Image(Global_Profit) ); 
               
      Old_Race_Start := Race_Start;
      Count := 0;
      Race_Profit := 0.0;
    end if;
    Count := Count +1; 
    Race_Profit := Race_Profit + Runner_Profit;          
    Global_Profit := Global_Profit + Runner_Profit;          
  end loop;  
  AWK.Close (Computer_File);
end Greening_Up_3;