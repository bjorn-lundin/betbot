
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

procedure Plot_Race_All_Runners is
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
 
   Secs : Integer_4 := 0;
   F : Text_Io.File_Type;
   
   
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
          
          Log("Eventid: " & H_Data.Eventid'Img);
          
          Text_Io.Create(F, Text_Io.Out_File,
          General_Routines.Skip_All_Blanks(H_Data.Eventid'Img & '_' & H_Data.Selectionid'Img & ".dat"));
          
          Loop_Runner : loop
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos2);
            exit Loop_Runner when Eos2;
            History := Table_History.Get(Stm_Select_Eventid_Selectionid_O);           
            
            if History.Scheduledoff >= History.Firsttaken then
              Secs := Calendar2.To_Seconds(History.Scheduledoff - History.Firsttaken );
              Secs := -Secs;
            else
              Secs := Calendar2.To_Seconds(History.Firsttaken - History.Scheduledoff  );
            end if;
            
            Text_IO.Put_Line(F, Secs'Img & " | " & 
                              History.Eventid'Img & " | " & 
                              History.Selectionid'Img & " | " & 
                              F8_Image(History.Odds) & " | " &
                              History.Winflag'Img  );    
    
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
          Text_Io.Close(F);
         --new runner ...
         
      end loop Loop_All;
      T.Commit ;
      exit Main when     Start_Date.Year  = Global_Stop_Date.Year
                and then Start_Date.Month = Global_Stop_Date.Month
                and then Start_Date.Day   = Global_Stop_Date.Day;
   end loop Main;

   Sql.Close_Session;

exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Plot_Race_All_Runners;
