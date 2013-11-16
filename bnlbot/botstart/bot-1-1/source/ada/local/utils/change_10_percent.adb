
with Sattmate_Types ; use Sattmate_Types;
with Sattmate_Exception;
with Sql;
--with Text_Io;
with Table_History;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;
--with General_Routines; use General_Routines;

with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Change_10_Percent is
    History : Table_History.Data_Type;
    Bad_Input : exception;
                     
    type H_Type is record
      Scheduledoff : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
      Eventid  : Integer_4 := 0;
      Selectionid : Integer_4 := 0;
    end record;     
                     
    package H_Pack is new Simple_List_Class(H_Type);       
    H_List : H_Pack.List_Type := H_Pack.Create;      
    H_Data :H_Type;                       

   T            : Sql.Transaction_Type;
   Select_All,
   Stm_Select_Eventid_Selectionid_O : Sql.Statement_Type;

   Start_Date       : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Stop_Date        : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Stop_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;

   Eos,
   Eos2             : Boolean := False;

   Config           : Command_Line_Configuration;

   Sa_Par_Animal         : aliased Gnat.Strings.String_Access;
   Sa_Par_Start_Date     : aliased Gnat.Strings.String_Access;
   Sa_Par_Stop_Date      : aliased Gnat.Strings.String_Access;
   Ia_Delta_Odds         : aliased Integer := 1;
   
   type Has_Type is (Count,Higher,Lower);
   Has : array (Has_Type'range) of Boolean := (others => False);
   
   type Odds_Interval_Type is (Lower, x5_10, x10_15, x15_20, x20_25, x25_30, x30_35, x35_40, Higher);
   Odds_Interval : Odds_Interval_Type := Lower; 
   
   type Stats_Type is record
     Num_In_Interval : Integer_4 := 0;
     Num_Less        : Integer_4 := 0;
     Num_More        : Integer_4 := 0;
   end record ;
   
   Stats : array (Odds_Interval_Type'range) of Stats_Type;   

begin
   Define_Switch
     (Config      => Config,
      Output      => Sa_Par_Start_Date'access,
      Long_Switch => "--start_date=",
      Help        => "when the data move starts yyyy-mm-dd, inclusive");

   Define_Switch
     (Config      => Config,
      Output      => Sa_Par_Stop_Date'access,
      Long_Switch => "--stop_date=",
      Help        => "when the data move stops yyyy-mm-dd, inclusive");
      
   Define_Switch
     (Config      => Config,
      Output      => Sa_Par_Animal'access,
      Long_Switch => "--animal=",
      Help        => "what animal is racing");
      
   Define_Switch
     (Config      => Config,
      Output      => Ia_Delta_Odds'access,
      Long_Switch => "--delta_odds=",
      Help        => "Wanted odds movement in perce of lower bound");

      
   Getopt (Config);  -- process the command line

   if Sa_Par_Start_Date.all = "" or else 
     Sa_Par_Stop_Date.all = "" or else 
     Sa_Par_Animal.all = "" then
     Display_Help (Config);
     return;
   end if;

   Start_Date := Sattmate_Calendar.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
   Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Par_Start_Date.all, "23:59:59:999");
   Start_Date := Start_Date - Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --remove a day first
   Stop_Date  := Stop_Date  - Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --remove a day first

   Global_Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");

   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bnl",
      Login    => "bnl",
      Password => "bnl");

    Main : loop
      Start_Date := Start_Date + Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --add a day
      Stop_Date  := Stop_Date  + Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --add a day

      Log ("Change_10_Percent - treat date " & String_Date(start_date));

      T.Start;
      
      if Sa_Par_Animal.all = "horse" then  
        Select_All.Prepare (
            "select SCHEDULEDOFF, EVENTID, SELECTIONID from HISTORY " &
            "where SCHEDULEDOFF >= :START " &
            "and SCHEDULEDOFF <= :STOP " &
            "and EVENT <> 'Forecast' " &
            "and EVENT <> 'TO BE PLACED' " &
            "and SPORTSID = 7 " &
            "and FULLDESCRIPTION <> 'Ante Post' " &
   --          "and COUNTRY in ('GBR','IRE','USA','FRA','RSA') " &
            "and COUNTRY in ('GBR') " &
            "and lower(FULLDESCRIPTION) not like '% v %'  " &
            "and lower(FULLDESCRIPTION) not like '%forecast%'  " &
            "and lower(FULLDESCRIPTION) not like '%challenge%'  " &
            "and lower(FULLDESCRIPTION) not like '%fc%'  " &
            "and lower(FULLDESCRIPTION) not like '%daily win%'  " &
            "and lower(FULLDESCRIPTION) not like '%reverse%'  " &
            "and lower(FULLDESCRIPTION) not like '%without%'  " &
            "group by SCHEDULEDOFF, EVENTID, SELECTIONID " &
            "order by SCHEDULEDOFF, EVENTID, SELECTIONID ");
            
      elsif Sa_Par_Animal.all = "hound" then  
        Select_All.Prepare (
            "select SCHEDULEDOFF, EVENTID, SELECTIONID from HISTORY " &
            "where SCHEDULEDOFF >= :START " &
            "and SCHEDULEDOFF <= :STOP " &
            "and EVENT <> 'TO BE PLACED' " &
            "and EVENT <> 'Forecast' " &
            "and SPORTSID = 4339 " &
            "and FULLDESCRIPTION <> 'Ante Post' " &
            "and lower(FULLDESCRIPTION) not like '% v %'  " &
            "and lower(FULLDESCRIPTION) not like '%forecast%'  " &
            "and lower(FULLDESCRIPTION) not like '%challenge%'  " &
            "and lower(FULLDESCRIPTION) not like '%fc%'  " &
            "and lower(FULLDESCRIPTION) not like '%daily win%'  " &
            "and lower(FULLDESCRIPTION) not like '%reverse%'  " &
            "and lower(FULLDESCRIPTION) not like '%without%'  " &
            "group by SCHEDULEDOFF, EVENTID, SELECTIONID " &
            "order by SCHEDULEDOFF, EVENTID, SELECTIONID ");
      else 
        raise Bad_Input with "bad animal: '" & Sa_Par_Animal.all & "'";
      end if;       

      Select_All.Set_Timestamp("START", Start_date);
      Select_All.Set_Timestamp("STOP",  Stop_date);
   
