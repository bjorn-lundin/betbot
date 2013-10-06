
--with Text_IO;
with Ini;
with Ada.Environment_Variables;
with General_Routines; use General_Routines;

with Logging ; use Logging;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;


package body Bot_Config is

  Me : constant String := "Config.";
  package EV renames Ada.Environment_Variables;
  Bad_Data,
  Unimplemented    : exception ;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Mode     : aliased Gnat.Strings.String_Access;
  Sa_Par_Dispatch : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  Command_Line_Is_Parsed : Boolean := False;
  Empty_Config : Config_Type;

  procedure Re_Read_Config is
  begin
    Config.Clear;
    Config.Read;
  end Re_Read_Config;

    -----------------------------------------------------

  procedure Read(Cfg : in out Config_Type) is
    function Get_Bet_Mode is new Ini.Get_Enumeration_Value(Bet_Mode_Type);
   -- function Get_Animal is new Ini.Get_Enumeration_Value(Animal_Type);
   type Cfg_Type is (Bet, Market, Animal);
   Was_Set : array (Cfg_Type'range) of Boolean := (others => False);
  begin
    Log(Me & "Read start");
    if not Command_Line_Is_Parsed then
      Define_Switch
       (Cmd_Line,
        Sa_Par_Bot_User'access,
        Long_Switch => "--user=",
        Help        => "user of bot");

      Define_Switch
       (Cmd_Line,
        Sa_Par_Mode'access,
        Long_Switch => "--mode=",
        Help        => "mode of bot - (real, simulation)");

      Define_Switch
       (Cmd_Line,
        Sa_Par_Dispatch'access,
        Long_Switch => "--dispatch=",
        Help        => "bets received");

      Define_Switch
        (Cmd_Line,
         Ba_Daemon'access,
         Long_Switch => "--daemon",
         Help        => "become daemon at startup");
         
      Define_Switch
        (Cmd_Line,
         Sa_Par_Inifile'access,
         Long_Switch => "--inifile=",
         Help        => "use alternative inifile");
      Getopt (Cmd_Line);  -- process the command line
      Command_Line_Is_Parsed := True;
    end if;
    Cfg.Bot_User := To_Unbounded_String(Sa_Par_Bot_User.all);

    if Ev.Exists("BOT_HOME") then

      Cfg.Bot_Log_File_Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/log/") & Cfg.Bot_User & To_Unbounded_String(".log");
      
      if Sa_Par_Inifile.all = "" then
        Cfg.Bot_Ini_File_Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/" & "betfair.ini");
      else 
        Cfg.Bot_Ini_File_Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
      end if;      
      Ini.Load(To_String(Cfg.Bot_Ini_File_Name)) ;
      
      -- Gloal
      Cfg.Global_Section.Delay_Between_Turns_Bad_Funding :=
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns_Bad_Funding","60.0"));

      Cfg.Global_Section.Delay_Between_Turns_No_Markets :=
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns_No_Markets","7.0"));

      Cfg.Global_Section.Delay_Between_Turns :=
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns","5.0"));

      Cfg.Global_Section.Network_Failure_Delay :=
           Float_8'Value(Ini.Get_Value("Global","Network_Failure_Delay","60.0"));
           
      Cfg.Global_Section.Logging := Ini.Get_Value("Global", "logging", True);

      --system, expanded ...
      Cfg.System_Section.Bot_Root   := To_Unbounded_String(EV.Value("BOT_ROOT"));
      Cfg.System_Section.Bot_Config := To_Unbounded_String(EV.Value("BOT_CONFIG"));
      Cfg.System_Section.Bot_Target := To_Unbounded_String(EV.Value("BOT_TARGET"));
      Cfg.System_Section.Bot_Source := To_Unbounded_String(EV.Value("BOT_SOURCE"));
      Cfg.System_Section.Bot_Script := To_Unbounded_String(EV.Value("BOT_SCRIPT"));
      Cfg.System_Section.Bot_Home   := To_Unbounded_String(EV.Value("BOT_HOME"));
      Cfg.System_Section.Daemonize  := Ba_Daemon;

--      Log("Read","Cfg.System_Section.Bot_Mode: '" &  Sa_Par_Mode.all & "'" &  Sa_Par_Mode.all'first'img &  Sa_Par_Mode.all'last'img);
      if Sa_Par_Mode.all'length >= 3 and then Sa_Par_Mode.all(Sa_Par_Mode.all'first .. Sa_Par_Mode.all'first + 3 -1) = "sim" then
        Cfg.System_Section.Bot_Mode  := Simulation;  -- real by default
      end if;

      declare
        Num_Sections : Natural := Ini.Get_Section_Count;
        Bet_Section : Bet_Section_Type;
      begin
        for i in 1 .. Num_Sections loop
          Log("Read","Section: " & Ini.Get_Section_Name(i));
          if Lower_Case(Ini.Get_Section_Name(i)) /= "system" and Lower_Case(Ini.Get_Section_Name(i)) /= "global" then

            Bet_Section.Bet_Name := To_Unbounded_String(Ini.Get_Section_Name(i));
            Bet_Section.Enabled := Ini.Get_Value(Ini.Get_Section_Name(i),"enabled", False);
            Bet_Section.Max_Daily_Loss := Max_Daily_Loss_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_daily_loss",""));
            Bet_Section.Max_Daily_Profit := Max_Daily_Profit_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_daily_profit",""));
            Bet_Section.Max_Daily_Num_Losses := Integer_4(Ini.Get_Value(Ini.Get_Section_Name(i),"max_daily_num_losses",0));
            Bet_Section.Max_Num_In_The_Air := Integer_4(Ini.Get_Value(Ini.Get_Section_Name(i),"max_num_in_the_air",0));
            
            Bet_Section.Back_Price := Back_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"back_price","0.0"));
            Bet_Section.Delta_Price := Delta_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"delta_price","0.0"));
            Bet_Section.Max_Lay_Price := Max_Lay_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_lay_price","0.0"));
            Bet_Section.Min_Lay_Price := Min_Lay_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"min_lay_price","0.0"));
            Bet_Section.Bet_Size := Bet_Size_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"bet_size",""));
