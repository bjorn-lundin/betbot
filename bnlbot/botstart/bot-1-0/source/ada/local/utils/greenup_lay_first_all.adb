with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Ada.Containers;
with Ada.Containers.Doubly_Linked_Lists;
--with Bot_System_Number;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
--with Bot_Messages;
with Rpc;
with Lock ;
--with Posix;
with Ini;
with Logging; use Logging;
--with Process_IO;
--with Core_Messages;
with Table_Amarkets;
--with Table_Aevents;
with Table_Aprices;
--with Table_Abalances;
with Table_Apriceshistory;
with Bot_Svn_Info;
--with Config;
--with Utils; use Utils;
with Table_Abets;
with Table_Arunners;
with Tics;
with Sim;


procedure Greenup_Lay_First_All is

  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;
  use type Ada.Containers.Count_Type;

  Me              : constant String := "Greenup_Lay_First_All.";

  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Cmd_Line        : Command_Line_Configuration;
  -------------------------------------------------------------
  type Bet_Type is record
    Laybet            : Table_Abets.Data_Type := Table_Abets.Empty_Data;
    Greenup_Backbet   : Table_Abets.Data_Type := Table_Abets.Empty_Data;
    Stop_Loss_Backbet : Table_Abets.Data_Type := Table_Abets.Empty_Data;
  end record;
  use type Table_Abets.Data_Type;
  package Bet_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Bet_Type);
  Bet_List : Bet_List_Pack.List;
  
  
