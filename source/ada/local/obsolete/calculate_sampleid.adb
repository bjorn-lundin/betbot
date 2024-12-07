
with Types ; use Types;
--with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Table_Apricesfinish2;
with Gnat.Command_Line; use Gnat.Command_Line;
---with GNAT.Strings;
with Calendar2; -- use Calendar2;
with Logging; use Logging;
with Utils;
with Ada.Containers.Doubly_Linked_Lists;
--with Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

procedure Calculate_Sampleid is


  -- Pricets_Pack
  -- Holds list of all unique pricets

  type Sample_Record is record
    Pricets  : Calendar2.Time_Type := Calendar2.Time_Type_First;
    Sampleid : Integer_4 := 0;
  end record;
    
  package Sample_Pack is new Ada.Containers.Doubly_Linked_Lists(Sample_Record);
 
  Global_Sample_List : Sample_Pack.List;
  

   T                  : Sql.Transaction_Type;
   Select_All_Markets : Sql.Statement_Type;

   Config           : Command_Line_Configuration;

   IA_Max_Start_Price : aliased Integer := 30;
   IA_Lay_At_Price    : aliased Integer := 100;
   IA_Max_Lay_Price   : aliased Integer := 200;

   
   --------------------------------------------------------------------------
   
begin
  Define_Switch
    (Config      => Config,
     Output      => IA_Max_Start_Price'access,
     Long_Switch => "--max_start_price=",
     Help        => "starting price (back)(");

  Define_Switch
    (Config      => Config,
     Output      => Ia_Lay_At_Price'access,
     Long_Switch => "--lay_at_price=",
     Help        => "Lay the runner at this price(Back)");

  Define_Switch
    (Config      => Config,
     Output      => IA_Max_Lay_Price'access,
     Long_Switch => "--max_lay_price=",
     Help        => "Runner cannot have higer price that this when layed (Lay)");

  Getopt (Config);  -- process the command line

--     if Ia_Best_Position = 0 or else
--       Ia_Max_Odds = 0 then
--       Display_Help (Config);
--       return;
--     end if;

  Log ("Connect db");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "dry",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");

  T.Start;
  Select_All_Markets.Prepare (
    "select distinct(PF.PRICETS) " &
    "from APRICESFINISH2 PF " &
    "order by PF.PRICETS");               
    
  Log("fill list with all unique marketids ");                           
  declare
    Eos : Boolean := False;
    SR  : Sample_Record;
  begin                          
    Select_All_Markets.Open_Cursor;
    loop
      Select_All_Markets.Fetch(Eos);
      exit when Eos;
      Select_All_Markets.Get_Timestamp(1,Sr.Pricets);      
      Global_Sample_List.Append(Sr);
    end loop;  
    Select_All_Markets.Close_Cursor;
  end; 
  T.Commit ;
  
  Log("start process");      
  declare
    Cnt : Integer := 0;
    Total : Integer := Integer(Global_Sample_List.Length);
    Previous_Sample : Sample_Record;
    use Calendar2;
  begin
    for S of Global_Sample_List loop   
      Cnt := Cnt+1;
      if Cnt mod 1000 = 0 then
        Log (Utils.F8_Image(Float_8(100.0 * Float_8(Cnt) / Float_8(Total))));
      end if;  
      if S.Pricets - Previous_Sample.Pricets < (0,0,0,0,5) then  -- 5 ms
        -- got 2 pricets in 1 sample...
        Log("got 2 pricets in 1 sample" & 
            Calendar2.String_Date_Time_ISO(Previous_Sample.Pricets, T => " " , Tz => "") & 
            " " &
            Calendar2.String_Date_Time_ISO(S.Pricets, T => " " , Tz => ""));
      else
        S.Sampleid := Integer_4(Cnt); -- update list
      end if;        
    end loop;  -- Global_Sample_List
  end;   
  
  Log("start update");      
  declare   
    Update_Pricets : Sql.Statement_Type;
    Cnt : Integer := 0;
    Total : Integer := Integer(Global_Sample_List.Length);
   begin   
    T.Start;
    Update_Pricets.Prepare(
      "update APRICESFINISH2 set SAMPLEID = :SAMPLEID where PRICETS = :PRICETS");
    for S of Global_Sample_List loop 
      Cnt := Cnt+1;
      if Cnt mod 1000 = 0 then
       Log ( Cnt'Img & "/" & Total'Img & " -> " & Utils.F8_Image(Float_8(100.0 * Float_8(Cnt) / Float_8(Total))) & " %");
      end if;        
      Update_Pricets.Set("SAMPLEID", S.Sampleid);
      Update_Pricets.Set("PRICETS", S.Pricets);
      Update_Pricets.Execute;
    end loop;  -- Global_Sample_List
    T.Commit ;
  end;   
  Log("done update");      
  
  Global_Sample_List.Clear;
  Log("used --max_start_price=" & IA_Max_Start_Price'Img &
    " --lay_at_price=" & IA_Lay_At_Price'Img &
    " --max_lay_price=" & IA_Max_Lay_Price'Img);
  Sql.Close_Session;
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Calculate_Sampleid;
