
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
--with Table_Aprices;
with Table_Apricesfinish;
with Table_Arunners;
--with Table_Amarkets;
with Table_Abets;
with Gnat.Command_Line; use Gnat.Command_Line;
---with GNAT.Strings;
with Calendar2; -- use Calendar2;
with Logging; use Logging;

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings;
with Ada.Strings.Hash;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Utils; use Utils;

procedure Back_Hitrate is

  package Sample_Map is new Ada.Containers.Ordered_Maps
        (Key_Type     => Calendar2.Time_Type,
         Element_Type => Table_Apricesfinish.Apricesfinish_List_Pack2.List,
         "<"          => Calendar2."<",
         "="          => Table_Apricesfinish.Apricesfinish_List_Pack2."=");
 

  package Marketid_Pack is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Sample_Map.Map,
         Ada.Strings.Hash,
         "=",
         Sample_Map."=");

  Global_Marketid_Map : Marketid_Pack.Map;

  
--  package Place_Winners_Pack is new Ada.Containers.Doubly_Linked_Lists(Integer_4);
  
  package Marketid_Winner_Maps is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Table_Arunners.Arunners_List_Pack2.List,
         Ada.Strings.Hash,
         "=",
         Table_Arunners.Arunners_List_Pack2."=");
  
  Global_Winner_Map: Marketid_Winner_Maps.Map;


  package Marketid_Win_Place_Maps is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Market_Id_Type,
         Ada.Strings.Hash,
         "=",
         "=");

  Global_Win_Place_Map: Marketid_Win_Place_Maps.Map;
  
--  type Bet_List_Record is record
--    Bet          : Table_Abets.Data_Type;
--  end record;
  
  package Bet_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Table_Abets.Data_Type, Table_Abets."=");
  
  Global_Bet_List : Bet_List_Pack.List;
    
  T            : Sql.Transaction_Type;
  Find_Plc_Market,
  Select_Count_All_Markets,
  Select_All_Markets,
  Select_Sampleids_In_One_Market,
  Select_Race_Winner_In_One_Market,
  Select_Prices_For_Runner_In_One_Market : Sql.Statement_Type;
  
  Config           : Command_Line_Configuration;
  
  IA_Max_Start_Price : aliased Integer := 30;
  IA_Lay_At_Price    : aliased Integer := 100;
  IA_Max_Lay_Price   : aliased Integer := 200;
  
  Global_Back_Size          : Float_8 := 30.0;
  
  type Best_Runners_Type is array (1..4) of Table_Apricesfinish.Data_Type ;
  type Bet_Status_Type is (No_Bet_Laid, Bet_Laid, Bet_Matched, Bet_Won, Bet_Lost);

--   Income, Stake: Float_8 := 0.0;


--   type Stats_Type is record
--     Hits : Integer_4 := 0;
--     Profit : Float_8 := 0.0;
--   end record ;
--   Profit, Global_Profit : Float_8 := 0.0;

--   OK_Starting_Price : Boolean := False;
--   First_Loop        : Boolean := True;

