with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Environment_Variables;
with Ada.Directories;
with Logging; use Logging;

with Sql;

with Utils;

package body Simulation_Storage is

  Object : constant String := "Simulation_Storage.";

  package EV renames Ada.Environment_Variables;
  package AD renames Ada.Directories;
  
  Global_Streamed_Objects_Direcory : constant String := Ev.Value("BOT_HISTORY") & "/data/streamed_objects/";

  Find_Plc_Market,
  Select_Count_All_Markets,
  Select_All_Markets,
  Select_Sampleids_In_One_Market,
  Select_Race_Winner_In_One_Market,
  Select_Prices_For_Runner_In_One_Market : Sql.Statement_Type;
  
 type Global_Map_Files_Type is record
   Filename : Repository_Types.String_Object;
   Exists   : Boolean;
 end record;  
 
 type Exists_Type is (Marketid, Winner, Win_Place);
 Global_Map_Files : array (Exists_Type'range) of Global_Map_Files_Type  := 
   (
    Marketid  => 
      (Filename => Repository_Types.Create(Global_Streamed_Objects_Direcory & "marketid_map.dat"),
       Exists   => False),
    Winner    => 
      (Filename => Repository_Types.Create(Global_Streamed_Objects_Direcory & "winner_map.dat"),
       Exists   => False),
    Win_Place => 
      (Filename => Repository_Types.Create(Global_Streamed_Objects_Direcory & "win_place_map.dat"),
       Exists   => False)
   );
   
  ----------------------------------------------------------------------------
 
  procedure Create_Files_From_Database is
   Service : constant String := "Create_Files_From_Database";
   T : Sql.Transaction_Type;
   Marketid_Map  : Marketid_Map_Pack.Map;
   Winner_Map    : Winner_Map_Pack.Map;
   Win_Place_Map : Win_Place_Map_Pack.Map;
   Need_Creation : Boolean := False;
  begin
    for i in Exists_Type loop
      Global_Map_Files(i).Exists := AD.Exists(Global_Map_Files(i).Filename.Fix_String);
      Log(Object & Service, Global_Map_Files(i).Filename.Fix_String & " exists " &  Global_Map_Files(i).Exists'Img);         
      if not  Global_Map_Files(i).Exists then
        Need_Creation := True;
      end if;
    end loop;  
  
    Log(Object & Service, "Need_Creation " & Need_Creation'Img);         
    if not Need_Creation then
      return;         
    end if;
    
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
                        
    Log(Object & Service, "count marketids ");                           
    declare
      type Eos_Type is (Count, Market_Key, Sample_Key, Samples); 
      Eos : array (Eos_Type'range) of Boolean :=  (others => False);
      Marketid : Market_Id_Type := (others => ' ');   
      A_Sample_Map : Sample_Map_Pack.Map;
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
    
      Log(Object & Service, "fill list with all valid marketids ");                           
      Select_All_Markets.Open_Cursor;
      loop
        Select_All_Markets.Fetch(Eos(Market_Key));
        exit when Eos(Market_Key);
        Cur := Cur +1;
        Log(Object & Service, Utils.F8_Image( Float_8( 100 * Cur) / Float_8(Cnt)) & " %");
        
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
        Marketid_Map.Insert(Marketid, A_Sample_Map);      
      end loop;  
      Select_All_Markets.Close_Cursor;
    end; 
  
    Log(Object & Service, "fill map win/place market relation ");      
    declare
      Marketid_Place,
      Marketid_Win    : Market_Id_Type := (others => ' ');   
      Eos : Boolean := False;
      C : Marketid_Map_Pack.Cursor := Marketid_Map.First;
    begin
       while Marketid_Map_Pack.Has_Element(C) loop     
         Marketid_Win := Marketid_Map_Pack.Key(C);
         Find_Plc_Market.Set("WINMARKETID", Marketid_Win);
         Find_Plc_Market.Open_Cursor;
         Find_Plc_Market.Fetch(Eos);
         if not Eos then
           Find_Plc_Market.Get("MARKETID",Marketid_Place);
         end if;
         Find_Plc_Market.Close_Cursor;    
         Win_Place_Map.Insert(Marketid_Win, Marketid_Place);      
         Marketid_Map_Pack.Next(C);
       end loop;
    end;
        
    Log(Object & Service, "fill map winners of place race");      
    declare
      Marketid_Win : Market_Id_Type := (others => ' ');   
      Marketid_Plc : Market_Id_Type := (others => ' ');   
      C : Marketid_Map_Pack.Cursor := Marketid_Map.First;
      List : Table_Arunners.Arunners_List_Pack2.List;
    begin
       while Marketid_Map_Pack.Has_Element(C) loop
         Marketid_Win := Marketid_Map_Pack.Key(C);
         Marketid_Plc := Win_Place_Map(Marketid_Win);          
         Select_Race_Winner_In_One_Market.Set("MARKETID", Marketid_Plc) ;
         List.Clear;
         Table_Arunners.Read_List(Select_Race_Winner_In_One_Market, List);   
         Winner_Map.Insert(Marketid_Plc, List);   
         Marketid_Map_Pack.Next(C);
       end loop;
    end;
    T.Commit ;
  
    Log(Object & Service, "Stream Marketid_Map to file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String := Global_Map_Files(Marketid).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Create 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.Out_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Marketid_Map_Pack.Map'Write(Stream, Marketid_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Stream Marketid_Map written to file " & Filename);
    end;
    
    Log(Object & Service, "Stream Win_Place_Map to file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String := Global_Map_Files(Win_Place).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Create 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.Out_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Win_Place_Map_Pack.Map'Write(Stream, Win_Place_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Stream Win_Place_Map written to file " & Filename);
    end;
  
    Log(Object & Service, "Stream Winner_Map to file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String := Global_Map_Files(Winner).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Create 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.Out_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Winner_Map_Pack.Map'Write(Stream, Winner_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Stream Winner_Map written to file " & Filename);  
    end;
  
  end Create_Files_From_Database;
  -------------------------------------------------------
  procedure Fill_Maps(Marketid_Map  : out Marketid_Map_Pack.Map;
                      Winner_Map    : out Winner_Map_Pack.Map; 
                      Win_Place_Map : out Win_Place_Map_Pack.Map) is
    Service : constant String := "Create_Files_From_Database";
  begin
   --if not found then files, create them, else just return 
    Create_Files_From_Database;
  
    Log(Object & Service, "read Marketid_Map from file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String := Global_Map_Files(Marketid).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Open 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.In_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Marketid_Map_Pack.Map'Read(Stream, Marketid_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Marketid_Map read from file " & Filename);
    end;
  
    Log(Object & Service, "read Win_Place_Map from file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String :=  Global_Map_Files(Win_Place).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Open 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.In_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Win_Place_Map_Pack.Map'Read(Stream, Win_Place_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Win_Place_Map read from file " & Filename);
    end;
  
    Log(Object & Service, "read Winner_Map from file ");
    declare
     File   : Ada.Streams.Stream_IO.File_Type;
     Stream : Ada.Streams.Stream_IO.Stream_Access;  
     Filename : String := Global_Map_Files(Winner).Filename.Fix_String;
    begin
      Ada.Streams.Stream_IO.Open 
          (File => File,
           Name => Filename,
           Mode => Ada.Streams.Stream_IO.In_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Winner_Map_Pack.Map'Read(Stream, Winner_Map);
      Ada.Streams.Stream_IO.Close(File);
      Log(Object & Service, "Winner_Map read from file " & Filename);
    end;
  end Fill_Maps;  
  ----------------------------------------------------   

  procedure Load_Strategies(Strategy_List : out Strategy_List_Pack.List) is
  begin
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.10_7.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.10,
                                        Next_At_Min     => 7.0,
                                        Place_Of_Next   => 2,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.25_12.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.25,
                                        Next_At_Min     => 12.0,
                                        Place_Of_Next   => 2,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );  
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.20_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.20,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.30_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.30,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.40_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.40,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Profit            => 0.0,
                                        Backprice_Matched => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.50_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.50,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Profit            => 0.0,
                                        Backprice_Matched => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.60_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.60,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.70_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.70,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.80_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.80,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.90_30.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.90,
                                        Next_At_Min     => 30.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
  ---
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.20_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.20,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.30_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.30,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.40_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.40,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.50_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.50,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.60_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.60,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.70_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.70,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.80_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.80,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.90_40.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.90,
                                        Next_At_Min     => 40.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
  ---
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.20_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.20,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.30_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.30,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.40_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.40,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.50_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.50,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.60_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.60,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.70_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.70,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.80_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.80,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.90_50.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.90,
                                        Next_At_Min     => 50.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
  ---
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.20_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.20,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.30_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.30,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.40_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.40,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.50_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.50,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.60_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.60,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.70_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.70,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.80_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.80,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Num_Matched       => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.90_60.0_1"), 
                                        Marketid        => (others => ' '), 
                                        Leader_At_Max   => 1.90,
                                        Next_At_Min     => 60.0,
                                        Place_Of_Next   => 4,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                               );
    
  end Load_Strategies;

  

end Simulation_Storage;