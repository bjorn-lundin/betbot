------------------------------------------------------------------------------
--
--	COPYRIGHT	Consafe Logistics AB
--
--	FILE NAME	Mobile_Ws_CONFIG.ADS
--
--	RESPONSIBLE	Ann-Charlotte Andersson
--
--	DESCRIPTION	Specification of the Mobile WebServer configuration package
--
-------------------------------------------------------------------------------
--Version     Author    Date      Description
--------------------------------------------------------------------------------
--   AEA      11-Jan-13  Original version
--------------------------------------------------------------------------------
with Unicode.Encodings;

package Mobile_Ws_Config is
 
  Configuration_Error : Exception;   -- v10.2#2550

 -- Read configuration file
  procedure Initiate;

  -- Close logs
  procedure Close;

  -- Log_handler.Put
  procedure Process_Log_Put(Id   : in String; Text : in String);

  function Get_Port return Natural;

  function Get_Max_Connections return Positive;

  function Get_Session_Cleanup_Interval return Duration;

  function Get_Session_Lifetime return Duration;

  function DoUseSession return Boolean;

  function DoUseLogfile return Boolean;

  function Get_Default_Page return String;

  function Get_DocRoot return String;

  function Get_WebServerLogPath return String;

  function Get_Xml_Header return String;

  procedure OutFile_Put(Id   : in String; Text : in String);
  
  function Get_Login_Host return String ;

  function Get_Login_Port return Natural ;

  function Get_Login_Db_Profile_Key return String ;
  
  function Get_Default_Language return String;

  function Get_Mobile_Noun return Natural;

  function Get_Mobile_Verb return Natural;

  function Get_Encoding return Unicode.Encodings.Unicode_Encoding;

end Mobile_Ws_Config;