--with Types;    use Types;
--with Sql;
with Calendar2; use Calendar2;
with Text_IO;
with Ini;
with Ada.Environment_Variables;
--with Utils; use Utils;
with Rpc;
with Logging; use Logging;

procedure Race_Time is

  Me : constant String := "Race_Time";
  package EV renames Ada.Environment_Variables;
  gDebug : Boolean := False;
  
  -------------------------------
  procedure Debug (What : String) is
  begin
     if gDebug then
       Text_Io.Put_Line (Text_Io.Standard_Error, Calendar2.String_Date_Time_ISO (Clock, " " , "") & " " & What);
     end if;
  end Debug;
  pragma Warnings(Off, Debug);
  -------------------------------
  procedure Print (What : String) is
  begin
     Text_Io.Put_Line (What);
  end Print;
  -------------------------------
   
  Start_Time_List : Rpc.Calendar2_Pack.List;
  Arrow_Is_Printed : Boolean := False;
  Now : Time_Type := Time_Type_First;
  
begin

  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
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

  Rpc.Get_Starttimes(Start_Time_List);
  Rpc.Logout;
  loop
    Arrow_Is_Printed := False;
    Now := Calendar2.Clock;
    for s of Start_Time_List loop
      if not Arrow_Is_Printed and then
        Now >= S.Starttime then
           Print(
             S.Starttime.String_Time(Seconds => False) & " | " &
             S.Venue(1..30) & " <----"
           ) ;
        Arrow_Is_Printed := True;
      else
           Print(
             S.Starttime.String_Time(Seconds => False) & " | " &
             S.Venue(1..30)
           ) ;
      end if;      
    end loop;
    Text_Io.New_Line(25);   
    delay 5.0;
  end loop;  

end Race_Time;