--   Stats : array (Bet_Status_Type'range) of Stats_Type;
--   Cnt : Integer := 0;

  Min_Backprice1  : constant Float_8 :=  1.1;
  Max_Backprice1  : constant Float_8 :=  2.0;   
  Min_Backprice4  : constant Float_8 :=  30.0;
  Max_Backprice4  : constant Float_8 :=  90.0;

  Step_Backprice1 : constant Float_8 :=  0.1;
  Step_Backprice4 : constant Float_8 :=  5.0;
   
  Backprice1      :          Float_8 :=  0.0;
  Backprice4      :          Float_8 :=  0.0;
   
   --------------------------------------------------------------------------
   
  function "<" (Left,Right : Table_Apricesfinish.Data_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";

  package Backprice_Sorter is new Table_Apricesfinish.Apricesfinish_List_Pack2.Generic_Sorting("<");  
   
  procedure Sort_Best_Runners(Best : in out Best_Runners_Type;  Sample_List : in out Table_Apricesfinish.Apricesfinish_List_Pack2.List) is
    Price : Table_Apricesfinish.Data_Type;
  begin
    -- ok find the runner with lowest backprice:     
    Backprice_Sorter.Sort(Sample_List);
    Price.Backprice := 10_000.0;
    Best := (others => Price);
    
    declare
      Idx : Integer := 0;
    begin
      for Tmp of Sample_List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Float_8(0.0) and then
           Tmp.Layprice  > Float_8(0.0) and then
           Tmp.Backprice < Float_8(1_000.0) and then
           Tmp.Layprice  < Float_8(1_000.0) 
        then
          Idx := Idx +1;
          exit when Idx > Best'Last;
          Best(Idx) := Tmp;
        end if;
      end loop;
    end ;

    for i in Best'range loop
      Log("Best(i) " & i'Img & Best(i).To_String);
    end loop;
  
  end Sort_Best_Runners;  
  -------------------------------------------------------------------- 
   
  procedure Treat(Best_Runners       : in     Best_Runners_Type;
                  Status             : in out Bet_Status_Type;
                  Bet                : in out Table_Abets.Data_Type;
                  Bet_List           : in out Bet_List_Pack.List;
                  Back1,Back4        : in     Float_8) is
    use Calendar2;
  begin
    case Status is
      when No_Bet_Laid => 
        if Best_Runners(1).Backprice <= Back1 and then
           Best_Runners(4).Backprice >= Back4 then
            
          Bet.Marketid := Best_Runners(1).Marketid;
          Bet.Selectionid := Best_Runners(1).Selectionid;
          Bet.Size := Global_Back_Size;
          Bet.Price := Best_Runners(1).Backprice;
          Bet.Betplaced := Best_Runners(1).Pricets;
          Status := Bet_Laid;
        end if;
       
      when Bet_Laid    =>  
        if Best_Runners(1).Pricets >  Bet.Betplaced + (0,0,0,1,0) and then -- 1 second later at least, time for BF delay
           Best_Runners(1).Backprice >= Bet.Price then
           
            Status := Bet_Matched;
            Bet_List.Append(Bet);
        end if;
       
      when Bet_Matched => null;
      when Bet_Won     => null;
      when Bet_Lost    => null;
    end case;  
  end Treat;
  --------------------------------------------------------------------------
   
   
   
   
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

--     if Ia_Best_Position = 0 or else
--       Ia_Max_Odds = 0 then
--       Display_Help (Config);
--       return;
--     end if;

  Log ("Connect db");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "dry",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");

  T.Start;
  
  Select_Count_All_Markets.Prepare(
    "select count('a') from ( " &
    "  select distinct(MARKETID) from APRICESFINISH" &
    ") tmp");
    
  Select_All_Markets.Prepare (
    "select distinct(MARKETID) " &
    "from APRICESFINISH " &
    "order by MARKETID");
                      
  Select_Sampleids_In_One_Market.Prepare( "select distinct(PRICETS) " &
    "from APRICESFINISH " &
    "where MARKETID = :MARKETID " &
    "order by PRICETS" ) ;

  Select_Prices_For_Runner_In_One_Market.Prepare(
    "select * " &
    "from APRICESFINISH " &
    "where MARKETID = :MARKETID " &
    "and PRICETS = :PRICETS " ) ;
                      
  Select_Race_Winner_In_One_Market.Prepare(
    "select * " &
    "from ARUNNERS " &
    "where MARKETID = :MARKETID " &
    "and STATUS = 'WINNER' ") ;
                      
  Find_Plc_Market.Prepare(
    "select MP.* from AMARKETS MW, AMARKETS MP " &
    "where MW.EVENTID = MP.EVENTID " &
    "and MW.STARTTS = MP.STARTTS " &
    "and MW.MARKETID = :WINMARKETID " &
    "and MP.MARKETTYPE = 'PLACE' " &
    "and MW.MARKETTYPE = 'WIN'" ) ;
                      
  Log("count marketids ");                           
  declare
    type Eos_Type is (Count, Market_Key, Sample_Key, Samples); 
    Eos : array (Eos_Type'range) of Boolean :=  (others => False);
    Marketid : Market_Id_Type := (others => ' ');   
    A_Sample_Map : Sample_Map.Map;
    Sampleid : Calendar2.Time_Type := Calendar2.Time_Type_First;
    Sample_List :  Table_Apricesfinish.Apricesfinish_List_Pack2.List;
    Sample :  Table_Apricesfinish.Data_Type;
    Cnt, Cur : Integer_4 := 0;
  begin
    Select_Count_All_Markets.Open_Cursor;                 
    Select_Count_All_Markets.Fetch(Eos(Count));
    if not Eos(Count) then
      Select_Count_All_Markets.Get(1,Cnt);                 
    else
      Cnt := 1;
    end if;    
    Select_Count_All_Markets.Close_Cursor;

  
    Log("fill list with all valid marketids ");                           
    Select_All_Markets.Open_Cursor;
    loop
      Select_All_Markets.Fetch(Eos(Market_Key));
      exit when Eos(Market_Key);
      Cur := Cur +1;
      Log(Utils.F8_Image( Float_8( 100 * Cur) / Float_8(Cnt)));
      
      Select_All_Markets.Get(1,Marketid); 
      
      Select_Sampleids_In_One_Market.Set("MARKETID", Marketid) ;
      Select_Sampleids_In_One_Market.Open_Cursor;
      A_Sample_Map.Clear;
      loop
        Select_Sampleids_In_One_Market.Fetch(Eos(Sample_Key));
        exit when Eos(Sample_Key);
        Select_Sampleids_In_One_Market.Get(1,Sampleid);
        
        Select_Prices_For_Runner_In_One_Market.Set("MARKETID", Marketid);
        Select_Prices_For_Runner_In_One_Market.Set("PRICETS", Sampleid);
        Sample_List.Clear;
        Select_Prices_For_Runner_In_One_Market.Open_Cursor;
        loop 
          Select_Prices_For_Runner_In_One_Market.Fetch(Eos(Samples));
          exit when Eos(Samples);
          Sample := Table_Apricesfinish.Get(Select_Prices_For_Runner_In_One_Market);
          Sample_List.Append(Sample);
        end loop;
        A_Sample_Map.Insert(Sampleid, Sample_List);      
        Select_Prices_For_Runner_In_One_Market.Close_Cursor;
      end loop;  
      Select_Sampleids_In_One_Market.Close_Cursor;
      Global_Marketid_Map.Insert(Marketid, A_Sample_Map);      
    end loop;  
    Select_All_Markets.Close_Cursor;
  end; 

  Log("fill map win/place market relation ");      
  declare
    Marketid_Place,
    Marketid_Win    : Market_Id_Type := (others => ' ');   
    Eos : Boolean := False;
    C : Marketid_Pack.Cursor := Global_Marketid_Map.First;
  begin
     while Marketid_Pack.Has_Element(C) loop     
       Marketid_Win := Marketid_Pack.Key(C);
       Find_Plc_Market.Set("WINMARKETID", Marketid_Win);
       Find_Plc_Market.Open_Cursor;
       Find_Plc_Market.Fetch(Eos);
       if not Eos then
         Find_Plc_Market.Get("MARKETID",Marketid_Place);
       end if;
       Find_Plc_Market.Close_Cursor;    
       Global_Win_Place_Map.Insert(Marketid_Win, Marketid_Place);      
       Marketid_Pack.Next(C);
     end loop;
  end;
      
  Log("fill map winners ");      
  declare
    Marketid : Market_Id_Type := (others => ' ');   
    C : Marketid_Pack.Cursor := Global_Marketid_Map.First;
    List : Table_Arunners.Arunners_List_Pack2.List;
  begin
     while Marketid_Pack.Has_Element(C) loop
       Marketid := Marketid_Pack.Key(C);
       Select_Race_Winner_In_One_Market.Set("MARKETID", Marketid) ;
       
       List.Clear;
       Table_Arunners.Read_List(Select_Race_Winner_In_One_Market, List);   
       Global_Winner_Map.Insert(Marketid, List);   
       
       Marketid_Pack.Next(C);
     end loop;
  end;
  T.Commit ;
  -- no need for db anymore
  Sql.Close_Session;
  
  Log("start process");      
  Backprice1 := Min_Backprice1 - Step_Backprice1; -- incremented first time 
  Back1 : loop
    Backprice1 := Backprice1 + Step_Backprice1;
    exit Back1 when Backprice1 > Max_Backprice1;
    
    Backprice4 := Min_Backprice4 - Step_Backprice4; -- incremented first time 
    Back4 : loop
      Backprice4 := Backprice4 + Step_Backprice4;
      exit Back4 when Backprice4 > Max_Backprice4;
      
      Log ("treat Backprice:" & F8_Image(Backprice1) & " Backprice4:" & F8_Image(Backprice4)); 
      
      declare
        Cnt          : Integer := 0;
        Bet          : Table_Abets.Data_Type; 
        Market_Id_C  : Marketid_Pack.Cursor := Global_Marketid_Map.First;
        Marketid     : Market_Id_Type := (others => ' ');   
        Sample_Id_C  : Sample_Map.Cursor;
        Pricets      : Calendar2.Time_Type := Calendar2.Time_Type_First;      
        A_Sample_Map : Sample_Map.Map;
      begin
        Markets_Loop : while Marketid_Pack.Has_Element(Market_Id_C) loop
          Cnt := Cnt + 1; 
          Marketid := Marketid_Pack.Key(Market_Id_C);
          Log("Marketid " & Marketid);
          A_Sample_Map := Marketid_Pack.Element(Market_Id_C);
          Sample_Id_C := A_Sample_Map.First;
          
          while Sample_Map.Has_Element(Sample_Id_C) loop
            Pricets := Sample_Map.Key(Sample_Id_C);
            Log("pricts " & Pricets.To_String);
            declare           
              Bet_Status   : Bet_Status_Type := No_Bet_Laid;
              Sample_List  : Table_Apricesfinish.Apricesfinish_List_Pack2.List := Sample_Map.Element(Sample_Id_C);
              Best_Runners : Best_Runners_Type := (others => Table_Apricesfinish.Empty_Data);            
            begin
              Sort_Best_Runners(Best_Runners, Sample_List);
              Treat(Best_Runners, Bet_Status, Bet, Global_Bet_List, Backprice1, Backprice4);
              exit when Bet_Status >= Bet_Matched;    
            end;  
            exit Markets_Loop when Cnt > Integer(5) ; --tmp test   
            Sample_Map.Next(Sample_Id_C);
          end loop;
  
          Marketid_Pack.Next(Market_Id_C);
        end loop Markets_Loop;        
      end;   
     end loop Back4;
  end loop Back1;    
     
  Log("num matched bets" & Global_Bet_List.Length'Img);      
  declare
    Sum, Sum_Winners, Sum_Losers : Float_8 := 0.0;
    Profit : Float_8 := 0.0;
    Winners,Losers : Integer_4 := 0;
  begin
    for Bet of Global_Bet_List loop
          -- did it win ?
      if true then 
      --     if Global_Winner_Map.Element((Bet.Marketid)) = Bet.Selectionid then
        -- won
        Profit := (Bet.Price -1.0) * Global_Back_Size * 0.935;
        Winners := Winners+1;
        Sum_Winners := Sum_Winners + Profit;              
      else
        -- lost
        Profit := -Global_Back_Size;
        Losers := Losers +1;
        Sum_Losers := Sum_Losers + Profit;
      end if;
    end loop;
    Sum := Sum_Winners + Sum_Losers ;
    Log("Winners :" & Winners'Img & Integer_4(Sum_Winners)'Img );      
    Log("Losers  :" & Losers'Img  & Integer_4(Sum_Losers)'Img);      
    Log("Sum     :" & Integer_4(Sum)'Img  );      
    pragma Compile_Time_Warning(True, "Lista/map per strategi ...."  );          
  end ;
  Global_Bet_List.Clear;      
 
--  Log("Total profit = " & Integer_4(Global_Profit)'Img);
--  for i in Bet_Status_Type'range loop
--    Log(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);
--  end loop;
  Log("used --max_start_price=" & IA_Max_Start_Price'Img &
    " --lay_at_price=" & IA_Lay_At_Price'Img &
    " --max_lay_price=" & IA_Max_Lay_Price'Img);
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Back_Hitrate;
