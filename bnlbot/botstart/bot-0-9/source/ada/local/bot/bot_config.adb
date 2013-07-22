
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

  Unimplemented    : exception ;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
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
   -- function Get_Bet_Type is new Ini.Get_Enumeration_Value(Bet_Type_Type);
   -- function Get_Animal is new Ini.Get_Enumeration_Value(Animal_Type);
  begin
    Log(Me & "Read start");
    if not Command_Line_Is_Parsed then
      Define_Switch
       (Cmd_Line,
        Sa_Par_Bot_User'access,
        "-u:",
        Long_Switch => "--user=",
        Help        => "user of bot");
  
      Define_Switch
        (Cmd_Line,
         Ba_Daemon'access,
         "-d",
         Long_Switch => "--daemon",
         Help        => "become daemon at startup");
      Getopt (Cmd_Line);  -- process the command line 
      Command_Line_Is_Parsed := True;
    end if; 
    Cfg.Bot_User := To_Unbounded_String(Sa_Par_Bot_User.all);
      
    if Ev.Exists("BOT_HOME") then
    
      Cfg.Bot_Log_File_Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/log/") & Cfg.Bot_User & To_Unbounded_String(".log");
    
      Ini.Load(Ev.Value("BOT_HOME") & "/" & "betfair.ini") ;
      -- Gloal
      Cfg.Global_Section.Delay_Between_Turns_Bad_Funding := 
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns_Bad_Funding","60.0"));

      Cfg.Global_Section.Delay_Between_Turns_No_Markets := 
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns_No_Markets","7.0"));

      Cfg.Global_Section.Delay_Between_Turns := 
           Float_8'Value(Ini.Get_Value("Global","Delay_Between_Turns","5.0"));

      Cfg.Global_Section.Network_Failure_Delay := 
           Float_8'Value(Ini.Get_Value("Global","Network_Failure_Delay","60.0"));

      --system, expanded ...
      Cfg.System_Section.Bot_Root   := To_Unbounded_String(EV.Value("BOT_ROOT"));
      Cfg.System_Section.Bot_Config := To_Unbounded_String(EV.Value("BOT_CONFIG"));
      Cfg.System_Section.Bot_Target := To_Unbounded_String(EV.Value("BOT_TARGET"));
      Cfg.System_Section.Bot_Source := To_Unbounded_String(EV.Value("BOT_SOURCE"));
      Cfg.System_Section.Bot_Script := To_Unbounded_String(EV.Value("BOT_SCRIPT"));
      Cfg.System_Section.Bot_Home   := To_Unbounded_String(EV.Value("BOT_HOME"));
      Cfg.System_Section.Daemonize  := Ba_Daemon;
      
      declare
        Num_Sections : Natural := Ini.Get_Section_Count;
        Bet_Section : Bet_Section_Type;
      begin
        for i in 1 .. Num_Sections loop
          Log("Read","Section: " & Ini.Get_Section_Name(i));
          if Lower_Case(Ini.Get_Section_Name(i)) /= "system" and Lower_Case(Ini.Get_Section_Name(i)) /= "global" then  
            Bet_Section.Bet_Name := To_Unbounded_String(Ini.Get_Section_Name(i));
            
            Bet_Section.Enabled := Ini.Get_Value(Ini.Get_Section_Name(i),"enabled", False);
            
            Bet_Section.Max_Daily_Loss :=
               Max_Daily_Loss_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_daily_loss",""));
            Bet_Section.Max_Daily_Profit :=
               Max_Daily_Profit_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_daily_profit",""));
            Bet_Section.Back_Price :=
               Back_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"back_price","0.0"));
            Bet_Section.Delta_Price :=
               Delta_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"delta_price","0.0"));
            Bet_Section.Max_Lay_Price :=
               Max_Lay_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_lay_price","0.0"));
            Bet_Section.Min_Lay_Price :=
               Min_Lay_Price_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"min_lay_price","0.0"));
            Bet_Section.Bet_Size :=
               Bet_Size_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"bet_size",""));
            Bet_Section.Dry_Run := Ini.Get_Value(Ini.Get_Section_Name(i),"dry_run", True);
            Bet_Section.Allow_In_Play := Ini.Get_Value(Ini.Get_Section_Name(i),"allow_in_play", False);
            Bet_Section.Max_Num_Runners :=
               Max_Num_Runners_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"max_num_runners",""));
            Bet_Section.Min_Num_Runners :=
               Min_Num_Runners_Type'Value(Ini.Get_Value(Ini.Get_Section_Name(i),"min_num_runners",""));
            
