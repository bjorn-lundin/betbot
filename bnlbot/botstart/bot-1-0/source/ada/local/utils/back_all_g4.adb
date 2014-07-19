
with Types ; use Types;
with Stacktrace;
with Sql;
with Text_Io;
with Table_Arunners;
with Table_Aprices;

with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Calendar2; use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;

--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);

procedure Back_All_G4 is
   Price : Table_Aprices.Data_Type;
   Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;
   Runner : Table_Arunners.Data_Type;


   Bad_Data, Bad_Input : exception;



   T                     : Sql.Transaction_Type;
   Select_All            : Sql.Statement_Type;

   Start_Date            : Calendar2.Time_Type := Calendar2.Time_Type_First;
   Stop_Date             : Calendar2.Time_Type := Calendar2.Time_Type_Last;

   Eos                   : Boolean := False;

   Config                : Command_Line_Configuration;

   Sa_Par_Animal         : aliased Gnat.Strings.String_Access;
   Sa_Par_Start_Date     : aliased Gnat.Strings.String_Access;
   Sa_Par_Stop_Date      : aliased Gnat.Strings.String_Access;
   Ia_Min_Odds           : aliased Integer := 8;
   Ia_Max_Odds           : aliased Integer := 1000;

   Global_Profit, Profit : Float_8 := 0.0;

   Back_Size : Float_8 := 30.0;

   Income, Stake: Float_8 := 0.0;

   type Outcome_Type is (Backed_Won, Backed_Lost, No_Bet_Laid);
   Outcome : Outcome_Type := No_Bet_Laid;

   type Stats_Type is record
     Hits   : Integer_4 := 0;
     Profit : Float_8   := 0.0;
   end record ;

   Stats : array (Outcome_Type'range) of Stats_Type;

   Cnt,Cur : Integer := 0;

begin
    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Start_Date'access,
       Long_Switch => "--start_date=",
       Help        => "when the data move starts yyyy-mm-dd, inclusive");

    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Stop_Date'access,
       Long_Switch => "--stop_date=",
       Help        => "when the data move stops yyyy-mm-dd, inclusive");

    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Animal'access,
       Long_Switch => "--animal=",
       Help        => "what animal is racing");

    Define_Switch
      (Config      => Config,
       Output      => Ia_Max_Odds'access,
       Long_Switch => "--max_odds=",
       Help        => "Max odds to accept, inclusive, to place the bet");

    Define_Switch
      (Config      => Config,
       Output      => Ia_Min_Odds'access,
       Long_Switch => "--min_odds=",
       Help        => "Min odds to accept, inclusive, to place the bet");

    Getopt (Config);  -- process the command line

    if Sa_Par_Start_Date.all = "" or else
      Sa_Par_Stop_Date.all = "" or else
      Sa_Par_Animal.all = "" then
      Display_Help (Config);
      return;
    end if;

    Start_Date := Calendar2.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
    Stop_Date  := Calendar2.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");
--   Start_Date := Start_Date - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first
--   Stop_Date  := Stop_Date  - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first


    Log ("params: " & 
         "start_date=" &  Calendar2.String_Date_And_Time(Start_Date) & " " &
         "stop_date=" &  Calendar2.String_Date_And_Time(Stop_Date) & " " &
         "animal=" & Sa_Par_Animal.all & " " &
         "max_odds=" & Ia_Max_Odds'Img & " " &
         "min_odds=" & Ia_Min_Odds'Img );


    Log ("Connect db");
    Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "nono",
      Login    => "bnl",
      Password => "bnl");

      
    T.Start;

    if Sa_Par_Animal.all = "horse" then
      Select_All.Prepare (
          "select P.* " &
          "from AMARKETS M, AEVENTS E, APRICES P " &
          "where M.STARTTS >= :START " &
          "and M.STARTTS <= :STOP " &
          "and M.EVENTID = E.EVENTID " &
          "and M.MARKETID = P.MARKETID " &
          "and P.BACKPRICE >= :MIN_ODDS " &
          "and P.BACKPRICE <= :MAX_ODDS " &
          "and M.MARKETTYPE = 'WIN' " &
          "and E.EVENTTYPEID = 7 " &
          "and E.COUNTRYCODE in ('GB') " &
          "order by M.STARTTS, M.MARKETID");
    else
      raise Bad_Input with "bad animal: '" & Sa_Par_Animal.all & "'";
    end if;

    Select_All.Set("MIN_ODDS", Integer_4(Ia_Min_Odds));
    Select_All.Set("MAX_ODDS", Integer_4(Ia_Max_Odds));
    Select_All.Set_Timestamp("START", Start_date);
    Select_All.Set_Timestamp("STOP",  Stop_date);

--      Text_IO.Put_Line(Text_IO.Standard_Error,"--------------------------");

    Table_Aprices.Read_List(Select_All, Price_List);


    Cnt :=  Table_Aprices.Aprices_List_Pack.Get_Count(Price_List);
    Cur := Cnt;
    Loop_All : while not Table_Aprices.Aprices_List_Pack.Is_Empty(Price_List) loop
        Table_Aprices.Aprices_List_Pack.Remove_From_Head(Price_List, Price);

        Cur := Cur - 1 ;
        if Cur rem 1000 = 0 then
          Log ("Back_All_G4 - " & Cur'Img & " /" & Cnt'Img  );
        end if;


        Runner := Table_Arunners.Empty_Data;
        Runner.Marketid := Price.Marketid;
        Runner.Selectionid := Price.Selectionid;
        Table_Arunners.Read(Runner, Eos);
        if Eos then
          raise Bad_Data with "eos on runner " & Table_Arunners.To_String(Runner);
        else
          if Runner.Status(1..6) = "WINNER" then
            Outcome := Backed_Won;
          elsif Runner.Status(1..5) = "LOSER" then
            Outcome := Backed_Lost;
          else
            Outcome := No_Bet_Laid;          
          end if;
        end if;

        case Outcome is
           when No_Bet_Laid =>    -- no bet at all
             Income := 0.0;
             Stake  := 0.0;
             Profit := 0.0;
           when Backed_Won =>  -- A winning back bet only
             Income := Back_Size * Price.Backprice;
             Stake  := Back_Size;
             Profit := 1.0 * (Income - Stake);
--             Profit := 0.95 * (Income - Stake);
           when Backed_Lost =>  -- A losing back bet only
             Income := 0.0;
             Stake  := Back_Size;
             Profit := - Stake;
        end case;
        Stats(Outcome).Hits := Stats(Outcome).Hits + 1;
        Stats(Outcome).Profit := Stats(Outcome).Profit + Profit;

--        if Outcome /= No_Bet_Laid then
           Text_IO.Put_Line(Outcome'Img & " | " &
                            Runner.Status(1..7)  & " | " &
                            Price.Marketid & " | " &
                            Price.Selectionid'Img & " | " &
                            F8_Image(Price.Backprice) & " | " &
                            F8_Image(Price.Layprice) & " | " &
                            F8_Image(Back_Size) & " | " &
                            F8_Image(Profit) );
--        end if;

        Global_Profit := Global_Profit + Profit;

    end loop Loop_All;
    T.Commit ;

   Sql.Close_Session;

   for i in Outcome_Type'range loop
     Log(i'Img & " hits " & Stats(i).Hits'Img & " profit " & Integer_4(Stats(i).Profit)'Img);
   end loop;
   Log("Total profit = " & Integer_4(Global_Profit)'Img);
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Back_All_G4;
