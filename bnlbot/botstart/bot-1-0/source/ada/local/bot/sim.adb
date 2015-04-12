with Ada.Containers.Doubly_Linked_Lists;
with Logging; use Logging;

with Bot_System_Number;
with Calendar2; use Calendar2;
--with Utils; use Utils;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Bot_Svn_Info;
with Table_Apricesfinish;
with Sql;


package body Sim is


  Stm_Select_Marketid_Pricets_O : Sql.Statement_Type;
  Stm_Select_Pricets_O : Sql.Statement_Type;

  
  Current_Market : Table_Amarkets.Data_Type := Table_Amarkets.Empty_Data;
  Global_Price_During_Race_List : Table_Apricesfinish.Apricesfinish_List_Pack2.List;
    
  Global_Current_Pricets: Calendar2.Time_Type := Calendar2.Time_Type_First ;
  package Pricets_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Calendar2.Time_Type);
  Pricets_List : Pricets_List_Pack.List;


  procedure Get_Market_Prices(Market_Id  : in     Market_Id_Type; 
                              Market     : in out Table_Amarkets.Data_Type;
                              Price_List : in out Table_Aprices.Aprices_List_Pack2.List;
                              In_Play    :    out Boolean) is
    Eos : Boolean := False;                           
    use type Table_Amarkets.Data_Type;
    Price_During_Race_Data : Table_Apricesfinish.Data_Type;
    Price_Data : Table_Aprices.Data_Type;
    T : Sql.Transaction_Type;
    Ts : Calendar2.Time_Type := Calendar2.Time_Type_First ;
  begin
    In_Play := True;
    -- trigg for a new market
    if Current_Market = Table_Amarkets.Empty_Data then
      Current_Market := Market;
      Global_Price_During_Race_List.Clear;
      Pricets_List.Clear;
      T.Start;
      Stm_Select_Pricets_O.Prepare(
        "select distinct(PRICETS) from APRICESFINISH " &
        "where MARKETID =:MARKETID " &
        "order by PRICETS ");
        
      Stm_Select_Pricets_O.Set("MARKETID", Market_Id);
      Stm_Select_Pricets_O.Open_Cursor;
      loop
        Stm_Select_Pricets_O.Fetch(Eos);
        exit when Eos;
        Stm_Select_Pricets_O.Get(1,Ts);
        Pricets_List.Append(Ts);
      end loop;
      Stm_Select_Pricets_O.Close_Cursor;
      T.Commit;
      if not Pricets_List.Is_Empty then
        Global_Current_Pricets := Pricets_List.First_Element;
      else
       Log("Sim.Get_Market_Prices : No pricesdata found");
       Move("CLOSED",Market.Status);  
       Current_Market := Table_Amarkets.Empty_Data;
       return;
      end if;      
    else
      -- find next in list by seraching the list for curr val and return next
      declare 
        Use_Next : Boolean := False;
        Next_Existed : Boolean := False;
      begin
        for e of Pricets_List loop
          if e = Global_Current_Pricets then
            Use_Next := True;
          elsif Use_Next then
            Global_Current_Pricets := e;
            Next_Existed := True;
            exit;
          end if;
        end loop;
        if not Next_Existed then
          Move("CLOSED",Market.Status);  
          Current_Market := Table_Amarkets.Empty_Data;
          return;
        end if;
      end;
    end if;
      
    T.Start;        
    Stm_Select_Marketid_Pricets_O.Prepare(
      "select * from APRICESFINISH " &
      "where MARKETID =:MARKETID " &
      "and PRICETS =:PRICETS ");      
    Stm_Select_Marketid_Pricets_O.Set("MARKETID", Market_Id);
    Stm_Select_Marketid_Pricets_O.Set("PRICETS", Global_Current_Pricets);
    Stm_Select_Marketid_Pricets_O.Open_Cursor;
    loop
      Stm_Select_Marketid_Pricets_O.Fetch(Eos);
      exit when Eos;
      Price_During_Race_Data := Table_Apricesfinish.Get(Stm_Select_Marketid_Pricets_O);
      Price_Data := (
         Marketid     => Price_During_Race_Data.Marketid,
         Selectionid  => Price_During_Race_Data.Selectionid,
         Pricets      => Price_During_Race_Data.Pricets,
         Status       => Price_During_Race_Data.Status,
         Totalmatched => Price_During_Race_Data.Totalmatched,
         Backprice    => Price_During_Race_Data.Backprice,
         Layprice     => Price_During_Race_Data.Layprice,
         Ixxlupd      => Price_During_Race_Data.Ixxlupd,
         Ixxluts      => Price_During_Race_Data.Ixxluts
      );
      Price_List.Append(Price_Data);
    end loop;
    Stm_Select_Marketid_Pricets_O.Close_Cursor;
    T.Commit;
    Move("OPEN",Market.Status);    
        
  end Get_Market_Prices;
                              
  
                              
  procedure Place_Bet (Bet_Name         : in     Bet_Name_Type;
                       Market_Id        : in     Market_Id_Type; 
                       Side             : in     Bet_Side_Type;
                       Runner_Name      : in     Runner_Name_Type;
                       Selection_Id     : in     Integer_4;
                       Size             : in     Bet_Size_Type;
                       Price            : in     Bet_Price_Type;
                       Bet_Persistence  : in     Bet_Persistence_Type;
                       Bet              :    out Table_Abets.Data_Type) is
    pragma Unreferenced(Bet_Persistence);        
                       
    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;

    Bet_Id : Integer_8 := 0;
    Now : Calendar2.Time_Type := Calendar2.Clock;                       
    Side_String   : Bet_Side_String_Type := (others => ' ');
    Market : Table_Amarkets.Data_Type;
    Eos : Boolean := False;
  begin
    Move(Side'Img, Side_String);
    Market.Marketid := Market_Id;
    Market.Read(Eos);
    Bet_Id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
    Move( "EXECUTION_COMPLETE", Order_Status);
    Move( "SUCCESS", Execution_Report_Status);
    Move( "SUCCESS", Execution_Report_Error_Code);
    Move( "SUCCESS", Instruction_Report_Status);
    Move( "SUCCESS", Instruction_Report_Error_Code);

    Bet := (
      Betid          => Bet_Id,
      Marketid       => Market_Id,
      Betmode        => Bot_Mode(Simulation),
      Powerdays      => 0,
      Selectionid    => Selection_Id,
      Reference      => (others => '-'),
      Size           => Float_8(Size),
      Price          => Float_8(Price),
      Side           => Side_String,
      Betname        => Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => Market.Startts,
      Betplaced      => Now,
      Pricematched   => Float_8(Price),
      Sizematched    => Float_8(Size),
      Runnername     => Runner_Name,
      Fullmarketname => Market.Marketname,
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );
  end Place_Bet;
  
end Sim ;
