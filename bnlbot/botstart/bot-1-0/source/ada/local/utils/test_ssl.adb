
with Ada.Environment_Variables;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
--with Ada.Environment_Variables;
with Logging; use Logging;
with Aws; use Aws;
with Aws.Headers;
--with Aws.Headers.Set;
with Aws.Response;
with Aws.Client;

with Aws.Net.Ssl;
with Utils; use Utils;
pragma Elaborate_All (AWS.Headers);
with Rpc;
--with Bot_System_Number;
--with Sql;
with Ini;
with Token;





procedure test_ssl is

 Me : constant String := "RPC.";


  Global_Token : Token.Token_Type;


  procedure Login is
    Login_HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    AWS_Reply    : Aws.Response.Data;
    Header : AWS.Headers.List;
    use Aws.Client;


    --bnl test start
    function Post2
      (Url          : String;
       Data         : String;
       Content_Type : String          := No_Data;
       User         : String          := No_Data;
       Pwd          : String          := No_Data;
       Proxy        : String          := No_Data;
       Proxy_User   : String          := No_Data;
       Proxy_Pwd    : String          := No_Data;
       Timeouts     : Timeouts_Values := No_Timeout;
       Attachments  : Attachment_List := Empty_Attachment_List;
       Headers      : Header_List     := Empty_Header_List) return Aws.Response.Data
    is
      Connection : Http_Connection;
      Result     : Aws.Response.Data;
      Cfg : Aws.Net.Ssl.Config;
    begin


    Log(Me & "Login", "0" );

    Aws.Net.Ssl.initialize
     (Config               => Cfg,
      Certificate_Filename => "/home/bnl/bnlbot/botstart/bot-1-0/source/ada/cert.pem"
      );
   --  Initialize the SSL layer into Config. Certificate_Filename must point
   --  to a valid certificate. Security mode can be used to change the
   --  security method used by AWS. Key_Filename must be specified if the key
   --  is not in the same file as the certificate. The Config object can be
   --  associated with all secure sockets sharing the same options. If
   --  Exchange_Certificate is True the client will send its certificate to
   --  the server, if False only the server will send its certificate.


    Log(Me & "Login", "1" );
      Create (Connection,
              Url, User, Pwd, Proxy, Proxy_User, Proxy_Pwd,
              Persistent => False,
              Ssl_Config => Cfg,
              Timeouts   => Timeouts);
    Log(Me & "Login", "2" );

      Post (Connection, Result, Data, Content_Type,
            Attachments => Attachments,
            Headers     => Headers);
    Log(Me & "Login", "3");

      Close (Connection);
    Log(Me & "Login", "4" );
      return Result;
    end Post2;

    --bnl test stop


  begin
--      Aws.Headers.Add (Login_HTTP_Headers, "User-Agent", "AWS-BNL/1.0");
--
--
--      Aws_Reply := Aws.Client.Get (Url      => "https://svn.consafelogistics.com/satt/sattmate-std/trunk/sattmate/config/gpr/utility.gpr",
--                                   User     => "sattmate",
--                                   Pwd      => "sattmate",
--                                   Certificate => "cert.pem",
--                                   Headers  => Login_Http_Headers,
--                                   Timeouts => Aws.Client.Timeouts (Each => 30.0));
--
--
--      Log(Me & "Login", "reply GET" & Aws.Response.Message_Body(AWS_Reply));
--      return;


    declare
      Data : String :=  "username=" & Global_Token.Get_Username & "&" &
                         "password=" & Global_Token.Get_Password &"&" &
                         "login=true" & "&" &
                         "redirectMethod=POST" & "&" &
                         "product=home.betfair.int" & "&" &
                         "product=home.betfair.int" & "&" &
                         "url=https://www.betfair.com/";
    begin
--        AWS_Reply := Aws.Client.Post (Url          => "https://identitysso.betfair.com/api/login",
--                                      Data         => Data,
--                                      Content_Type => "application/x-www-form-urlencoded",
--                                      Headers      => Login_HTTP_Headers,
--                                      Timeouts     => Aws.Client.Timeouts (Each => 30.0));
      AWS_Reply := Post2 (Url          => "https://identitysso.betfair.com/api/login",
                                    Data         => Data,
                                    Content_Type => "application/x-www-form-urlencoded",
                                    Headers      => Login_HTTP_Headers,
                                    Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    end ;
    Log(Me & "Login", "reply" & Aws.Response.Message_Body(AWS_Reply));




    -- login reply should look something like below (522 chars)
    -- <html>
    -- <head>
    --     <title>Login</title>
    -- </head>
    -- <body onload="document.postLogin.submit()">
    -- <iframe src="https://secure.img-cdn.mediaplex.com/0/16689/universal.html?page_name=loggedin&amp;loggedin=1&amp;mpuid=6081705" HEIGHT="1" WIDTH="1" FRAMEBORDER="0" ></iframe>
    -- <form name="postLogin" action="https://www.betfair.com/" method="POST">
    --     <input type="hidden" name="productToken" value="UeJjgqWpxf3VstCg9VqFmrDhsrHQkOvHu7alH5NCldA="/>
    --     <input type="hidden" name="loginStatus" value="SUCCESS"/>
    -- </form>
    -- </body>
    -- </html>

    declare
      String_Reply : String := Aws.Response.Message_Body(AWS_Reply);
    begin
      if String_Reply'length < 500 then
        raise Token.login_Failed with "Bad reply from server at login";
      end if;
    end ;

    Header := AWS.Response.Header(AWS_Reply);

    for i in 1 .. AWS.Headers.Length(Header) loop
      declare
        Head : String := AWS.Headers.Get_Line(Header,i);
        Index_First_Equal : Integer := 0;
        Index_First_Semi_Colon : Integer := 0;
        -- Set-Cookie: ssoid=o604egQ2BuWCG6ij8NMJtyer6fycB2Dw7eHLiWoA1vI=; Domain=.betfair.com; Path=/
      begin
        if Position(Head,"ssoid") > Integer(0) then
          Log("Login"," " & Head);
          for i in Head'range loop
            case Head(i) is
              when '=' =>
                if Index_First_Equal = 0 then
                  Index_First_Equal := i;
                end if;

              when ';' =>
                if Index_First_Semi_Colon = 0 then
                  Index_First_Semi_Colon := i;
                end if;
              when others => null;
            end case;
          end loop;
          if Index_First_Equal > Integer(0) and then Index_First_Semi_Colon > Index_First_Equal then
            Log("Login","ssoid: '" & Head(Index_First_Equal +1 .. Index_First_Semi_Colon -1) & "'");
            Global_Token.Set(Head(Index_First_Equal +1 .. Index_First_Semi_Colon -1));
          end if;
        end if;
      end;
    end loop;
  end Login;
 ---------------
  package Ev renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

begin


  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Rpc.Init(
           Username   => Ini.Get_Value("betfair","username",""),
           Password   => Ini.Get_Value("betfair","password",""),
           Product_Id => Ini.Get_Value("betfair","product_id",""),
           Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
           App_Key    => Ini.Get_Value("betfair","appkey","")
          );

 Log("Login","start");
 Login;


end Test_ssl;
