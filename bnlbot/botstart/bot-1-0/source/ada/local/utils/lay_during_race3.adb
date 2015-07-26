with Ada.Containers.Doubly_Linked_Lists;
--with Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Sim;

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


  -- Market_Id_With_Data_Pack
  -- Holds list of all market ids that has data

  Market_Id_With_Data_List : Sim.Market_Id_With_Data_Pack.List;
    
  Marketid_Timestamp_To_Apriceshistory_Map : Sim.Marketid_Timestamp_To_Apriceshistory_Maps.Map;

  --Marketid_Runners_Map         : Sim.Marketid_Runners_Maps.Map;
  Marketid_Pricets_Map         : Sim.Marketid_Pricets_Maps.Map;
  --Marketid_Runners_Pricets_Map : Sim.Marketid_Runners_Pricets_Maps.Map;
  
  Winners_Map: Sim.Marketid_Winner_Maps.Map;

  

  --Racedata_Map : Sim.Market_Id_And_Selectionid_Maps.Map;

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

  Lay_Size  : Float_8 := 30.0;

  type Bet_Status_Type is (No_Bet_Laid, Bet_Laid, Bet_Matched, Bet_Won, Bet_Lost);
  Bet_Status : Bet_Status_Type := No_Bet_Laid;

  
  Global_Min_Backprice  : constant Integer_4 := 160;
  Global_Max_Backprice  : constant Integer_4 := 400;   
  Global_Min_Layprice   : constant Integer_4 :=  10;
  Global_Max_Layprice   : constant Integer_4 := 200;