--  Bet_List : array (Delta_Tics_Type'range) of Bet_List_Pack.List;

  Back_Stake      : constant Bet_Size_Type := 30.0;
  Lay_Stake       : constant Bet_Size_Type := 40.0;
  Stop_Loss_Stake : constant Bet_Size_Type := 40.0;

  subtype Max_Layprice_Type is Integer_4 range 100 .. 100;
  subtype Min_Layprice_Type is Integer_4 range  50 .. 50;
  subtype Delta_Tics_Greenup_Type is Integer range 10 .. 20;
  subtype Delta_Tics_Stop_Loss_Type is Integer range 100 .. 200;

  -----------------------------------------------------------------
  procedure Check_Bet ( R : in Table_Arunners.Data_Type;
                        B : in out Table_Abets.Data_Type) is
  begin
    if R.Status(1..7) = "REMOVED" then
      return;
    end if;
    if B.Side(1..4) = "BACK" then
        if R.Status(1..6) = "WINNER" then
          B.Betwon := True;
          B.Profit := Float_8(Back_Stake) * (B.Price - 1.0);
        elsif R.Status(1..5) = "LOSER" then
          B.Betwon := False;
          B.Profit := Float_8(-Back_Stake);
        elsif R.Status(1..7) = "REMOVED" then
          B.Status(1) := 'R';
          B.Betwon := True;
        end if;
    elsif B.Side(1..3) = "LAY" then
        if R.Status(1..6) = "WINNER" then
          B.Betwon := False;
          B.Profit := Float_8(-Lay_Stake) * (B.Price - 1.0);
        elsif R.Status(1..5) = "LOSER" then
          B.Profit := Float_8(Lay_Stake);
          B.Betwon := True;
        elsif R.Status(1..7) = "REMOVED" then
          B.Status(1) := 'R';
          B.Betwon := True;
        end if;
    end if;
    B.Insert;
  end Check_Bet;

  -----------------------------------------------------------------

  procedure Run(Price_Data : in Table_Aprices.Data_Type;
                Delta_Tics_Greenup : in Integer;
                Delta_Tics_Stop_Loss : in Integer;
                Min_Layprice : in Min_Layprice_Type;
                Max_Layprice : in Max_Layprice_Type ) is

    Market    : Markets.Market_Type;
    --Event     : Table_AEvents.Event_Type;
    Eos               : Boolean := False;
    Price_During_Race_List : Table_Apriceshistory.Apriceshistory_List_Pack2.List;
    Runner : Table_Arunners.Data_Type;
    Tic_Lay : Integer := 0;
    Bet : Bet_Type;
    Last_Price : Table_Apriceshistory.Data_Type;
    Lay_Bet_Name   : constant Bet_Name_Type := "2_HOUNDS_WIN_GREEN_UP_LAY                                                                           ";
    Back_Bet_Name  : constant Bet_Name_Type := "2_HOUNDS_WIN_GREEN_UP_BACK                                                                          ";
    Stop_Loss_Name : constant Bet_Name_Type := "2_HOUNDS_WIN_GREEN_UP_BACK_STOP_LOSS                                                                ";
    Dst_Change : Calendar2.Time_Type := (2016,03,27,03,0,0,0);
  begin
   -- Log(Me & "Run", "Treat market: " &  Price_Data.Marketid);
    Market.Marketid := Price_Data.Marketid;
    Market.Read(Eos);
    if Eos then
      Log(Me & "Run", "no market found");
      return;
    end if;
    
    --fix dst/utc
    if Market.Startts < Dst_Change then
      Market.Startts := Market.Startts + (0,1,0,0,0); -- 1 hour
    elsif Market.Startts > Dst_Change then
      Market.Startts := Market.Startts + (0,2,0,0,0); -- 2 hours
    end if;  
    
    Log(Me & "Run", "Market: " & Market.To_String);
    Sim.Read_Marketid_Selectionid(Marketid    => Market.Marketid,  
                                  Selectionid => Price_Data.Selectionid, 
                                  List        => Price_During_Race_List) ;

    Runner.Marketid := Price_Data.Marketid;
    Runner.Selectionid := Price_Data.Selectionid;
    Runner.Read(Eos);

    if Price_During_Race_List.Length > 80 then
      if Eos then
        Log(Me & "Run", "no runner found found  " & Runner.To_String);
      end if;     
      Tic_Lay := Tics.Get_Tic_Index(Price_Data.Layprice);
      
      Sim.Place_Bet(Bet_Name         => Lay_Bet_Name,
                    Market_Id        => Market.Marketid,
                    Side             => Lay,
                    Runner_Name      => Runner.Runnernamestripped,
                    Selection_Id     => Price_Data.Selectionid,
                    Size             => Lay_Stake,
                    Price            => Bet_Price_Type(Price_Data.Layprice),
                    Bet_Persistence  => Persist,
                    Bet_Placed       => Price_Data.Pricets,
                    Bet              => Bet.Laybet ) ;
      Move("M",Bet.Laybet.Status);
      Move(Max_Layprice'Img & '/' & Trim(Min_Layprice'Img,Both) & '/' & Trim(Delta_Tics_Greenup'Img,Both) & '/' & Trim(Delta_Tics_Stop_Loss'Img,Both), Bet.Laybet.Reference);
      Check_Bet(Runner, Bet.Laybet);

      Sim.Place_Bet(Bet_Name         => Back_Bet_Name,
                    Market_Id        => Market.Marketid,
                    Side             => Back,
                    Runner_Name      => Runner.Runnernamestripped,
                    Selection_Id     => Price_Data.Selectionid,
                    Size             => Back_Stake,
                    Price            => Bet_Price_Type(Tics.Get_Tic_Price(Tic_Lay + Delta_Tics_Greenup)),
                    Bet_Persistence  => Persist,
                    Bet_Placed       => Price_Data.Pricets,
                    Bet              => Bet.Greenup_Backbet ) ;
      Move("U",Bet.Greenup_Backbet.Status);
      Move(Max_Layprice'Img & '/' & Trim(Min_Layprice'Img,Both) & '/' & Trim(Delta_Tics_Greenup'Img,Both) & '/' & Trim(Delta_Tics_Stop_Loss'Img,Both), Bet.Greenup_Backbet.Reference);

      Sim.Place_Bet(Bet_Name         => Stop_Loss_Name,
                    Market_Id        => Market.Marketid,
                    Side             => Back,
                    Runner_Name      => Runner.Runnernamestripped,
                    Selection_Id     => Price_Data.Selectionid,
                    Size             => Stop_Loss_Stake,
                    Price            => Bet_Price_Type(Tics.Get_Tic_Price(Tic_Lay - Delta_Tics_Stop_Loss)),
                    Bet_Persistence  => Persist,
                    Bet_Placed       => Price_Data.Pricets,
                    Bet              => Bet.Stop_Loss_Backbet ) ;
      Move("U",Bet.Stop_Loss_Backbet.Status);
      Move(Max_Layprice'Img & '/' & Trim(Min_Layprice'Img,Both) & '/' & Trim(Delta_Tics_Greenup'Img,Both) & '/' & Trim(Delta_Tics_Stop_Loss'Img,Both), Bet.Stop_Loss_Backbet.Reference);
      
      
      --Log(Me & "Run", "Price_Data " & Price_Data.To_String);
      --Log(Me & "Run", "Bet.Laybet " & Bet.Laybet.To_String);
      --Log(Me & "Run", "Bet.Greenup_Backbet " & Bet.Greenup_Backbet.To_String);
      --Log(Me & "Run", "Bet.Stop_Loss_Backbet " & Bet.Stop_Loss_Backbet.To_String);

      -- see if we meet stop_loss or greenup
      for Race_Data of Price_During_Race_List loop
        --Log(Me & "Run", "Race_Data " & Race_Data.To_String);
        --Log(Me & "Run", " Race_Data.Backprice >= Bet.Greenup_Backbet.Price " & Boolean(Race_Data.Backprice >= Bet.Greenup_Backbet.Price)'img);
        --Log(Me & "Run", " Race_Data.Backprice <= Bet.Stop_Loss_Backbet.Price " & Boolean(Race_Data.Backprice <= Bet.Stop_Loss_Backbet.Price)'img);
            
        if Price_Data.Backprice > Float_8(0.0) and then Price_Data.Layprice > Float_8(0.0) then   -- must be valid
          if Race_Data.Pricets >= Price_Data.Pricets then   -- must be later in time
            if Price_Data.Selectionid = Race_Data.Selectionid then -- same dog
              if    Race_Data.Backprice >= Bet.Greenup_Backbet.Price then -- a match
                Move("M",Bet.Greenup_Backbet.Status);
                exit;
              elsif Race_Data.Backprice <= Bet.Stop_Loss_Backbet.Price then -- a match
                Move("M",Bet.Stop_Loss_Backbet.Status);
                exit;
              end if;
            end if;
          end if;
        end if;
        Last_Price := Race_Data;
      --  Log(Me & "Run", "Race_Data.Pricets >= Market.Startts " & Boolean(Race_Data.Pricets >= Market.Startts)'img);
        exit when Race_Data.Pricets >= Market.Startts; --- closing time
      end loop;
      
      --if we are not matched, then stop_loss
      if  Bet.Greenup_Backbet.Status(1) = 'U' and then
        Bet.Stop_Loss_Backbet.Status(1) = 'U' then
          Bet.Stop_Loss_Backbet.Price := Last_Price.Backprice;
          Move("M",Bet.Stop_Loss_Backbet.Status);
          Move("C",Bet.Greenup_Backbet.Status);
      end if;
      Check_Bet(Runner, Bet.Greenup_Backbet);
      Check_Bet(Runner, Bet.Stop_Loss_Backbet);

     -- Bet_List.Insert
    else
      Log(Me & "not enough data for runner" & Price_During_Race_List.Length'Img, Price_Data.To_String);
    end if;
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------
begin

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line
   
  if not EV.Exists("BOT_NAME") then
    EV.Set("BOT_NAME","greenup_lfa");
  end if;  

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database_ghd", "host", ""),
         Port     => Ini.Get_Value("database_ghd", "port", 5432),
         Db_Name  => Ini.Get_Value("database_ghd", "name", ""),
         Login    => Ini.Get_Value("database_ghd", "username", ""),
         Password =>Ini.Get_Value("database_ghd", "password", ""));
  Log(Me, "db Connected");


  declare
    Stm : Sql.Statement_Type;
    T   : Sql.Transaction_Type;
    Price_List  : Table_Aprices.Aprices_List_Pack2.List;
  begin  
    T.Start;
    Stm.Prepare(
     "select P.* " &
     "from APRICES P, AMARKETS M, AEVENTS E " &
     "where E.EVENTID=M.EVENTID " &
     "and M.MARKETTYPE = 'WIN' " &
     "and E.COUNTRYCODE in ('GB','IE') " &
     "and P.MARKETID = M.MARKETID " &
     "and E.EVENTTYPEID = 4339 " &
     "and M.STARTTS::date > '2016-03-10' " &
   --  "and P.LAYPRICE <= :MAX_LAYPRICE " &
   --  "and P.LAYPRICE >= :MIN_LAYPRICE " &
     "order by M.STARTTS, P.MARKETID, P.SELECTIONID ");
    Table_Aprices.Read_List(Stm, Price_List);
    T.Commit;

    for Max_Layprice in Max_Layprice_Type'range loop
      for Min_Layprice in Min_Layprice_Type'range loop
        declare
          Layprice_High : Float_8 := Float_8(Max_Layprice)/10.0;
          Layprice_Low  : Float_8 := Float_8(Min_Layprice)/10.0;
        begin
          for Price of Price_List loop
            if Price.Layprice <= Layprice_High and then
               Price.Layprice >= Layprice_Low then
               
              Log(Me & "Run", "Treat market:" & Min_Layprice'Img & " " & Max_Layprice'Img & " " & Price.To_String );
              T.Start;
              for Dtg in Delta_Tics_Greenup_Type'range loop
                for Dtsl in Delta_Tics_Stop_Loss_Type'range loop                  
                  Log(Me & "Run", "Treat market:" & Min_Layprice'Img & " " & Max_Layprice'Img & " " & Dtg'Img & " " & Dtsl'Img & " " & Price.To_String );
                  Run(Price_Data           => Price, 
                      Delta_Tics_Greenup   => Dtg, 
                      Delta_Tics_Stop_Loss => Dtsl,
                      Min_Layprice         => Min_Layprice, 
                      Max_Layprice         => Max_Layprice);
                end loop;
              end loop;
              T.Commit;
            end if; 
          end loop;  
        end;
      end loop;
    end loop;
  end;
  
  Log(Me, "Close Db");
  Sql.Close_Session;
  Logging.Close;
  
exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;
    Log(Me, "Closed log and die");
    Logging.Close;
end Greenup_Lay_First_All;

