with Ada.Containers.Doubly_Linked_Lists;
--with Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Sim;
with Utils; use Utils;
with Types ; use Types;
--with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
with Table_Apriceshistory;
with Table_Abets;
with Gnat.Command_Line; use Gnat.Command_Line;
---with GNAT.Strings;
with Calendar2; -- use Calendar2;
with Logging; use Logging;


procedure Lay_During_Race3 is

  Bad_Bet_Side : exception;
  -- Market_Id_With_Data_Pack
  -- Holds list of all market ids that has data


  type Bet_List_Record is record
    Bet          : Table_Abets.Data_Type;
    Price_Finish : Table_Apriceshistory.Data_Type;
  end record;

  package Bet_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Bet_List_Record);

  Global_Bet_List : Bet_List_Pack.List;
  Config           : Command_Line_Configuration;

  IA_Max_Start_Price : aliased Integer := 30;
  IA_Lay_At_Price    : aliased Integer := 100;
  IA_Max_Lay_Price   : aliased Integer := 200;

  Lay_Size  : Fixed_Type := 30.0;
  Back_Size : Fixed_Type := 100.0;

  type Bet_Status_Type is (No_Bet_Laid, Bet_Laid);
  Bet_Status : Bet_Status_Type := No_Bet_Laid;


  Global_Min_Backprice  : constant Integer_4 := 250;
  Global_Max_Backprice  : constant Integer_4 := 300;
  Global_Min_Layprice   : constant Integer_4 := 100;
  Global_Max_Layprice   : constant Integer_4 := 290;
  Start                 : Calendar2.Time_Type := Calendar2.Clock;

   --------------------------------------------------------------------------

  function "<" (Left,Right : Table_Apriceshistory.Data_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Table_Apriceshistory.Apriceshistory_List_Pack2.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1..4) of Table_Apriceshistory.Data_Type;


  procedure Treat_Lay(List         : in     Table_Apriceshistory.Apriceshistory_List_Pack2.List ;
                      WR           : in     Table_Apriceshistory.Data_Type ;
                      Status       : in out Bet_Status_Type;
                      Bet_List     : in out Bet_List_Pack.List;
                      Max_Backprice: in     Integer_4;
                      Min_Backprice: in     Integer_4;
                      Max_Layprice : in     Integer_4;
                      Min_Layprice : in     Integer_4) is
    pragma Unreferenced(List);                  
    use Calendar2;
    Bet_Already_Laid : Boolean := False;
    Bet : Table_Abets.Data_Type;
  begin
    case Status is
      when No_Bet_Laid =>
        -- check for bet already laid for this runner on this market  
        for B of Bet_List loop
          if B.Bet.Selectionid = WR.Selectionid and then
             B.Bet.Marketid    = WR.Marketid then
               Bet_Already_Laid := True;
               exit;
          end if;    
        end loop;                
      
        -- make sure no bet in the air, waiting for 1 second
        if not Bet_Already_Laid then
          if WR.Backprice >= Fixed_Type(Min_Backprice)and then
             WR.Layprice  >= Fixed_Type(Min_Layprice) and then
             WR.Backprice <= Fixed_Type(Max_Backprice) and then
             WR.Layprice  <= Fixed_Type(Max_Layprice) then

            Bet.Marketid    := WR.Marketid;
            Bet.Selectionid := WR.Selectionid;
            Bet.Size        := Lay_Size;
            Bet.Side        := "LAY ";
            Bet.Price       := WR.Layprice;
            Bet.Betplaced   := WR.Pricets;
            Status          := Bet_Laid;
            Bet.Status(1) := 'U';
            Bet_List.Append(Bet_List_Record'(Bet,WR));
          end if;
        end if;
        
      when Bet_Laid    =>
        -- make sure the WR here is the same as got the bet laid
        for B of Bet_List loop
          if B.Bet.Selectionid =  WR.Selectionid then
            if WR.Pricets >  B.Bet.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
              if WR.Layprice <= B.Bet.Price and then -- Laybet so yes '<=' NOT '>='
               WR.Layprice >  Fixed_Type(1.0) and then -- sanity
               WR.Backprice >  Fixed_Type(1.0) then -- sanity
                 Status := No_Bet_Laid; --reset for other runners
                 B.Bet.Status(1) := 'M';
                 B.Bet.Pricematched := WR.Layprice;
                 exit;
              end if;
            end if;
          end if;
        end loop;                
    end case;
  end Treat_Lay;
  --------------------------------------------------------------------------
  procedure Treat_Back(List         : in     Table_Apriceshistory.Apriceshistory_List_Pack2.List ;
                       BRA          : in     Best_Runners_Array_Type ;
                       Status       : in out Bet_Status_Type;
                       Bet_List     : in out Bet_List_Pack.List) is
    pragma Unreferenced(List);                  
    use Calendar2;
    Bet_Already_Laid : Boolean := False;
    Bet : Table_Abets.Data_Type;
    Place_Data_At_Time_Of_Bet_Laid : Table_Apriceshistory.Data_Type;
    use type Table_Apriceshistory.Data_Type;
  begin
    case Status is
      when No_Bet_Laid =>
--        -- check for bet already laid for this market  
--        for B of Bet_List loop
--          if B.Bet.Marketid = BRA(1).Marketid then
--            Bet_Already_Laid := True;
--            exit;
--          end if;    
--        end loop;                
--        -- make sure no bet in the air, waiting for 1 second
--        if not Bet_Already_Laid then
          if BRA(1).Backprice <= Fixed_Type(1.20) and then
             BRA(1).Backprice >  Fixed_Type(1.10) and then
             BRA(2).Backprice >= Fixed_Type(10.0) and then
             BRA(2).Backprice < Fixed_Type(10_000.0) and then  -- so it exists
             BRA(3).Backprice < Fixed_Type(10_000.0) then  -- so it exists
             
             -- for place  Place_Data_At_Time_Of_Bet_Laid := Sim.Get_Place_Price(BRA(1));
             -- for place  if Place_Data_At_Time_Of_Bet_Laid /= Table_Apriceshistory.Empty_Data then
             -- for place    Bet.Marketid    := Place_Data_At_Time_Of_Bet_Laid.Marketid;
             -- for place    Bet.Selectionid := Place_Data_At_Time_Of_Bet_Laid.Selectionid;
             -- for place    Bet.Size        := Back_Size;
             -- for place    Bet.Side        := "BACK";
             -- for place    Bet.Price       := Place_Data_At_Time_Of_Bet_Laid.Backprice;
             -- for place    Bet.Betplaced   := BRA(1).Pricets;
             -- for place    Status          := Bet_Laid;
             -- for place    Bet.Status(1) := 'U';
             -- for place    Bet_List.Append(Bet_List_Record'(Bet,BRA(1)));
              Bet.Marketid    := BRA(1).Marketid;
              Bet.Selectionid := BRA(1).Selectionid;
              Bet.Size        := Back_Size;
              Bet.Side        := "BACK";
              Bet.Price       := BRA(1).Backprice;
              Bet.Betplaced   := BRA(1).Pricets;
              Status          := Bet_Laid;
              Bet.Status(1) := 'U'; --Unmatched
              Bet_List.Append(Bet_List_Record'(Bet,BRA(1)));
   --       end if;
        end if;
        
      when Bet_Laid    =>
        for B of Bet_List loop
          if B.Bet.Selectionid = BRA(1).Selectionid then
            if BRA(1).Pricets     >  B.Bet.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
              if BRA(1).Backprice >= B.Bet.Price and then -- Backbet so yes '>=' NOT '<='
                 BRA(1).Layprice  > Fixed_Type(1.0) and then -- sanity
                 BRA(1).Backprice >  Fixed_Type(1.0) then -- sanity
                   B.Bet.Status(1) := 'M'; --Matched
                   B.Bet.Pricematched :=  BRA(1).Backprice;
                   exit;
              end if;
            end if;
          end if;
        end loop;                
    end case;
  end Treat_Back;
  --------------------------------------------------------------------------


  Best_Runners      : Best_Runners_Array_Type := (others => Table_Apriceshistory.Empty_Data);
  Worst_Runner      : Table_Apriceshistory.Data_Type := Table_Apriceshistory.Empty_Data;


  procedure Sort_Array(List : in out Table_Apriceshistory.Apriceshistory_List_Pack2.List ;
                       BRA  :    out Best_Runners_Array_Type;
                       WR   :    out Table_Apriceshistory.Data_Type ) is

    Price             : Table_Apriceshistory.Data_Type;
  begin
      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort(List);

      Price.Backprice := 10_000.0;
      BRA := (others => Price);
      WR.Layprice := 10_000.0;

      declare
        Idx : Integer := 0;
      begin
        for Tmp of List loop
          if Tmp.Status(1..6) = "ACTIVE" and then
             Tmp.Backprice > Fixed_Type(1.0) and then
             Tmp.Layprice < Fixed_Type(1_000.0)  then
            Idx := Idx +1;
            exit when Idx > BRA'Last;
            BRA(Idx) := Tmp;
          end if;
        end loop;
      end ;

      for Tmp of List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Fixed_Type(1.0) and then
           Tmp.Layprice < Fixed_Type(1_000.0) and then
           Tmp.Selectionid /= BRA(1).Selectionid and then
           Tmp.Selectionid /= BRA(2).Selectionid then

          WR := Tmp;
        end if;
      end loop;

     -- for i in BRA'range loop
     --   Log("Best_Runners(i)" & i'Img & " " & BRA(i).To_String);
     -- end loop;
     -- Log("Worst_Runner " & WR.To_String);

  end Sort_Array;
  ---------------------------------------------------------------
begin
  Define_Switch
    (Config      => Config,
     Output      => IA_Max_Start_Price'access,
     Long_Switch => "--max_start_price=",
     Help        => "starting price (back)(");

  Define_Switch
    (Config      => Config,
     Output      => Ia_Lay_At_Price'access,
     Long_Switch => "--lay_at_price=",
     Help        => "Lay the runner at this price(Back)");

  Define_Switch
    (Config      => Config,
     Output      => IA_Max_Lay_Price'access,
     Long_Switch => "--max_lay_price=",
     Help        => "Runner cannot have higer price that this when layed (Lay)");

  Getopt (Config);  -- process the command line

  
  for Month in Calendar2.Short_Month_Type'range loop
    Log ("Connect db");
    Sql.Connect
      (Host     => "localhost",
       Port     => 5432,
       Db_Name  => "dry",
       Login    => "bnl",
       Password => "bnl");
    Log ("Connected to db");  
    Sim.Fill_Data_Maps(Month);
    Sql.Close_Session;    -- no need for db anymore
    Log("start process");
  
    declare
      Cnt : Integer := 0;
    begin
      for Marketid of Sim.Market_Id_With_Data_List loop
        Cnt := Cnt + 1;
     --   Log( F8_Image(Fixed_Type(Cnt)*100.0/ Fixed_Type(Sim.Market_Id_With_Data_List.Length)) & " %");
        Bet_Status := No_Bet_Laid;
        -- list of timestamps in this market
        declare
          Timestamp_To_Apriceshistory_Map : Sim.Timestamp_To_Apriceshistory_Maps.Map :=
                        Sim.Marketid_Timestamp_To_Apriceshistory_Map(Marketid);
        begin
          for Timestamp of Sim.Marketid_Pricets_Map(Marketid) loop
            declare
              List : Table_Apriceshistory.Apriceshistory_List_Pack2.List :=
                        Timestamp_To_Apriceshistory_Map(Timestamp.To_String);
            begin
              Best_Runners := (others => Table_Apriceshistory.Empty_Data);
              Worst_Runner := Table_Apriceshistory.Empty_Data;
  
              Sort_Array(List => List,
                         BRA  => Best_Runners,
                         WR   => Worst_Runner);
  
              Treat_Back(List         => List,
                        BRA           => Best_Runners,
                        Status        => Bet_Status,
                        Bet_List      => Global_Bet_List);
                        
             -- Treat_Lay(List          => List,
             --           WR            => Worst_Runner,
             --           Status        => Bet_Status,
             --           Bet_List      => Global_Bet_List,
             --           Max_Backprice => Global_Max_Backprice,
             --           Min_Backprice => Global_Min_Backprice,
             --           Max_Layprice  => Global_Max_Layprice,
             --           Min_Layprice  => Global_Min_Layprice);
  
            end;
          end loop; --  Timestamp
        end;
      end loop;  -- marketid
    end;

    Log("num bets laid" & Global_Bet_List.Length'Img);
  
    declare
      Sum, Sum_Winners, Sum_Losers : Fixed_Type := 0.0;
      Profit : Fixed_Type := 0.0;
      Winners,Losers,Unmatched,Strange : Integer_4 := 0;
    begin
      for Bet_Record of Global_Bet_List loop
        --Log("");
        --Log(Bet_Record.Bet.To_String);
        --Log(Bet_Record.Price_Finish.To_String);
        --Log("----------------");
        case Bet_Record.Bet.Status(1) is
          when 'M'  => -- matched
          
            if Bet_Record.Bet.Side(1..3) = "LAY" then
              -- did it win ?
              if Sim.Is_Race_Winner(Bet_Record.Bet.Selectionid, Bet_Record.Bet.Marketid) then
                Profit := -(Bet_Record.Bet.Price - 1.0) * Lay_Size ;
                Losers := Losers +1;
                Sum_Losers := Sum_Losers + Profit;
                Log("bad bet: " & Bet_Record.Price_Finish.To_String);
              else-- won
                Profit := Lay_Size * 0.935;
                Winners := Winners+1;
                Sum_Winners := Sum_Winners + Profit;
              end if;
            elsif Bet_Record.Bet.Side(1..4) = "BACK" then
              -- did it win ?
              if Sim.Is_Race_Winner(Bet_Record.Bet.Selectionid, Bet_Record.Bet.Marketid) then
                Profit := (Bet_Record.Bet.Price - 1.0) * Back_Size * 0.935;
                Winners := Winners+1;
                Sum_Winners := Sum_Winners + Profit;
              else-- won
                Profit := -Back_Size ;
                Losers := Losers +1;
                Sum_Losers := Sum_Losers + Profit;
                Log("bad bet: " & Bet_Record.Price_Finish.To_String);
              end if;
            
            else
              raise Bad_Bet_Side with "Bet_Record.Bet.Side ='" & Bet_Record.Bet.Side & "'";
            end if;
          when 'U'  => -- unmatched
            Unmatched := Unmatched +1;
          when others => --Strange
            Strange := Strange +1;
        end case;
      end loop;
      Sum := Sum_Winners + Sum_Losers ;
      Log("RESULT Month   : " & Month'Img );   
      Log("RESULT Winners   : " & Winners'Img & " " & Integer_4(Sum_Winners)'Img );
      Log("RESULT Losers    : " & Losers'Img  & " " & Integer_4(Sum_Losers)'Img);
      Log("RESULT Unmatched : " & Unmatched'Img  & " " & Unmatched'Img);
      Log("RESULT Strange   : " & Strange'Img  & " " & Strange'Img);
      Log("RESULT Sum       : " & Integer_4(Sum)'Img &
      " Min_Backprice:" & Global_Min_Backprice'Img &
      " Max_Backprice:" & Global_Max_Backprice'Img &
      " Min_Layprice:"  & Global_Min_Layprice'Img  &
      " Max_Layprice:"  & Global_Max_Layprice'Img);
    end ;
  
    Global_Bet_List.Clear;
  end loop;
  Log("Started : " & Start.To_String);

--  Log("Total profit = " & Integer_4(Global_Profit)'Img);
--  for i in Bet_Status_Type'range loop
--    Log(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);
--  end loop;
--  Log("used --max_start_price=" & IA_Max_Start_Price'Img &
--    " --lay_at_price=" & IA_Lay_At_Price'Img &
--    " --max_lay_price=" & IA_Max_Lay_Price'Img);
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_During_Race3;