--            Bet_Section.Animal := Get_Animal(Ini.Get_Section_Name(i),"animal",Horse);
--            Bet_Section.Bet_Type := Get_Bet_Type(Ini.Get_Section_Name(i),"bet_type",Back);
            
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_lay_") > 0 then 
              Bet_Section.Bet_Type := Lay;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_back_") > 0 then 
              Bet_Section.Bet_Type := Back;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "hounds_") > 0 then 
              Bet_Section.Animal := Hound;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "horses_") > 0 then 
              Bet_Section.Animal := Horse;
            end if;
            
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_plc_") > 0 then 
              Bet_Section.Market_Type := Place;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_place_") > 0 then 
              Bet_Section.Market_Type := Place;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_winner_") > 0 then 
              Bet_Section.Market_Type := Winner;
            end if;
            if Position( Lower_Case(To_String(Bet_Section.Bet_Name)), "_win_") > 0 then 
              Bet_Section.Market_Type := Winner;
            end if;
            
            
            Bet_Section.Countries :=
               To_Unbounded_String(Ini.Get_Value(Ini.Get_Section_Name(i),"countries",""));
            Bet_Pack.Insert_At_Tail(Cfg.Bet_Section_List, Bet_Section);   
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
       "<Main>" &
         "<Bot_User>" & To_String(Cfg.Bot_User) & "</Bot_User>" &
         "<Bot_Log_File_Name>" & To_String(Cfg.Bot_Log_File_Name) & "</Bot_Log_File_Name>" &
         "<System>" & 
           "<Bot_Root>"   & To_String(Cfg.System_Section.Bot_Root) & "</Bot_Root>" &
           "<Bot_Config>" & To_String(Cfg.System_Section.Bot_Config) & "</Bot_Config>" & 
           "<Bot_Target>" & To_String(Cfg.System_Section.Bot_Target) & "</Bot_Target>" & 
           "<Bot_Source>" & To_String(Cfg.System_Section.Bot_Source) & "</Bot_Source>" & 
           "<Bot_Script>" & To_String(Cfg.System_Section.Bot_Script) & "</Bot_Script>" & 
           "<Bot_Home>" & To_String(Cfg.System_Section.Bot_Home) & "</Bot_Home>" &   
           "<Daemonize>" & Cfg.System_Section.Daemonize'Img & "</Daemonize>" &
         "</System>" &
         "<Global>" &
           "<Delay_Between_Turns_Bad_Funding>" & Cfg.Global_Section.Delay_Between_Turns_Bad_Funding'Img & "</Delay_Between_Turns_Bad_Funding>" &
           "<Delay_Between_Turns_No_Markets>" & Cfg.Global_Section.Delay_Between_Turns_No_Markets'Img & "</Delay_Between_Turns_No_Markets>" & 
           "<Delay_Between_Turns>" & Cfg.Global_Section.Delay_Between_Turns'Img & "</Delay_Between_Turns>" & 
           "<Network_Failure_Delay>" & Cfg.Global_Section.Network_Failure_Delay'Img & "</Network_Failure_Delay>" &          
         "</Global>" & 
         "<Bets>" );
           
           Bet_Pack.Get_First(Cfg.Bet_Section_List, Bet_Section,Eol);
           loop
             exit when Eol;
             Append(Return_String,
             "<Bets>" &
               "<Bet_Name>" & To_String(Bet_Section.Bet_Name) & "</Bet_Name>" &
               "<Max_Daily_Loss>" & Bet_Section.Max_Daily_Loss'Img & "</Max_Daily_Loss>" & 
               "<Max_Daily_Profit>" & Bet_Section.Max_Daily_Profit'Img & "</Max_Daily_Profit>" & 
               "<Back_Price>" & Bet_Section.Back_Price'Img & "</Back_Price>" & 
               "<Delta_Price>" & Bet_Section.Delta_Price'Img & "</Delta_Price>" & 
               "<Max_Lay_Price>" & Bet_Section.Max_Lay_Price'Img & "</Max_Lay_Price>" & 
               "<Min_Lay_Price>" & Bet_Section.Min_Lay_Price'Img & "</Min_Lay_Price>" & 
               "<Max_Daily_Loss>" & Bet_Section.Max_Daily_Loss'Img & "</Max_Daily_Loss>" & 
               "<Bet_Size>" & Bet_Section.Bet_Size'Img & "</Bet_Size>" & 
               "<Dry_Run>" & Bet_Section.Dry_Run'Img & "</Dry_Run>" & 
               "<Allow_In_Play>" & Bet_Section.Allow_In_Play'Img & "</Allow_In_Play>" & 
               "<Animal>" & Bet_Section.Animal'Img & "</Animal>" & 
               "<Bet_Type>" & Bet_Section.Bet_Type'Img & "</Bet_Type>" & 
               "<Max_Num_Runners>" & Bet_Section.Max_Num_Runners'Img & "</Max_Num_Runners>" & 
               "<Min_Num_Runners>" & Bet_Section.Min_Num_Runners'Img & "</Min_Num_Runners>" & 
               "<Countries>" & To_String(Bet_Section.Countries) & "</Countries>" & 
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
       "</Main>");
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
