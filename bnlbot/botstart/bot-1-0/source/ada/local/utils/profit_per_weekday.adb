with Gnat.Command_Line; use Gnat.Command_Line;
with Types;    use Types;
with Gnat.Strings;
with Sql;
with Logging;               use Logging;
with Text_IO;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Bot_Types;
with General_Routines;

procedure Profit_Per_Weekday is
   Sa_Par_Db            : aliased Gnat.Strings.String_Access;
   Sa_Par_Port          : aliased Gnat.Strings.String_Access;
   Sa_Par_Host          : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_Pwd        : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_User       : aliased Gnat.Strings.String_Access;
   Sa_Par_Bet_Name      : aliased Gnat.Strings.String_Access;
   Ia_Powerdays         : aliased Integer;
   Config               : Command_Line_Configuration;
   Port                 : Natural := 5432;
   T                    : Sql.Transaction_Type;
   Stm_Profit       : Sql.Statement_Type;
   type Eos_Type is (Prf);
   Eos : array (Eos_Type'range) of Boolean := (others => False);

  
   Weekday : Integer_4 := 0 ;  
   IMode    : Integer_4 := 0 ;  
   Mode : Bot_Types.Bet_Mode_Type;
   Count   : Integer_4 := 0 ;  
   Profit : Float_8 := 0.0;
      
   subtype String3 is String (1..3);
   Day_Map : array (0..6) of String3 := ( 0 => "sun",   
                                          1 => "mon",
                                          2 => "tue",
                                          3 => "wed",
                                          4 => "thu",
                                          5 => "fri",
                                          6 => "sat");
 
                                         
   procedure Debug (What : String) is
   begin
      Text_IO.Put_Line(Text_Io.Standard_Error, What);
   end Debug;
   pragma Warnings(Off, Debug);
   -------------------------------
   
begin
   Define_Switch
     (Config,
      Sa_Par_Bet_Name'access,
      Long_Switch => "--betname=",
      Help        => "bet name, HOUNDS_PLACE_BACK_BET");

   Define_Switch
     (Config,
      Sa_Par_Host'access,
      Long_Switch => "--host=",
      Help        => "host name");

   Define_Switch
     (Config,
      Sa_Par_Db'access,
      Long_Switch => "--database=",
      Help        => "database name");

   Define_Switch
     (Config,
      Sa_Par_Port'access,
      Long_Switch => "--port=",
      Help        => "database port");

   Define_Switch
     (Config,
      Sa_Par_Db_Pwd'access,
      Long_Switch => "--pwd=",
      Help        => "database pwd");
      
   Define_Switch
     (Config,
      Sa_Par_Db_User'access,
      Long_Switch => "--user=",
      Help        => "database user");

   Define_Switch
     (Config,
      Ia_Powerdays'access,
      Long_Switch => "--powerdays=",
      Help        => "power of historyfunction and days to look back");
      
 

   Getopt (Config);  -- process the command line

   if Sa_Par_Host.all = "" or else 
      Sa_Par_Db.all = "" or else
      Sa_Par_Bet_Name.all = "" or else
      Sa_Par_Port.all = "" or else
      Sa_Par_Db_User.all = "" or else
      Sa_Par_Db_Pwd.all = "" 
   then
     Display_Help (Config);
     return;
   end if;

   if Sa_Par_Port.all /= "" then
     Port := Natural'Value(Sa_Par_Port.all);
   end if;

   Log ("Treat: " & Sa_Par_Bet_Name.all & "/" & Ia_Powerdays'Img);
--   Log ("Get_database_data start: " & Sa_Par_Host.all & "/" & Sa_Par_Db.all & "/" & Port'Img);
   Sql.Connect
        (Host     => Sa_Par_Host.all,
         Port     => Port,
         Db_Name  => Sa_Par_Db.all,
         Login    => Sa_Par_Db_User.all,
         Password => Sa_Par_Db_Pwd.all);
--   Log ("connected to database");
   T.Start;

   Stm_Profit.Prepare(
      "select " & 
      "  sum(b.profit) as sumprofit, " & 
      "  b.powerdays, " & 
      "  b.betmode, " & 
      "  b.betname, " & 
      "  extract(dow from b.startts ) as weekday, " & 
      "  count(b.profit) as count " & 
      "from " & 
      "  abets b, amarkets m, aevents e " & 
      "where " & 
-- '::' BAD      "  b.startts::date > (select current_date - interval '420 days') " & 
      "      b.status = 'EXECUTION_COMPLETE' " & 
      "  and b.betwon is not null " & 
      "  and b.betname = :BETNAME " & 
      "  and b.marketid = m.marketid " & 
      "  and m.eventid = e.eventid " & 
      "  and ( (b.betmode in (1,3,4) and b.powerdays = :POWERDAYS) or (b.powerdays = 0)) " & 
      "group by " & 
      "  b.betname, " & 
      "  b.powerdays, " & 
      "  b.betmode, " & 
      "  weekday " & 
      "having sum(b.profit) > -100000000.0 " & 
      "order by " & 
      "  b.betmode, " & 
      "  weekday ");

   Stm_Profit.Set("BETNAME",Sa_Par_Bet_Name.all);
   Stm_Profit.Set("POWERDAYS", Integer_4(Ia_Powerdays));
                 
   Stm_Profit.Open_Cursor;
   loop   
     Stm_Profit.Fetch(Eos(Prf));
     exit when Eos(Prf);
     Stm_Profit.Get(1, Profit);
     Stm_Profit.Get(3, IMode);
     Stm_Profit.Get(5, Weekday);
     Stm_Profit.Get(6, Count);
     Mode := Bot_Types.Bet_Mode(Imode);
          
     Print(Day_Map(Integer(Weekday)) & " | " &
           General_Routines.Lower_Case(mode'Img) & " | " &
           Integer'Image(Integer(Profit)) & " | " &
           Count'Img);
     
   end loop;
   Stm_Profit.Close_Cursor;
  
 
      
   T.Commit;
   Sql.Close_Session;
--   Log ("done");

end Profit_Per_Weekday;