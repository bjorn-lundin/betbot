
with Sql;
with Logging;

package body Bot_System_Number is

  Object : constant String := "Bot_System_Number.";
  Select_Table_Statements  : array(System_Number_Type_Type'range) of Sql.Statement_Type;
  Get_Number               : array(System_Number_Type_Type'range) of Sql.Statement_Type;

--------------------------------------------------------------------------------
  function Is_Number_Taken(System_Number_Type : in System_Number_Type_Type;
                           Number : in Integer_4) return Boolean is

    End_Of_Set      : Boolean := False;
--    Service         : constant string := "Is_Number_Taken";
  begin
--    Logging.Log(Object & Service, "start");
    case System_Number_Type is
      when Betid    => Select_Table_Statements(System_Number_Type).Prepare("select BETID from ABETS where BETID = :NUM");      
      when Sampleid => Select_Table_Statements(System_Number_Type).Prepare("select SAMPLEID from APRICESFINISH2 where SAMPLEID = :NUM");      
    end case;
    
    Select_Table_Statements(System_Number_Type).Set("NUM", Number);
    Select_Table_Statements(System_Number_Type).Open_Cursor;
    Select_Table_Statements(System_Number_Type).Fetch(End_Of_Set);
    Select_Table_Statements(System_Number_Type).Close_Cursor;
--    Logging.Log( Object & Service, "stop");
    return not End_Of_Set;
  end Is_Number_Taken;

--------------------------------------------------------------------------------

  function New_Number (System_Number_Type : in System_Number_Type_Type) return Integer_4 is
    No_More_System_Numbers : exception;
    End_Of_Set      : Boolean := False;
    Is_Number_Found : Boolean := False;
    Max_Tries       : constant Integer_4 := 99_999;
    No_Of_Tries     : Integer_4 := 0;
    Number          : Integer_4 := 0;
    Service         : constant string := "New_Number";
    Transaction     : Sql.Transaction_Type;
  begin
--    Logging.Log( Object & Service, "start");
    Transaction.Start;
   
    case Sql.Database is
      when Sql.PostgreSQL =>
        Get_Number(System_Number_Type).Prepare("select nextval(:SERIAL)");
        case System_Number_Type is
          when Betid    => Get_Number(System_Number_Type).Set("SERIAL","BET_ID_SERIAL");
          when Sampleid => Get_Number(System_Number_Type).Set("SERIAL","SAMPLE_ID_SERIAL");
        end case;
    end case;

    while not Is_Number_Found and No_Of_Tries < Max_Tries loop
      Get_Number(System_Number_Type).Open_Cursor;
      Get_Number(System_Number_Type).Fetch( End_Of_Set);
      if End_Of_Set then
        Get_Number(System_Number_Type).Close_Cursor;
        Transaction.Rollback;
        raise No_More_System_Numbers;
      else
        Get_Number(System_Number_Type).Get("NEXTVAL", Number);
        Get_Number(System_Number_Type).Close_Cursor;
        No_Of_Tries := No_Of_Tries + 1;
        Is_Number_Found := not Is_Number_Taken(System_Number_Type, Number);       
      end if;
    end loop;

    if not Is_Number_Found then
      Logging.Log(Object & Service, "All system numbers taken for type " & System_Number_Type'Img);
      Transaction.Commit;
      raise No_More_System_Numbers;
    end if;

    Transaction.Commit;
--    Logging.Log( Object & Service, "stop");
    return Number;
  end New_Number;

end Bot_System_Number;
