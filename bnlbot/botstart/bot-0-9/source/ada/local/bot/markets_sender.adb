--with Text_Io;
with Sattmate_Exception;
with Sql;
with Sattmate_Calendar;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;
with Sattmate_Types ; use Sattmate_Types;
with Lock ;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Posix;
with Table_Amarkets;
with Table_Awinners;
with Table_Aevents;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;
--with Ada.Directories;
with Process_IO;
with Bot_Messages;

procedure Markets_Sender is
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;

  Me : constant String := "Main.";
  Ba_Daemon    : aliased Boolean := False;
  Ba_Log       : aliased Boolean := False;
  Sa_Par_Marketid : aliased Gnat.Strings.String_Access;
  Config : Command_Line_Configuration;
  My_Lock  : Lock.Lock_Type;
  T : Sql.Transaction_Type;
  Markets : Sql.Statement_Type;

------------------------------ main start -------------------------------------
  Amarkets_List : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;
  Amarket :  Table_Amarkets.Data_Type;
  Aevent :  Table_Aevents.Data_Type;
  Awinner : Table_Awinners.Data_Type;
  MNR      : Bot_Messages.Market_Notification_Record;
  Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
  Tot,Cur : Natural := 0;
  type Eos_Type is (Event,Winner);
  Eos : array (Eos_Type'range) of Boolean := (others => False);

begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");

  Define_Switch
     (Config,
      Ba_Log'access,
      "-l",
      Long_Switch => "--log",
      Help        => "open logfile ");

  Define_Switch
     (Config,
      Sa_Par_Marketid'access,
      "-m",
      Long_Switch => "--marketid",
      Help        => "read markets with MARKETID > marketid ");
      
  Define_Switch
     (Config,
      Ba_Daemon'access,
      "-d",
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");
  Getopt (Config);  -- process the command line

  if Ba_Log then
    Logging.Open(EV.Value("BOT_HOME") & "/log/markets_sender.log");
  end if;

  if Ba_Daemon then
     Posix.Daemonize;
  end if;

   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take("markets_sender");

  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));

  T.Start;
  
  if Sa_Par_Marketid.all /= "" then
    Markets.Prepare("select * from AMARKETS where MARKETID > :MARKETID order by MARKETID");
    Markets.Set("MARKETID", Sa_Par_Marketid.all);
  else
    Markets.Prepare("select * from AMARKETS  order by MARKETID");
  end if;
  Table_Amarkets.Read_List(Stm => Markets, List  => Amarkets_List);
--  Table_Amarkets.Read_All(List  => Amarkets_List, Order=> True);
  T.Commit;
  Tot := Table_Amarkets.Amarkets_List_Pack.Get_Count(Amarkets_List);
  Log(Me, "found # markets:" & Tot'Img );
  while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(Amarkets_List) loop
     Cur := Cur +1;
     Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(Amarkets_List, Amarket);
     Awinner.Marketid := Amarket.Marketid;
     Table_Awinners.Read_One_Marketid(Awinner,False,Eos(Winner));
     if not Eos(Winner) then -- need to have a winner
       MNR.Market_Id := (others => ' ');
       Move(Amarket.Marketid, MNR.Market_Id);
       
       Aevent.Eventid := Amarket.Eventid;
       Table_Aevents.Read(Aevent,Eos(Event));
       
       if not Eos(Event) then
        if Aevent.Eventtypeid = 7 then       -- horse
          if Trim(Amarket.Markettype) = "PLACE" then
            Move("horse_plc_xx", Receiver.Name);
          elsif Trim(Amarket.Markettype) = "WIN" then     
            if    Aevent.Countrycode = "US" then
              Move("horse_win_us", Receiver.Name);
            elsif Aevent.Countrycode = "GB" then
              Move("horse_win_gb", Receiver.Name);
            elsif Aevent.Countrycode = "IE" then
              Move("horse_win_ie", Receiver.Name);
            elsif Aevent.Countrycode = "ZA" then
              Move("horse_win_za", Receiver.Name);
            elsif Aevent.Countrycode = "SG" then
              Move("horse_win_sg", Receiver.Name);
            elsif Aevent.Countrycode = "FR" then
              Move("horse_win_fr", Receiver.Name);
            else
              Move("horse_win_xx", Receiver.Name);            
            end if;            
          end if;
        
        elsif Aevent.Eventtypeid = 4339 then -- hound
          if Trim(Amarket.Markettype) = "PLACE" then
              Move("hound_plc_xx", Receiver.Name);
          elsif Trim(Amarket.Markettype) = "WIN" then     
              Move("hound_win_xx", Receiver.Name);
          end if;        
        end if;
       
         Log(Me, "Notifying " & Trim(Receiver.Name) & " with marketid: '" & MNR.Market_Id   & " Startts = " &
                  Sattmate_Calendar.String_Date_And_Time(Amarket.Startts, Milliseconds => true)
                  & "'" & Cur'Img & "/" & Tot'Img);
         Bot_Messages.Send(Receiver, MNR);
       end if;        
     end if;
  end loop;

  Log(Me, "shutting down, close db");
  Sql.Close_Session;
  Log(Me, "do_exit");
  Posix.Do_Exit(0); -- terminate
  Log(Me, "after do_exit");

exception
  when Lock.Lock_Error =>
      Posix.Do_Exit(0); -- terminate

  when E: others =>
    Sattmate_Exception.Tracebackinfo(E);
    Posix.Do_Exit(0); -- terminate
end Markets_Sender;

