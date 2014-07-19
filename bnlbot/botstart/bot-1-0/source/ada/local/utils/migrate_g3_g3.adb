

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Anonrunners;
with Table_Aprices;
with Table_Awinners;

with Sql;
with Logging ; use Logging;
--with Types; use Types;
with Calendar2; use Calendar2;
--with Ada.Strings ; use Ada.Strings;
--with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Stacktrace;


procedure Migrate_G3_G3 is
--  Bad_Input : exception;
 
  Me : constant String := "Main"; 
 
  G3_Market_List : Table_Amarkets.Amarkets_List_Pack.List_Type := 
            Table_Amarkets.Amarkets_List_Pack.Create;
            
  G3_Event_List : Table_Aevents.Aevents_List_Pack.List_Type := 
            Table_Aevents.Aevents_List_Pack.Create;
 
  G3_Price_List : Table_Aprices.Aprices_List_Pack.List_Type := 
            Table_Aprices.Aprices_List_Pack.Create;
                       
  G3_Runner_List : Table_Arunners.Arunners_List_Pack.List_Type := 
            Table_Arunners.Arunners_List_Pack.Create;
            
  G3_Nonrunner_List : Table_Anonrunners.Anonrunners_List_Pack.List_Type := 
            Table_Anonrunners.Anonrunners_List_Pack.Create;
 
  G3_Winner_List : Table_Awinners.Awinners_List_Pack.List_Type := 
            Table_Awinners.Awinners_List_Pack.Create;
            
  Sa_Par_Startts   : aliased Gnat.Strings.String_Access;
  Sa_Par_Stopts    : aliased Gnat.Strings.String_Access;
  
  Par_Startts   : Calendar2.Time_Type;
  Par_Stopts    : Calendar2.Time_Type;
  
  Config : Command_Line_Configuration;
             
 ------------------------------------------------------------------------------------------
 procedure Read_G3_Markets(List : in out Table_Amarkets.Amarkets_List_Pack.List_Type;
                           Startts : Calendar2.Time_Type;
                           Stopts  : Calendar2.Time_Type
                           ) is
  Me : constant String := "Read_G3_Markets"; 
  Stm : Sql.Statement_Type;
 begin
  Stm.Prepare("select * from AMARKETS " &
         "where STARTTS >= :STARTTS " &
         "and STARTTS <= :STOPTS ");
  Stm.Set_Timestamp("STARTTS", Startts);       
  Stm.Set_Timestamp("STOPTS", Stopts);       
  Table_Amarkets.Read_List(Stm, List);
  Log(Me, "read # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(List)'Img);
 
 end Read_G3_Markets; 
 ------------------------------------------------------------------------------------------

 procedure Insert_G3_Markets(List : in out Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Markets"; 
  Amarket: Table_Amarkets.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Amarkets.Amarkets_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(List) loop
    Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(List,AMarket) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    Table_Amarkets.Insert(Amarket); 
  end loop;
  Log(Me, "Stop");
 end Insert_G3_Markets;
 -----------------------------------------------------------------------------------------
 
 
 procedure Remove_Old_G3_Markets_Already_In_New_Db(List : in out Table_Amarkets.Amarkets_List_Pack.List_Type) is
   Tmp_List  : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;
   Amarket: Table_Amarkets.Data_Type;
   Eos : Boolean := False;
 begin  -- this is run in new db
   while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(List) loop
     Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(List, Amarket);
     Table_Amarkets.Read(Amarket, Eos) ;
     if Eos then -- keep only if not in new db
       Table_Amarkets.Amarkets_List_Pack.Insert_At_Tail(Tmp_List, Amarket);
     end if;
   end loop;
 
   -- move back to oldlist
   while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(Tmp_List) loop
     Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(Tmp_List, Amarket);
     Table_Amarkets.Amarkets_List_Pack.Insert_At_Tail(List, Amarket);
   end loop;
  
   Table_Amarkets.Amarkets_List_Pack.Release(Tmp_List);
 end Remove_Old_G3_Markets_Already_In_New_Db;

 
 -----------------------------------------------------------------------------------------
 procedure Read_G3_Runners(List       : in out Table_Arunners.Arunners_List_Pack.List_Type;
                           Marketlist : in     Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Read_G3_Runners"; 
  Stm : Sql.Statement_Type;
  Amarket: Table_Amarkets.Data_Type;
  Eol : Boolean := True;
 begin
  Log(Me, "will read RUNNERS for # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
  Table_Amarkets.Amarkets_List_Pack.Get_First(Marketlist,Amarket,Eol);
  loop
     exit when Eol;
     Stm.Prepare("select * from ARUNNERS where MARKETID = :MARKETID ");
     Stm.Set("MARKETID", Amarket.Marketid);
     Table_Arunners.Read_List(Stm, List);
     Table_Amarkets.Amarkets_List_Pack.Get_Next(Marketlist,Amarket,Eol);
  end loop;
  Log(Me, "read # ARUNNERS: " & Table_Arunners.Arunners_List_Pack.Get_Count(List)'Img);
 end Read_G3_Runners; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G3_Runners (List : in out Table_Arunners.Arunners_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Runners"; 
  Arunner : Table_Arunners.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Arunners.Arunners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Arunners.Arunners_List_Pack.Is_Empty(List) loop
    Table_Arunners.Arunners_List_Pack.Remove_From_Head(List,Arunner) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    Table_Arunners.Insert(Arunner);    
    -----------------------------------------
  end loop;    
  Log(Me, "Stop");
 end Insert_G3_Runners;
 
 ------------------------------------------------------------------------------------------


 procedure Read_G3_Prices(List       : in out Table_Aprices.Aprices_List_Pack.List_Type;
                          Marketlist : in     Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Read_G3_Prices"; 
  Stm : Sql.Statement_Type;
  Amarket: Table_Amarkets.Data_Type;
  Eol : Boolean := True;
 begin
  Log(Me, "will read PRICES for # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
  Table_Amarkets.Amarkets_List_Pack.Get_First(Marketlist,Amarket,Eol);
  loop
     exit when Eol;
     Stm.Prepare("select * from APRICES where MARKETID = :MARKETID ");
     Stm.Set("MARKETID", Amarket.Marketid);
     Table_Aprices.Read_List(Stm, List);
     Table_Amarkets.Amarkets_List_Pack.Get_Next(Marketlist,Amarket,Eol);
  end loop;
  Log(Me, "read # APRICES: " & Table_Aprices.Aprices_List_Pack.Get_Count(List)'Img);
 end Read_G3_Prices; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G3_Prices (List : in out Table_Aprices.Aprices_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Prices"; 
  Aprice : Table_Aprices.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Aprices.Aprices_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Aprices.Aprices_List_Pack.Is_Empty(List) loop
    Table_Aprices.Aprices_List_Pack.Remove_From_Head(List,Aprice) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    Table_Aprices.Insert(Aprice);    
    -----------------------------------------
  end loop;    
  Log(Me, "Stop");
 end Insert_G3_Prices;
 ---------------------------------------------------------------------------------

 procedure Read_G3_Winners(List       : in out Table_Awinners.Awinners_List_Pack.List_Type;
                          Marketlist : in     Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Read_G3_Winners"; 
  Stm : Sql.Statement_Type;
  Amarket: Table_Amarkets.Data_Type;
  Eol : Boolean := True;
 begin
  Log(Me, "will read WINNERS for # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
  Table_Amarkets.Amarkets_List_Pack.Get_First(Marketlist,Amarket,Eol);
  loop
    exit when Eol;
    Stm.Prepare("select * from AWINNERS where MARKETID = :MARKETID ");
    Stm.Set("MARKETID", Amarket.Marketid);
    Table_Awinners.Read_List(Stm, List);
    Table_Amarkets.Amarkets_List_Pack.Get_Next(Marketlist,Amarket,Eol);
  end loop;
  Log(Me, "read # Awinners: " & Table_Awinners.Awinners_List_Pack.Get_Count(List)'Img);
 end Read_G3_Winners; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G3_Winners (List : in out Table_Awinners.Awinners_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Winners"; 
  Awinner : Table_Awinners.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Awinners.Awinners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Awinners.Awinners_List_Pack.Is_Empty(List) loop
    Table_Awinners.Awinners_List_Pack.Remove_From_Head(List,Awinner) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Awinners.Insert(Awinner);
    exception
      when Sql.Duplicate_Index =>
        Log("ignoring winner duplicate " & Table_Awinners.To_String(Awinner));
    end;  
    -----------------------------------------
  end loop;    
  Log(Me, "Stop");
 end Insert_G3_Winners;
 
 
  ---------------------------------------------------------------------------------

 procedure Read_G3_Nonrunners(List       : in out Table_Anonrunners.Anonrunners_List_Pack.List_Type;
                              Marketlist : in     Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Read_G3_Nonrunners"; 
  Stm : Sql.Statement_Type;
  Amarket: Table_Amarkets.Data_Type;
  Eol : Boolean := True;
 begin
  Log(Me, "will read NONRUNNERS for # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
   Table_Amarkets.Amarkets_List_Pack.Get_First(Marketlist,Amarket,Eol);
  loop
    exit when Eol;
    Stm.Prepare("select * from ANONRUNNERS where MARKETID = :MARKETID ");
    Stm.Set("MARKETID", Amarket.Marketid);
    Table_Anonrunners.Read_List(Stm, List);
    Table_Amarkets.Amarkets_List_Pack.Get_Next(Marketlist,Amarket,Eol);
  end loop;
  Log(Me, "read # ANONRUNNERS: " & Table_Anonrunners.Anonrunners_List_Pack.Get_Count(List)'Img);
 end Read_G3_Nonrunners; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G3_Nonrunners (List : in out Table_Anonrunners.Anonrunners_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Nonrunners"; 
  Nonrunner : Table_Anonrunners.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Anonrunners.Anonrunners_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Anonrunners.Anonrunners_List_Pack.Is_Empty(List) loop
    Table_Anonrunners.Anonrunners_List_Pack.Remove_From_Head(List,Nonrunner) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Anonrunners.Insert(Nonrunner);    
    exception
      when Sql.Duplicate_Index =>
        Log("ignoring nonrunner duplicate " & Table_Anonrunners.To_String(NonRunner));
    end;  
    -----------------------------------------
  end loop;    
  Log(Me, "Stop");
 end Insert_G3_Nonrunners;
 
 ----------------------------------------------------------------------------------------------------
 
 procedure Read_G3_Events(List       : in out Table_Aevents.Aevents_List_Pack.List_Type;
                          Marketlist : in     Table_Amarkets.Amarkets_List_Pack.List_Type) is
  Me : constant String := "Read_G3_Events"; 
  Stm : Sql.Statement_Type;
  Amarket: Table_Amarkets.Data_Type;
  Eol : Boolean := True;
 begin
  Log(Me, "will read EVENTS for # AMARKETS: " & Table_Amarkets.Amarkets_List_Pack.Get_Count(Marketlist)'Img);
  Table_Amarkets.Amarkets_List_Pack.Get_First(Marketlist,Amarket,Eol);
  loop
    exit when Eol;
    Stm.Prepare("select * from AEVENTS where EVENTID = :EVENTID ");
    Stm.Set("EVENTID", Amarket.Eventid);
    Table_Aevents.Read_List(Stm, List);
    Table_Amarkets.Amarkets_List_Pack.Get_Next(Marketlist,Amarket,Eol);
  end loop;
  Log(Me, "read # AEVENTS: " & Table_Aevents.Aevents_List_Pack.Get_Count(List)'Img);
 end Read_G3_Events; 

 ------------------------------------------------------------------------------------------
 procedure Insert_G3_Events (List : in out Table_Aevents.Aevents_List_Pack.List_Type) is
  Me : constant String := "Insert_G3_Events"; 
  Event : Table_Aevents.Data_Type;
  Left, Tot : Integer := 0;
 begin
  Log(Me, "Start");
  Tot := Table_Aevents.Aevents_List_Pack.Get_Count(List);
  Left := Tot;
  while not Table_Aevents.Aevents_List_Pack.Is_Empty(List) loop
    Table_Aevents.Aevents_List_Pack.Remove_From_Head(List,Event) ;
    -- 
    Left := Left - 1;
    if Left mod 1_000 = 0 then
      Log ("left/tot :" & Left'img & "/" & Trim(Tot'Img));
    end if;
    begin
      Table_Aevents.Insert(Event);    
    exception -- many markets to 1 event...
      when Sql.Duplicate_Index => null;
    end;  
     
   -----------------------------------------
  end loop;    
  Log(Me, "Stop");
 end Insert_G3_Events;
 
 T : Sql.Transaction_Type;
 
 ------------------------------------------------------------------------------------------
begin 

  Define_Switch
  (Config,
   Sa_Par_Startts'access,
   Long_Switch => "--startts=",
   Help    => "timestamp of first market, yyyy-mm-dd_hh24:mi:ss.ms");
  Define_Switch
  (Config,
   Sa_Par_Stopts'access,
   Long_Switch => "--stopts=",
   Help    => "timestamp of last market, yyyy-mm-dd_hh24:mi:ss.ms");

   Getopt (Config); -- process the command line

   Log(Me, "Par_Startts: '" & Sa_Par_Startts.all & "'");
   Log(Me, "Par_Stopts:  '" & Sa_Par_Stopts.all & "'");

   Par_Startts := (2013,08,11,13,15,00,001);
   Par_Stopts  := (2013,12,31,23,29,29,999);
   Log(Me, "hardcoded dates 2013-08-11_12:51:00.001  -> 2013-12-31_23:59:59.999");
    
   
--   Par_Startts := Calendar2.To_Time_Type(Sa_Par_Startts.all(1..10), Sa_Par_Startts.all(12..23) );
--   Par_Stopts  := Calendar2.To_Time_Type(Sa_Par_Stopts.all(1..10),  Sa_Par_Stopts.all(12..23) );   

  -- log in to old database
  Log(Me, "log in to old database");
  Sql.Connect
     (Host   => "192.168.1.13",
      Port   => 5432,
      Db_Name => "bnl",
      Login  => "bnl",
      Password => "bnl");
  Log(Me, "db Connected");
 
  -- read to list
  T.Start;
    Read_G3_Markets(G3_Market_List,Par_Startts ,Par_Stopts);
  T.Commit;

  Log(Me, "close old db");
  Sql.Close_Session;
 
  Log(Me, "log in to new database");
  Sql.Connect
     (Host   => "localhost",
      Port   => 5432,
      Db_Name => "bnl",
      Login  => "bnl",
      Password => "bnl");
  Log(Me, "db Connected");

  -- remove markets alreayd in new db from list
  T.Start;
    Remove_Old_G3_Markets_Already_In_New_Db(G3_Market_List);
  T.Commit;
  
  Log(Me, "close new db");
  Sql.Close_Session;
  
  
  Log(Me, "log in to old database");
  Sql.Connect
     (Host   => "192.168.1.13",
      Port   => 5432,
      Db_Name => "bnl",
      Login  => "bnl",
      Password => "bnl");
  Log(Me, "db Connected");
  
  Log(Me, "read rest in old db");

  T.Start;
    Read_G3_Events(G3_Event_List, G3_Market_List);
    Read_G3_Nonrunners(G3_Nonrunner_List, G3_Market_List);
    Read_G3_Prices(G3_Price_List, G3_Market_List);
    Read_G3_Runners(G3_Runner_List, G3_Market_List);
    Read_G3_Winners(G3_Winner_List, G3_Market_List);
  T.Commit;

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
 

  T.Start;
   Insert_G3_Markets(G3_Market_List);
   Insert_G3_Events(G3_Event_List);
   Insert_G3_Nonrunners(G3_Nonrunner_List);
   Insert_G3_Prices(G3_Price_List);
   Insert_G3_Runners(G3_Runner_List);
   Insert_G3_Winners(G3_Winner_List);
  T.Commit;

 
  Log(Me, "close new db");
  Sql.Close_Session;

exception
  when  Gnat.Command_Line.Invalid_Switch =>
    Display_Help(Config);
  when E: others => 
    Stacktrace.Tracebackinfo(E); 
 
end Migrate_G3_G3;