
with GNAT; use GNAT;
with GNAT.AWK;
with Types; use Types;
with Text_Io; use Text_Io;
with Logging; use Logging;
with Ada.Exceptions;
with Ada.Command_Line;
with Stacktrace;
with Calendar2; use Calendar2;
with Repository_Types;

procedure Knockout is

  ---------------------------------------------------------
  function To_Time2(S2: String) return Calendar2.Time_Type is
    Tmp : Time_Type;
    S : String (1 .. S2'Length) := S2;
  begin
    -- '2014-03-22'
    Tmp.Year  := Year_Type'Value (S (1 .. 4));
    Tmp.Month := Month_Type'Value (S (6 .. 7));
    Tmp.Day   := Day_Type'Value (S (9 .. 10));
  
    Tmp.Hour        := 0;
    Tmp.Minute      := 0;
    Tmp.Second      := 0;
    Tmp.MilliSecond := 0;
    return Tmp;
  end To_Time2;
  ---------------------------------------------------------
  function To_Time(S2: String) return Calendar2.Time_Type is
    Tmp : Time_Type;
    S : String (1 .. S2'Length) := S2;
    
    function Mon(S:String) return Month_Type is
      Tmp : Repository_Types.String_Object;
    begin
      Tmp.Set(S);
      if Tmp.Lower_Case = "jan" then return 1;  end if;
      if Tmp.Lower_Case = "feb" then return 2;  end if;
      if Tmp.Lower_Case = "mar" then return 3;  end if;
      if Tmp.Lower_Case = "apr" then return 4;  end if;
      if Tmp.Lower_Case = "may" then return 5;  end if;
      if Tmp.Lower_Case = "jun" then return 6;  end if;
      if Tmp.Lower_Case = "jul" then return 7;  end if;
      if Tmp.Lower_Case = "aug" then return 8;  end if;
      if Tmp.Lower_Case = "sep" then return 9;  end if;
      if Tmp.Lower_Case = "oct" then return 10; end if;
      if Tmp.Lower_Case = "nov" then return 11; end if;
      if Tmp.Lower_Case = "dec" then return 12; end if;
      raise Program_Error with "Bad month '" & S & "'";  
    end Mon;
    
  begin
    -- 'Mar-03'
    Tmp.Year  := 2000;
    Tmp.Month := Mon(S(1..3));
    Tmp.Day   := Day_Type'Value (S (5 .. 6));
    Tmp.Hour        := 0;
    Tmp.Minute      := 0;
    Tmp.Second      := 0;
    Tmp.MilliSecond := 0;
    return Tmp;
  end To_Time;
  ---------------------------------------------------------

  
  Computer_File : AWK.Session_Type;
  
  Correct_Date,
  First_Date,
  Second_Date : Calendar2.Time_Type;
  
  Diff1,Diff2 : Calendar2.Interval_Type;
  Global_Worst_Guess,
  Best_Guess : Integer_4 := 0;
  
  
begin

  AWK.Set_Current (Computer_File);
  AWK.Open (Separators => "|",
            Filename   => "/home/bnl/knockout.dat");
  while not AWK.End_Of_File loop
    AWK.Get_Line;
    -- Text_io.Put_Line(AWK.Field(1));
    -- get first char
    if AWK.Field(1)(1) = 'Q' then
      Global_Worst_Guess := 0;
      Text_io.Put_Line("--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--"); -- new round
      Text_io.Put(AWK.Field (1) & ":"); -- contender
      Correct_Date := To_Time2(AWK.Field (2));
      Text_Io.New_Line;
      Text_io.Put("Contender"); -- contender
      Text_io.Set_Col(15);
      Text_io.Put("Entered Date");
      Text_io.Set_Col(28);
      Text_io.Put("First Date");
      Text_io.Set_Col(41);
      Text_io.Put("Second Date");
      Text_io.Set_Col(53);
      Text_io.Put("Diff1");
      Text_io.Set_Col(59);
      Text_io.Put("Diff2");
      Text_io.Set_Col(66);
      Text_io.Put_Line("Best");
      Text_io.Put("--------------------------------------------------------------------- "); -- contender
      Text_Io.New_Line;
    elsif AWK.Field(1)(1) = '-' then -- end of Q
      Text_io.Put_Line("Correct date      : " & String_Date(Correct_Date));
      Text_io.Put_Line("Worst guess off by: " & Global_Worst_Guess'Img);
      Text_Io.New_Line;
    elsif AWK.Field(1)(1) = '#' then -- Comment
      null;
    else 
      Text_io.Put(AWK.Field (1)); -- contender
      First_Date := To_Time(AWK.Field (2));
      First_Date.Year := Correct_Date.Year;
      Second_Date := First_Date;
      if First_Date <= Correct_Date then
        Second_Date.Year := Second_Date.Year + 1;
      else 
        First_Date.Year := First_Date.Year - 1;
      end if;
      Text_io.Set_Col(20);
      Text_io.Put(AWK.Field (2));
      
      Text_io.Set_Col(28);
      Text_io.Put(String_Date(First_Date));
      Text_io.Set_Col(41);
      Text_io.Put(String_Date(Second_Date));
      
      -- sanity checks
      if First_Date > Correct_Date then
        raise Program_Error with "Bad first date";
      end if;
      
      if Correct_Date > Second_Date then
        raise Program_Error with "Bad second date";
      end if;
      
      Diff1 := Correct_Date - First_Date;
      Text_io.Set_Col(53);
      Text_io.Put(Diff1.Days'Img);
     
      Diff2 := Second_Date - Correct_Date;
      Text_io.Set_Col(59);
      Text_io.Put(Diff2.Days'Img);
      
      Best_Guess := Integer_4'Min(Diff1.Days, Diff2.Days);
      Text_io.Set_Col(66);
      Text_io.Put(Best_Guess'Img);
      Global_Worst_Guess := Integer_4'Max(Global_Worst_Guess, Best_Guess); 
      Text_Io.New_Line;
    end if;
  end loop; 
  
  AWK.Close (Computer_File);
exception
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;
    Log("Closed log and die");
    Logging.Close;
  
end Knockout;
