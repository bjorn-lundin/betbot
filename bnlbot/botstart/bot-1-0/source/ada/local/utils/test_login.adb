

--with Rpc;
--with Ini;
--with Ada.Environment_Variables;
with Logging; use Logging;
with Stacktrace;
with Table_Abalances;
with Types; use Types;
with Bot_Types; use Bot_Types;
--with General_Routines; use General_Routines;
with Utils; use Utils;

with Ada.Strings.Fixed;
procedure Test_Login is

--   package EV renames Ada.Environment_Variables;
 
  Saldo : Table_Abalances.Data_Type;
  
  Bet_Size : Bet_Size_Type := 0.0;
  Cfg_Size : Bet_Size_Type := 0.33333;
  Me : String := "Main.";
  
  type Bet_Type is (Back_1_1, Back_1_1_Marker,
                    Back_2_1, Back_2_1_Marker,
                    Back_3_1, Back_3_1_Marker,
                    Back_3_2, Back_3_2_Marker,
                    Back_3_3, Back_3_3_Marker,
                    Back_4_1, Back_4_1_Marker,
                    Back_5_1, Back_5_1_Marker,
                    Back_6_1, Back_6_1_Marker);
  
    Bets_Allowed : array (Bet_Type'range) of boolean;

begin

--    for i in Bets_Allowed'range loop
--      if Ada.Strings.Fixed.Index(i'Img, "MARKER") > Natural(0) then
--        Log("is marker: " & I'Img);
--      else  
--        Log("is no marker: " & I'Img);
--      end if;
--    end loop;
--return;

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
  when E: others => Stacktrace.Tracebackinfo(E);

end Test_Login;