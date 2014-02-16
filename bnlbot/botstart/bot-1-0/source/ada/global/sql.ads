
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Pgada.Database; use Pgada.Database;
with Ada.Finalization; use Ada.Finalization;
with Sattmate_Calendar;
with Sattmate_Types; use Sattmate_Types;

with Simple_List_Class;
pragma Elaborate_All (Simple_List_Class);

package Sql is

   Not_Connected             : exception;
   No_Transaction            : exception;
   Duplicate_Index           : exception;
   No_Such_Row               : exception;
   Transaction_Conflict      : exception;
   Postgresql_Error          : exception;
   Too_Many_Cursors          : exception;
   Sequence_Error            : exception;
   Too_Many_Input_Parameters : exception;
   No_Such_Column            : exception;
   Null_Value                : exception;
   Transaction_Error         : exception;
   Sql_Error                 : exception;
   No_Such_Object            : exception;
   No_Such_Parameter         : exception;
   Conversion_Error          : exception;

   type Database_Type is (Rdb,         -- Not currently supported
                          Oracle,
                          Mimer,       -- Not currently supported
                          Sql_Server,  -- Not currently supported
                          Ms_Access,    -- Not currently supported
                          Postgresql);  --bnl

   -- Function Database returns the name of the current database.
   function Database return Database_Type;

   type Transaction_Status_Type is (None, Read_Write, Read_Only);
   type Transaction_Isolation_Level_Type is (Read_Commited, Serializable);
   type Transaction_Isolation_Level_Scope_Type is (Transaction, Session);

--   type Transaction_Type is  limited private;

   type Statement_Type is new Limited_Controlled with private ;

   --  type Statement_Type   is limited private;

   -----------------------------------------------------------
   procedure Open_Oracle_Session (User : String; Password : String);

   procedure Open_Odbc_Session (D1 : String; D2 : String; D3 : String);

   procedure Close_Session;

   procedure Connect (Host       : in String  := "";
                      Port       : in Natural := 5432;
                      Options    : in String  := "";
                      Tty        : in String  := "";
                      Db_Name    : in String  := "";
                      Login      : in String := "";
                      Password   : in String := "");

   function  Is_Session_Open return Boolean;

   -----------------------------------------------------------

   procedure Set_Transaction_Isolation_Level (Level : in Transaction_Isolation_Level_Type;
                                              Scope : in Transaction_Isolation_Level_Scope_Type);

   type Transaction_Type is new Limited_Controlled with private;
   
   procedure Start_Read_Write_Transaction (T : in out Transaction_Type);
   procedure Start (T : in out Transaction_Type) renames Start_Read_Write_Transaction;
   procedure Start_Read_Only_Transaction (T : in out Transaction_Type);
   procedure Commit (T : in out Transaction_Type) ;
   procedure Rollback (T : in out Transaction_Type) ;

   function  Transaction_Status return Transaction_Status_Type;
   -----------------------------------------------------------

   procedure Prepare (Statement : in out Statement_Type;
                      Command   : in String) ;


   procedure Open_Cursor (Statement : in Statement_Type);

   procedure Fetch (Statement  : in Statement_Type;
                    End_Of_Set : out    Boolean) ;

   procedure Close_Cursor (Statement : in Statement_Type);


   -----------------------------------------------------------
   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Integer_4) ;

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Integer_4);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Integer_8) ;

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Integer_8);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out String);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out String);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Float_8);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Float_8);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Character);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Character);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in Positive;
                  Value     : out Boolean);

   procedure Get (Statement : in Statement_Type;
                  Parameter : in String;
                  Value     : out Boolean);

   procedure Get_Date (Statement : in Statement_Type;
                       Parameter : in String;
                       Value     : out Sattmate_Calendar.Time_Type) ;

   procedure Get_Time (Statement : in Statement_Type;
                       Parameter : in Positive;
                       Value     : out Sattmate_Calendar.Time_Type) ;

   procedure Get_Timestamp (Statement : in Statement_Type;
                            Parameter : in Positive;
                            Value     : out Sattmate_Calendar.Time_Type) ;

   procedure Get_Date (Statement : in Statement_Type;
                       Parameter : in Positive;
                       Value     : out Sattmate_Calendar.Time_Type) ;

   procedure Get_Time (Statement : in Statement_Type;
                       Parameter : in String;
                       Value     : out Sattmate_Calendar.Time_Type) ;

   procedure Get_Timestamp (Statement : in Statement_Type;
                            Parameter : in String;
                            Value     : out Sattmate_Calendar.Time_Type) ;

   -----------------------------------------------------------

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Integer_4);

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Integer_8);

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in String);

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Character);

   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Float_8);
                  
   procedure Set (Statement : in out Statement_Type;
                  Parameter : in String;
                  Value     : in Boolean);

   procedure Set_Date (Statement : in out Statement_Type;
                       Parameter : in String;
                       Value     : in Sattmate_Calendar.Time_Type);

   procedure Set_Time (Statement : in out Statement_Type;
                       Parameter : in String;
                       Value     : in Sattmate_Calendar.Time_Type);

   procedure Set_Timestamp (Statement : in out Statement_Type;
                            Parameter : in String;
                            Value     : in Sattmate_Calendar.Time_Type);
   -----------------------------------------------------------

   procedure Execute (Statement           : in Statement_Type;
                      No_Of_Affected_Rows : out Natural) ;


   procedure Execute (Statement : in Statement_Type) ;

   --------------------------------------------------------------
   function Is_Null (Statement : Statement_Type;
                     Parameter : Positive) return Boolean ;

   function Is_Null (Statement : Statement_Type;
                     Parameter : String) return Boolean ;

   ------------------------------------------------------------

   procedure Set_Null (Statement : in out Statement_Type;
                       Parameter : String);


   procedure Set_Null_Date (Statement : in out Statement_Type;
                            Parameter : String);

   ------------------------------------------------------------
   --  procedure Print_Errors(MyUnit   : in String;
   --                         MyStatus : in Exec_Status_Type);


   ------------------------------------------------------------
   function Error_Message return String; -- not implementet, dummy
   ------------------------------------------------------------
   procedure Set_Module (Module : in String);

   procedure Set_Action (Action : in String);

   procedure Set_Client_Info (Client_Info : in String);

   function Module return String;

   function Action return String;

   function Client_Info return String;

   function Last_Statement return String; 		-- V8.3a

   procedure Get_Column_Info
     (Statement   : Statement_Type;
      Parameter   : Positive;
      Name        : out String;
      Namelen     : out Integer_4;
      Datatype    : out Integer_4;
      Datatypelen : out Integer_4);

   function Get_Nbr_Columns (Statement : Statement_Type) return Integer;

   ---------------------------------------------------------------

