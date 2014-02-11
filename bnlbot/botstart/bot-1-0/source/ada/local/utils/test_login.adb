

with Rpc;
with Ini;
with Ada.Environment_Variables;
with Logging; use Logging;
with Sattmate_Exception;

procedure Test_Login is

   package EV renames Ada.Environment_Variables;
 
  
begin
  Log("start");
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );    
  Log("Init ok");
          
  Rpc.Login; 
  
  Rpc.Logout; 

 -- Log("Got Token : " & Rpc.Get_Token.Get);
  
  
exception  
  when E: others => Sattmate_Exception.Tracebackinfo(E);

end Test_Login;