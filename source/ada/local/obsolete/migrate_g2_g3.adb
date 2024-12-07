

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Aprices;
with Table_Awinners;

with Table_Dryrunners;
with Table_Dryresults;
with Table_Drymarkets;
with Sql;
with Logging ; use Logging;
with Types; use Types;
with Calendar2; use Calendar2;
with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Stacktrace;


procedure Migrate_G2_G3 is
 Bad_Input : exception;

 Me : constant String := "Main"; 

 G2_Market_List : Table_Drymarkets.Drymarkets_List_Pack.List_Type := 
           Table_Drymarkets.Drymarkets_List_Pack.Create;

 G2_Runner_List : Table_Dryrunners.Dryrunners_List_Pack.List_Type := 
           Table_Dryrunners.Dryrunners_List_Pack.Create;

 G2_Result_List : Table_Dryresults.Dryresults_List_Pack.List_Type := 
           Table_Dryresults.Dryresults_List_Pack.Create;


           
 Sa_Par_Market_Type : aliased Gnat.Strings.String_Access;
 Sa_Par_Table    : aliased Gnat.Strings.String_Access;
 Ia_Animal     : aliased Integer := 0;
-- Ba_Daemon     : aliased Boolean := False;
 Config : Command_Line_Configuration;
           
           
           
 function Country_Code(C: String) return String is
 begin
  if C = "DEU" then
   return "DE";
  elsif C = "ITA" then
   return "IT";
  elsif C = "GBR" then
   return "GB";
  elsif C = "USA" then
   return "US";
  elsif C = "ZAF" then
   return "ZA";
  elsif C = "FRA" then
   return "FR";
  elsif C = "IRL" then
   return "IE";
  elsif C = "SGP" then
   return "SG";
  else
   return "XX";  
  end if;
 end Country_Code;
 ------------------------------------------------------------------------------------------
 procedure Read_G2_Markets(List : in out Table_Drymarkets.Drymarkets_List_Pack.List_Type;
              Animal : Integer;
              Market_Type : String) is
  Me : constant String := "Read_G2_Markets"; 
  Stm : Sql.Statement_Type;
  T : Sql.Transaction_Type;
 begin
  T.Start;
  if Animal = 7 then
   if Market_Type = "Plats" then
     Stm.Prepare("select * from DRYMARKETS " &
           "where EVENTHIERARCHY like '/7/%' " &
           "and MARKETNAME = 'Plats' " &
           "and MARKETTYPE = 'O' " &
           "and EXCHANGEID=1 " &
           "and MARKETSTATUS = 'ACTIVE' " );
   elsif Market_Type = "Vinnare" then
     Stm.Prepare("select * from DRYMARKETS " &
           "where EVENTHIERARCHY like '/7/%' " &
           "and MARKETNAME not like 'Rever%' " &
           "and MARKETNAME not like '% v %' " &
           "and MARKETNAME not like 'Fore%' " &
           "and MARKETNAME not like 'With%' " &
           "and MARKETNAME not like 'How Far%' " &
           "and MARKETNAME not like '%TBP%' " &
           "and MENUPATH not like '%pecials%' " &
           "and MARKETNAME <> 'TO BE PLACED' " &
           "and MARKETNAME <> 'Plats' " &
           "and MARKETNAME <> 'Kombinationer' " &
           "and NOOFRUNNERS > 7 " &
           "and MARKETTYPE = 'O' " &
           "and EXCHANGEID=1 " &
           "and MARKETSTATUS = 'ACTIVE' " );
   else
    T.Rollback;
    raise Bad_Input with "Market_Type not in 'Vinnare','Plats' : '" & Market_Type & "'";
   end if;   

  elsif Animal = 4339 then  
  Log(Me, "7");
   if Market_Type = "Plats" then
     Stm.Prepare("select * from DRYMARKETS " &
           "where EVENTHIERARCHY like '/4339/%' " &
           "and MARKETNAME = 'Plats' " &
           "and MARKETTYPE = 'O' " &
           "and EXCHANGEID=1 " &
           "and MARKETSTATUS = 'ACTIVE' " );
   elsif Market_Type = "Vinnare" then
     Stm.Prepare("select * from DRYMARKETS " & 
                 "where EVENTHIERARCHY like '/4339/%' " & 
                 "and  " &
                 "  (MARKETNAME like 'HC %' or " &
                 "   MARKETNAME like 'OR %' or " &
                 "   MARKETNAME ~ 'A[1-9] ' " &
                 ") " &
                 "and MARKETTYPE = 'O'  " &
                 "and EXCHANGEID=1  " &
                 "and MARKETSTATUS = 'ACTIVE'");
   else
    T.Rollback;
    raise Bad_Input with "Market_Type not in 'Vinnare','Plats' : '" & Market_Type & "'";
   end if;   
  
  else
    T.Rollback;
   raise Bad_Input with "Animal not in 7,4339 : " & Animal'Img;
  end if;
  Table_Drymarkets.Read_List(Stm, List);
  T.Commit;
  Log(Me, "read # DRYMARKETS: " & Table_Drymarkets.Drymarkets_List_Pack.Get_Count(List)'Img);
 
 end Read_G2_Markets; 
 ------------------------------------------------------------------------------------------

 procedure Insert_G2_Markets_Into_G3(List : in out Table_Drymarkets.Drymarkets_List_Pack.List_Type;
                   Animal : Integer;
                   Market_Type : String) is
  Me : constant String := "Insert_G2_Markets_Into_G3"; 
  T : Sql.Transaction_Type;
  Aevent,Aevent2 : Table_Aevents.Data_Type;
  Amarket,Amarket2 : Table_Amarkets.Data_Type;
  Dry_Market : Table_Drymarkets.Data_Type;
  Left, Tot : Integer := 0;
  type Eos_Type is (Event,Market);
  Eos : array (Eos_Type'range) of Boolean := (others => False);
 begin
  Log(Me, "Start");
  Tot := Table_Drymarkets.Drymarkets_List_Pack.Get_Count(List);
  Left := Tot;
  T.Start;
   while not Table_Drymarkets.Drymarkets_List_Pack.Is_Empty(List) loop
    Table_Drymarkets.Drymarkets_List_Pack.Remove_From_Head(List,Dry_Market) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
   
    Aevent := Table_Aevents.Empty_Data;
    Move("0." & Trim(Dry_Market.Marketid'Img), Aevent.Eventid);
    Move(Trim(Dry_Market.Marketname),Aevent.Eventname);
    Move(Country_Code(Dry_Market.Countrycode),Aevent.Countrycode );
    Move("None", Aevent.Timezone);
    Aevent.Opents   := Dry_Market.Eventdate;
    Aevent.Eventtypeid := Integer_4(Animal);
    -----------------------------------------

    Amarket := Table_Amarkets.Empty_Data;
    Move("0." & Trim(Dry_Market.Marketid'Img), Amarket.Marketid);
    Move("0." & Trim(Dry_Market.Marketid'Img), Amarket.Eventid);
    Move(Trim(Dry_Market.Marketname),Amarket.Marketname);
    Amarket.Startts := Dry_Market.Eventdate;
    if Market_Type = "Plats" then
     Move("PLACE",Amarket.Markettype);
    elsif Market_Type = "Vinnare" then
     Move("WIN",Amarket.Markettype);
    else
     raise Bad_Input with "Market_Type not in 'Vinnare','Plats' : '" & Market_Type & "'";
    end if;
    Move("OPEN",Amarket.status);
    Amarket.Betdelay := Dry_Market.Betdelay;
    Amarket.Numwinners := Dry_Market.Noofwinners;
    Amarket.Numrunners := Dry_Market.Noofrunners;
    Amarket.Numactiverunners := Dry_Market.Noofrunners;
    Amarket.Totalmatched := Float_8(Dry_Market.Totalmatched);
    Amarket.Totalavailable := 0.0;

    Aevent2 := Aevent;
    Table_Aevents.Read(Aevent, Eos(Event));
    if Eos(Event) then 
      Table_Aevents.Insert(Aevent);
    end if;
    
    Amarket2 := Amarket;
    Table_Amarkets.Read(Amarket, Eos(Market)); 
    if Eos(Market) then 
      Table_Amarkets.Insert(Amarket); 
    end if;  
    -----------------------------------------    
   end loop;
  T.Commit;
  Log(Me, "Stop");
 end Insert_G2_Markets_Into_G3;
 
 -----------------------------------------------------------------------------------------
 procedure Read_G2_Runners(List : in out Table_Dryrunners.Dryrunners_List_Pack.List_Type) is
  Me : constant String := "Read_G2_Runners"; 
  Stm : Sql.Statement_Type;
  T : Sql.Transaction_Type;
 begin
  T.Start;
   Stm.Prepare("select * from DRYRUNNERS order by MARKETID,SELECTIONID ");
   Table_Dryrunners.Read_List(Stm, List);
  T.Commit;
  Log(Me, "read # DRYRUNNERS: " & Table_Dryrunners.Dryrunners_List_Pack.Get_Count(List)'Img);
 end Read_G2_Runners; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G2_Runners_Into_G3 (List : in out Table_Dryrunners.Dryrunners_List_Pack.List_Type) is
  Me : constant String := "Insert_G2_Runners_Into_G3"; 
  T : Sql.Transaction_Type;
  Arunner : Table_Arunners.Data_Type;
  Aprice : Table_Aprices.Data_Type;
  Dry_Runner : Table_Dryrunners.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Dryrunners.Dryrunners_List_Pack.Get_Count(List);
  Left := Tot;
  T.Start;
   while not Table_Dryrunners.Dryrunners_List_Pack.Is_Empty(List) loop
    Table_Dryrunners.Dryrunners_List_Pack.Remove_From_Head(List,Dry_Runner) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    
    Arunner := Table_Arunners.Empty_Data;
    Move("0." & Trim(Dry_Runner.Marketid'Img), Arunner.Marketid);
    Arunner.Selectionid := Dry_Runner.Selectionid;
    Move(Trim(Dry_Runner.Runnername), Arunner.Runnername);
    Move(Trim(Dry_Runner.Runnernamestripped), Arunner.Runnernamestripped);
    Move(Trim(Dry_Runner.startnum), Arunner.Runnernamenum);
    Table_Arunners.Insert(Arunner);    
    -----------------------------------------
    
    Aprice := Table_Aprices.Empty_Data;
    Move("0." & Trim(Dry_Runner.Marketid'Img), Aprice.Marketid);
    Aprice.Selectionid := Dry_Runner.Selectionid;
    Aprice.Pricets := Clock;
    Move("ACTIVE", Aprice.status);
    Aprice.totalmatched := 0.0;
    Aprice.Backprice := Dry_Runner.Backprice;
    Aprice.Layprice := Dry_Runner.Layprice;
    Table_Aprices.Insert(Aprice);   
   end loop;    
  T.Commit;
  Log(Me, "Stop");
 
 
 end Insert_G2_Runners_Into_G3;
 
 ------------------------------------------------------------------------------------------
 
 
 procedure Read_G2_Results(List : in out Table_Dryresults.Dryresults_List_Pack.List_Type) is
  Me : constant String := "Read_G2_Results"; 
  Stm : Sql.Statement_Type;
  T : Sql.Transaction_Type;
 begin
  T.Start;
   Stm.Prepare("select * from DRYRESULTS order by MARKETID,SELECTIONID ");
   Table_Dryresults.Read_List(Stm, List);
  T.Commit;
  Log(Me, "read # DRYRESULTS: " & Table_Dryresults.Dryresults_List_Pack.Get_Count(List)'Img);
 end Read_G2_Results; 

 
 ------------------------------------------------------------------------------------------
 procedure Insert_G2_Winners_Into_G3 (List : in out Table_Dryresults.Dryresults_List_Pack.List_Type) is
  Me : constant String := "Insert_G2_Winners_Into_G3"; 
  T : Sql.Transaction_Type;
  Awinner : Table_Awinners.Data_Type;
  Dry_Result : Table_Dryresults.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Dryresults.Dryresults_List_Pack.Get_Count(List);
  Left := Tot;
  T.Start;
   while not Table_Dryresults.Dryresults_List_Pack.Is_Empty(List) loop
    Table_Dryresults.Dryresults_List_Pack.Remove_From_Head(List,Dry_Result) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    
    Awinner := Table_Awinners.Empty_Data;
    Move("0." & Trim(Dry_Result.Marketid'Img), Awinner.Marketid);
    Awinner.Selectionid := Dry_Result.Selectionid;
    Table_Awinners.Insert(Awinner);    
   end loop;
  T.Commit;
  Log(Me, "Stop");
 end Insert_G2_Winners_Into_G3;
 
 
 ------------------------------------------------------------------------------------------
begin 

  Define_Switch
  (Config,
   Sa_Par_Market_Type'access,
   "-m:",
   Long_Switch => "--markettype=",
   Help    => "'Plats', 'Vinnare'");
  Define_Switch
  (Config,
   Ia_Animal'access,
   "-a:",
   Long_Switch => "--animal=",
   Help    => "animal, 7=horse 4339=hound");

 Define_Switch
   (Config,
   Sa_Par_Table'access,
   "-t:",
   Long_Switch => "--table=",
   Help    => "what to convert (market, runner, winner)");
 Getopt (Config); -- process the command line




 -- log in to old database
 Log(Me, "log in to old database");
 Sql.Connect
    (Host   => "192.168.0.13",
     Port   => 5432,
     Db_Name => "betting",
     Login  => "bnl",
     Password => "bnl");
 Log(Me, "db Connected");
 
 if Sa_Par_Table.all = "market" then
  -- read to list
  Read_G2_Markets(G2_Market_List, Ia_Animal, Sa_Par_Market_Type.all);
 elsif Sa_Par_Table.all = "runner" then
  Read_G2_Runners(G2_Runner_List);
 elsif Sa_Par_Table.all = "winner" then
  Read_G2_Results(G2_Result_List);
 else
  raise Bad_Input with "market not in market, runner, winner : '" & Sa_Par_Table.all & "'";
 end if;
 
 Log(Me, "close old db");
 Sql.Close_Session;
 
 -- 
 
 Log(Me, "log in to new database");
 Sql.Connect
    (Host   => "localhost",
     Port   => 5432,
     Db_Name => "bnl",
     Login  => "bnl",
     Password => "bnl");
 Log(Me, "db Connected");
 
 
 -- insert stuff
 if Sa_Par_Table.all = "market" then
  Insert_G2_Markets_Into_G3(G2_Market_List, Ia_Animal, Sa_Par_Market_Type.all);
 elsif Sa_Par_Table.all = "runner" then
  Insert_G2_Runners_Into_G3(G2_Runner_List);
 elsif Sa_Par_Table.all = "winner" then
  Insert_G2_Winners_Into_G3(G2_Result_List);
 else
  raise Bad_Input with "market not in market, runner, winner : '" & Sa_Par_Table.all & "'";
 end if;

 Log(Me, "close new db");
 Sql.Close_Session;

exception
  when  Gnat.Command_Line.Invalid_Switch =>
    Display_Help(Config);
  when E: others => 
    Stacktrace.Tracebackinfo(E); 
 
end Migrate_G2_G3;