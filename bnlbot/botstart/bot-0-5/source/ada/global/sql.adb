with Ada.Text_Io;           use Ada.Text_Io;
with General_Routines;
pragma Elaborate_All (General_Routines);
with Ada.Characters.Handling;
with Ada.Exceptions ;
with Unchecked_Deallocation;
with Ada.Strings.Fixed;


--with PGAda_Unicode;

package body Sql is


   Global_Statement_Index_Counter : Natural := 0;
   Global_Connection              : Connection_Type;  -- the default connection;
   Global_Transaction             : Transaction_Type ;  -- the only REAL allowed transaction;

   Global_Debug_Level             : constant Integer := 0;
   Global_Indent_Level            : Integer := 0;
   Global_Indent_Step             : Integer := 2;
   Global_Transaction_Identity    : Transaction_Identity_Type;


   type Open_Statement_Type is record
      Statement_Pointer : Private_Statement_Type_Ptr;
   end record;

   package Open_Cursors is new Simple_List_Class (Open_Statement_Type);

   Global_Open_Statement_List : Open_Cursors.List_Type := Open_Cursors.Create;
   Global_Open_Statement      : Open_Statement_Type;

   type Error_Type is (Error_Duplicate_Index, Error_No_Such_Object, Error_No_Such_Column);
   type Error_Array_Type is array (Error_Type'Range) of Boolean;

   ------------------------------------------------------------
   procedure Decrease_Global_Indent is
   begin
      Global_Indent_Level := Global_Indent_Level - Global_Indent_Step;
   end Decrease_Global_Indent;

   procedure Increase_Global_Indent is
   begin
      Global_Indent_Level := Global_Indent_Level + Global_Indent_Step;
   end Increase_Global_Indent;

   procedure Log (What : in String; Level : in Integer := 1) is
      function Indent return String is
         S : String (1 .. Global_Indent_Level) := (others => ' ');
      begin
         return S;
      end Indent;
   begin
      case Global_Debug_Level is
         when Integer'First .. 0 => null;
         when 1 .. Integer'Last  =>
            case Level is
               when 0 => null;
               when others => Put_Line (Indent & What);
            end case;
      end case;
   end Log;
   ------------------------------------------------------------
   function Make_Dollar_Variable (Idx : Natural ) return String is
   begin
      return General_Routines.Skip_All_Blanks (" $" & Natural'Image (Idx));
   end Make_Dollar_Variable ;
   ------------------------------------------
   procedure Free is new Unchecked_Deallocation (Private_Statement_Type, Private_Statement_Type_Ptr);

   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
   -- called by prepare. We dont get elaborate warnings now
   procedure Do_Initialize (Statement : in out Statement_Type) is
   begin
      if Statement.Private_Statement = null then
         Statement.Private_Statement := new Private_Statement_Type;
         Statement.Private_Statement.Do_Initialize;
      end if;
   end Do_Initialize;

   procedure Finalize (Statement : in out Statement_Type) is
   begin
      Free (Statement.Private_Statement);
   end Finalize;
   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++

   -- called by prepare. We dont get elaborate warnings now
   --   procedure Initialize (Private_Statement : in out Private_Statement_Type) is
   procedure Do_Initialize (Private_Statement : in out Private_Statement_Type) is
   begin
      Global_Statement_Index_Counter := Global_Statement_Index_Counter + 1;
      Private_Statement.Index                   := Global_Statement_Index_Counter;
      --    Log("Initialize Private_Statement_Type # " & Natural'Image(Private_Statement.Index));
      Ada.Strings.Fixed.Move ("S" & General_Routines.Trim (Integer'Image (Private_Statement.Index)), Private_Statement.Statement_Name);

      Private_Statement.Cursor_Name     := Private_Statement.Statement_Name;
      Private_Statement.Cursor_Name (1) := 'C';
   end Do_Initialize;

   procedure Finalize (Private_Statement : in out Private_Statement_Type) is
   begin
      Map.Release (Private_Statement.Parameter_Map);
   end Finalize;
   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++

   procedure Associate (Private_Statement : in out Private_Statement_Type;
                        Bind_Varible      : String;
                        Idx               : Natural) is
      Local_Map_Item : Parameter_Map_Type;
   begin
      Local_Map_Item := (
                         Index          => Idx,
                         Name           => To_Unbounded_String (Bind_Varible),
                         Value          => To_Unbounded_String (""),
                         Parameter_Type => Not_Set
                        );
      Log ("Associate : '" & Bind_Varible & " -> " & Natural'Image (Idx));
      Map.Insert_At_Tail (Private_Statement.Parameter_Map, Local_Map_Item);
   end	Associate;

   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++

   procedure Update_Map (Private_Statement      : in out Private_Statement_Type;
                         Bind_Varible           : in     String;
                         Value                  : in     String;
                         Parameter_Type         : in     Parameter_Type_Type) is
      Local_Map_Item : Parameter_Map_Type;
      Found, Eol     : Boolean := False;
   begin
      Map.Get_First (Private_Statement.Parameter_Map, Local_Map_Item, Eol);
      loop
         exit when Eol;
         if To_String (Local_Map_Item.Name) = Bind_Varible then
            Local_Map_Item.Value := To_Unbounded_String (Value);
            Local_Map_Item.Parameter_Type := Parameter_Type;
            Map.Update (Private_Statement.Parameter_Map, Local_Map_Item);
            Found := True;
         end if;
         Map.Get_Next (Private_Statement.Parameter_Map, Local_Map_Item, Eol);
      end loop;

      if not Found then
         Ada.Exceptions.Raise_Exception (No_Such_Parameter'Identity, Bind_Varible);
      end if;
   end Update_Map;
   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++

   procedure Check_Is_Prepared (Private_Statement : in out Private_Statement_Type) is
   begin
      if not Private_Statement.Is_Prepared then
         raise Sequence_Error;
      end if;
   end Check_Is_Prepared;
   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++

   procedure Local_Close_Cursor (Private_Statement : in out Private_Statement_Type) ;

   --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
   procedure Exchange_Binder_Variables (Private_Statement : in out Private_Statement_Type) is
      Index                          : Natural                       := 0;
      Orig_Stm                       : String                        := To_String (Private_Statement.Original_Statement);
      Cmd                            : String (1 .. Orig_Stm'Last + 1) := Orig_Stm & " ";
      Binder_Parameter_Position_Stop : Integer := 0;
      ------------------------------------------
   begin
      --    Private_Statement.PG_Prepared_Statement := To_String("");
      Log ("Exchange_Binder_Variables-start (Original_Statement) '" & Orig_Stm & "'");
      Command_Loop : for I in Cmd'Range loop
         if Cmd (I) = ':' then
            Index := Index + 1;
            Associate_Loop : for J in I + 1 .. Cmd'Last loop
               case Cmd (J) is
                  when ' ' | ')' | ',' =>
                     Private_Statement.Associate (Cmd (I + 1 .. J - 1), Index);
                     Append (Private_Statement.Pg_Prepared_Statement, Make_Dollar_Variable (Index) );
                     Binder_Parameter_Position_Stop := J;
                     exit Associate_Loop;
                     when others => null;
               end case;
            end loop Associate_Loop;
            --        Log("Binder_Parameter_Position_Stop :" & Integer'Image(Binder_Parameter_Position_Stop));
         else
            -- we skip the part replaced by eg $2
            -- ...      and XLOCID = :XLOCID and XLOCSIZ >= :XLOCSIZ turns to
            -- ...      and XLOCID = $2 and XLOCSIZ >= $3
            -- so skip (on first line  ^^^^^    and            ^^^^^
            -- by setting Binder_Parameter_Position_Stop to the char AFTER the bindword
            if I >= Binder_Parameter_Position_Stop then
               Append (Private_Statement.Pg_Prepared_Statement, Cmd (I));
            end if;
         end if;
      end loop Command_Loop;
      Private_Statement.Number_Parameters := Index;
      Private_Statement.Is_Prepared := True;
      Log ("Exchange_Binder_Variables-stop (PG_Prepared_Statement) '" & To_String (Private_Statement.Pg_Prepared_Statement) & "'");

   end Exchange_Binder_Variables;

   ------------------------------------------------------------
   procedure Fill_Data_In_Prepared_Statement (Private_Statement : in out Private_Statement_Type) is
      Local_Map_Item : Parameter_Map_Type;
      Eol            : Boolean := False;
      Tmp            : Unbounded_String := Private_Statement.Pg_Prepared_Statement;
      --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
      procedure Replace_Dollar_Place_Holder (S   : in out Unbounded_String;
                                             Lmi : in     Parameter_Map_Type) is
         Cmd        : String  := To_String (S);
         Start, Stop : Integer := 0;
         Look_For   : String  := Make_Dollar_Variable (Lmi.Index);
      begin
         Start := General_Routines.Position (Cmd, Look_For);
         if Start > Cmd'First - 1 then
            Stop := Start + Look_For'Length ;
            --        Log("Cmd(Cmd'First .. Start-1) " & Cmd(Cmd'First .. Start-1) );
            --        Log("LMI.Value                 " & To_String(LMI.Value));
            --        Log("Cmd(Stop .. Cmd'Last)     " & Cmd(Stop .. Cmd'Last) );
            case Lmi.Parameter_Type is
               when An_Integer | A_Float  =>
                  S := To_Unbounded_String (Cmd (Cmd'First .. Start - 1)) &
                    Lmi.Value &
                    To_Unbounded_String (Cmd (Stop .. Cmd'Last));
               when A_Character | A_Date | A_Time | A_Timestamp =>
                  S := To_Unbounded_String (Cmd (Cmd'First .. Start - 1) & "'") &
                    Lmi.Value &
                    To_Unbounded_String ("'" & Cmd (Stop .. Cmd'Last));
               when A_String   =>
                  declare
                     Trimmed_Value : String := General_Routines.Trim (To_String (Lmi.Value));
                  begin
                     S := To_Unbounded_String (
                                               Cmd (Cmd'First .. Start - 1) &
                                                 "" & Trimmed_Value & "" &
                                                 Cmd (Stop .. Cmd'Last));
                  end;
               when Null_Type =>
                  S := To_Unbounded_String (
                                            Cmd (Cmd'First .. Start - 1) &
                                              "null" &
                                              Cmd (Stop .. Cmd'Last));
               when Not_Set   => raise Sequence_Error;
            end case;
         else
            Log ("Fill_Data_In_Prepared_Statement.Replace_Dollar_Place_Holder Did not find '" & Look_For & "' in '" & Cmd & "'");
         end if;

      end Replace_Dollar_Place_Holder;
      --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
   begin
      if not Private_Statement.Is_Prepared then
         Log ("Fill_Data_In_Prepared_Statement. Was not prepared: '" & To_String (Tmp) & "'");
         raise Sequence_Error;
      end if;

      Log ("Fill_Data_In_Prepared_Statement.start: '" & To_String (Tmp) & "'");
      Map.Get_First (Private_Statement.Parameter_Map, Local_Map_Item, Eol);
      if not Eol then
         Replace_Dollar_Place_Holder (Tmp, Local_Map_Item);
         loop
            Map.Get_Next (Private_Statement.Parameter_Map, Local_Map_Item, Eol);
            exit when Eol;
            Replace_Dollar_Place_Holder (Tmp, Local_Map_Item);
         end loop;
      end if;
      Private_Statement.Prepared_Statement := Tmp;
      Log ("Fill_Data_In_Prepared_Statement.stop: '" & To_String (Tmp) & "'");
   end Fill_Data_In_Prepared_Statement;





   ------------------------------------------------------------
   -- start local procs
   ------------------------------------------------------------


   ------------------------------------------------------------


   ------------------------------------------------------------

   function Get_New_Transaction return Transaction_Identity_Type is
   begin
      Global_Transaction_Identity := Transaction_Identity_Type'Succ (Global_Transaction_Identity);
      return Global_Transaction_Identity;
   end Get_New_Transaction;

   ------------------------------------------------------------

   procedure Print_Errors (Myunit   : in String;
                           Mystatus : in Exec_Status_Type) is
   begin
      if ((Mystatus /= Command_Ok) and
            (Mystatus /= Tuples_Ok)) then
         Put_Line (Standard_Error, Myunit);
         Put_Line (Standard_Error, Error_Message (Global_Connection));
         Put_Line (Standard_Error, Exec_Status_Type'Image (Mystatus));
      end if;
   end Print_Errors;

   ------------------------------------------------------------

   function Pgerror (Local_Status : Exec_Status_Type) return Boolean is
      Failure : Boolean := True;
   begin
      Failure := ((Local_Status /= Command_Ok) and (Local_Status /= Tuples_Ok));
      if Failure then
         Log ("PGerror: " & Exec_Status_Type'Image (Local_Status));
      end if;
      return Failure;
   end Pgerror;

   --------------------------------------------------------------------------------

   function Convert_To_Time (Mytime : String) return Sattmate_Calendar.Time_Type is
      Local_Time : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   begin -- '11:22:32'
      Local_Time.Hour   := Sattmate_Calendar.Hour_Type'Value (Mytime (1 .. 2));
      Local_Time.Minute := Sattmate_Calendar.Minute_Type'Value (Mytime (4 .. 5));
      Local_Time.Second := Sattmate_Calendar.Second_Type'Value (Mytime (7 .. 8));
      return Local_Time;
   exception
      when Constraint_Error =>
         Put_Line ("Failed to convert : '" & Mytime & "' to a time");
         raise Conversion_Error;
   end Convert_To_Time;

   --------------------------------------------------------------------------------

   function Convert_To_Date (Mydate : String) return Sattmate_Calendar.Time_Type is
      Local_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   begin  -- '2002-01-06'
      Local_Date.Year  := Sattmate_Calendar.Year_Type'Value (Mydate (1 .. 4));
      Local_Date.Month := Sattmate_Calendar.Month_Type'Value (Mydate (6 .. 7));
      Local_Date.Day   := Sattmate_Calendar.Day_Type'Value (Mydate (9 .. 10));
      return Local_Date;
   exception
      when Constraint_Error =>
         Put_Line ("Failed to convert : '" & Mydate & "' to a date");
         raise Conversion_Error;
   end Convert_To_Date;

   ------------------------------------------------------------
   function Convert_To_Timestamp (Mytimestamp : String) return Sattmate_Calendar.Time_Type is
      Local_Timestamp : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   begin -- '2002-01-06 11:22:32.123' or
      -- '2002-01-06 11:22:32.1' or
      -- '2002-01-06 11:22:32.1' or
      -- '2002-01-06 11:22:32'
      Local_Timestamp.Year        := Sattmate_Calendar.Year_Type'Value (Mytimestamp (1 .. 4));
      Local_Timestamp.Month       := Sattmate_Calendar.Month_Type'Value (Mytimestamp (6 .. 7));
      Local_Timestamp.Day         := Sattmate_Calendar.Day_Type'Value (Mytimestamp (9 .. 10));
      Local_Timestamp.Hour        := Sattmate_Calendar.Hour_Type'Value (Mytimestamp (12 .. 13));
      Local_Timestamp.Minute      := Sattmate_Calendar.Minute_Type'Value (Mytimestamp (15 .. 16));
      Local_Timestamp.Second      := Sattmate_Calendar.Second_Type'Value (Mytimestamp (18 .. 19));
      Local_Timestamp.Millisecond := 0;
      if Mytimestamp'Length = 21 then -- ms like '.1'
         Local_Timestamp.Millisecond := Sattmate_Calendar.Millisecond_Type'Value (Mytimestamp (21 .. 21));
      elsif Mytimestamp'Length = 22 then -- ms like '.14'
         Local_Timestamp.Millisecond := Sattmate_Calendar.Millisecond_Type'Value (Mytimestamp (21 .. 22));
      elsif Mytimestamp'Length = 23 then -- ms like '.143'
         Local_Timestamp.Millisecond := Sattmate_Calendar.Millisecond_Type'Value (Mytimestamp (21 .. 23));
      end if;
      return Local_Timestamp;
   exception
      when Constraint_Error =>
         Put_Line ("Failed to convert : '" & Mytimestamp & "' to a timestamp");
         raise Conversion_Error;
   end Convert_To_Timestamp;

   ------------------------------------------------------------


   -- end local procs
   ------------------------------------------------------------

   ------------------------------------------------------------
   -- start connection related proces
   --------------------------------------------------------------

   procedure Connect (Host       : in String  := "";
                      Port       : in Natural := 0;
                      Options    : in String  := "";
                      Tty        : in String  := "";
                      Db_Name    : in String  := "";
                      Login      : in String := "";
                      Password   : in String := "")     is
      Local_Status : Connection_Status_Type;
   begin
      Set_Db_Login (Global_Connection,
                    Host      => Host,
                    Port      => Port,
                    Options   => Options,
                    Tty       => Tty,
                    Db_Name   => Db_Name,
                    Login     => Login,
                    Password  => Password);

      Local_Status := Status (Global_Connection);
      case Local_Status is
         when Connection_Ok =>
            Global_Connection.Set_Connected (True);
            Set_Transaction_Isolation_Level (Read_Commited, Session);
            --      declare
            --        Enc : String := Global_Connection.Database_Encoding;
            begin
               Global_Connection.Set_Encoding (Latin_1);
               Global_Connection.Set_Client_Encoding ("LATIN1");
               --          if Enc = "UTF8" then
            end;

         when Connection_Bad =>
            Global_Connection.Set_Connected (False);
            Put_Line ("Connect : db_name,login,password ->: '" & Db_Name & "', '" & Login & "', '" & Password & "'");
            Put_Line (Error_Message (Global_Connection));
            raise Not_Connected with "Sql.Connect: Not_Connected" ;
      end case;
   end Connect;

   ---------------------------------------------------------------

   procedure Open_Oracle_Session (User : String; Password : String) is
   --    pragma Warnings(Off,User);
   --    pragma Warnings(Off,Password);
   begin
      Connect (Db_Name => "sattmate", Login => User, Password => Password);
   end Open_Oracle_Session;

   ---------------------------------------------------------------

   procedure Open_Odbc_Session (D1 : String; D2 : String; D3 : String) is
   --    pragma Warnings(Off,d1);
   --    pragma Warnings(Off,d2);
   --    pragma Warnings(Off,d3);
   begin
      Connect (Db_Name => D1, Login => D2, Password => D3);
   end Open_Odbc_Session;

   --------------------------------------------------------------

   function Transaction_In_Progress return Boolean ;


   procedure Close_Session is
   begin
      if Is_Session_Open then
         if Transaction_In_Progress then
            --reset transactions
            begin
               Rollback (Global_Transaction);
            exception
               when Transaction_Error => null; --rollback what we did not start...
            end;
            Global_Transaction.Counter := Transaction_Identity_Type'First;
         end if;
         Global_Statement_Index_Counter := 0;
         Global_Connection.Finish;
         Global_Connection.Set_Connected (False);
         Global_Transaction.Status := None;
      end if;
      Log ("Session closed");
   end Close_Session;

   --------------------------------------------------------------

   function Database return Database_Type is
   begin
      return Postgresql;
   end Database;


   ----------------------------------------------------------------
   function Is_Session_Open return Boolean is
   begin
      return Global_Connection.Get_Connected;
   end Is_Session_Open;

   --------------------------------------------------------------
   -- end connection related procs
   --------------------------------------------------------------

   --------------------------------------------------------------
   -- start transaction handling procs
   --------------------------------------------------------------
   function Transaction_In_Progress return Boolean is
   begin
      return Global_Transaction.Counter > Transaction_Identity_Type'First;
   end Transaction_In_Progress;

   --------------------------------------------------------------
   procedure Check_Is_Connected is
   begin
      if not Global_Connection.Get_Connected then
         raise Not_Connected;
      end if;
   end Check_Is_Connected;

   ------------------------------------------------------------

   procedure Check_Transaction_In_Progress is
   begin
      if not Transaction_In_Progress then
         raise No_Transaction;
      end if;
   end Check_Transaction_In_Progress;

   ------------------------------------------------------------


   procedure Start_Transaction (T  : in out Transaction_Type;
                                Ts : in Transaction_Status_Type) is
      Dml_Status  : Exec_Status_Type;
      Dml_Result  : Result_Type;
   begin
      Increase_Global_Indent;
      Check_Is_Connected;
      -- check if transaction already in progress
      case Global_Transaction.Status is
         when None =>
            T.Counter := Get_New_Transaction;
            Global_Transaction.Counter := T.Counter;
         when Read_Only =>
            if Ts = Read_Write then
               Put_Line ("Start_Transaction: Transaction_Error");
               raise Transaction_Error;
            end if;
            T.Counter := Get_New_Transaction;
            return;  -- do nothing

         when Read_Write =>
            if Ts = Read_Only then
               Put_Line ("Start_Transaction: Transaction_Error");
               raise Transaction_Error;
            end if;
            T.Counter := Get_New_Transaction;
            return;  -- do nothing
      end case;

      Log ("begin");
      Global_Connection.Exec ("begin", Dml_Result);
      Dml_Status := Result_Status (Dml_Result);
      Clear (Dml_Result);
      if Pgerror (Dml_Status) then
         Print_Errors ("Start_Read_Only_Transaction", Dml_Status);
         raise Postgresql_Error;
      end if;

      Global_Transaction.Status := Ts;
   end Start_Transaction;

   ---------------------------------------------------------------

   procedure Start_Read_Only_Transaction (T : in out Transaction_Type) is
   begin
      Start_Transaction (T, Read_Only);
   end Start_Read_Only_Transaction;

   ---------------------------------------------------------------

   procedure Start_Read_Write_Transaction (T : in out Transaction_Type) is
   begin
      Start_Transaction (T, Read_Write);
   end Start_Read_Write_Transaction;

   ------------------------------------------------------------

   procedure Commit (T : in Transaction_Type) is
      Dml_Status  : Exec_Status_Type;
      Dml_Result  : Result_Type;
   begin
      Check_Is_Connected;
      Check_Transaction_In_Progress;
      -- check if transaction already in progress
      case Global_Transaction.Status is
         when None =>
            Put_Line ("Commit: No_Transaction");
            raise No_Transaction;

         when Read_Only | Read_Write =>
            -- check for ownership
            if T.Counter /= Global_Transaction.Counter then
               -- not the owner, do nothing
               Log ("not the owner tries to commit");
               return;
            end if;
      end case;
      -- Finsh off those cursors that are not closed, by bad code
      while not Open_Cursors.Is_Empty (Global_Open_Statement_List) loop
         Open_Cursors.Remove_From_Head (Global_Open_Statement_List,
                                        Global_Open_Statement);
         Local_Close_Cursor (Global_Open_Statement.Statement_Pointer.all);
         --       Global_Open_Statement.Statement_Pointer.Empty_The_Map;
      end loop;

      Log ("commit");
      Global_Connection.Exec ("commit", Dml_Result);
      Dml_Status := Result_Status (Dml_Result);
      Clear (Dml_Result);

      if Pgerror (Dml_Status) then
         Print_Errors ("commit", Dml_Status);
         raise Postgresql_Error;
      end if;

      Global_Transaction.Counter := Transaction_Identity_Type'First;
      Global_Transaction.Status := None;
      Log ("the owner commits");
      Decrease_Global_Indent;
   end Commit;

   ------------------------------------------------------------

   procedure Rollback (T : in Transaction_Type) is
      Dml_Status  : Exec_Status_Type;
      Dml_Result  : Result_Type;
   begin
      Check_Is_Connected;
      Check_Transaction_In_Progress;

      case Global_Transaction.Status is
         when None =>
            Put_Line ("Rollback: No_Transaction");
            raise No_Transaction;

         when Read_Only | Read_Write =>
            -- check for ownership
            if T.Counter /= Global_Transaction.Counter then
               -- not the owner
               Put_Line ("not the owner tries to rollback");
               raise Transaction_Error;
               --          return;
            end if;
      end case;

      while not Open_Cursors.Is_Empty (Global_Open_Statement_List) loop
         Open_Cursors.Remove_From_Head (Global_Open_Statement_List,
                                        Global_Open_Statement);
         Local_Close_Cursor (Global_Open_Statement.Statement_Pointer.all);
         --       Global_Open_Statement.Statement_Pointer.Empty_The_Map;
      end loop;

      Log ("rollback");
      Global_Connection.Exec ("rollback", Dml_Result);
      Dml_Status := Result_Status (Dml_Result);
      Clear (Dml_Result);
      if Pgerror (Dml_Status) then
         Print_Errors ("rollback", Dml_Status);
         raise Postgresql_Error;
      end if;

      Global_Transaction.Counter := Transaction_Identity_Type'First;
      Global_Transaction.Status := None;
      Decrease_Global_Indent;
   end Rollback;

   --------------------------------------------------------------

   function Transaction_Status return Transaction_Status_Type is
   begin
      return Global_Transaction.Status;
   end Transaction_Status;

   --------------------------------------------------------------
   procedure Set_Transaction_Isolation_Level (Level : in Transaction_Isolation_Level_Type;
                                              Scope : in Transaction_Isolation_Level_Scope_Type) is
      Local_Transaction   : Transaction_Type;
      Transaction_Setting : array (Transaction_Isolation_Level_Type'Range,
                                   Transaction_Isolation_Level_Scope_Type'Range) of Statement_Type;
   begin
      Start_Read_Write_Transaction (Local_Transaction);
      case Level is
         when Read_Commited =>
            case Scope is
               when Transaction =>
                  Prepare (Transaction_Setting (Level, Scope), "SET TRANSACTION ISOLATION LEVEL READ COMMITTED");
               when Session =>
                  Prepare (Transaction_Setting (Level, Scope), "SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED");
            end case;
         when Serializable =>
            case Scope is
               when Transaction =>
                  Prepare (Transaction_Setting (Level, Scope), "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE");
               when Session =>
                  Prepare (Transaction_Setting (Level, Scope), "SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE");
            end case;
      end case;
      Execute (Transaction_Setting (Level, Scope));
      Commit (Local_Transaction);
   end Set_Transaction_Isolation_Level;


   --------------------------------------------------------------
   -- end transaction handling procs
   --------------------------------------------------------------


   --------------------------------------------------------------
   -- start public cursor handling procs
   --------------------------------------------------------------

   procedure Prepare (Private_Statement : in out Private_Statement_Type;
                      Command           : in String) is
      use Ada.Characters.Handling;
      Stm : String := General_Routines.Trim (To_Lower (Command));
   begin
      if not Private_Statement.Is_Prepared then
         Private_Statement.Do_Initialize; -- instead of using Initialize, and get warnings
         Log ("Prepare - First time Stm: '" & Stm & "'");
         if    Stm (1 .. 6) = "select" then
            Private_Statement.Type_Of_Statement := A_Select;
         elsif Stm (1 .. 6) = "insert" then
            Private_Statement.Type_Of_Statement := An_Insert;
         elsif Stm (1 .. 6) = "update" then
            Private_Statement.Type_Of_Statement := An_Update;
         elsif Stm (1 .. 6) = "delete" then
            Private_Statement.Type_Of_Statement := A_Delete;
         else
            Private_Statement.Type_Of_Statement := A_Ddl;
         end if;
         Private_Statement.Original_Statement := To_Unbounded_String (Command) ;
         Private_Statement.Exchange_Binder_Variables;
         Log ("Prepare - PGPrepared_stm: '" & To_String (Private_Statement.Pg_Prepared_Statement) & "'");
         --      declare
         --        use Interfaces.C, Interfaces.C.Strings;
         --        Types_Array    : Pgada.Thin.Int_Array_Type(1..3) := (0,0,0);
         --      begin
         --        Prepare(Connection    => Global_Connection.Connection,
         --                Statment_Name => Private_Statement.Statement_Name,
         --                Query         => To_String(Private_Statement.Prepared_Statement),
         --                Number_Params => Private_Statement.Number_Parameters,
         --                Param_Types   => Types_Array,
         --                Result        => DML_Result);
         --        Status := Result_Status(DML_Result);
         --        Clear(DML_Result);
         --        if PGerror(Status) then
         --          Print_Errors("Prepare",Status);--          raise PostgreSQL_Error;
         --        end if;
         --      end;
         --      Private_Statement.Is_Prepared := True;
      else
         Log ("Prepare - Already prepared Stm: '" & Stm & "'");
      end if;
   end Prepare;

   procedure Prepare (Statement : in out Statement_Type;
                      Command   : in String) is
   begin
      Statement.Do_Initialize;
      Prepare (Statement.Private_Statement.all, Command);
   end Prepare;
   ------------------------------------------------------------


   function Determine_Errors (Result : Result_Type; Stm_String : String) return Error_Array_Type is
   -- see http://www.postgresql.org/docs/8.3/interactive/errcodes-appendix.html
      Local_Array : Error_Array_Type := (others => False);
      Sql_State   : String := Error_Sql_State (Result);
      -----------------------------------------------------
      procedure Print_Diagnostics (Label, Content : String) is
      begin
         if Content'Length > 0 then
            Put_Line (Label & ": '" & Content & "'");
         end if;
      end Print_Diagnostics;
      -----------------------------------------------------
      procedure Print_All_Diagnostics is
      begin
         Print_Diagnostics ("Sql_State", Sql_State);
         Print_Diagnostics ("Severity", Error_Severity (Result));
         Print_Diagnostics ("Message Primary", Error_Message_Primary (Result));
         Print_Diagnostics ("Message Detail", Error_Message_Detail (Result));
         Print_Diagnostics ("Message Hint", Error_Message_Hint (Result));
         Print_Diagnostics ("Statement Position", Error_Statement_Position (Result));
         Print_Diagnostics ("Internal Position", Error_Internal_Position (Result));
         Print_Diagnostics ("Internal Query", Error_Internal_Query (Result));
         Print_Diagnostics ("Context", Error_Context (Result));
         -- Print_Diagnostics("Source File", Error_Source_File(Result));
         -- Print_Diagnostics("Source Line", Error_Source_Line(Result));
         -- Print_Diagnostics("Source Function", Error_Source_Function(Result));
         Print_Diagnostics ("Statement", Stm_String);

      end Print_All_Diagnostics;
   begin
      if Sql_State = "23505" then                    -- UNIQUE VIOLATION
         Local_Array (Error_Duplicate_Index) := True;
      elsif Sql_State = "42703" then                 --	UNDEFINED COLUMN
         Local_Array (Error_No_Such_Column) := True;
      elsif Sql_State = "42P01" then                 --	UNDEFINED TABLE
         Local_Array (Error_No_Such_Object) := True;
      else
         Print_All_Diagnostics;                       -- only print info on unknown errors
      end if;
      return Local_Array;
   end Determine_Errors;
   ---------------------------------------
   function Determine_Errors (Private_Statement : Private_Statement_Type) return Error_Array_Type is
      Ea : Error_Array_Type := Determine_Errors (Private_Statement.Result, To_String (Private_Statement.Prepared_Statement));
   begin
      --      for i in EA'range loop
      --        if EA(i) then
      --          Put_Line(To_String(Private_Statement.Prepared_Statement));
      --          exit;
      --        end if;
      --      end loop;
      return Ea;
   end Determine_Errors;
   --------------------------------------------------
   procedure Open_Cursor (Private_Statement : in out Private_Statement_Type) is
      Status           : Exec_Status_Type;
      Dml_Result       : Result_Type;
      Savepoint_Result : Result_Type;
   begin
      -- check for open database and prepared Statement too!!
      -- declare/open the cursor and execute the Statement
      Check_Is_Connected;
      Check_Transaction_In_Progress;

      if Private_Statement.Is_Ok_To_Close then
         Local_Close_Cursor (Private_Statement);
      end if;

      Private_Statement.Fill_Data_In_Prepared_Statement;

      Log ("SQL.OPEN_CURSOR: " & To_String (Private_Statement.Original_Statement));

      Global_Connection.Exec ("savepoint A_select", Savepoint_Result);
      Status := Result_Status (Savepoint_Result);
      if Pgerror (Status) then
         Print_Errors ("Open_Cursor savepoint a_select", Status);
         Clear (Savepoint_Result);
         raise Postgresql_Error;
      end if;

      declare
         Declare_String : String :=
                            "declare " & Private_Statement.Cursor_Name & " cursor without hold for " &
                            To_String (Private_Statement.Prepared_Statement);
      begin
         Global_Connection.Exec (Declare_String, Dml_Result);
         Log ("SQL.OPEN_CURSOR: " & Declare_String);
         Status := Result_Status (Dml_Result);
         if Pgerror (Status) then
            Print_Errors ("Open_Cursor", Status);
            declare
               Errors : Error_Array_Type := Determine_Errors (Dml_Result, Declare_String);
            begin
               Clear (Dml_Result);
               Global_Connection.Exec ("rollback to savepoint a_select", Savepoint_Result);
               Status := Result_Status (Savepoint_Result);
               if Pgerror (Status) then
                  Print_Errors ("Open_Cursor rollback to savepoint a_select", Status);
                  Clear (Savepoint_Result);
                  raise Postgresql_Error;
               end if;

               if    Errors (Error_Duplicate_Index) then
                  raise Duplicate_Index;
               elsif Errors (Error_No_Such_Object) then
                  raise No_Such_Object;
               elsif Errors (Error_No_Such_Column) then
                  raise No_Such_Column;
               end if;
            end;
            raise Postgresql_Error;
         end if;
      end;

      Global_Connection.Exec ("release savepoint a_select", Savepoint_Result);
      Status := Result_Status (Savepoint_Result);
      if Pgerror (Status) then
         Print_Errors ("Open_Cursor savepoint release a_select", Status);
         Clear (Savepoint_Result);
         raise Postgresql_Error;
      end if;

      Clear (Dml_Result);
   end Open_Cursor;
   --------------------------------------------
   procedure Open_Cursor (Statement : in Statement_Type) is
   begin
      Open_Cursor (Statement.Private_Statement.all);
      Open_Cursors.Insert_At_Tail (Global_Open_Statement_List,
                                   Open_Statement_Type'(Statement_Pointer => Statement.Private_Statement));
   end Open_Cursor;

   ------------------------------------------------------------

   procedure Fetch (Private_Statement  : in out Private_Statement_Type;
                    End_Of_Set         : out Boolean) is
      Dml_Status : Exec_Status_Type;
      Ntpl       : Natural := 0;
   begin
      Check_Is_Connected;
      Check_Transaction_In_Progress;
      Private_Statement.Check_Is_Prepared;

      if Private_Statement.Current_Row = Private_Statement.Number_Actually_Fetched then
         -- Ok first time, or we have already fetched
         --  Private_Statement.Number_Actually_Fetched rows.
         -- we need to get another Private_Statement.Number_To_Fetch rows into
         -- our result set
         declare
            Fetch_String : String :=
                             "fetch forward" & Natural'Image (Private_Statement.Number_To_Fetch) & " in " & Private_Statement.Cursor_Name;
         begin
            Log ("Fetch: " & Fetch_String);
            Global_Connection.Exec (Fetch_String, Private_Statement.Result);
         end;
         Dml_Status := Result_Status (Private_Statement.Result);
         Log ("Fetched from db");

         if Pgerror (Dml_Status) then
            Print_Errors ("Fetch", Dml_Status);
            raise Postgresql_Error;
         end if;
         --      Private_Statement.Result.Set_Encoding(Global_Connection.Get_Encoding);
         begin
            Ntpl := Rows_Affected (Private_Statement.Result);
         exception
            when Constraint_Error => Ntpl := 0;
         end;
         End_Of_Set := (Ntpl = 0);
         Private_Statement.Current_Row := 1;
         Private_Statement.Number_Actually_Fetched := Ntpl;
         Log ("Number_Actually_Fetched" & Natural'Image (Private_Statement.Number_Actually_Fetched));
      else
         -- just point to the next row in the cached resultset
         Private_Statement.Current_Row := Private_Statement.Current_Row + 1;
         End_Of_Set := False;
         Log ("Fetched from cached cursor");
      end if;
      Log ("current row is now" & Natural'Image (Private_Statement.Current_Row));
   end Fetch;

   procedure Fetch (Statement  : in Statement_Type;
                    End_Of_Set : out Boolean) is
   begin
      Fetch (Statement.Private_Statement.all, End_Of_Set);
   end Fetch;

   ----------------------------------------------------------

   procedure Local_Close_Cursor (Private_Statement : in out Private_Statement_Type) is
   -------------------------------------
      procedure Close_This_Cursor (Cursor_Name : in Name_Type) is
         Dml_Status  : Exec_Status_Type;
         Dml_Result  : Result_Type;
      begin
         declare
            Close_String : String := "close " & Cursor_Name;
         begin
            Global_Connection.Exec (Close_String,  Dml_Result);
            Log ("Close_This_Cursor -> " & Close_String);
         end;
         Dml_Status := Result_Status (Dml_Result);
         Clear (Dml_Result);
         if Pgerror (Dml_Status) then
            Print_Errors ("Close_This_Cursor", Dml_Status);
            raise Postgresql_Error;
         end if;
      end Close_This_Cursor;
      -------------------------------------
   begin
      if Private_Statement.Is_Ok_To_Close then
         Private_Statement.Result.Clear; --clear old result
         Close_This_Cursor (Private_Statement.Cursor_Name);
         Private_Statement.Is_Ok_To_Close := False;
         Private_Statement.Current_Row := 0;
         Private_Statement.Number_Actually_Fetched := 0;
      end if;
   end Local_Close_Cursor;

   ------------------------------------------------------------

   procedure Close_Cursor (Private_Statement : in out Private_Statement_Type) is
   begin
      -- remove cursor and association?
      Check_Is_Connected;
      Check_Transaction_In_Progress;
      Private_Statement.Is_Ok_To_Close := True;
      Log ("Close_cursor " & "Marked OK to Close " & Private_Statement.Cursor_Name);
   end Close_Cursor;

   procedure Close_Cursor (Statement : in Statement_Type) is
   begin
      Close_Cursor (Statement.Private_Statement.all);
   end Close_Cursor;

   -------------------------------------------------------------

   procedure Execute (Private_Statement           : in out Private_Statement_Type;
                      No_Of_Affected_Rows         : out Natural) is
      Status : Exec_Status_Type;
      type Savepoint_Handling_Type is (Insert, Remove, Rollback_To);

      -------------------------------------------------------------------------

      -------------------------------------------------------------------------
      procedure Handle_Savepoint (How             : in Savepoint_Handling_Type;
                                  P_Stm           : in out Private_Statement_Type;
                                  Clear_Statement : in Boolean := False) is
         Dml_Status  : Exec_Status_Type;
         Dml_Result  : Result_Type;
      begin
         if Clear_Statement then
            Clear (P_Stm.Result);
         end if;
         case How is
            when Insert =>
               Global_Connection.Exec ("savepoint " &
                                         Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Result);
            when Remove =>
               Global_Connection.Exec ("release savepoint " &
                                         Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Result);
            when Rollback_To =>
               Global_Connection.Exec ("rollback to savepoint " &
                                         Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Result);
         end case;
         Dml_Status := Result_Status (Dml_Result);
         Clear (Dml_Result);

         if Pgerror (Dml_Status) then
            case How is
               when Insert =>
                  Print_Errors ("savepoint " &
                                  Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Status);
               when Remove =>
                  Print_Errors ("release savepoint " &
                                  Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Status);

               when Rollback_To =>
                  Print_Errors ("rollback to savepoint " &
                                  Statement_Type_Type'Image (P_Stm.Type_Of_Statement), Dml_Status);
            end case;
            raise Postgresql_Error;
         end if;
      end Handle_Savepoint;
      -------------------------------------------------------------------------
      procedure Handle_Error (P_Stm : in out Private_Statement_Type; Clear_Statement : in Boolean) is
         Errors      : Error_Array_Type  := Determine_Errors (P_Stm);
      begin
         --      Log("Handle_Error -> '" & Err_String & "'" );
         if Clear_Statement then
            Clear (P_Stm.Result);
         end if;
         -- rollback to the savepoint
         Handle_Savepoint (How => Rollback_To, P_Stm => P_Stm);

         -- remove the savepoint
         Handle_Savepoint (How => Remove, P_Stm => P_Stm);

         if    Errors (Error_Duplicate_Index) then
            raise Duplicate_Index;
         elsif Errors (Error_No_Such_Object) then
            raise No_Such_Object;
         elsif Errors (Error_No_Such_Column) then
            raise No_Such_Column;
         else
            Put_Line ("");
            Put_Line ("---------------------------------------------------------");
            Put_Line ("see http://www.postgresql.org/docs/8.3/interactive/errcodes-appendix.html");
            Put_Line ("---------------------------------------------------------");
            Print_Errors (To_String (P_Stm.Prepared_Statement), Status);
            Put_Line ("sql ->: '" & To_String (P_Stm.Prepared_Statement) & "'");
            Put_Line ("---------------------------------------------------------");
            Put_Line ("");
            raise Postgresql_Error;
         end if;
      end Handle_Error;
      ----------------------------------------------------------------------------
   begin
      -- check for open database and prepared Statement too!!
      -- declare/open the cursor and execute the Statement
      Log ("Execute start");
      Check_Is_Connected;
      Check_Transaction_In_Progress;

      if Transaction_Status /= Read_Write then
         Put_Line ("Exceute: current transaction type is: " &
                     Transaction_Status_Type'Image (Transaction_Status));
         raise Sequence_Error;
      end if;

      -- extract cursor.Query to its Bindvarables here!
      -- raise sequence error if not all are bound!
      Private_Statement.Fill_Data_In_Prepared_Statement;

      Log ("Original_Statement    '" & To_String (Private_Statement.Original_Statement));
      Log ("PG_Prepared_Statement '" & To_String (Private_Statement.Pg_Prepared_Statement));
      Log ("Prepared_Statement    '" & To_String (Private_Statement.Prepared_Statement));

      Log ("Execute will run '" & To_String (Private_Statement.Prepared_Statement) & "'");
      Log ("Escaped string is'" & Escape (Global_Connection, To_String (Private_Statement.Prepared_Statement) & "'"));

      case Private_Statement.Type_Of_Statement is
         when A_Select  => raise Sequence_Error;
         when An_Insert =>
            Log ("Execute.Insert start");
            No_Of_Affected_Rows := 1;

            Handle_Savepoint (How => Insert, P_Stm => Private_Statement);
            Global_Connection.Exec (To_String (Private_Statement.Prepared_Statement),
                                    Private_Statement.Result);
            Status := Result_Status (Private_Statement.Result);

            if Pgerror (Status) then
               Handle_Error (P_Stm => Private_Statement, Clear_Statement => True);
            end if;
            Private_Statement.Result.Clear;
            Handle_Savepoint (How => Remove, P_Stm => Private_Statement);

            Log ("Execute.Insert end");

         when A_Delete  =>
            Log ("Execute.Delete start");
            No_Of_Affected_Rows := Natural'Last;

            Handle_Savepoint (How => Insert, P_Stm => Private_Statement);

            Global_Connection.Exec (To_String (Private_Statement.Prepared_Statement),
                                    Private_Statement.Result);
            Status := Result_Status (Private_Statement.Result);

            if Pgerror (Status) then
               Handle_Error (P_Stm => Private_Statement, Clear_Statement => True);
            end if;

            No_Of_Affected_Rows := Rows_Affected (Private_Statement.Result);
            Private_Statement.Result.Clear;

            Handle_Savepoint (How => Remove, P_Stm => Private_Statement);

            Log ("Execute.Delete end");

         when An_Update =>
            Log ("Execute.Update start");
            No_Of_Affected_Rows := Natural'Last;
            Handle_Savepoint (How => Insert, P_Stm => Private_Statement);

            Global_Connection.Exec (To_String (Private_Statement.Prepared_Statement),
                                    Private_Statement.Result);
            Status := Result_Status (Private_Statement.Result);

            if Pgerror (Status) then
               Handle_Error (P_Stm => Private_Statement, Clear_Statement => True);
            end if;

            No_Of_Affected_Rows := Rows_Affected (Private_Statement.Result);
            Private_Statement.Result.Clear;

            Handle_Savepoint (How => Remove, P_Stm => Private_Statement);
            Log ("Execute.Update end");

         when A_Ddl     =>
            Log ("Execute.DDL start");
            Handle_Savepoint (How => Insert, P_Stm => Private_Statement);
            No_Of_Affected_Rows := Natural'Last;
            Global_Connection.Exec (To_String (Private_Statement.Prepared_Statement),
                                    Private_Statement.Result);
            Status := Result_Status (Private_Statement.Result);
            if Pgerror (Status) then
               Handle_Error (P_Stm => Private_Statement, Clear_Statement => True);
            end if;
            Private_Statement.Result.Clear;
            Handle_Savepoint (How => Remove, P_Stm => Private_Statement);
            Log ("Execute.DDL end");
      end case;
      Log ("Execute end");
   end Execute;
   -----------------------------------------------------------
   procedure Execute (Statement           : in Statement_Type;
                      No_Of_Affected_Rows : out Natural) is
   begin
      Execute (Statement.Private_Statement.all, No_Of_Affected_Rows);
   end Execute;
   ------------------------------------------------------------

   procedure Execute (Statement : in  Statement_Type) is
      Rows : Natural := 0;
   begin
      Execute (Statement.Private_Statement.all, Rows);
      if Rows = 0 then
         raise No_Such_Row;
      end if;
   end Execute;

   ------------------------------------------------------------

   function Is_Null (Statement : Statement_Type;
                     Parameter : Positive) return Boolean is
   begin
      return Pgada.Database.Is_Null (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
   end Is_Null;

   ------------------------------------------------------------

   function Is_Null (Statement : Statement_Type;
                     Parameter : String) return Boolean is
   begin
      return Is_Null (Statement, Positive (Field_Index (Statement.Private_Statement.Result, Parameter)));
   end Is_Null;

   --------------------------------------------------------------
   -- end cursor handling procs
   ------------------------------------------------------------

   --------------------------------------------------------------
   -- start Set handling procs
   ------------------------------------------------------------

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in String) is
      Local_Value : constant String := Escape (Global_Connection, Value);
   begin
      Statement.Private_Statement.Update_Map (Parameter, Local_Value, A_String);
   end Set;

   ------------------------------------------------------------

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Integer_4) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, General_Routines.Trim (Integer_4'Image (Value)), An_Integer);
   end Set;

   ------------------------------------------------------------
   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Integer_8) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, General_Routines.Trim (Integer_8'Image (Value)), An_Integer);
   end Set;

   ------------------------------------------------------------

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Float_8) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, General_Routines.Trim (Float'Image (Float (Value))), A_Float);
   end Set;

   ---------------------------------------------------------

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Character) is
      Local_Value : String (1 .. 1) := (others => ' ');
   begin
      Local_Value (1) := Value;
      Statement.Private_Statement.Update_Map (Parameter, Local_Value, A_Character);
   end Set;
   -------------------------------------------------------------

   procedure Set_Date (Statement : in out Statement_Type;
                       Parameter : in String;
                       Value     : in Sattmate_Calendar.Time_Type) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, Sattmate_Calendar.String_Date (Value), A_Date);
   end Set_Date;
   ------------------------------------------------------------

   procedure Set_Time (Statement : in out Statement_Type;
                       Parameter : in String;
                       Value     : in Sattmate_Calendar.Time_Type) is
      Local_Time_1 : constant String := Sattmate_Calendar.String_Time (Value);
      Local_Time_2 : String (1 .. 6) := (others => ' ');
   begin
      Local_Time_2 (1 .. 2) := Local_Time_1 (1 .. 2);  -- remove ':' from time
      Local_Time_2 (3 .. 4) := Local_Time_1 (4 .. 5);
      Local_Time_2 (5 .. 6) := Local_Time_1 (7 .. 8);

      Statement.Private_Statement.Update_Map (Parameter, Local_Time_2, A_Time);

   end Set_Time;
   ------------------------------------------------------------
   procedure Set_Timestamp (Statement : in out Statement_Type;
                            Parameter : in String;
                            Value     : in Sattmate_Calendar.Time_Type) is
      Local_Time_1 : constant String := Sattmate_Calendar.String_Date_And_Time (Value, Milliseconds => True);
      --    Local_Time_2 : String(1..6) := (others => ' ');
   begin -- '2002-01-06 11:22:32.123'
      --    Local_Time_2(1..2) := Local_Time_1(1..2);  -- remove ':' from time
      --    Local_Time_2(3..4) := Local_Time_1(4..5);
      --    Local_Time_2(5..6) := Local_Time_1(7..8);

      --    Statement.Private_Statement.Update_Map(Parameter, Local_Time_2, A_Time);
      Statement.Private_Statement.Update_Map (Parameter, Local_Time_1, A_Timestamp);

   end Set_Timestamp;
   ------------------------------------------------------------


   procedure Set_Null (Statement : in out Statement_Type;
                       Parameter : String) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, "NULL", Null_Type);
   end Set_Null;

   ------------------------------------------------------------

   procedure Set_Null_Date (Statement : in out Statement_Type;
                            Parameter : String) is
   begin
      Statement.Private_Statement.Update_Map (Parameter, "NULL", Null_Type);
   end Set_Null_Date;

   --------------------------------------------------------------
   -- end Set handling procs
   ------------------------------------------------------------

   --------------------------------------------------------------
   -- start Get handling procs
   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Integer_4) is
   begin
      declare
         Local_String : constant String := Get_Value (
                                                      Statement.Private_Statement.Result,
                                                      Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                                      Field_Index_Type (Parameter));
      begin
         --      Put_Line("local_String: '" & Local_String & "'");
         if Local_String'Length = 0 then
            Value := 0;
         else
            Value := Integer_4'Value (Local_String);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get;

   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Integer_4) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get (Statement, Positive (Field_Number), Value);
   end Get;

   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Integer_8) is
   begin
      declare
         Local_String : constant String := Get_Value (
                                                      Statement.Private_Statement.Result,
                                                      Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                                      Field_Index_Type (Parameter));
      begin
         --      Put_Line("local_String: '" & Local_String & "'");
         if Local_String'Length = 0 then
            Value := 0;
         else
            Value := Integer_8'Value (Local_String);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get;

   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Integer_8) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get (Statement, Positive (Field_Number), Value);
   end Get;

   ------------------------------------------------------------


   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out String) is
      Local_String : constant String :=
                       Get_Value (Statement.Private_Statement.Result,
                                  Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                  Field_Index_Type (Parameter));
   begin
      if Local_String'Length = 0 then
         Value := (others => ' ');
      else
         Value (1 .. Local_String'Length) := Local_String;
      end if;
   exception
      when Constraint_Error =>
         ada.text_io.put_line	("local_string: '" & local_string & "'");
         Put_Line ("No such column: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get;

   -----------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out String) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get (Statement, Positive (Field_Number), Value);
   end Get;

   ----------------------------------------------------------


   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Character) is
   begin
      declare
         Local_String : constant String :=
                          Get_Value (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
      begin
         if Local_String'Length = 0 then
            Value := ' ';
         else
            Value := Local_String (1);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get;

   ----------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Character) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get (Statement, Positive (Field_Number), Value);
   end Get;

   ----------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Float_8) is
   begin
      declare
         Local_String : constant String :=
                          Get_Value (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
      begin
         if Local_String'Length = 0 then
            Value := 0.0;
         else
            Value := Float_8 (Float'Value (Local_String));
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get;

   ------------------------------------------------------------

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Float_8) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get (Statement, Positive (Field_Number), Value);
   end Get;

   ------------------------------------------------------------

   procedure Get_Date (Statement : in Statement_Type;
                       Parameter : in Positive;
                       Value     : out Sattmate_Calendar.Time_Type) is
   begin
      declare
         Local_String : constant String :=
                          Get_Value (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
      begin
         if Local_String'Length = 0 then
            Value := Sattmate_Calendar.Time_Type_First;
         else
            Value := Convert_To_Date (Local_String);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column number: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get_Date;

   ------------------------------------------------------------
   procedure Get_Date (Statement : in Statement_Type;
                       Parameter : in String;
                       Value     : out Sattmate_Calendar.Time_Type) is
      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get_Date (Statement, Positive (Field_Number), Value);
   end Get_Date;

   ------------------------------------------------------------

   procedure Get_Time (Statement : in Statement_Type;
                       Parameter : in Positive;
                       Value     : out Sattmate_Calendar.Time_Type) is
   begin
      declare
         Local_String : constant String :=
                          Get_Value (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
      begin
         if Local_String'Length = 0 then
            Value := Sattmate_Calendar.Time_Type_First;
         else
            Value := Convert_To_Time (Local_String);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column number: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get_Time;

   --------------------------------------------------------------

   procedure Get_Time (Statement : in Statement_Type;
                       Parameter : in String;
                       Value     : out Sattmate_Calendar.Time_Type) is

      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get_Time (Statement, Positive (Field_Number), Value);
   end Get_Time;

   ---------------------------------------------------------------
   procedure Get_Timestamp (Statement : in Statement_Type;
                            Parameter : in Positive;
                            Value     : out Sattmate_Calendar.Time_Type) is
   begin
      declare
         Local_String : constant String :=
                          Get_Value (Statement.Private_Statement.Result,
                                     Tuple_Index_Type (Statement.Private_Statement.Current_Row),
                                     Field_Index_Type (Parameter));
      begin
         if Local_String'Length = 0 then
            Value := Sattmate_Calendar.Time_Type_First;
         else
            Value := Convert_To_Timestamp (Local_String);
         end if;
      end;
   exception
      when Constraint_Error =>
         Put_Line ("No such column number: " & Positive'Image (Parameter));
         raise No_Such_Column;
   end Get_Timestamp;

   --------------------------------------------------------------

   procedure Get_Timestamp (Statement : in Statement_Type;
                            Parameter : in String;
                            Value     : out Sattmate_Calendar.Time_Type) is

      Field_Number : Field_Index_Type := Field_Index (Statement.Private_Statement.Result, Parameter);
   begin
      Get_Timestamp (Statement, Positive (Field_Number), Value);
   end Get_Timestamp;
   ------------------------------------------------------------
   -- end Get handling procs
   ------------------------------------------------------------

   --------------------------------------------------------------
   -- start unimplemented procs
   ------------------------------------------------------------



   -- v9.1-I141 New function
   function Module return String is
   begin
      --    return CONTEXT.MODULE(1..SKIP_TRAILING_BLANKS (CONTEXT.MODULE)'Length);
      return "Not implemented!";
   end Module;

   -- v9.1-I141 New function
   function Action return String is
   begin
      --  return CONTEXT.ACTION(1..SKIP_TRAILING_BLANKS (CONTEXT.ACTION)'Length);
      return "Function ACTION is not implemented!";
   end Action;

   -- v9.1-I141 New function
   function Client_Info return String is
   begin
      --    return CONTEXT.CLIENT_INFO(1..SKIP_TRAILING_BLANKS (CONTEXT.CLIENT_INFO)'Length);
      return "Function CLIENT_INFO is not implemented!";
   end Client_Info;

   -- v9.1-I141 New procedure
   procedure Set_Module (Module : in String) is
      pragma Warnings (Off, Module);
   begin
      --    CONTEXT.MODULE := (others => ' ');
      --    if MODULE'Length > 0 then
      --      if MODULE'Length > CONTEXT.MODULE'Length then
      --        CONTEXT.MODULE := MODULE(1..CONTEXT.MODULE'Length);
      --      else
      --        CONTEXT.MODULE (1..MODULE'Length) := MODULE;
      --      end if;
      --    end if;
      null;
   end Set_Module;

   -- v9.1-I141 New procedure
   procedure Set_Action (Action : in String) is
      pragma Warnings (Off, Action);
   begin
      --    CONTEXT.ACTION := (others => ' ');
      --    if ACTION'Length > 0 then
      --      if ACTION'Length > CONTEXT.ACTION'Length then
      --        CONTEXT.ACTION := ACTION(1..CONTEXT.ACTION'Length);
      --      else
      --        CONTEXT.ACTION (1..ACTION'Length) := ACTION;
      --      end if;
      --    end if;
      null;
   end Set_Action;

   -- v9.1-I141 New procedure
   procedure Set_Client_Info (Client_Info : in String) is
      pragma Warnings (Off, Client_Info);
   begin
      --    CONTEXT.CLIENT_INFO := (others => ' ');
      --    if CLIENT_INFO'Length > 0 then
      --      if CLIENT_INFO'Length > CONTEXT.CLIENT_INFO'Length then
      --        CONTEXT.CLIENT_INFO := CLIENT_INFO(1..CONTEXT.CLIENT_INFO'Length);
      --      else
      --        CONTEXT.CLIENT_INFO (1..CLIENT_INFO'Length) := CLIENT_INFO;
      --      end if;
      --    end if;
      null;
   end Set_Client_Info;


   function Last_Statement return String is		-- V8.3a
      --    TEXT   : STRING(1..1024) := (others => ' ');
      --    LENGTH : Integer := TEXT'Length;
   begin
      --    SQLIFC.LAST_STATEMENT (TEXT'ADDRESS, LENGTH'ADDRESS);
      --    return TEXT(1..LENGTH);
      return "Function LAST_STATEMENT is not implementeted!";
   end Last_Statement;


   function Error_Message return String is -- not implementet, dummy
   begin
      return "Error_Message not implemented";
   end Error_Message;


   procedure Get_Column_Info
     (Statement   : Statement_Type;
      Parameter   : Positive;
      Name        : out String;
      Namelen     : out Integer_4;
      Datatype    : out Integer_4;
      Datatypelen : out Integer_4) is
   begin
      null;
   end Get_Column_Info;

   function Get_Nbr_Columns (Statement : Statement_Type) return Integer is
   begin
      return 0;
   end Get_Nbr_Columns;


   --------------------------------------------------------------
   -- end unimplemented procs
   ------------------------------------------------------------
end Sql;
