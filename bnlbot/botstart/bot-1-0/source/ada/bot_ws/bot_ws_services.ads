------------------------------------------------------------------------------
--with AWS.Session;
with Types; use Types;

package Bot_Ws_Services is

  Stop_Process   : exception;

  function Operator_Login(Username   : in String;
                          Password   : in String;
                          Context    : in String) return String;

  function Operator_Logout(Username  : in String;
                           Context   : in String) return String;

  function Settled_Bets   (Username  : in String;
                           Context   : in String) return String;


end Bot_Ws_Services;
