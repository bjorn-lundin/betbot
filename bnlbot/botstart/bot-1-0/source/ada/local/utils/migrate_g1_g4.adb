

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
--with Table_Anonrunners;
with Table_Aprices;
with Table_Awinners;

with Sql;
with Logging ; use Logging;
with Types; use Types;
with Calendar2; use Calendar2;
--with Ada.Strings ; use Ada.Strings;
--with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;
with Stacktrace;


procedure Migrate_G1_G4 is
--  Bad_Input : exception;
 
  Me : constant String := "Main"; 
 
  G4_Market_List : Table_Amarkets.Amarkets_List_Pack.List_Type := 
            Table_Amarkets.Amarkets_List_Pack.Create;
            
  G4_Event_List : Table_Aevents.Aevents_List_Pack.List_Type := 
            Table_Aevents.Aevents_List_Pack.Create;
 
  G4_Price_List : Table_Aprices.Aprices_List_Pack.List_Type := 
            Table_Aprices.Aprices_List_Pack.Create;
                       
  G4_Runner_List : Table_Arunners.Arunners_List_Pack.List_Type := 
            Table_Arunners.Arunners_List_Pack.Create;
            
--  G3_Nonrunner_List : Table_Anonrunners.Anonrunners_List_Pack.List_Type := 
--            Table_Anonrunners.Anonrunners_List_Pack.Create;
 
  G4_Winner_List : Table_Awinners.Awinners_List_Pack.List_Type := 
            Table_Awinners.Awinners_List_Pack.Create;
            
--  Sa_Par_Startts   : aliased Gnat.Strings.String_Access;
--  Sa_Par_Stopts    : aliased Gnat.Strings.String_Access;
  
  Par_Startts   : Calendar2.Time_Type;
  Par_Stopts    : Calendar2.Time_Type;
  Startts   : Calendar2.Time_Type;
  Stopts    : Calendar2.Time_Type;
  
  
  
  
--  Config : Command_Line_Configuration;
             
             
             
 ------------------------------------------------------------------------------------------
  function Get_Num_Runners(Eventid : integer_4) return Integer_4 is
    Stm : Sql.Statement_Type;
    Eos : Boolean := False;
    Num : Integer_4 := 0;
  begin
    Stm.Prepare("select count('a') from HISTORY where EVENTID =:EVENTID");
    Stm.Set("EVENTID", Eventid);
    Stm.Open_Cursor;
    Stm.Fetch(Eos);
    if not Eos then
      Stm.Get(1,Num);
    end if;  
    Stm.Close_Cursor;    
    return Num;
  end Get_Num_Runners;  
 ------------------------------------------------------------------------------------------
  procedure Read_G1(Marketlist : in out Table_Amarkets.Amarkets_List_Pack.List_Type;
                    Eventlist  : in out Table_Aevents.Aevents_List_Pack.List_Type;
                    Runnerlist : in out Table_Arunners.Arunners_List_Pack.List_Type  ;     
                    Pricelist : in out Table_Aprices.Aprices_List_Pack.List_Type  ;     
                    Winnerlist : in out Table_Awinners.Awinners_List_Pack.List_Type  ;     
                    Startts : Calendar2.Time_Type;
                    Stopts  : Calendar2.Time_Type
                            ) is
  Me : constant String := "Read_G1"; 
  Stm : Sql.Statement_Type;
  Eos : Boolean := False;
  M : Table_Amarkets.Data_Type;
  E : Table_Aevents.Data_Type;
  P : Table_Aprices.Data_Type;
  R : Table_Arunners.Data_Type;
  W : Table_Awinners.Data_Type;
  
  Is_Winner : Boolean := False;
  
  Eventid : Integer_4 := 0;
  Cntry : String(1..3);
  Cnt : Integer_4 := 0;
 begin
    Stm.Prepare (
          "select * from HISTORY " &
          "where SCHEDULEDOFF >= :START " &
          "and SCHEDULEDOFF <= :STOP " &
          "and FIRSTTAKEN <= SCHEDULEDOFF " &
          "and LATESTTAKEN >= SCHEDULEDOFF " &          
          "and EVENT <> 'Forecast' " &
          "and EVENT <> 'TO BE PLACED' " &
          "and SPORTSID = 7 " &
          "and FULLDESCRIPTION <> 'Ante Post' " &
          "and COUNTRY <> 'ANTEPOST' " &
          "and lower(FULLDESCRIPTION) not like '% v %'  " &
          "and lower(FULLDESCRIPTION) not like '%forecast%' " &
          "and lower(FULLDESCRIPTION) not like '%tbp%'  " &
          "and lower(FULLDESCRIPTION) not like '%challenge%' " &
          "and lower(FULLDESCRIPTION) not like '%fc%'  " &
          "and lower(FULLDESCRIPTION) not like '%daily win%' " &
          "and lower(FULLDESCRIPTION) not like '%reverse%' " &
          "and lower(FULLDESCRIPTION) not like '%without%' " &
          "and inplay = 'PE' " &   -- pre event !!
          "order by EVENTID, SELECTIONID ");

   Stm.Set_Timestamp("START", Startts);       
   Stm.Set_Timestamp("STOP", Stopts);    
   
   