--      Text_IO.Put_Line(Text_IO.Standard_Error,"--------------------------");
      Select_All.Open_Cursor;
      loop
        Select_All.Fetch(Eos);
        exit when Eos;
        Select_All.Get_Timestamp("SCHEDULEDOFF", H_Data.Scheduledoff);
        Select_All.Get("EVENTID", H_Data.Eventid);
        Select_All.Get("SELECTIONID", H_Data.Selectionid);
        H_Pack.Insert_At_Tail(H_List,H_Data);
      end loop;        
      Select_All.Close_Cursor;      
      Stm_Select_Eventid_Selectionid_O.Prepare( "select * " & 
            "from HISTORY " &
            "where EVENTID = :EVENTID " &
            "and SELECTIONID = :SELECTIONID " &
            "order by FIRSTTAKEN"  ) ;

      Loop_All : while not H_Pack.Is_Empty(H_List) loop
          H_Pack.Remove_From_Head(H_List, H_Data);           
          Stm_Select_Eventid_Selectionid_O.Set("EVENTID", H_Data.Eventid);
          Stm_Select_Eventid_Selectionid_O.Set("SELECTIONID", H_Data.Selectionid);
          Stm_Select_Eventid_Selectionid_O.Open_Cursor;
          History := Table_History.Empty_Data;
          
          Has := (others => False);
          Loop_Runner : loop
          
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos2);
            exit Loop_Runner when Eos2;
            History := Table_History.Get(Stm_Select_Eventid_Selectionid_O);
            if History.Scheduledoff - History.Firsttaken  >= (0,1,0,0,0) and then 
               History.Scheduledoff - History.Latesttaken <= (0,1,0,0,0) and then
               History.Inplay = "PE"  and then  
               not Has(Count) then -- ca 20_000 secs

               
              -- use start odds  
              if History.Odds < 5.0 then  
                Odds_Interval := Lower;
              elsif 5.0 < History.Odds and History.Odds < 10.0 then  
                Odds_Interval := x5_10;
              elsif 10.0 < History.Odds and History.Odds < 15.0 then  
                Odds_Interval := x10_15;
              elsif 15.0 < History.Odds and History.Odds < 20.0 then  
                Odds_Interval := x15_20;
              elsif 20.0 < History.Odds and History.Odds < 25.0 then  
                Odds_Interval := x20_25;
              elsif 25.0 < History.Odds and History.Odds < 30.0 then  
                Odds_Interval := x25_30;
              elsif 30.0 < History.Odds and History.Odds < 35.0 then  
                Odds_Interval := x30_35;
              elsif 35.0 < History.Odds and History.Odds < 40.0 then  
                Odds_Interval := x35_40;
              else
                Odds_Interval := Higher;
              end if;

