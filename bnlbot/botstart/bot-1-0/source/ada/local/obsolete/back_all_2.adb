
with Types ; use Types;
with Stacktrace;
with Sql;
with Text_Io;
with Table_History;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Calendar2; use Calendar2;
with Logging; use Logging;
with General_Routines; use General_Routines;

with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Back_All_2 is
    History : Table_History.Data_Type;
    Bad_Input : exception;
                     
    type H_Type is record
      Scheduledoff : Calendar2.Time_Type := Calendar2.Time_Type_First;
      Eventid  : Integer_4 := 0;
      Selectionid : Integer_4 := 0;
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
--   Ia_Delta_Odds         : aliased Integer := 1;
   
   Back_Odds, Lay_Odds   : Float_8 := 0.0;
   Global_Profit, Profit : Float_8 := 0.0;
   
   Back_Size : Float_8 := 50.0;
   Lay_Size  : Float_8 := 0.0;
   
   Income, Stake: Float_8 := 0.0;
   
   type Outcome_Type is (Backed_Won, Backed_Lost, No_Bet_Laid);
   Outcome : Outcome_Type := No_Bet_Laid;
   
   type Stats_Type is record
     Hits : Integer_4 := 0;
     Profit : Float_8 := 0.0;
   end record ;
   
   Stats : array (Outcome_Type'range) of Stats_Type;   

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

      Log ("Greening_Up_2 - treat date " & String_Date(start_date));

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
          
          Loop_Runner : loop
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos2);
            exit Loop_Runner when Eos2;
            History := Table_History.Get(Stm_Select_Eventid_Selectionid_O);
            
            if History.Scheduledoff - History.Firsttaken  >= (0,Hour_Type(Ia_Hours_Before_Start),0,0,0) and then -- 1 h
               History.Scheduledoff - History.Latesttaken <= (0,Hour_Type(Ia_Hours_Before_Start),0,0,0)     then -- 1 h
               if Outcome = No_Bet_Laid then
                  -- do the back bet                 
                  if Float_8(Ia_Min_Odds) <= History.Odds and then
                     History.Odds <= Float_8(Ia_Max_Odds) then
                     Back_Odds := History.Odds;
                     Outcome := Backed_Won;
                     exit Loop_Runner;
                  end if;   
               end if;
            end if;   
       
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
         --new runner ...

          if Outcome = Backed_Won and then not History.Winflag then 
            -- no lay bet, so, and we did NOT win
            Outcome := Backed_Lost;
          end if;
         
          case Outcome is 
             when No_Bet_Laid =>    -- no bet at all
               Income := 0.0;
               Stake  := 0.0;
               Profit := 0.0;
             when Backed_Won =>  -- A winning back bet only
               Income := Back_Size * Back_Odds;            
               Stake  := Back_Size;
               Profit := 1.0 * (Income - Stake);
--               Profit := 0.95 * (Income - Stake);
             when Backed_Lost =>  -- A losing back bet only
               Income := 0.0;
               Stake  := Back_Size;
               Profit := - Stake;
          end case;  
          Stats(Outcome).Hits := Stats(Outcome).Hits + 1; 
          Stats(Outcome).Profit := Stats(Outcome).Profit + Profit;           
          
          if Outcome /= No_Bet_Laid then         
             Text_IO.Put_Line(Calendar2.String_Date_Time_ISO(History.Scheduledoff, T=> " ", TZ => "") & " | " &
                              Outcome'Img & " | " &
                              History.Fulldescription(1..20) & " | " & 
                              History.Event(1..20) & " | " & 
                              History.Eventid'Img & " | " & 
                              History.selectionid'Img & " | " & 
                              History.Winflag'Img & " | " & 
                              F8_Image(Back_Odds) & " | " &
                              F8_Image(Lay_Odds) & " | " &                    
                              F8_Image(Back_Size) & " | " &                    
                              F8_Image(Lay_Size) & " | " &                    
                              F8_Image(Profit) );    
          end if;
           
          Global_Profit := Global_Profit + Profit;          
           
          --reset for next turn 
          Lay_Size  := 0.0;
          Lay_Odds  := 0.0;
          Back_Odds := 0.0;
          Outcome   := No_Bet_Laid;
          Profit    := 0.0;
         
      end loop Loop_All;
      T.Commit ;
      exit Main when     Start_Date.Year  = Global_Stop_Date.Year
                and then Start_Date.Month = Global_Stop_Date.Month
                and then Start_Date.Day   = Global_Stop_Date.Day;
   end loop Main;

   Sql.Close_Session;

   Log("Total profit = " & Integer_4(Global_Profit)'Img);  
   for i in Outcome_Type'range loop  
     Log(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);        
   end loop;   
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Back_All_2;
