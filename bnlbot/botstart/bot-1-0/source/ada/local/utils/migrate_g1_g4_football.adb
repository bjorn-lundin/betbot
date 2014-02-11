

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Aprices;
with Sql;
with Logging ; use Logging;
with Sattmate_Types; use Sattmate_Types;
with Sattmate_Calendar; use Sattmate_Calendar;
with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;
with Sattmate_Exception;

procedure Migrate_G1_G4_Football is
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
            
--  Sa_Par_Startts   : aliased Gnat.Strings.String_Access;
--  Sa_Par_Stopts    : aliased Gnat.Strings.String_Access;
  
  Par_Startts   : Sattmate_Calendar.Time_Type;
  Par_Stopts    : Sattmate_Calendar.Time_Type;
  Startts   : Sattmate_Calendar.Time_Type;
  Stopts    : Sattmate_Calendar.Time_Type;
  
--  Config : Command_Line_Configuration;
  function Country_Code(Desc : String) return String is
    use General_Routines;
  begin
       if Lower_Case(Desc(1..3)) = "arg" then return "AR";
    elsif Lower_Case(Desc(1..3)) = "arm" then return "AM";
    elsif Lower_Case(Desc(1..6)) = "austra" then return "AU";
    elsif Lower_Case(Desc(1..6)) = "austri" then return "AT";
    elsif Lower_Case(Desc(1..3)) = "aze" then return "AZ";
    elsif Lower_Case(Desc(1..3)) = "bah" then return "BH";
    elsif Lower_Case(Desc(1..4)) = "bela" then return "BY";
    elsif Lower_Case(Desc(1..4)) = "belg" then return "BE";
    elsif Lower_Case(Desc(1..3)) = "bol" then return "BO";
    elsif Lower_Case(Desc(1..3)) = "bos" then return "BA";
    elsif Lower_Case(Desc(1..3)) = "bra" then return "BR";
    elsif Lower_Case(Desc(1..3)) = "bul" then return "BG";
    elsif Lower_Case(Desc(1..3)) = "can" then return "CA";
    elsif Lower_Case(Desc(1..3)) = "chi" then return "CL";
    elsif Lower_Case(Desc(1..3)) = "col" then return "CO";
    elsif Lower_Case(Desc(1..3)) = "cro" then return "HR";
    elsif Lower_Case(Desc(1..3)) = "cze" then return "CZ";
    elsif Lower_Case(Desc(1..3)) = "dan" then return "DK";
    elsif Lower_Case(Desc(1..3)) = "dut" then return "NL";
    elsif Lower_Case(Desc(1..3)) = "ecu" then return "EC";
    elsif Lower_Case(Desc(1..3)) = "egy" then return "EG";
    elsif Lower_Case(Desc(1..3)) = "eng" then return "GB";
    elsif Lower_Case(Desc(1..3)) = "est" then return "EE";
    elsif Lower_Case(Desc(1..3)) = "fin" then return "FI";
    elsif Lower_Case(Desc(1..3)) = "fre" then return "FR";
    elsif Lower_Case(Desc(1..4)) = "geor" then return "GE";
    elsif Lower_Case(Desc(1..4)) = "germ" then return "DE";
    elsif Lower_Case(Desc(1..3)) = "gre" then return "GR";
    elsif Lower_Case(Desc(1..3)) = "hun" then return "HU";
    elsif Lower_Case(Desc(1..3)) = "ice" then return "IS";
    elsif Lower_Case(Desc(1..4)) = "indi" then return "IN";
    elsif Lower_Case(Desc(1..4)) = "indo" then return "RI";
    elsif Lower_Case(Desc(1..3)) = "iri" then return "IE";
    elsif Lower_Case(Desc(1..3)) = "isr" then return "IL";
    elsif Lower_Case(Desc(1..3)) = "ita" then return "IT";
    elsif Lower_Case(Desc(1..3)) = "jap" then return "JP";
    elsif Lower_Case(Desc(1..3)) = "jor" then return "JO";
    elsif Lower_Case(Desc(1..3)) = "kaz" then return "KZ";
    elsif Lower_Case(Desc(1..3)) = "lat" then return "LV";
    elsif Lower_Case(Desc(1..3)) = "lit" then return "LT";
    elsif Lower_Case(Desc(1..3)) = "mac" then return "MK";
    elsif Lower_Case(Desc(1..4)) = "mala" then return "MY";
    elsif Lower_Case(Desc(1..4)) = "malt" then return "MT";
    elsif Lower_Case(Desc(1..3)) = "mex" then return "MX";
    elsif Lower_Case(Desc(1..3)) = "mor" then return "MA";
    elsif Lower_Case(Desc(1..3)) = "nor" then return "NO";
    elsif Lower_Case(Desc(1..3)) = "par" then return "PY";
    elsif Lower_Case(Desc(1..3)) = "per" then return "PE";
    elsif Lower_Case(Desc(1..3)) = "pol" then return "PO";
    elsif Lower_Case(Desc(1..3)) = "por" then return "PT";
    elsif Lower_Case(Desc(1..3)) = "qat" then return "QA";
    elsif Lower_Case(Desc(1..3)) = "rom" then return "RO";
    elsif Lower_Case(Desc(1..3)) = "rus" then return "RU";
    elsif Lower_Case(Desc(1..3)) = "sau" then return "SA";
    elsif Lower_Case(Desc(1..3)) = "sco" then return "GB";
    elsif Lower_Case(Desc(1..3)) = "ser" then return "RS";
    elsif Lower_Case(Desc(1..3)) = "sin" then return "SG";
    elsif Lower_Case(Desc(1..5)) = "slova" then return "SK";
    elsif Lower_Case(Desc(1..5)) = "slove" then return "SI";
    elsif Lower_Case(Desc(1..3)) = "spa" then return "ES";
    elsif Lower_Case(Desc(1..3)) = "swe" then return "SE";
    elsif Lower_Case(Desc(1..3)) = "swi" then return "CH";
    elsif Lower_Case(Desc(1..3)) = "tha" then return "TH";
    elsif Lower_Case(Desc(1..3)) = "tur" then return "TR";
    elsif Lower_Case(Desc(1..3)) = "ukr" then return "UA";
    elsif Lower_Case(Desc(1..3)) = "uru" then return "UY";
    elsif Lower_Case(Desc(1..3)) = "wel" then return "GB";
    elsif Lower_Case(Desc(1..3)) = "ven" then return "VE";
    elsif Lower_Case(Desc(1..3)) = "vie" then return "VN";
    else                          return "XX";
    end if;
  end Country_Code;     
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
                    Startts : Sattmate_Calendar.Time_Type;
                    Stopts  : Sattmate_Calendar.Time_Type
                            ) is
  Me : constant String := "Read_G1"; 
  Stm : Sql.Statement_Type;
  Eos : Boolean := False;
  H : Table_History.Data_Type;
  M : Table_Amarkets.Data_Type;
  E : Table_Aevents.Data_Type;
  P : Table_Aprices.Data_Type;
  R : Table_Arunners.Data_Type;
  
  Is_Winner : Boolean := False;
  
  Eventid : Integer_4 := 0;
  Cntry : String(1..3);
  Cnt : Integer_4 := 0;
 begin
    Stm.Prepare (
--          "select * from HISTORY " &
--          "where SCHEDULEDOFF >= :START " &
--          "and SCHEDULEDOFF <= :STOP " &
--          "and FIRSTTAKEN <= SCHEDULEDOFF " &
--          "and LATESTTAKEN >= SCHEDULEDOFF " &          
--          "and SPORTSID = 1 " &
--          "and COUNTRY <> 'ANTEPOST' " &
--          "and inplay = 'PE' " &   -- pre event !!
--          "order by EVENTID, SELECTIONID ");
          "select * from HISTORY " &
          "where SCHEDULEDOFF >= :START " &
          "and SCHEDULEDOFF <= :STOP " &
          "and SCHEDULEDOFF >= LATESTTAKEN " &
          "and SPORTSID = 1 " &
          "and COUNTRY <> 'ANTEPOST' " &
          "and inplay = 'PE' " &   -- pre event !!
          "order by EVENTID, SELECTIONID, LATESTTAKEN DESC ");
          
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
     H := Table_History.Empty_Data;
     H := Table_History.Get(Stm);
     
     M := Table_Amarkets.Empty_Data;
     --Stm.Get("EVENTID",Eventid);
     
     M.Marketid := "1." & H.Eventid'Img(2..10);
     M.Numrunners := Get_Num_Runners(H.Eventid); 
     M.Numactiverunners := M.Numrunners;
