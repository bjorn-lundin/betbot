

--with Rpc;
--with Ini;
--with Ada.Environment_Variables;
with Logging; use Logging;
with Sattmate_Exception;
with Table_Abalances;
with Sattmate_Types; use Sattmate_Types;
with Bot_Types; use Bot_Types;
with General_Routines; use General_Routines;
procedure Test_Login is

--   package EV renames Ada.Environment_Variables;
 
  Saldo : Table_Abalances.Data_Type;
  
  Bet_Size : Bet_Size_Type := 0.0;
  Cfg_Size : Bet_Size_Type := 0.33333;
  Me : String := "Main.";
begin
  Log("start");
--  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
--  Rpc.Init(
--            Username   => Ini.Get_Value("betfair","username",""),
--            Password   => Ini.Get_Value("betfair","password",""),
--            Product_Id => Ini.Get_Value("betfair","product_id",""),  
--            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
--            App_Key    => Ini.Get_Value("betfair","appkey","")
--          );    
--  Log("Init ok");
--          
--  Rpc.Login; 
  Saldo.Balance := 1500.0;
  Saldo.Exposure := 738.0;

  if Saldo.Exposure > Float_8(0.0) then
    Bet_Size := Cfg_Size * Bet_Size_Type(Saldo.Balance + Saldo.Exposure);
    Log(Me & "Run", "Bet_Size 1 " & F8_Image(Float_8(Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
    if Bet_Size > Bet_Size_Type(Saldo.Balance) then
      Bet_Size := Bet_Size_Type(Saldo.Balance);
      Log(Me & "Run", "Bet_Size 2 " & F8_Image(Float_8(Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
    end if;
  else
    Bet_Size := Cfg_Size * Bet_Size_Type(Saldo.Balance);
  end if;
  Log(Me & "Run", "Bet_Size 3 " & F8_Image(Float_8(Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
  
--  Rpc.Logout; 

 -- Log("Got Token : " & Rpc.Get_Token.Get);
  
  
exception  
  when E: others => Sattmate_Exception.Tracebackinfo(E);

end Test_Login;