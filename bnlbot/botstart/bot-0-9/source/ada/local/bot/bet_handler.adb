with Bot_Types; use  Bot_Types;
with Bot_Config; use Bot_Config;

with Table_Abets;
with Sql;

package body Bet_Handler is

  Select_Runners,
  Select_Prices : Sql.Statement_Type;

  
  function Create (Market_Notification : in Bot_Messages.Market_Notification_Record) return Bet_Info_Record is
    Bet_Info : Bet_Info_Record ;
    type Eos_Type is (A_Event, A_Market, A_Runner, A_Price);
    Eos : array(Eos_Type'range) of Boolean := (others => True);
    Runner : Table_Arunners.Data_Type;
    Price  : Table_Aprices.Data_Type;    
    T : Sql.Transaction_Type;
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
        if Bot_Config.Animal /= Horse then
           Bad_Data with "7 is not :" &  Bot_Config.Animal'Img;
        end if;
      when 4339 => -- hounds
        if Bot_Config.Animal /= Hound then
           Bad_Data with "4339 is not :" &  Bot_Config.Animal'Img;
        end if;
      when others => raise Bad_Data with "not supported eventtype:" & Bet_Info.Event.Eventtypeid'Img; 
    end case;

    declare -- see if we can make a bet now
      Bet : Bet_Type := Create(Bet_Info, Bot_Config);
    begin
      Log(Me & "Try_Make_New_Bet", Bet.To_String);
      if Bet.Conditions_Fullfilled then
        Bet.Make_Dry_Bet;
        if Bet.Enabled then
          if Bet.History_Ok then
            Bet.Make_Real_Bet;
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

  function Create (Bet_Info : Bet_Info_Record; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type is
    Tmp : Bet_Type ;
  begin
    Tmp.Bet_Info := Bet_Info;
    Tmp.Bot_Cfg := Bot_Cfg;
    if General_Routines.Positions( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "lay") > 0 then 
      Tmp.This_Bet_Type := Lay;
    elsif General_Routines.Positions( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "back") > 0 then 
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

  
  function Conditions_Fulfilled(Bet : Bet_Type) return Boolean;
  function History_Ok(Bet : Bet_Type) return Boolean;
  function To_String(Bet : Bet_Type) return String;
  procedure Make_Dry_Bet(Bet : in out Bet_Type) ;
  procedure Make_Real_Bet(Bet : in out Bet_Type) ;
--------------------  BET_TYPE stop----------------------------------------  

  
  
end Bet_Handler;
