--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
--with Sql;
--with General_Routines; use General_Routines;
--with Ada.Streams;

--with Gnat.Sockets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

--with Sattmate_Calendar; use Sattmate_Calendar;
--with Gnatcoll.Json; use Gnatcoll.Json;

with Rpc;
--with Lock ;
--with Posix;
--with Table_Abalances;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;

--with Process_IO;
--with Core_Messages;

procedure Rpc_Tester is
  package EV renames Ada.Environment_Variables;

  use type Rpc.Result_Type;
  
  Me : constant String := "Main.";  

--  Msg      : Process_Io.Message_Type;

--  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Sa_Par_Betid : aliased Gnat.Strings.String_Access;
  Sa_Par_Marketid : aliased Gnat.Strings.String_Access;
  Cmd_Line : Command_Line_Configuration;
  
--  Betfair_Result : Rpc.Result_Type := Rpc.Ok;
 
--  My_Lock  : Lock.Lock_Type;
---------------------------------------------------------------  



  ---------------------------------------------------------------------
  
--  procedure Balance( Betfair_Result : in out Rpc.Result_Type ; Saldo : out Table_Abalances.Data_Type) is
--    Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
--  begin
--
--    Rpc.Get_Balance(Betfair_Result,Saldo);           
--         
--    if Betfair_Result = Rpc.Ok then    
--      Saldo.Baldate := Now;  
--    end if;
--    
--  end Balance;    
  
   
------------------------------ main start -------------------------------------

begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
   
  Define_Switch
   (Cmd_Line,
    Sa_Par_Betid'access,
    Long_Switch => "--betid=",
    Help        => "Betid");
    
  Define_Switch
   (Cmd_Line,
    Sa_Par_Marketid'access,
    Long_Switch => "--marketid=",
    Help        => "Marketid");
    
--  Define_Switch
--    (Cmd_Line,
--     Sa_Par_Token'access,
--     "-t:",
--     Long_Switch => "--token=",
--     Help        => "use this token, if token is already retrieved");

     
  Getopt (Cmd_Line);  -- process the command line
   
    -- Ask a pythonscript to login for us, returning a token
  Log(Me, "Login betfair");
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );    
  Rpc.Login; 
  Log(Me, "Login betfair done");
  
  Rpc.Cancel_Bet(Market_Id => Sa_Par_Marketid.all,
                 Bet_Id    => Integer_8'Value(Sa_Par_Betid.all));  
               
  Log(Me, "do_exit");
 
exception

  when E: others =>
    Sattmate_Exception.Tracebackinfo(E);
end Rpc_Tester;