--  Step_Layprice  : constant Integer_4 :=   5;
--  Step_Backprice : constant Integer_4 :=   5;
--   
--  Layprice       :          Integer_4 :=  10;
--  Backprice      :          Integer_4 :=  10;
   
   --------------------------------------------------------------------------
   
  function "<" (Left,Right : Table_Apriceshistory.Data_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new  Table_Apriceshistory.Apriceshistory_List_Pack2.Generic_Sorting("<");
   
  type Best_Runners_Array_Type is array (1..4) of Table_Apriceshistory.Data_Type;
   
   
  procedure Treat_Lay(List     : in Table_Apriceshistory.Apriceshistory_List_Pack2.List ;
                      WR       : in Table_Apriceshistory.Data_Type ;
                      Status   : in out Bet_Status_Type;
                      Bet      : in out Table_Abets.Data_Type;
                      Bet_List : in out Bet_List_Pack.List;
                      Max_Backprice: in Integer_4;
                      Min_Backprice: in Integer_4;
                      Max_Layprice : in Integer_4;
                      Min_Layprice : in Integer_4) is
    use Calendar2;
  begin
    case Status is
      when No_Bet_Laid => 
        -- make sure no bet in the air, waiting for 1 second
        if Bet.Selectionid = 0 then
          if WR.Backprice >= Float_8(Min_Backprice)and then
             WR.Layprice  >= Float_8(Min_Layprice) and then 
             WR.Backprice <= Float_8(Max_Backprice) and then 
             WR.Layprice  <= Float_8(Max_Layprice) then
              
            Bet.Marketid    := WR.Marketid;
            Bet.Selectionid := WR.Selectionid;
            Bet.Size        := Lay_Size;
            Bet.Price       := WR.Layprice;
            Bet.Betplaced   := WR.Pricets;
            Status          := Bet_Laid;
          end if;
        end if;      
      when Bet_Laid    =>  
        -- make sure the WR here is the same as got the bet laid
        if WR.Selectionid = Bet.Selectionid then
          if WR.Pricets >  Bet.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
            if WR.Layprice <= Bet.Price and then -- Laybet so yes '<=' NOT '>='
             WR.Layprice >  Float_8(1.0) and then -- sanity
             WR.Backprice >  Float_8(1.0) then -- sanity
              Status := Bet_Matched;
              Bet.Status(1) := 'M';
              Bet_List.Append(Bet_List_Record'(Bet,WR));
              Bet := Table_Abets.Empty_Data;  --reset bet
            end if;
          end if;
        end if;   
       
      when Bet_Matched => null;
      when Bet_Won     => null;
      when Bet_Lost    => null;
    end case;  
  end Treat_Lay;
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
          if Tmp.Status(1..6) = "ACTIVE" then
            Idx := Idx +1;
            exit when Idx > BRA'Last;
            BRA(Idx) := Tmp;
          end if;
        end loop;
      end ;

      for Tmp of List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Float_8(1.0) and then
           Tmp.Layprice < Float_8(1_000.0) and then
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


  Log ("Connect db");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "dry",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");

  Log("fill list with all valid marketids ");   
  Sim.Read_All_Markets(Market_Id_With_Data_List); 

  Log("fill map with all pricets for a marketid ");   
  Sim.Fill_Marketid_Pricets_Map(Market_Id_With_Data_List, Marketid_Pricets_Map); 

  Log("fill map with map of timestamp list for all marketids ");   
  Sim.Fill_Marketid_Runners_Pricets_Map(Market_Id_With_Data_List,
                                        Marketid_Pricets_Map,
                                        Marketid_Timestamp_To_Apriceshistory_Map) ;
   
  Log("fill map winners ");     
  Sim.Fill_Winners_Map(Market_Id_With_Data_List, Winners_Map );
  
  -- no need for db anymore
  Sql.Close_Session;
  
  Log("start process");      

      declare
        Cnt             : Integer := 0;
        Bet : Table_Abets.Data_Type; 

      begin
        for Marketid of Market_Id_With_Data_List loop    
          Cnt := Cnt + 1; 
          Log("marketid '" & Marketid & "'" & Cnt'Img & "/" & Market_Id_With_Data_List.Length'Img);   
        
          Bet_Status := No_Bet_Laid;
          Bet := Table_Abets.Empty_Data;        
          -- list of timestamps in this market
          declare
            Timestamp_To_Apriceshistory_Map : Sim.Timestamp_To_Apriceshistory_Maps.Map :=
                          Marketid_Timestamp_To_Apriceshistory_Map(Marketid);
          begin  
            for Timestamp of Marketid_Pricets_Map(Marketid) loop
              declare
                List : Table_Apriceshistory.Apriceshistory_List_Pack2.List := 
                          Timestamp_To_Apriceshistory_Map(Timestamp.To_String);
              begin         
                Best_Runners := (others => Table_Apriceshistory.Empty_Data);
                Worst_Runner := Table_Apriceshistory.Empty_Data;

                Sort_Array(List => List,
                           BRA  => Best_Runners, 
                           WR   => Worst_Runner);
                           
               -- Treat_Back(List, Best_Runners);
                Treat_Lay(List          => List, 
                          WR            => Worst_Runner,
                          Status        => Bet_Status, 
                          Bet           => Bet, 
                          Bet_List      => Global_Bet_List, 
                          Max_Backprice => Global_Max_Backprice,
                          Min_Backprice => Global_Min_Backprice,
                          Max_Layprice  => Global_Max_Layprice,
                          Min_Layprice  => Global_Min_Layprice);  

              end; 
            end loop; --  Timestamp
          end;  
        end loop;  -- marketid
      end;   

      -- Winners_Map
      
      Log("num matched bets" & Global_Bet_List.Length'Img);      
     
      declare
        Sum, Sum_Winners, Sum_Losers : Float_8 := 0.0;
        Profit : Float_8 := 0.0;
        Winners,Losers : Integer_4 := 0;
      begin
        for Bet_Record of Global_Bet_List loop
          --Log("");
          --Log(Bet_Record.Bet.To_String);
          --Log(Bet_Record.Price_Finish.To_String);
          --Log("----------------");
          case Bet_Record.Bet.Status(1) is
            when 'M'  => -- matched
              -- did it win ?
              if Winners_Map.Element((Bet_Record.Bet.Marketid)) = Bet_Record.Bet.Selectionid then
                -- lost
              -- Bet.Status(1) := 'L';
              --  Bet.Profit := Lay_Size * 0.935;
                Profit := -(Bet_Record.Bet.Price - 1.0) * Lay_Size ;
                Losers := Losers +1;
                Sum_Losers := Sum_Losers + Profit;
                Log("bad bet: " & Bet_Record.Price_Finish.To_String);
              else
                -- won
                --Bet.Status(1) := 'W';
                --Bet.Profit := (Bet.Price - 1.0) * Lay_Size ;
                Profit := Lay_Size * 0.935;
                Winners := Winners+1;
                Sum_Winners := Sum_Winners + Profit;
                
              end if;
            when others => null;
          end case;
        end loop;
        Sum := Sum_Winners + Sum_Losers ;
        Log("Winners : " & Winners'Img & " " & Integer_4(Sum_Winners)'Img );      
        Log("Losers  : " & Losers'Img  & " " & Integer_4(Sum_Losers)'Img);      
        Log("Sum     : "  & Integer_4(Sum)'Img & 
        " Min_Backprice:" & Global_Min_Backprice'Img & 
        " Max_Backprice:" & Global_Max_Backprice'Img & 
        " Min_Layprice:"  & Global_Min_Layprice'Img  &     
        " Max_Layprice:"  & Global_Max_Layprice'Img);      
      end ;
     
      Global_Bet_List.Clear;
 
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