--              Log("cn " &Table_History.To_String(History)); 
               
              Stats(Odds_Interval).Num_In_Interval := Stats(Odds_Interval).Num_In_Interval +1;
              Has(Count) := True;              
            end if;  
              
            if History.Firsttaken + (0,1,0,0,0) >= History.Scheduledoff and then 
--               History.Inplay = "PE"  and then -- before start 
               Has(Count) then
            
              if not Has(Lower) then
--                 Log("lo " & Table_History.To_String(History)); 
                 case Odds_Interval is
                   when x5_10 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 5.0 then
--                     if History.Odds < 4.5 then
                       Has(Lower) := True;
                     end if;
                   when x10_15 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 10.0 then
--                     if History.Odds < 9.0 then
                       Has(Lower) := True;
                     end if;
                   when x15_20 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 15.0 then
--                     if History.Odds < 13.5 then
                       Has(Lower) := True;
                     end if;
                   when x20_25 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 20.0 then
--                     if History.Odds < 18.0 then
                       Has(Lower) := True;
                     end if;
                   when x25_30 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 25.0 then
--                     if History.Odds < 22.5 then
                       Has(Lower) := True;
                     end if;
                   when x30_35 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 30.0 then
--                     if History.Odds < 27.0 then
                       Has(Lower) := True;
                     end if;
                   when x35_40 =>
                     if History.Odds < (Float_8(100 - Ia_Delta_Odds) / 100.0) * 40.0 then
--                     if History.Odds < 36.0 then
                       Has(Lower) := True;
                     end if;
                   when others => null;
                 end case;                         
                 if Has(Lower) then
                   Stats(Odds_Interval).Num_Less := Stats(Odds_Interval).Num_Less +1;
                 end if;
               end if;  
                 
              if not Has(Higher) then
--                 Log("hi " & Table_History.To_String(History)); 
                 case Odds_Interval is
                   when x5_10 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 5.0 then
--                     if History.Odds > 5.5 then
                       Has(Higher) := True;
                     end if;
                   when x10_15 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 10.0 then
--                     if History.Odds > 11.0 then
                       Has(Higher) := True;
                     end if;
                   when x15_20 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 15.0 then
--                     if History.Odds > 16.5 then
                       Has(Higher) := True;
                     end if;
                   when x20_25 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 20.0 then
--                     if History.Odds > 22.0 then
                       Has(Higher) := True;
                     end if;
                   when x25_30 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 25.0 then
--                     if History.Odds > 27.5 then
                       Has(Higher) := True;
                     end if;
                   when x30_35 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 30.0 then
--                     if History.Odds > 33.0 then
                       Has(Higher) := True;
                     end if;
                   when x35_40 =>
                     if History.Odds > (Float_8(100 + Ia_Delta_Odds) / 100.0) * 40.0 then
--                     if History.Odds > 38.5 then
                       Has(Higher) := True;
                     end if;
                   when others => null;
                 end case;  

                 if Has(Higher) then
                   Stats(Odds_Interval).Num_More := Stats(Odds_Interval).Num_More +1;
                 end if;
               end if;  
            end if;
       
            exit Loop_Runner when Has(Higher) and Has(Lower) and Has(Count);
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
         --new runner ...
          
         
      end loop Loop_All;
      T.Commit ;
      exit Main when     Start_Date.Year  = Global_Stop_Date.Year
                and then Start_Date.Month = Global_Stop_Date.Month
                and then Start_Date.Day   = Global_Stop_Date.Day;
      for i in Stats'range loop  
        Log(i'Img & Stats(i).Num_In_Interval'Img & Stats(i).Num_More'Img  & Stats(i).Num_Less'Img  );        
      end loop;   
--      exit Main; --if tesxt one only
   end loop Main;

   Sql.Close_Session;

   for i in Stats'range loop  
     Log(i'Img & Stats(i).Num_In_Interval'Img & Stats(i).Num_More'Img  & Stats(i).Num_Less'Img  );        
   end loop;   
exception
   when E: others =>
      Sattmate_Exception.Tracebackinfo(E);
end Change_10_Percent;
