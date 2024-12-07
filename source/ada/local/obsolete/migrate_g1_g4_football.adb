

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Aprices;
with Table_Alinks;
with Table_History;
with Sql;
with Logging ; use Logging;
with Types; use Types;
with Calendar2; use Calendar2;
with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
--with General_Routines; use General_Routines;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;

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

  G4_Link_List : Table_Alinks.Alinks_List_Pack.List_Type :=
            Table_Alinks.Alinks_List_Pack.Create;

  Config           : Command_Line_Configuration;
  Sa_Par_Database  : aliased Gnat.Strings.String_Access;
  Sa_Par_Hostname  : aliased Gnat.Strings.String_Access;
  Sa_Par_Username  : aliased Gnat.Strings.String_Access;
  Sa_Par_Password  : aliased Gnat.Strings.String_Access;


--  Par_Startts   : Calendar2.Time_Type;
  Par_Stopts    : Calendar2.Time_Type;
  Startts   : Calendar2.Time_Type;
  Stopts    : Calendar2.Time_Type;
  ----------------------------------------------------
  function Country_Code(Desc : String) return String is
--    use General_Routines;
  begin
--    Log("Country_Code: '" & Desc(1..5) & "'");
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
    elsif Lower_Case(Desc(1..3)) = "cyp" then return "CY";
    elsif Lower_Case(Desc(1..3)) = "col" then return "CO";
    elsif Lower_Case(Desc(1..3)) = "cos" then return "CR";
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
    elsif Lower_Case(Desc(1..3)) = "hon" then return "HK";
    elsif Lower_Case(Desc(1..3)) = "ice" then return "IS";
    elsif Lower_Case(Desc(1..4)) = "indi" then return "IN";
    elsif Lower_Case(Desc(1..4)) = "indo" then return "RI";
    elsif Lower_Case(Desc(1..4)) = "iran" then return "IR";
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
    elsif Lower_Case(Desc(1..5)) = "n iri" then return "GB";
    elsif Lower_Case(Desc(1..3)) = "par" then return "PY";
    elsif Lower_Case(Desc(1..3)) = "per" then return "PE";
    elsif Lower_Case(Desc(1..3)) = "pol" then return "PO";
    elsif Lower_Case(Desc(1..3)) = "por" then return "PT";
    elsif Lower_Case(Desc(1..3)) = "pue" then return "PR";
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
    elsif Lower_Case(Desc(1..12)) = "south africa" then return "ZA";
    elsif Lower_Case(Desc(1..12)) = "south korean" then return "KR";
    elsif Lower_Case(Desc(1..3)) = "swe" then return "SE";
    elsif Lower_Case(Desc(1..3)) = "swi" then return "CH";
    elsif Lower_Case(Desc(1..3)) = "syr" then return "SY";
    elsif Lower_Case(Desc(1..3)) = "tha" then return "TH";
    elsif Lower_Case(Desc(1..3)) = "tur" then return "TR";
    elsif Lower_Case(Desc(1..3)) = "uae" then return "UE";
    elsif Lower_Case(Desc(1..3)) = "ukr" then return "UA";
    elsif Lower_Case(Desc(1..3)) = "uru" then return "UY";
    elsif Lower_Case(Desc(1..3)) = "uzb" then return "UZ";
    elsif Lower_Case(Desc(1..3)) = "wel" then return "GB";
    elsif Lower_Case(Desc(1..3)) = "ven" then return "VE";
    elsif Lower_Case(Desc(1..3)) = "vie" then return "VN";
    elsif Lower_Case(Desc(1..5)) = "women" then return "WN";
    elsif Lower_Case(Desc(1..3)) = "u19" then return "19";
    elsif Lower_Case(Desc(1..3)) = "u20" then return "20";
    elsif Lower_Case(Desc(1..3)) = "u21" then return "21";
    elsif Lower_Case(Desc(1..3)) = "u23" then return "23";
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
                    Pricelist  : in out Table_Aprices.Aprices_List_Pack.List_Type  ;
                    Linklist   : in out Table_Alinks.Alinks_List_Pack.List_Type ;
                    Startts    : in     Calendar2.Time_Type;
                    Stopts     : in     Calendar2.Time_Type
                            ) is
  Me : constant String := "Read_G1";
  Stm : Sql.Statement_Type;
  Eos : Boolean := False;
  H : Table_History.Data_Type;
  M : Table_Amarkets.Data_Type;
  E : Table_Aevents.Data_Type;
  P : Table_Aprices.Data_Type;
  R : Table_Arunners.Data_Type;
  L : Table_Alinks.Data_Type;


  Cnt : Integer_4 := 0;
 begin
    Stm.Prepare (
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
--     H := Table_History.Empty_Data;
     H := Table_History.Get(Stm);

     M := Table_Amarkets.Empty_Data;
     Move(H.Eventid'Img(2..10), M.Marketid);

     M.Numrunners := Get_Num_Runners(H.Eventid);
     M.Numactiverunners := M.Numrunners;
     Move(H.Eventid'Img(2..10), M.Eventid);
     M.Startts := H.Scheduledoff;
     Move(H.Event,M.Marketname);

     if M.Marketname(1..17) = "Half Time Score  " then
       Move("HALF_TIME_SCORE", M.Markettype);
     elsif M.Marketname(1..15) = "Correct Score  " then
       Move("CORRECT_SCORE", M.Markettype);
     elsif M.Marketname(1..12) = "Match Odds  " then
       Move("MATCH_ODDS", M.Markettype);
     else
       Move("XXX" ,M.Markettype);
     end if;

     M.Totalmatched := H.Volumematched;

     M.Numwinners := 1;


     Table_Amarkets.Amarkets_List_Pack.Insert_At_Tail(Marketlist,M);
     E := Table_Aevents.Empty_Data;

     Move(H.Eventid'Img(2..10), E.Eventid);

     E.Countrycode := Country_Code(H.Fulldescription);
     E.Eventtypeid := 1;
     E.Opents := M.Startts;
     E.Timezone(1..4) := "None";

    declare
      Last_Slash_Position : Integer := 0;
      Last_Non_Blank_Position : Integer := 0;
      V_Pos : Integer := Position(S =>  H.Fulldescription, Match => " v ");
    begin
      --German Soccer/Regionalliga Nord / Fixtures 21 September/Cloppenberg v Hamburg II/whatever
      for i in reverse H.Fulldescription'range loop
        case H.Fulldescription(i) is
          when '/' => -- going backwards, the first slash is the one we want, to the left of ' v '
            if Last_Slash_Position = 0 and then i < V_Pos then
              Last_Slash_Position := i;
              exit;
            end if;
          when ' ' => null; -- pass through all blanks at the end
          when others =>
          if Last_Non_Blank_Position = 0 then
            Last_Non_Blank_Position := i;
          end if;
        end case;
      end loop;
--          Log(Me, "Last_Slash_Position:" & Last_Slash_Position'Img &
--                 " Last_Non_Blank_Position" & Last_Non_Blank_Position'Img & " '" &
--                 Link_Data.Eventname(Last_Slash_Position +1 .. Last_Non_Blank_Position) & "'");
      Move(Trim(H.Fulldescription(Last_Slash_Position +1 .. Last_Non_Blank_Position)), E.Eventname);
     end;
     Table_Aevents.Aevents_List_Pack.Insert_At_Tail(Eventlist,E);

     P := Table_Aprices.Empty_Data;
     P.Marketid := M.Marketid;
     P.Selectionid := H.Selectionid;
     P.Pricets := H.Firsttaken;
     P.Layprice := H.Odds;
     P.Backprice := P.Layprice;

     Table_Aprices.Aprices_List_Pack.Insert_At_Tail(Pricelist,P);

     R := Table_Arunners.Empty_Data;
     R.Marketid := P.Marketid;
     R.Selectionid := P.Selectionid;
     Move(H.Selection, R.Runnername);

     if H.Winflag then
       Move("WINNER", R.Status);
     else
       Move("LOSER", R.Status);
     end if;
     Table_Arunners.Arunners_List_Pack.Insert_At_Tail(Runnerlist,R);

     L := Table_Alinks.Empty_Data;
     Move(H.Eventid'Img(2..10), L.Eventid);
     Move(H.Fulldescription, L.Eventname);
     L.Newid := 0;
     Table_Alinks.Alinks_List_Pack.Insert_At_Tail(Linklist,L);

   end loop;
   Stm.Close_Cursor;

   Log(Me, "read # Markets/Events: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);

 end Read_G1;
 ------------------------------------------------------------------------------------------

 procedure Insert_G4_Markets(List : in out Table_Amarkets.Amarkets_List_Pack.List_Type) is
 -- Me : constant String := "Insert_G4_Markets";
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
 -- Me : constant String := "Insert_G4_Events";
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
--  Me : constant String := "Insert_G4_Runners";
  Arunner : Table_Arunners.Data_Type;
  Left, Tot : Integer := 0;
 begin
 -- Log(Me, "Start");
  Tot := Table_Arunners.Arunners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Arunners.Arunners_List_Pack.Is_Empty(List) loop
    Table_Arunners.Arunners_List_Pack.Remove_From_Head(List,Arunner) ;
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
  end loop;
 -- Log(Me, "Stop");
 end Insert_G4_Runners;

 ------------------------------------------------------------------------------------------
 procedure Insert_G4_Prices (List : in out Table_Aprices.Aprices_List_Pack.List_Type) is
 -- Me : constant String := "Insert_G4_Prices";
  Aprice : Table_Aprices.Data_Type;
  Left, Tot : Integer := 0;
 begin
 -- Log(Me, "Start");
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
 -- Log(Me, "Stop");
 end Insert_G4_Prices;
 ---------------------------------------------------------------------------------
 procedure Insert_G4_Links (List : in out Table_Alinks.Alinks_List_Pack.List_Type) is
 -- Me : constant String := "Insert_G4_Links";
  Alink : Table_Alinks.Data_Type;
  Left, Tot : Integer := 0;
 begin
 -- Log(Me, "Start");
  Tot := Table_Alinks.Alinks_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Alinks.Alinks_List_Pack.Is_Empty(List) loop
    Table_Alinks.Alinks_List_Pack.Remove_From_Head(List,Alink) ;
    --
    Left := Left - 1;
    if Left > 0 and then Left mod 10_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Alinks.Insert(Alink);
    exception
      when Sql.Duplicate_Index => null;
--        Log("ignoring winner duplicate " & Table_Aprices.To_String(Aprice));
    end;
    -----------------------------------------
  end loop;
 -- Log(Me, "Stop");
 end Insert_G4_Links;
 -----------------------------------
 procedure Truncate_Destination_Tables is
   type Table_Type is (Aevents,
                       Amarkets,
                       Arunners,
                       Aprices,
                       Alinks);

   Truncate : array(Table_Type'range) of Sql.Statement_Type;
 begin
   for i in Table_Type'range loop
     Log ("Truncate_Destination_Tables", "Truncating " & i'img);
     Truncate(i).Prepare("truncate " & i'img);
     Truncate(i).Execute;
   end loop;
 end Truncate_Destination_Tables;

 ---------------------------------------------------------------------------------

 T : Sql.Transaction_Type;

 ------------------------------------------------------------------------------------------
begin
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Hostname'access,
     Long_Switch => "--hostname=",
     Help        => "hostname");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Database'access,
     Long_Switch => "--database=",
     Help        => "database");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Username'access,
     Long_Switch => "--username=",
     Help        => "username");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Password'access,
     Long_Switch => "--password=",
     Help        => "password");

   Getopt (Config);  -- process the command line

  if Sa_Par_Hostname.all = "" or else
    Sa_Par_Database.all = "" or else
    Sa_Par_Username.all = "" or else
    Sa_Par_Password.all = "" then
    Display_Help (Config);
    return;
  end if;

  Log(Me, "log into database");
  Sql.Connect
     (Host     => Sa_Par_Hostname.all,
      Port     => 5432,
      Db_Name  => Sa_Par_Database.all,
      Login    => Sa_Par_Username.all,
      Password => Sa_Par_Password.all);
  Log(Me, "db Connected");
  T.Start;
    Truncate_Destination_Tables;
  T.Commit;

  Startts    := (2012,01,01,00,00,00,000);
  Par_Stopts := (2014,01,01,00,00,00,000);
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
              G4_Link_List,
              Startts, Stopts);

      Insert_G4_Markets(G4_Market_List);
      Insert_G4_Events(G4_Event_List);
      Insert_G4_Runners(G4_Runner_List);
      Insert_G4_Prices(G4_Price_List);
      Insert_G4_Links (G4_Link_List);
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
end Migrate_G1_G4_Football;