--   Log(Me, "Startts " & String_Date_Time_ISO(Startts)); 
--   Log(Me, "Stopts " & String_Date_Time_ISO(Stopts)); 
   
   Stm.Open_Cursor;
   loop
     Cnt := Cnt +1;
     if Cnt rem 10_000 = 0 then
       Log(Me, Cnt'Img); 
     end if;
     Stm.Fetch(Eos);
     exit when Eos;
     
     M := Table_Amarkets.Empty_Data;
     Stm.Get("EVENTID",Eventid);
     M.Marketid := "1." & Eventid'Img(2..10);
     M.Numrunners := Get_Num_Runners(Eventid); 
     M.Numactiverunners := M.Numrunners;
     Stm.Get("EVENTID",M.Eventid);
     Stm.Get_Timestamp("SCHEDULEDOFF",M.Startts);
     Stm.Get("EVENT",M.Marketname);
     M.Markettype := "WIN   ";
     M.Numwinners := 1;
     Table_Amarkets.Amarkets_List_Pack.Insert_At_Tail(Marketlist,M);
     E := Table_Aevents.Empty_Data;
     
     E.Eventid := M.Eventid;
     E.Eventname := M.Marketname;
     Cntry := (others => ' ');
     Stm.Get("COUNTRY",Cntry);
     if Cntry = "GBR" then
       E.Countrycode := "GB";
     elsif Cntry = "IRL" then
       E.Countrycode := "IE";
     elsif Cntry = "USA" then
       E.Countrycode := "US";
     elsif Cntry = "RSA" then
       E.Countrycode := "ZA";
     elsif Cntry = "FRA" then
       E.Countrycode := "FR";
     else  
       E.Countrycode := "XX";
     end if;
     
     E.Eventtypeid := 7;
     E.Opents := M.Startts;
     E.Timezone(1..4) := "None";
     
     Table_Aevents.Aevents_List_Pack.Insert_At_Tail(Eventlist,E);
     
     P := Table_Aprices.Empty_Data;
     P.Marketid := M.Marketid;
     Stm.Get("SELECTIONID", P.Selectionid);      
     Stm.Get_Timestamp("FIRSTTAKEN", P.Pricets);      
     Stm.Get("ODDS", P.Layprice);  
     P.Backprice := P.Layprice;     

     Table_Aprices.Aprices_List_Pack.Insert_At_Tail(Pricelist,P);
     
     R := Table_Arunners.Empty_Data;
     R.Marketid := P.Marketid;
     R.Selectionid := P.Selectionid;
     Stm.Get("SELECTION", R.Runnername);      
     Table_Arunners.Arunners_List_Pack.Insert_At_Tail(Runnerlist,R);
     
     Stm.Get("WINFLAG",Is_Winner);
     if Is_Winner then     
       W := Table_Awinners.Empty_Data;
       W.Marketid := P.Marketid;
       W.Selectionid := P.Selectionid;
       Table_Awinners.Awinners_List_Pack.Insert_At_Tail(Winnerlist,W);
     end if;     
     
   end loop;
   Stm.Close_Cursor;    
  
   Log(Me, "read # Markets/Events: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
 
 end Read_G1; 
 ------------------------------------------------------------------------------------------


 procedure Insert_G4_Markets(List : in out Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Insert_G4_Markets"; 
  Amarket: Table_Amarkets.Data_Type;
  Left, Tot : Integer := 0;
 begin
--  Log(Me, "Start");
  Tot := Table_Amarkets.Amarkets_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(List) loop
    Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(List,AMarket) ;
    -- 
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Amarkets.Insert(Amarket); 
    exception
      when Sql.Duplicate_Index => null;
--        Log("ignoring winner duplicate " & Table_Amarkets.To_String(Amarket));
    end;  
  end loop;
--  Log(Me, "Stop");
 end Insert_G4_Markets;
 -----------------------------------------------------------------------------------------
 procedure Insert_G4_Events(List : in out Table_Aevents.Aevents_List_Pack.List_Type) is
  Me : constant String := "Insert_G4_Events"; 
  Aevent: Table_Aevents.Data_Type;
  Left, Tot : Integer := 0;
 begin
--  Log(Me, "Start");
  Tot := Table_Aevents.Aevents_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Aevents.Aevents_List_Pack.Is_Empty(List) loop
    Table_Aevents.Aevents_List_Pack.Remove_From_Head(List,Aevent) ;
    -- 
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Aevents.Insert(Aevent); 
    exception
      when Sql.Duplicate_Index => null;
--        Log("ignoring winner duplicate " & Table_Aevents.To_String(Aevent));
    end;  
  end loop;
--  Log(Me, "Stop");
 end Insert_G4_Events;
 ------------------------------------------------------------------------------------------
 procedure Insert_G4_Runners (List : in out Table_Arunners.Arunners_List_Pack.List_Type) is
  Me : constant String := "Insert_G4_Runners"; 
  Arunner : Table_Arunners.Data_Type;
  Left, Tot : Integer := 0;
 begin
--  Log(Me, "Start");
  Tot := Table_Arunners.Arunners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Arunners.Arunners_List_Pack.Is_Empty(List) loop
    Table_Arunners.Arunners_List_Pack.Remove_From_Head(List,Arunner) ;
    -- 
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Arunners.Insert(Arunner);    
    exception
     when Sql.Duplicate_Index => null;
--       Log("ignoring winner duplicate " & Table_Arunners.To_String(Arunner));
   end;  
   -----------------------------------------
  end loop;    
--  Log(Me, "Stop");
 end Insert_G4_Runners;
 
 ------------------------------------------------------------------------------------------
 procedure Insert_G4_Prices (List : in out Table_Aprices.Aprices_List_Pack.List_Type) is
  Me : constant String := "Insert_G4_Prices"; 
  Aprice : Table_Aprices.Data_Type;
  Left, Tot : Integer := 0;
 begin
--  Log(Me, "Start");
  Tot := Table_Aprices.Aprices_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Aprices.Aprices_List_Pack.Is_Empty(List) loop
    Table_Aprices.Aprices_List_Pack.Remove_From_Head(List,Aprice) ;
    -- 
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Aprices.Insert(Aprice);    
    exception
      when Sql.Duplicate_Index => null;
--        Log("ignoring winner duplicate " & Table_Aprices.To_String(Aprice));
    end;  
    -----------------------------------------
  end loop;    
--  Log(Me, "Stop");
 end Insert_G4_Prices;
 ---------------------------------------------------------------------------------

 procedure Insert_G4_Winners (List : in out Table_Awinners.Awinners_List_Pack.List_Type) is
  Me : constant String := "Insert_G4_Winners"; 
  Awinner : Table_Awinners.Data_Type;
  Left, Tot : Integer := 0;
 begin
--  Log(Me, "Start");
  Tot := Table_Awinners.Awinners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Awinners.Awinners_List_Pack.Is_Empty(List) loop
    Table_Awinners.Awinners_List_Pack.Remove_From_Head(List,Awinner) ;
    -- 
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Awinners.Insert(Awinner);
    exception
      when Sql.Duplicate_Index => null;
--        Log("ignoring winner duplicate " & Table_Awinners.To_String(Awinner));
    end;  
    -----------------------------------------
  end loop;    
--  Log(Me, "Stop");
 end Insert_G4_Winners;
  
 ---------------------------------------------------------------------------------

 
 T : Sql.Transaction_Type;
 
 ------------------------------------------------------------------------------------------
begin 

--  Define_Switch
--  (Config,
--   Sa_Par_Startts'access,
--   Long_Switch => "--startts=",
--   Help    => "timestamp of first market, yyyy-mm-dd_hh24:mi:ss.ms");
--  Define_Switch
--  (Config,
--   Sa_Par_Stopts'access,
--   Long_Switch => "--stopts=",
--   Help    => "timestamp of last market, yyyy-mm-dd_hh24:mi:ss.ms");
--
--   Getopt (Config); -- process the command line
--
--   Log(Me, "Par_Startts: '" & Sa_Par_Startts.all & "'");
--   Log(Me, "Par_Stopts:  '" & Sa_Par_Stopts.all & "'");

   Par_Startts := (2012,01,01,0,0,0,0);
   Par_Stopts  := (2013,12,31,23,29,29,999);
    
   
--   Par_Startts := Calendar2.To_Time_Type(Sa_Par_Startts.all(1..10), Sa_Par_Startts.all(12..23) );
--   Par_Stopts  := Calendar2.To_Time_Type(Sa_Par_Stopts.all(1..10),  Sa_Par_Stopts.all(12..23) );   

  -- log in to old database
 
  Log(Me, "log into database");
  Sql.Connect
     (Host   => "localhost",
      Port   => 5432,
      Db_Name => "bnl",
      Login  => "bnl",
      Password => "bnl");
  Log(Me, "db Connected");
  
  Startts := Par_Startts;
 
  loop
    
    Stopts := Startts + (0,23,59,59,999) ;
    exit when Stopts > Par_Stopts;
 
    Log(Me, "Treat Date " & String_Date(Stopts)); 
   
    -- read to list
    T.Start;
      Read_G1(G4_Market_List,
              G4_Event_List,
              G4_Runner_List,
              G4_Price_List,
              G4_Winner_List,
              Startts, Stopts);
              
      Insert_G4_Markets(G4_Market_List);
      Insert_G4_Events(G4_Event_List);
      Insert_G4_Runners(G4_Runner_List);
      Insert_G4_Prices(G4_Price_List);
      Insert_G4_Winners(G4_Winner_List);
    T.Commit;

    Startts := Startts + (1,0,0,0,0) ;
    
  end loop;

  
  Log(Me, "close db");
  Sql.Close_Session;

exception
--  when  Gnat.Command_Line.Invalid_Switch =>
--    Display_Help(Config);
  when E: others => 
    Stacktrace.Tracebackinfo(E); 
 
end Migrate_G1_G4;