--            Bet_Section.Dry_Run := Ini.Get_Value(Ini.Get_Section_Name(i),"dry_run", True);
            Bet_Section.Lay_Exit_Early := Ini.Get_Value(Ini.Get_Section_Name(i),"lay_exit_early", False);
            Bet_Section.Allow_In_Play := Ini.Get_Value(Ini.Get_Section_Name(i),"allow_in_play", False);
            Bet_Section.Max_Num_Runners := Max_Num_Runners_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_num_runners",""));
            Bet_Section.Min_Num_Runners := Min_Num_Runners_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"min_num_runners",""));
            Bet_Section.Num_Winners := Num_Winners_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"no_of_winners",""));
            Bet_Section.Powerdays := Integer_4(Ini.Get_Value(Ini.Get_Section_Name(i),"powerdays",0));
            Bet_Section.Max_Odds := Back_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_odds","20.0"));

            Bet_Section.Bet_Mode := Get_Bet_Mode(Ini.Get_Section_Name(i),"mode", Sim) ;

--            Bet_Section.Animal := Get_Animal(Ini.Get_Section_Name(i),"animal",Horse);
--            Bet_Section.Bet_Type := Get_Bet_Type(Ini.Get_Section_Name(i),"bet_type",Back);

            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay_") > Natural(0) then
              Bet_Section.Bet_Type := Lay;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_back_") > Natural(0) then
              Bet_Section.Bet_Type := Back;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay1_") > Natural(0) then
              Bet_Section.Bet_Type := Lay1;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay2_") > Natural(0) then
              Bet_Section.Bet_Type := Lay2;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay3_") > Natural(0) then
              Bet_Section.Bet_Type := Lay3;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay4_") > Natural(0) then
              Bet_Section.Bet_Type := Lay4;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay5_") > Natural(0) then
              Bet_Section.Bet_Type := Lay5;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay6_") > Natural(0) then
              Bet_Section.Bet_Type := Lay6;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay7_") > Natural(0) then
              Bet_Section.Bet_Type := Lay7;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay8_") > Natural(0) then
              Bet_Section.Bet_Type := Lay8;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay9_") > Natural(0) then
              Bet_Section.Bet_Type := Lay9;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_fav2_") > Natural(0) then
              Bet_Section.Bet_Type := Fav2;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_fav3_") > Natural(0) then
              Bet_Section.Bet_Type := Fav3;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_fav4_") > Natural(0) then
              Bet_Section.Bet_Type := Fav4;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_fav5_") > Natural(0) then
              Bet_Section.Bet_Type := Fav5;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_fav6_") > Natural(0) then
              Bet_Section.Bet_Type := Fav6;
              Was_Set(Bet) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "hounds_") > Natural(0) then
              Bet_Section.Animal := Hound;
              Was_Set(Animal) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "horses_") > Natural(0) then
              Bet_Section.Animal := Horse;
              Was_Set(Animal) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_plc_") > Natural(0) then
              Bet_Section.Market_Type := Place;
              Was_Set(Market) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_place_") > Natural(0) then
              Bet_Section.Market_Type := Place;
              Was_Set(Market) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_winner_") > Natural(0) then
              Bet_Section.Market_Type := Winner;
              Was_Set(Market) := True;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_win_") > Natural(0) then
              Bet_Section.Market_Type := Winner;
              Was_Set(Market) := True;
            end if;

            for i in Was_Set'range loop
              if not Was_Set(i) then
                raise Bad_Data with I'Img & " was not set";
              end if;
              Was_Set(i) := False; --reset
            end loop;

            Bet_Section.Countries := To_Unbounded_String(Ini.Get_Value(Ini.Get_Section_Name(i),"countries",""));

            declare
              Days : String := Ini.Get_Value(Ini.Get_Section_Name(i),"allowed_days","al");
              Day  : String(1..2) := (others => ' ');
              Index : Integer := 1;
              use Sattmate_Calendar;
            begin
              --reset
              for i in Week_Day_Type'range loop
                Bet_Section.Allowed_Days(i) := False;
              end loop;

              for i in Days'range loop
                case Days(i) is
                  when ',' =>
                    if    Lower_Case(Day) = "al" then
                      for i in Week_Day_Type'range loop
                        Bet_Section.Allowed_Days(i) := True;
                      end loop;
                    elsif    Lower_Case(Day) = "mo" then
                      Bet_Section.Allowed_Days(Monday) := True;
                    elsif Lower_Case(Day) = "tu" then
                      Bet_Section.Allowed_Days(Tuesday) := True;
                    elsif Lower_Case(Day) = "we" then
                      Bet_Section.Allowed_Days(Wednesday) := True;
                    elsif Lower_Case(Day) = "th" then
                      Bet_Section.Allowed_Days(Thursday) := True;
                    elsif Lower_Case(Day) = "fr" then
                      Bet_Section.Allowed_Days(Friday) := True;
                    elsif Lower_Case(Day) = "sa" then
                      Bet_Section.Allowed_Days(Saturday) := True;
                    elsif Lower_Case(Day) = "su" then
                      Bet_Section.Allowed_Days(Sunday) := True;
                    else
                      raise Bad_Data with "day = " & Day;
                    end if;
                  when others =>
                    case Index is
                      when 1 =>
                        Day(1) := Days(i);
                        Index := 2;
                      when 2 =>
                        Day(2) := Days(i);
                        Index := 1;
                      when others => raise Bad_Data with "Index = " & Index'Img;
                    end case;
                end case;
              end loop;
              -- check also for the last entry (mo,fr)
              if    Lower_Case(Day) = "al" then
                for i in Week_Day_Type'range loop
                  Bet_Section.Allowed_Days(i) := True;
                end loop;
              elsif    Lower_Case(Day) = "mo" then
                Bet_Section.Allowed_Days(Monday) := True;
              elsif Lower_Case(Day) = "tu" then
                Bet_Section.Allowed_Days(Tuesday) := True;
              elsif Lower_Case(Day) = "we" then
                Bet_Section.Allowed_Days(Wednesday) := True;
              elsif Lower_Case(Day) = "th" then
                Bet_Section.Allowed_Days(Thursday) := True;
              elsif Lower_Case(Day) = "fr" then
                Bet_Section.Allowed_Days(Friday) := True;
              elsif Lower_Case(Day) = "sa" then
                Bet_Section.Allowed_Days(Saturday) := True;
              elsif Lower_Case(Day) = "su" then
                Bet_Section.Allowed_Days(Sunday) := True;
              else
                raise Bad_Data with "day = " & Day;
              end if;
            end;

            Bet_Pack.Insert_At_Tail(Cfg.Bet_Section_List, Bet_Section);
          end if;
          if Float_8(Bet_Section.Max_Lay_Price) < Float_8(Bet_Section.Min_Lay_Price) then
            raise Bad_Config with "Max < Min: " & To_String(Bet_Section.Bet_Name);
          end if;
        end loop;
      end;
      -- ok, parse login stuff

      Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
      --betfair stuff
      Cfg.Betfair_Section.Username   := To_Unbounded_String(Ini.Get_Value("betfair","username",""));
      Cfg.Betfair_Section.Password   := To_Unbounded_String(Ini.Get_Value("betfair","password",""));
      Cfg.Betfair_Section.Product_Id := To_Unbounded_String(Ini.Get_Value("betfair","product_id",""));
      Cfg.Betfair_Section.Vendor_Id  := To_Unbounded_String(Ini.Get_Value("betfair","vendor_id",""));
      Cfg.Betfair_Section.App_Key    := To_Unbounded_String(Ini.Get_Value("betfair","appkey",""));
      --db stuff
      Cfg.Database_Section.Name       := To_Unbounded_String(Ini.Get_Value("database","name",""));
      Cfg.Database_Section.Username   := To_Unbounded_String(Ini.Get_Value("database","username",""));
      Cfg.Database_Section.Password   := To_Unbounded_String(Ini.Get_Value("database","password",""));
      Cfg.Database_Section.Host       := To_Unbounded_String(Ini.Get_Value("database","host",""));


    else --exists
      raise Unimplemented with "BOT_HOME not set";
    end if;
    Log(Me & "read stop");
  end Read;

  -----------------------------------------------------

  function To_String(Cfg : Config_Type) return String is
    Eol : Boolean := True;
    Bet_Section : Bet_Section_Type;
    Return_String : Unbounded_String := Null_Unbounded_String;
  begin
    Return_String := To_Unbounded_String(
       "<Config>" &
         "<Bot_User>" & To_String(Cfg.Bot_User) & "</Bot_User>" &
         "<Bot_Log_File_Name>" & To_String(Cfg.Bot_Log_File_Name) & "</Bot_Log_File_Name>" &
         "<Bot_Ini_File_Name>" & To_String(Cfg.Bot_Ini_File_Name) & "</Bot_Ini_File_Name>" &
         "<System>" &
           "<Bot_Root>"   & To_String(Cfg.System_Section.Bot_Root) & "</Bot_Root>" &
           "<Bot_Config>" & To_String(Cfg.System_Section.Bot_Config) & "</Bot_Config>" &
           "<Bot_Target>" & To_String(Cfg.System_Section.Bot_Target) & "</Bot_Target>" &
           "<Bot_Source>" & To_String(Cfg.System_Section.Bot_Source) & "</Bot_Source>" &
           "<Bot_Script>" & To_String(Cfg.System_Section.Bot_Script) & "</Bot_Script>" &
           "<Bot_Home>" & To_String(Cfg.System_Section.Bot_Home) & "</Bot_Home>" &
           "<Daemonize>" & Cfg.System_Section.Daemonize'Img & "</Daemonize>" &
           "<Bot_Mode>" & Cfg.System_Section.Bot_Mode'Img & "</Bot_Mode>" &
         "</System>" &
         "<Global>" &
           "<Delay_Between_Turns_Bad_Funding>" & F8_Image(Cfg.Global_Section.Delay_Between_Turns_Bad_Funding) & "</Delay_Between_Turns_Bad_Funding>" &
           "<Delay_Between_Turns_No_Markets>" & F8_Image(Cfg.Global_Section.Delay_Between_Turns_No_Markets) & "</Delay_Between_Turns_No_Markets>" &
           "<Delay_Between_Turns>" & F8_Image(Cfg.Global_Section.Delay_Between_Turns) & "</Delay_Between_Turns>" &
           "<Network_Failure_Delay>" & F8_Image(Cfg.Global_Section.Network_Failure_Delay) & "</Network_Failure_Delay>" &
           "<Logging>" & Cfg.Global_Section.Logging'Img & "</Logging>" &
         "</Global>" &
         "<Bets>" );

           Bet_Pack.Get_First(Cfg.Bet_Section_List, Bet_Section,Eol);
           loop
             exit when Eol;
             Append(Return_String,
             "<Bets>" &
               "<Bet_Name>" & To_String(Bet_Section.Bet_Name) & "</Bet_Name>" &
               "<Max_Daily_Loss>" & F8_Image(Float_8(Bet_Section.Max_Daily_Loss)) & "</Max_Daily_Loss>" &
               "<Max_Daily_Profit>" & F8_Image(Float_8(Bet_Section.Max_Daily_Profit)) & "</Max_Daily_Profit>" &
               "<Back_Price>" & F8_Image(Float_8(Bet_Section.Back_Price)) & "</Back_Price>" &
               "<Delta_Price>" & F8_Image(Float_8(Bet_Section.Delta_Price)) & "</Delta_Price>" &
               "<Max_Lay_Price>" & F8_Image(Float_8(Bet_Section.Max_Lay_Price)) & "</Max_Lay_Price>" &
               "<Min_Lay_Price>" & F8_Image(Float_8(Bet_Section.Min_Lay_Price)) & "</Min_Lay_Price>" &
               "<Favorite_By>" & F8_Image(Float_8(Bet_Section.Favorite_By)) & "</Favorite_By>" &
               "<Bet_Size>" & F8_Image(Float_8(Bet_Section.Bet_Size)) & "</Bet_Size>" &
               "<Bet_Mode>" & Bet_Section.Bet_Mode'Img & "</Bet_Mode>" &
               "<Allow_In_Play>" & Bet_Section.Allow_In_Play'Img & "</Allow_In_Play>" &
               "<Lay_Exit_Early>" & Bet_Section.Lay_Exit_Early'Img & "</Lay_Exit_Early>" &
               "<Animal>" & Bet_Section.Animal'Img & "</Animal>" &
               "<Bet_Type>" & Bet_Section.Bet_Type'Img & "</Bet_Type>" &
               "<Market_Type>" & Bet_Section.Market_Type'Img & "</Market_Type>" &
               "<Max_Num_Runners>" & Bet_Section.Max_Num_Runners'Img & "</Max_Num_Runners>" &
               "<Min_Num_Runners>" & Bet_Section.Min_Num_Runners'Img & "</Min_Num_Runners>" &
               "<Num_Winners>" & Bet_Section.Num_Winners'Img & "</Num_Winners>" &
               "<Countries>" & To_String(Bet_Section.Countries) & "</Countries>" &
               "<Max_Odds>" & F8_Image(Float_8(Bet_Section.Max_Odds)) & "</Max_Odds>" &
             "</Bets>"  );
             Bet_Pack.Get_Next(Cfg.Bet_Section_List, Bet_Section, Eol);
           end loop;
         Append(Return_String,
         "</Bets>"  &
         "<Betfair>" &
           "<Username>" & To_String(Cfg.Betfair_Section.Username) & "</Username>" &
           "<Password>" & To_String(Cfg.Betfair_Section.Password) & "</Password>" &
           "<Product_Id>" & To_String(Cfg.Betfair_Section.Product_Id) & "</Product_Id>" &
           "<Vendor_Id>" & To_String(Cfg.Betfair_Section.Vendor_Id) & "</Vendor_Id>" &
         "</Betfair>" &
         "<Database>" &
           "<Name>" & To_String(Cfg.Database_Section.Name) & "</Name>" &
           "<Username>" & To_String(Cfg.Database_Section.Username) & "</Username>" &
           "<Password>" & To_String(Cfg.Database_Section.Password) & "</Password>" &
           "<Host>" & To_String(Cfg.Database_Section.Host) & "</Host>" &
         "</Database>" &
       "</Config>");
       return To_String(Return_String);
  end To_String;

  procedure Clear(Cfg : in out Config_Type)is
  begin
    Log(Me & "Clear start");
    Bet_Pack.Remove_All(Cfg.Bet_Section_List);
    Cfg := Empty_Config;
    Log(Me & "Clear stop");
  end Clear;
  ---------------------------------------------

end Bot_Config;
