
with Types ; use Types;
with Stacktrace;
with Sql;
--with Text_Io;
--with Table_History;
with Table_Aprices;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Calendar2; use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;

with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Lay_All_If_Profitable is
--    History : Table_History.Data_Type;
    Price : Table_Aprices.Data_Type;
    Bad_Input : exception;
                     
    type H_Type is record
      Startts : Calendar2.Time_Type := Calendar2.Time_Type_First;
      Marketid  : String(1..11) := (others => ' ');
    end record;     
                     
    package H_Pack is new Simple_List_Class(H_Type);       
    H_List : H_Pack.List_Type := H_Pack.Create;      
    H_Data :H_Type;                       

   T            : Sql.Transaction_Type;
   Select_All,
   Stm_Select_Eventid_Selectionid_O : Sql.Statement_Type;

   Start_Date       : Calendar2.Time_Type := Calendar2.Time_Type_First;
   Stop_Date        : Calendar2.Time_Type := Calendar2.Time_Type_First;
   Global_Stop_Date : Calendar2.Time_Type := Calendar2.Time_Type_First;

   Eos,
   Eos2             : Boolean := False;

   Config           : Command_Line_Configuration;

   Sa_Par_Animal         : aliased Gnat.Strings.String_Access;
   Sa_Par_Start_Date     : aliased Gnat.Strings.String_Access;
   Sa_Par_Stop_Date      : aliased Gnat.Strings.String_Access;
   Ia_Hours_Before_Start : aliased Integer := 1;
   Ia_Min_Odds           : aliased Integer := 11;
   Ia_Max_Odds           : aliased Integer := 20;
   Ia_Delta_Odds         : aliased Integer := 1;
   
   
   type Outcome_Type is (none,x2,x3,x4,x5,x6,x7,x8,x9,x10);
   
   type Stats_Type is record
     Hits : Integer_4 := 0;
     Profit : Float_8 := 0.0;
   end record ;
   
   Local_Stats  : array (Outcome_Type'range) of Stats_Type := (others => (0,0.0));   
   Global_Stats : array (Outcome_Type'range) of Stats_Type := (others => (0,0.0));

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
      Output      => Ia_Hours_Before_Start'access,
      Long_Switch => "--hours_before_start=",
      Help        => "How hany hours in advance to place the bet");
      
   Define_Switch
     (Config      => Config,
      Output      => Ia_Max_Odds'access,
      Long_Switch => "--max_odds=",
      Help        => "Max odds to accept, inclusive, to place the bet");
      
   Define_Switch
     (Config      => Config,
      Output      => Ia_Min_Odds'access,
      Long_Switch => "--min_odds=",
      Help        => "Min odds to accept, inclusive, to place the bet");

   Define_Switch
     (Config      => Config,
      Output      => Ia_Delta_Odds'access,
      Long_Switch => "--delta_odds=",
      Help        => "Wanted odds movement");

      
   Getopt (Config);  -- process the command line

   if Sa_Par_Start_Date.all = "" or else 
     Sa_Par_Stop_Date.all = "" or else 
     Sa_Par_Animal.all = "" then
     Display_Help (Config);
     return;
   end if;

   Start_Date := Calendar2.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
   Stop_Date  := Calendar2.To_Time_Type (Sa_Par_Start_Date.all, "23:59:59:999");
   Start_Date := Start_Date - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first
   Stop_Date  := Stop_Date  - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first

   Global_Stop_Date  := Calendar2.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");

   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bnl",
      Login    => "bnl",
      Password => "bnl");

    Main : loop
      Start_Date := Start_Date + Calendar2.Interval_Type'(1,0,0,0,0); --add a day
      Stop_Date  := Stop_Date  + Calendar2.Interval_Type'(1,0,0,0,0); --add a day

      Log ("Lay_All_If_Profitable - treat date " & String_Date(start_date));

      T.Start;
      
      if Sa_Par_Animal.all = "horse" then  
        Select_All.Prepare (
            "select M.MARKETID, M.STARTTS from " & 
            "AMARKETS M, AEVENTS E " &
            "where M.EVENTID = E.EVENTID " &
            "and M.STARTTS >= :START " &
            "and M.STARTTS <= :STOP " &
            "and E.EVENTTYPEID = 7 " &
            "and M.MARKETTYPE = 'WIN' " &
   --          "and COUNTRYCODE in ('GB','IE','US','FR','ZA') " &
            "and COUNTRYCODE in ('GB') " &
            "group by M.MARKETID,STARTTS " &
            "order by M.MARKETID,STARTTS ");
            
      elsif Sa_Par_Animal.all = "hound" then  
        Select_All.Prepare (
            "select SCHEDULEDOFF, EVENTID, SELECTIONID from HISTORY " &
            "where SCHEDULEDOFF >= :START " &
            "and SCHEDULEDOFF <= :STOP " &
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
        Select_All.Get_Timestamp("STARTTS", H_Data.Startts);
        Select_All.Get("MARKETID", H_Data.Marketid);
        H_Pack.Insert_At_Tail(H_List,H_Data);
      end loop;        
      Select_All.Close_Cursor;      
      Stm_Select_Eventid_Selectionid_O.Prepare( "select * " & 
            "from APRICES " &
            "where MARKETID = :MARKETID " &
            "order by LAYPRICE"  ) ;

      Loop_All : while not H_Pack.Is_Empty(H_List) loop
          H_Pack.Remove_From_Head(H_List, H_Data);           
          Stm_Select_Eventid_Selectionid_O.Set("MARKETID", H_Data.Marketid);
          Stm_Select_Eventid_Selectionid_O.Open_Cursor;
          Price := Table_Aprices.Empty_Data;
          Local_Stats := (others => (0,0.0));   
          
          Loop_Runner : loop
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos2);
            exit Loop_Runner when Eos2;
            Price := Table_Aprices.Get(Stm_Select_Eventid_Selectionid_O);

            if Price.Layprice <= 2.0 then
              Local_Stats(X2).Hits := Local_Stats(X2).Hits +1;
            end if;  
            if Price.Layprice <= 3.0 then
              Local_Stats(X3).Hits := Local_Stats(X3).Hits +1;
            end if;  
            if Price.Layprice <= 4.0 then
              Local_Stats(X4).Hits := Local_Stats(X4).Hits +1;
            end if;
            if Price.Layprice <= 5.0 then
              Local_Stats(X5).Hits := Local_Stats(X5).Hits +1;
            end if;  
            if Price.Layprice <= 6.0 then
              Local_Stats(X6).Hits := Local_Stats(X6).Hits +1;
            end if;  
            if Price.Layprice <= 7.0 then
              Local_Stats(X7).Hits := Local_Stats(X7).Hits +1;
            end if;  
            if Price.Layprice <= 8.0 then
              Local_Stats(X8).Hits := Local_Stats(X8).Hits +1;
            end if;  
            if Price.Layprice <= 9.0 then
              Local_Stats(X9).Hits := Local_Stats(X9).Hits +1;
            end if;  
            if Price.Layprice <= 10.0 then
              Local_Stats(X10).Hits := Local_Stats(X10).Hits +1;
            end if;  
            if Price.Layprice > 10.0 then
              Local_Stats(None).Hits := Local_Stats(None).Hits +1;
            end if;  
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
         --new runner ...

          -- will use them with as many as possible?
         
          if Local_Stats(X10).Hits >= 11 then
            Global_Stats(X10).Hits := Global_Stats(X10).Hits +1;
          elsif Local_Stats(X9).Hits >= 10 then
            Global_Stats(X9).Hits := Global_Stats(X9).Hits +1;
          elsif Local_Stats(X8).Hits >= 9 then
            Global_Stats(X8).Hits := Global_Stats(X8).Hits +1;
          elsif Local_Stats(X7).Hits >= 8 then
            Global_Stats(X7).Hits := Global_Stats(X7).Hits +1;
          elsif Local_Stats(X6).Hits >= 7 then
            Global_Stats(X6).Hits := Global_Stats(X6).Hits +1;
          elsif Local_Stats(X5).Hits >= 6 then
            Global_Stats(X5).Hits := Global_Stats(X5).Hits +1;
          elsif Local_Stats(X4).Hits >= 5 then
            Global_Stats(X4).Hits := Global_Stats(X4).Hits +1;
          elsif Local_Stats(X3).Hits >= 4 then
            Global_Stats(X3).Hits := Global_Stats(X3).Hits +1;
          elsif Local_Stats(X2).Hits >= 3 then
            Global_Stats(X2).Hits := Global_Stats(X2).Hits +1;
          end if;
         
      end loop Loop_All;
      T.Commit ;
      
      
      exit Main when     Start_Date.Year  = Global_Stop_Date.Year
                and then Start_Date.Month = Global_Stop_Date.Month
                and then Start_Date.Day   = Global_Stop_Date.Day;
   end loop Main;

   Sql.Close_Session;

   for i in Outcome_Type'range loop  
     Log(i'Img & Global_Stats(i).Hits'Img );        
   end loop;   
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_All_If_Profitable;
