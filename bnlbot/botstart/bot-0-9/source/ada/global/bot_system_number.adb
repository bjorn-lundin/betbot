
with Sql;
with Log_Handler;

package body Bot_System_Number is

  Object : constant String := "Bot_System_Number";

  Select_Table_Statements  : array (System_Number_Type_Type'First..System_Number_Type_Type'Last)
                             of Sql. Statement_Type;

  Get_Number               : array (System_Number_Type_Type'First..System_Number_Type_Type'Last)
                             of Sql.Statement_Type;

--------------------------------------------------------------------------------

  function Is_Number_Taken(System_Number_Type : in System_Number_Type_Type;
                           Number : in Integer_4) return Boolean is

    End_Of_Set      : Boolean := False;
  begin
    case System_Number_Type is
      when Betid       => Sql.Prepare(Select_Table_Statements(System_Number_Type),
                                       "select BETID from BETS " &
                                       "where BETID = :NUM");
    end case;
    Sql.Set(Select_Table_Statements(System_Number_Type), "NUM", Number);
    Sql.Open_Cursor(Select_Table_Statements(System_Number_Type));
    Sql.Fetch(Select_Table_Statements(System_Number_Type), End_Of_Set);
    Sql.Close_Cursor(Select_Table_Statements(System_Number_Type));
    return not End_Of_Set;
  end Is_Number_Taken;

--------------------------------------------------------------------------------

  function New_Number (System_Number_Type : in System_Number_Type_Type) return Integer_4 is

    No_More_System_Numbers : exception;

    End_Of_Set      : Boolean := False;
    Is_Number_Found : Boolean := False;
    Max_Tries       : constant Integer_4 := 99999;
    No_Of_Tries     : Integer_4 := 0;
    Number          : Integer_4 := 0;
    Service         : constant string := "New_Number";
    Transaction     : Sql.Transaction_Type;

  begin
    Sql.Start_Read_Write_Transaction(Transaction);

    case Sql.Database is
      when Sql.Oracle =>
        case System_Number_Type is
          when Betid =>
            Sql.Prepare(Get_Number(System_Number_Type),
                    "select BETID_SEQUENCE.NEXTVAL from DUAL");
        end case;
      when Sql.PostgreSQL =>
        case System_Number_Type is
          when Betid =>
            Sql.Prepare(Get_Number(System_Number_Type),
                    "select nextval('BET_ID_SERIAL')");
        end case;
      when others => raise Constraint_Error with "Unsupported database";
    end case;


    while not Is_Number_Found and No_Of_Tries < Max_Tries loop
      Sql.Open_Cursor(Get_Number(System_Number_Type));
      Sql.Fetch(Get_Number(System_Number_Type), End_Of_Set);
      Sql.Close_Cursor(Get_Number(System_Number_Type));
      if End_Of_Set then
        Sql.Rollback(Transaction);
        Log_handler.Put(1, Object & '.' & Service, "End_Of_Set when getting new number");
        raise No_More_System_Numbers;
      else
        Sql.Get(Get_Number(System_Number_Type), "NEXTVAL", Number);
        No_Of_Tries := No_Of_Tries + 1;
        Is_Number_Found := not Is_Number_Taken(System_Number_Type, Number);
      end if;
    end loop;

    if not Is_Number_Found then
      Log_Handler.Put(1, Object & '.' & Service, "All system numbers taken for type " &
                                              System_Number_Type_Type'Image(System_Number_Type));
      raise No_More_System_Numbers;
    end if;

    Sql.Commit(Transaction);
    return Number;
  end New_Number;

end Bot_System_Number;
