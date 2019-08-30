------------------------------------------------------------------------------

package Bot_Ws_Services is

  Stop_Process   : exception;

  function Operator_Login(Username   : in String;
                          Password   : in String;
                          Context    : in String) return String;

  function Operator_Logout(Username  : in String;
                           Context   : in String) return String;

  function Settled_Bets   (Username   : in String;
                           Context    : in String;
                           Total_Only : in Boolean := False) return String;

  function Sum_Settled_Bets(Username  : in String;
                            Context   : in String) return String;

  function Todays_Total   (Username  : in String;
                           Context   : in String) return String;

  function Get_Starttimes(Username  : in String;
                          Context   : in String) return String ;

  function Get_Weeks     (Username  : in String;
                          Context   : in String) return String ;

  function Get_Months    (Username  : in String;
                          Context   : in String) return String ;

end Bot_Ws_Services;
