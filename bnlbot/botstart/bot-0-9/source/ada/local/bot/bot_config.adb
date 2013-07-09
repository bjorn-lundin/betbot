
with Text_IO;
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

  Sa_Par_Bot_Name : aliased Gnat.Strings.String_Access;
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
    function Get_Bet_Type is new Ini.Get_Enumeration_Value(Bet_Type_Type);
    function Get_Animal is new Ini.Get_Enumeration_Value(Animal_Type);
  begin
    Log(Me & "Read start");
    if not Command_Line_Is_Parsed then
      Define_Switch
       (Cmd_Line,
        Sa_Par_Bot_Name'access,
        "-n:",
        Long_Switch => "--name=",
        Help        => "name of bot");
  
      Define_Switch
        (Cmd_Line,
         Ba_Daemon'access,
         "-d",
         Long_Switch => "--daemon",
         Help        => "become daemon at startup");
      Getopt (Cmd_Line);  -- process the command line 
      Command_Line_Is_Parsed := True;
    end if; 
    Cfg.Bot_Name := To_Unbounded_String(Sa_Par_Bot_Name.all);
      
    if Ev.Exists("BOT_HOME") then
    
      Cfg.Bot_Log_File_Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/log/") & Cfg.Bot_Name & To_Unbounded_String(".log");
    
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

      
      -- who are we? parse commandline
      Cfg.Bet_Section.Max_Daily_Loss :=
         Max_Daily_Loss_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"max_daily_loss",""));
      Cfg.Bet_Section.Max_Daily_Profit :=
         Max_Daily_Profit_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"max_daily_profit",""));
      Cfg.Bet_Section.Back_Price :=
         Back_Price_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"back_price","0.0"));
      Cfg.Bet_Section.Delta_Price :=
         Delta_Price_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"delta_price","0.0"));
      Cfg.Bet_Section.Max_Lay_Price :=
         Max_Lay_Price_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"max_lay_price","0.0"));
      Cfg.Bet_Section.Min_Lay_Price :=
         Min_Lay_Price_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"min_lay_price","0.0"));
      Cfg.Bet_Section.Bet_Size :=
         Bet_Size_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"bet_size",""));
      Cfg.Bet_Section.Dry_Run := Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"dry_run", True);
      Cfg.Bet_Section.Allow_In_Play := Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"allow_in_play", False);
      Cfg.Bet_Section.Max_Num_Runners :=
         Max_Num_Runners_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"max_num_runners",""));
      Cfg.Bet_Section.Min_Num_Runners :=
         Min_Num_Runners_Type'Value(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"min_num_runners",""));

      Cfg.Bet_Section.Animal := Get_Animal(Upper_Case(To_String(Cfg.Bot_Name)),"animal",Horse);
      Cfg.Bet_Section.Bet_Type := Get_Bet_Type(Upper_Case(To_String(Cfg.Bot_Name)),"bet_type",Back);
      Cfg.Bet_Section.Countries :=
         To_Unbounded_String(Ini.Get_Value(Upper_Case(To_String(Cfg.Bot_Name)),"countries",""));

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
  begin 
    return
       "<Main>" &
         "<Bot_Name>" & To_String(Cfg.Bot_Name) & "</Bot_Name>" &
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
         "<Bet>" &
           "<Max_Daily_Loss>" & Cfg.Bet_Section.Max_Daily_Loss'Img & "</Max_Daily_Loss>" & 
           "<Max_Daily_Profit>" & Cfg.Bet_Section.Max_Daily_Profit'Img & "</Max_Daily_Profit>" & 
           "<Back_Price>" & Cfg.Bet_Section.Back_Price'Img & "</Back_Price>" & 
           "<Delta_Price>" & Cfg.Bet_Section.Delta_Price'Img & "</Delta_Price>" & 
           "<Max_Lay_Price>" & Cfg.Bet_Section.Max_Lay_Price'Img & "</Max_Lay_Price>" & 
           "<Min_Lay_Price>" & Cfg.Bet_Section.Min_Lay_Price'Img & "</Min_Lay_Price>" & 
           "<Max_Daily_Loss>" & Cfg.Bet_Section.Max_Daily_Loss'Img & "</Max_Daily_Loss>" & 
           "<Bet_Size>" & Cfg.Bet_Section.Bet_Size'Img & "</Bet_Size>" & 
           "<Dry_Run>" & Cfg.Bet_Section.Dry_Run'Img & "</Dry_Run>" & 
           "<Allow_In_Play>" & Cfg.Bet_Section.Allow_In_Play'Img & "</Allow_In_Play>" & 
           "<Animal>" & Cfg.Bet_Section.Animal'Img & "</Animal>" & 
           "<Bet_Type>" & Cfg.Bet_Section.Bet_Type'Img & "</Bet_Type>" & 
           "<Max_Num_Runners>" & Cfg.Bet_Section.Max_Num_Runners'Img & "</Max_Num_Runners>" & 
           "<Min_Num_Runners>" & Cfg.Bet_Section.Min_Num_Runners'Img & "</Min_Num_Runners>" & 
           "<Countries>" & To_String(Cfg.Bet_Section.Countries) & "</Countries>" & 
         "</Bet>"  & 
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
       "</Main>";
  end To_String;
  
  procedure Clear(Cfg : in out Config_Type)is
  begin
    Log(Me & "Clear start");
    Cfg := Empty_Config;
    Log(Me & "Clear stop");
  end Clear;
  ---------------------------------------------
  
  
  
end Bot_Config;

