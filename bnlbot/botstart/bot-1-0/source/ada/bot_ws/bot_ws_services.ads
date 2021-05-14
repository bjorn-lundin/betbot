------------------------------------------------------------------------------
with Types; use Types;

package Bot_Ws_Services is

  Stop_Process   : exception;


  package Global is
     Host           : Types.String_Object;
     Port           : Natural := 0;
     Login          : Types.String_Object;
     Password       : Types.String_Object;
     procedure Initialize ;
  end Global;




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



  -- for moisture in flowers
  function Mail_Moisture_Report(Id : String; Moisture : Integer_4) return Boolean;



  procedure Log_Air_Quality(Id            : String;
                            Temperature   : Fixed_Type;
                            Pressure      : Integer_4;
                            Humidity      : Fixed_Type;
                            Gasresistance : Integer_4);
                            
  procedure Log_C02 (Id    : String;
                     Level : Integer_4);


end Bot_Ws_Services;