--     Stm.Get("EVENTID",M.Eventid);
     M.Eventid := "1." & H.Eventid'Img(2..10);
--     Stm.Get_Timestamp("SCHEDULEDOFF",M.Startts);
     M.Startts := H.Scheduledoff;  
--     Stm.Get("EVENT",M.Marketname);
     Move(H.Event,M.Marketname);
     
     if M.Marketname(1..15) = "Half Time Score" then
       Move("HALF_TIME_SCORE", M.Markettype);
     elsif M.Marketname(1..13) = "Correct Score" then
       Move("CORRECT_SCORE", M.Markettype);
     elsif M.Marketname(1..10) = "Match Odds" then
       Move("MATCH_ODDS", M.Markettype);
     else
       Move("XXX" ,M.Markettype);
     end if;  
       
     M.Numwinners := 1;
     Table_Amarkets.Amarkets_List_Pack.Insert_At_Tail(Marketlist,M);
     E := Table_Aevents.Empty_Data;
     
     E.Eventid := M.Eventid;
     E.Eventname := M.Marketname;
     
     --ta from fullname istället.
     E.Countrycode := Country_Code(H.Fulldescription);
--     Cntry := (others => ' ');
--     Stm.Get("COUNTRY",Cntry);
--     if Cntry = "GBR" then
--       E.Countrycode := "GB";
--     elsif Cntry = "IRL" then
--       E.Countrycode := "IE";
--     elsif Cntry = "USA" then
--       E.Countrycode := "US";
--     elsif Cntry = "RSA" then
--       E.Countrycode := "ZA";
--     elsif Cntry = "FRA" then
--       E.Countrycode := "FR";
--     else  
--       E.Countrycode := "XX";
--     end if;
     
     E.Eventtypeid := 1;
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
     
     Stm.Get("WINFLAG",Is_Winner);
     if Is_Winner then     
       Move("WINNER", R.Status);     
     else
       Move("LOSER", R.Status);          
     end if;     
     Table_Arunners.Arunners_List_Pack.Insert_At_Tail(Runnerlist,R);   
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

--   Par_Startts := Sattmate_Calendar.To_Time_Type(Sa_Par_Startts.all(1..10), Sa_Par_Startts.all(12..23) );
--   Par_Stopts  := Sattmate_Calendar.To_Time_Type(Sa_Par_Stopts.all(1..10),  Sa_Par_Stopts.all(12..23) );   

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
              Startts, Stopts);
              
      Insert_G4_Markets(G4_Market_List);
      Insert_G4_Events(G4_Event_List);
      Insert_G4_Runners(G4_Runner_List);
      Insert_G4_Prices(G4_Price_List);
    T.Commit;

    Startts := Startts + (1,0,0,0,0) ;    
  end loop;
 
  Log(Me, "close db");
  Sql.Close_Session;

exception
--  when  Gnat.Command_Line.Invalid_Switch =>
--    Display_Help(Config);
  when E: others => 
    Sattmate_Exception.Tracebackinfo(E);  
end Migrate_G1_G4_Football;
