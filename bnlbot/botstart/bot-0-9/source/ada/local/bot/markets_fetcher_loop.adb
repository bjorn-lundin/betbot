--with Unchecked_Conversion;
--with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with Logging; use Logging;
--with Text_Io;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);
with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;


with Unicode.CES;
with Unicode.CES.Basic_8bit;

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Sattmate_Exception;
with General_Routines;

with Token ;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;


procedure Markets_Fetcher_Loop is

 Sa_Par_Token : aliased Gnat.Strings.String_Access;
 Config : Command_Line_Configuration;

  
----------------------------------------------

  Answer : Aws.Response.Data;
  
  My_Token : Token.Token_Type;
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
  
begin
   Define_Switch
     (Config,
      Sa_Par_Token'access,
      "-t:",
      Long_Switch => "--token=",
      Help        => "use this token, if token is already retrieved");
    Getopt (Config);  -- process the command line

    if Sa_Par_Token.all = "" then
      Log("Login");
      My_Token.Login; -- Ask a pythonscript to login for us, returning a token
      Log("Logged in with token '" &  My_Token.Get & "'");
    else
      Log("set token '" & Sa_Par_Token.all & "'");
      My_Token.Set(Sa_Par_Token.all);
    end if;

    
--     Aws.Headers.Set.Add (Headers : in out List; Name, Value : String);
    Log("set headers");
    
    Aws.Headers.Set.Add (My_Headers, "X-Authentication", My_Token.Get);
    Aws.Headers.Set.Add (My_Headers, "X-Application", Token.App_Key);
    Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");
    Log("eaders set");


--http://forum.bdp.betfair.com/showthread.php?t=1832&page=2
--conn.setRequestProperty("content-type", "application/json");
--conn.setRequestProperty("X-Authentication", token);
--conn.setRequestProperty("X-Application", appKey);
--conn.setRequestProperty("Accept", "application/json");    
    
    loop
    Log("call betfair");

    Answer := Aws.Client.Post (Url          =>  Token.URL,
                               Data         =>  "{""jsonrpc"": ""2.0"", ""method"": ""SportsAPING/v1.0/listEventTypes"", ""params"": {""filter"":{}}, ""id"": 1}",
                               Content_Type => "application/json",
                               Headers      => My_Headers);
    Log("betfair called");
    
    
    Log(Aws.Response.Message_Body(Answer));
    Log("Wait 1 minute");
    delay 60.0;
    end loop; 
--    Sql.Connect
--        (Host     => "192.168.0.13",
--         Port     => 5432,
--         Db_Name  => "betting",
--         Login    => "bnl",
--         Password => "bnl");
--
--
--    if Get_Horses then
--      R := Aws.Client.Get(URL => URL_HORSES);
--      Log("----------- Start Horses -----------------" );
--      My_Reader.Current_Tag := Null_Unbounded_String;
--      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
--      My_Reader.Set_Feature(Validation_Feature,False);
--      My_Reader.Parse(Input);
--      Close(Input);
--      Log("----------- Stop Horses -----------------" );
--      Log("");
--    end if;
--
--    if Get_Hounds then    
--      R := Aws.Client.Get(URL => URL_HOUNDS);
--      Log("----------- Start Hounds -----------------" );
--      My_Reader.Current_Tag := Null_Unbounded_String;
--      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
--      My_Reader.Set_Feature(Validation_Feature,False);
--      My_Reader.Parse(Input);
--      Close(Input);
--      Log("----------- Stop Hounds -----------------" );
--      Log("");
--    end if;
--
--    Sql.Close_Session;
    
exception
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
end Markets_Fetcher_Loop;

