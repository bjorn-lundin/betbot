with Types;    use Types;
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
  Start : Time_Type := Clock;
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
  Days : loop        
    Rpc.Login;
    Log(Me, "Login betfair done");
    Start_Time_List.Clear;
    Rpc.Get_Starttimes(Start_Time_List);
    Rpc.Logout;
    Day : loop
      Arrow_Is_Printed := False;
      Now := Calendar2.Clock;
      Text_Io.New_Line(Text_Io.Count(Start_Time_List.Length));   
      for S of Start_Time_List loop
        if not Arrow_Is_Printed and then
          Now <= S.Starttime then
             Print(
               S.Starttime.String_Time(Seconds => False) & " | " &
               S.Venue(1..15) & " <----"
             ) ;
          Arrow_Is_Printed := True;
        else
             Print(
               S.Starttime.String_Time(Seconds => False) & " | " &
               S.Venue(1..15)
             ) ;
        end if;      
      end loop;
      for i in 1 .. 30 loop
        Text_Io.Put('.');   
        delay 1.0;
      end loop;  
      if Start.Day /= Now.Day then -- new day, get new list
        Start := Now;
        exit Day;
      end if;        
    end loop Day;
    
  end loop Days;    

end Race_Time;
