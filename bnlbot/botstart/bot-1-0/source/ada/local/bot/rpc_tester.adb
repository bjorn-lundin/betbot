--with Text_Io;
with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
--with General_Routines; use General_Routines;
--with Ada.Streams;

--with Gnat.Sockets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

--with Calendar2; use Calendar2;
--with Gnatcoll.Json; use Gnatcoll.Json;

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Rpc;
--with Lock ;
--with Posix;
--with Table_Abalances;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;

--with Process_IO;
--with Core_Messages;
with Table_Amarkets;
with Table_Aprices;
with Table_Abets;
with Table_Arunners;

procedure Rpc_Tester is
  package EV renames Ada.Environment_Variables;

  use type Rpc.Result_Type;
  
  Me : constant String := "Main.";  

--  Msg      : Process_Io.Message_Type;

--  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Sa_Par_Betid : aliased Gnat.Strings.String_Access;
  Sa_Par_Marketid : aliased Gnat.Strings.String_Access;
  Cmd_Line : Command_Line_Configuration;
  
  Update_Betwon_To_Null : Sql.Statement_Type;
  
--  Betfair_Result : Rpc.Result_Type := Rpc.Ok;
 
--  My_Lock  : Lock.Lock_Type;
---------------------------------------------------------------  



  ---------------------------------------------------------------------
  
--  procedure Balance( Betfair_Result : in out Rpc.Result_Type ; Saldo : out Table_Abalances.Data_Type) is
--    Now : Calendar2.Time_Type := Calendar2.Clock;
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


  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");


  
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
  
  
  
--  Rpc.Cancel_Bet(Market_Id => Sa_Par_Marketid.all,
--                 Bet_Id    => Integer_8'Value(Sa_Par_Betid.all));  
               
    declare
      Market    : Table_Amarkets.Data_Type;
      Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;
      Price,Tmp : Table_Aprices.Data_Type;
      In_Play   : Boolean := False;
      Best_Runners : array (1..2) of Table_Aprices.Data_Type := (others => Table_Aprices.Empty_Data);
      Eol : Boolean := False;
    begin     
      loop
        Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);
        Rpc.Get_Market_Prices(Market_Id  => Sa_Par_Marketid.all, 
                              Market     => Market,
                              Price_List => Price_List,
                              In_Play    => In_Play);
        
--        exit when not In_Play or else Market.Status(1..4) /= "OPEN";
        exit when Market.Status(1..4) /= "OPEN";
        -- ok find the runner with lowest backprice:        
        Price.Backprice := 10000.0;
        Table_Aprices.Aprices_List_Pack.Get_First(Price_List,Tmp,Eol);
        loop
          exit when Eol;          
          if Tmp.Status(1..6) = "ACTIVE" and then 
             Tmp.Backprice < Price.Backprice then
            Price := Tmp;
          end if;        
          Table_Aprices.Aprices_List_Pack.Get_Next(Price_List,Tmp,Eol);
        end loop;
        Best_Runners(1) := Price;
        -- find #2
        Price.Backprice := 10000.0;
        Table_Aprices.Aprices_List_Pack.Get_First(Price_List,Tmp,Eol);
        loop
          exit when Eol;          
          if Tmp.Status(1..6) = "ACTIVE" and then
             Tmp.Backprice < Price.Backprice and then 
             Tmp.Selectionid /= Best_Runners(1).Selectionid then
            Price := Tmp;
          end if;        
          Table_Aprices.Aprices_List_Pack.Get_Next(Price_List,Tmp,Eol);
        end loop;
        Best_Runners(2) := Price;
        
        
        for i in Best_Runners'range loop
          Log("Best_Runners(i) " & i'Img & Table_Aprices.To_String(Best_Runners(i)));         
        end loop;
        
        if Best_Runners(1).Backprice <= Float_8(1.15) and then 
           Best_Runners(1).Backprice >= Float_8(1.0) and then 
           Best_Runners(2).Backprice >= 7.0 then
          Log("Place bet on " & Table_Aprices.To_String(Best_Runners(1))); 
          
          declare
            T : Sql.Transaction_Type;
            Bet : Table_Abets.Data_Type;
            Bet_Name : Bet_Name_Type := (others => ' ');
            Market_Id : Market_Id_Type := (others => ' ');
            Runner : Table_Arunners.Data_Type;
            Runner_Name : Runner_Name_Type := (others => ' ');
            Market : Table_Amarkets.Data_Type;
            Eos : Boolean := False;
          begin
            Move("HORSES_WIN_BACK_FINISH_ANY", Bet_Name);
            Move(Sa_Par_Marketid.all, Market_Id);
            
            Rpc.Place_Bet (Bet_Name         => Bet_Name,
                           Market_Id        => Market_Id, 
                           Side             => Back,
                           Runner_Name      => Runner_Name,
                           Selection_Id     => Best_Runners(1).Selectionid,
                           Size             => 30.0,
                           Price            => 1.01,
                           Bet_Persistence  => Persist,
                           Bet              => Bet);
            
            
            T.Start;
              -- fix som missing fields first
              Runner.Marketid := Market_Id;
              Runner.Selectionid := Best_Runners(1).Selectionid;
              Table_Arunners.Read(Runner, Eos);
              if not Eos then
                Bet.Runnername := Runner.Runnername;
              else
                Log(Me & "Make_Bet", "no runnername found");
              end if;
              
              Market.Marketid := Market_Id;
              Table_Amarkets.Read(Market, Eos);
              if not Eos then
                Bet.Startts := Market.Startts;
                Bet.Fullmarketname := Market.Marketname;
              else
                Log(Me & "Make_Bet", "no market found");
              end if;
            
              Table_Abets.Insert(Bet);
              Log(Me & "Make_Bet", Bet_Name & " inserted bet: " & Table_Abets.To_String(Bet));
              if Trim(Bet.Exestatus) = "SUCCESS" then
                Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
                Sql.Set(Update_Betwon_To_Null,"BETID", Bet.Betid);
                Sql.Execute(Update_Betwon_To_Null);
              end if;
            T.Commit;
          end ;
    
          
          
          exit;           
        end if;
        
        
        
      end loop;    
    end;           
  Log(Me, "Close Db");
  Sql.Close_Session;
 
exception

  when E: others =>
    Stacktrace.Tracebackinfo(E);
    Sql.Close_Session;
end Rpc_Tester;