private
   type Transaction_Identity_Type is mod Integer'Last;

   type Parameter_Type_Type is (
                                Not_Set     ,
                                Null_Type   ,
                                An_Integer  ,
                                A_Float     ,
                                A_String    ,
                                A_Character ,
                                A_Date      ,
                                A_Time      ,
                                A_Timestamp );

   for Parameter_Type_Type'Size use Integer'Size;
   for Parameter_Type_Type use (
                                Not_Set     => -2,
                                Null_Type   => -1,
                                An_Integer  => 0,
                                A_Float     => 1,
                                A_String    => 2,
                                A_Character => 3,
                                A_Date      => 4,
                                A_Time      => 5,
                                A_Timestamp => 6);

   type Parameter_Map_Type is record
      Index          : Integer := 0;
      Name           : Unbounded_String;
      Value          : Unbounded_String;
      Parameter_Type : Parameter_Type_Type;
   end record;

   package Map is new Simple_List_Class (Parameter_Map_Type);

   type Statement_Type_Type is (A_Select, An_Insert, A_Delete, An_Update, A_Ddl);
   subtype Name_Type is String (1 .. 11);

   type Private_Statement_Type is new Limited_Controlled with record
      Index                   : Integer := 0;
      Statement_Name          : Name_Type := (others => ' ');
      Is_Prepared             : Boolean := False;
      Cursor_Name             : Name_Type := (others => ' ');
      Pg_Prepared_Statement   : Unbounded_String := To_Unbounded_String ("");
      Prepared_Statement      : Unbounded_String := To_Unbounded_String ("");
      Original_Statement      : Unbounded_String := To_Unbounded_String ("");
      Parameter_Map           : Map.List_Type := Map.Create;
      Result                  : Result_Type;
      Dml_Result              : Result_Type;
      Is_Ok_To_Close          : Boolean := False; -- is set in close_cursor, commit/rollback uses it
      Is_Open                 : Boolean := False; --set/unset in open/close check in fetch
      Type_Of_Statement       : Statement_Type_Type;
      Current_Row             : Natural := 0;
      Number_To_Fetch         : Natural := 10_000;
      Number_Actually_Fetched : Natural := 0;
      Number_Parameters       : Natural := 0;
      --	State                   : String(1..5) := (others => ' ');
      --    Error_MessageU          : Unbounded_String := To_Unbounded_String("");
   end record;

   --  procedure Initialize (Object : in out Private_Statement_Type) ;
   procedure Do_Initialize (Private_Statement : in out Private_Statement_Type) ;
   procedure Finalize (Private_Statement : in out Private_Statement_Type) ;
   procedure Associate (Private_Statement : in out Private_Statement_Type;
                        Bind_Varible      : String;
                        Idx               : Natural) ;
   procedure Check_Is_Prepared (Private_Statement : in out Private_Statement_Type) ;
   procedure Update_Map (Private_Statement      : in out Private_Statement_Type;
                         Bind_Varible           : in     String;
                         Value                  : in     String;
                         Parameter_Type         : in     Parameter_Type_Type) ;
   procedure Exchange_Binder_Variables (Private_Statement : in out Private_Statement_Type) ;
   procedure Fill_Data_In_Prepared_Statement (Private_Statement : in out Private_Statement_Type) ;

   type Private_Statement_Type_Ptr is access all Private_Statement_Type;

   type Statement_Type is new Limited_Controlled with record
      Private_Statement : Private_Statement_Type_Ptr := null;
   end record;
   --  procedure Initialize (Statement : in out Statement_Type);
   procedure Do_Initialize (Statement : in out Statement_Type);
   procedure Finalize (Statement : in out Statement_Type);

   type Transaction_Type is new Limited_Controlled with record
      Status  : Transaction_Status_Type   := None;
      Counter : Transaction_Identity_Type := 0;
   end record;
--   procedure Finalize (T : in out Transaction_Type);
   
--   type Transaction_Type is tagged limited record
--      Status  : Transaction_Status_Type   := None;
--      Counter : Transaction_Identity_Type := 0;
--   end record;
end Sql;




