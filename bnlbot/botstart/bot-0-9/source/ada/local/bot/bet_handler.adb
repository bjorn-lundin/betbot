with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Logging; use Logging;
--with Sattmate_Types; use Sattmate_Types;
--with Bot_Types; use  Bot_Types;
with Bot_Config; use Bot_Config;

with Table_Abets;
with Sql;
with General_Routines;
with Sattmate_Calendar;

package body Bet_Handler is

  Select_History,
  Select_Prices : Sql.Statement_Type;

  Me : constant String := "Bet_Handler.";  
  
  
  type Bet_History_Record is record
    Weight : Float_8 := 0.0;
    Date   : Sattmate_Calendar.Time_Type;
    Profit : Float_8 := 0.0;
  end record;
  
  type Bet_History_Array is array ( 1 .. 21 ) of Bet_History_Record;
  
  
  function Create (Market_Notification : in Bot_Messages.Market_Notification_Record) return Bet_Info_Record is
    Bet_Info : Bet_Info_Record ;
    type Eos_Type is (A_Event, A_Market);
    Eos : array(Eos_Type'range) of Boolean := (others => True);
    Runner : Table_Arunners.Data_Type;
    Price : Table_Aprices.Data_Type;
    Max_Idx : Integer := 0;
    T : Sql.Transaction_Type;
    Eol : Boolean := True;
  begin
    Sql.Start_Read_Write_Transaction(T);
 
    Bet_Info.Market.Marketid := Market_Notification.Market_Id;
    Table_Amarkets.Read(Bet_Info.Market, Eos(A_Market));
    
    if not Eos(A_Market) then
      Bet_Info.Event.Eventid := Bet_Info.Market.Eventid;
      Table_Aevents.Read(Bet_Info.Event, Eos(A_Event));      
    else
      raise No_Data with "Market missing: '" & Market_Notification.Market_Id & "'";    
    end if;
    
    if not Eos(A_Event) then
      Bet_Info.Runner_List := Table_Arunners.Arunners_List_Pack.Create;
      Runner.Marketid := Bet_Info.Market.Marketid;
      Table_Arunners.Read_I1_Marketid(Runner,Bet_Info.Runner_List, Order => True);
      if Table_Arunners.Arunners_List_Pack.Get_Count(Bet_Info.Runner_List) = 0 then
        raise No_Data with "Runners missing: '" & Market_Notification.Market_Id & "'";    
      end if;    
    else
      raise No_Data with "Event missing: '" & Market_Notification.Market_Id & "'";    
    end if;
      
    Bet_Info.Price_List := Table_Aprices.Aprices_List_Pack.Create;    
    Sql.Prepare(Select_Prices, 
      "select * from APRICES where MARKETID=:MARKETID order by BACKPRICE");
    Sql.Set(Select_Prices,"MARKETID", Bet_Info.Market.Marketid);
    Table_Aprices.Read_List(Select_Prices, Bet_Info.Price_List);
    
    if Table_Aprices.Aprices_List_Pack.Get_Count(Bet_Info.Price_List) = 0 then
      raise No_Data with "Prices missing: '" & Market_Notification.Market_Id & "'";    
    end if;    
      
    Sql.Commit(T);
    
    Table_Aprices.Aprices_List_Pack.Get_First(Bet_Info.Price_List, Price, Eol);
    loop
      exit when Eol;
      Max_Idx := Max_Idx +1; 
      Bet_Info.Price_Array(Max_Idx) := Price;
      Table_Aprices.Aprices_List_Pack.Get_Next(Bet_Info.Price_List, Price, Eol);
    end loop;
    Bet_Info.Last_Price := Max_Idx;
    
    Max_Idx := 0;    
    Table_Arunners.Arunners_List_Pack.Get_First(Bet_Info.Runner_List, Runner, Eol);
    loop
      exit when Eol;
      Max_Idx := Max_Idx +1; 
      Bet_Info.Price_Array(Max_Idx) := Price;
      Table_Arunners.Arunners_List_Pack.Get_Next(Bet_Info.Runner_List, Runner, Eol);
    end loop;
    Bet_Info.Last_Runner := Max_Idx;
    
    
    return Bet_Info;
  end Create;
  -------------------------------------------------------------------------------
  overriding procedure Finalize (Bet_Info : in out Bet_Info_Record) is
  begin
      Table_Arunners.Arunners_List_Pack.Release(Bet_Info.Runner_List);
      Table_Aprices.Aprices_List_Pack.Release(Bet_Info.Price_List);
  end Finalize;
  -------------------------------------------------------------------------------
    
  procedure Try_Make_New_Bet (Bet_Info : in out Bet_Info_Record; Bot_Cfg : in out Bot_Config.Bet_Section_Type) is
  begin
    -- some sanity checks
    case Bet_Info.Event.Eventtypeid is 
      when 7 =>    -- horses
        if Bot_Cfg.Animal /= Horse then
           raise Bad_Data with "7 is not :" &  Bot_Cfg.Animal'Img;
        end if;
      when 4339 => -- hounds
        if Bot_Cfg.Animal /= Hound then
           raise Bad_Data with "4339 is not :" &  Bot_Cfg.Animal'Img;
        end if;
      when others => raise Bad_Data with "not supported eventtype:" & Bet_Info.Event.Eventtypeid'Img; 
    end case;

    declare -- see if we can make a bet now
      Bet : Bet_Type := Create(Bet_Info, Bot_Cfg);
      Fulfilled : Boolean := True;
    begin
        pragma Compile_Time_Warning(True, "Do implement");
--      Log(Me & "Try_Make_New_Bet", Bet.To_String);
        Bet.Conditions_Fulfilled(Fulfilled);
      if Fulfilled then
--        Bet.Make_Dry_Bet;
        if Bet.Enabled then
          if Bet.History_Ok then
--            Bet.Make_Real_Bet;
              null; 
          end if;
        end if;
      end if;
    end;

    
  end Try_Make_New_Bet;
    
  -------------------------------------------------------------------------------
    
  procedure Treat_Market(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Bet_Info : Bet_Info_Record := Create(Market_Notification);
    Eol : Boolean := True;
    Bet_Section : Bet_Section_Type;
  begin
    Bet_Pack.Get_First(Bot_Config.Config.Bet_Section_List, Bet_Section,Eol);
    loop
      exit when Eol;
      Bet_Info.Try_Make_New_Bet(Bet_Section);
      Bet_Pack.Get_Next(Bot_Config.Config.Bet_Section_List, Bet_Section, Eol);
    end loop;
  end Treat_Market;
  -------------------------------------------------------------------------------
  
--------------------  BET_TYPE start----------------------------------------  

  function Create (Bet_Info : Bet_Info_Record'Class; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type is
    Tmp : Bet_Type ;
    use General_Routines;
  begin
    Tmp.Bet_Info := Bet_Info_Record(Bet_Info);
    Tmp.Bot_Cfg := Bot_Cfg;
    if Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_lay_") > 0 then 
      Tmp.This_Bet_Type := Lay;
    elsif Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_back_") > 0 then 
      Tmp.This_Bet_Type := Back;
    else
      raise Bad_Data with "bad bet type: '" & Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)) & "'";    
    end if;
    return Tmp;
  end Create;
  -----------------------------------------------------------------------
  function Enabled(Bet : Bet_Type) return Boolean is 
  begin
    return Bet.Bot_Cfg.Enabled;
  end Enabled;
  -----------------------------------------------------------------------

  
  procedure Conditions_Fulfilled(Bet : in out Bet_Type; Result : in out Boolean) is
    Price_Fav, Price_2nd_Fav : Table_Aprices.Data_Type;
    Max_Turns : Integer := 0;
    Num_Runners : Integer := Bet.Bet_Info.Last_Price;
    Max_Favorite_Odds : Float_8 := 0.0;
  begin
    Result := True;
    -- check market status --?
    if General_Routines.Trim(Bet.Bet_Info.Market.Status) /= "OPEN" then
      Log(Me & "Conditions_Fulfilled", "Market.Status /= 'OPEN', '" & General_Routines.Trim(Bet.Bet_Info.Market.Status) & "'");
      Result := False;
      return;
    end if;
  
    case Bet.This_Bet_Type is
      when Back => -- only check the favorite here
        if Bet.Bet_Info.Last_Price < 2 then
          Log(Me & "Conditions_Fulfilled", "Bet.Bet_Info.Last_Price < 2, " & Bet.Bet_Info.Last_Price'Img);
          Result := False;
          return;
        end if;           

        Price_Fav     := Bet.Bet_Info.Price_Array(1);
        Price_2nd_Fav := Bet.Bet_Info.Price_Array(2);
       
        -- check price within backprice +- deltaprice
        if  Bet.Bot_Cfg.Back_Price - Bet.Bot_Cfg.Delta_Price <= Price_Fav.Backprice and then
            Price_Fav.Backprice <= Bet.Bot_Cfg.Back_Price + Bet.Bot_Cfg.Delta_Price and then
            Price_Fav.Backprice + Bet.Bot_Cfg.Favorite_By < Price_2nd_Fav.Backprice then
          null; --Ok, within bot-bounds
        else
          Result := False;
          return;
        end if;
        Bet.Bet_Info.Selection_Id := Price_Fav.Selectionid;

      when Lay =>
        -- check min_lay_price < price <= max_lay_price
        -- we can not loop for dogs. Check how many turns for horses
        if General_Routines.Trim(Bet.Bet_Info.Market.Markettype) = "WIN" then
          case Bet.Bet_Info.Event.Eventtypeid is 
            when 7    => 
              Max_Turns := Num_Runners - 7;  -- always 7 horses before mine ...
              Max_Favorite_Odds := 5.0;
            when 4339 => 
              Max_Turns := 1;                --always last hound
              Max_Favorite_Odds := 1.9;
            when others => raise Bad_Data with "Bad eventtype: " & Bet.Bet_Info.Event.Eventtypeid'Img;
          end case;
        elsif General_Routines.Trim(Bet.Bet_Info.Market.Markettype) = "PLACE" then
          case Bet.Bet_Info.Event.Eventtypeid is 
            when 7    => 
              Max_Turns := 1;  -- always 0 horses before mine ...
              Max_Favorite_Odds := 2.0;
            when 4339 => 
              Max_Turns := 1;                --always last hound
              Max_Favorite_Odds := 1.5;
            when others => raise Bad_Data with "Bad eventtype: " & Bet.Bet_Info.Event.Eventtypeid'Img;
          end case;
        end if;
        -- check favorite odds (i.e. there is a clear favorite)
        if Bet.Bet_Info.Price_Array(1).Backprice > Max_Favorite_Odds then
          Log(Me & "Conditions_Fulfilled", "favorite sucks odds " & Bet.Bet_Info.Price_Array(1).Backprice'Img & 
                   " needs to be < " & Max_Favorite_Odds'Img);
          Result := False;
          return;
        end if;
        declare
          Was_OK : Boolean := False;
        begin           
          for i in reverse 1 + 7 .. Max_Turns + 7 loop           
            if  Bet.Bot_Cfg.Min_Lay_Price < Bet.Bet_Info.Price_Array(i).Layprice and then
                Bet.Bet_Info.Price_Array(i).Layprice <= Bet.Bot_Cfg.Max_Lay_Price then
              Bet.Bet_Info.Selection_Id := Bet.Bet_Info.Price_Array(i).Selectionid; -- save the selection
              Was_Ok := True;
              exit; -- exit on first match - from back of list
            end if;
          end loop;
          if not Was_Ok then
            Bet.Bet_Info.Selection_Id := 0; --reset
          end if;
        end;  
    end case;
  end Conditions_Fulfilled;
  ------------------------------------------------------------------------------------------------------
  function History_Ok(Bet : Bet_Type) return Boolean is
    History : Bet_History_Array; -- array of 21 days
    use Sattmate_Calendar;
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Start_Date, End_Date, Now : Time_Type := Clock; 
    Sum : Float_8 := 0.0;
  begin
    T.Start;
      Sql.Prepare(Select_History,
         "select " & 
           "sum(profit), " & 
           "betplaced " &
         "from   " &
           "abets " &
         "where " &
           "betplaced >= :STARTOFDAY " & 
           "and betplaced <= :ENDOFDAY  " &
           "and status = 'SETTLED' " &
           "and betname = :BETNAME " &
         "group by " &
           "betplaced ");
           
      Sql.Set(Select_History, "BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      
      for i in History'range loop
      
        Start_Date := Now - (Integer_4(i),0,0,0,0);
        Start_Date.Hour        := 0;
        Start_Date.Minute      := 0;
        Start_Date.Second      := 0;
        Start_Date.MilliSecond := 0;
        
        End_Date := Now   - (Integer_4(i),0,0,0,0);
        Start_Date.Hour        := 23;
        Start_Date.Minute      := 59;
        Start_Date.Second      := 59;
        Start_Date.MilliSecond := 999;
        
        History(i).Date   := Start_Date;
        History(i).Weight := 1.0 / Float_8(i);
        
        Sql.Set_Timestamp(Select_History, "STARTOFDAY",Start_Date);
        Sql.Set_Timestamp(Select_History, "ENDOFDAY",End_Date);
        Sql.Open_Cursor(Select_History);     
        Sql.Fetch(Select_History, Eos);     
        Sql.Close_Cursor(Select_History);     
        if not Eos then
          Sql.Get(Select_History, 1, History(i).Profit);
        end if;
      end loop;     
    T.Commit;
    
    
    for i in History'range loop
      Sum := Sum + (History(i).Weight * History(i).Profit);
    end loop;     
    
    Log(Me & "History_Ok", "Sum: " & Sum'Img & " Ok= " & Boolean'Image(Sum >= 0.0));
    return Sum >= 0.0;
    
  end History_Ok;
  ------------------------------------------------------------------------------------------------------
--  function To_String(Bet : Bet_Type) return String;
--  procedure Make_Dry_Bet(Bet : in out Bet_Type) ;
--  procedure Make_Real_Bet(Bet : in out Bet_Type) ;
--------------------  BET_TYPE stop----------------------------------------  

  
  
end Bet_Handler;
