------------------------------------------------------------------------------
--                                                                          --
--                       P G A D A . D A T A B A S E                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--  Copyright (c) Samuel Tardieu 2000                                       --
--  All rights reserved.                                                    --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions      --
--  are met:                                                                --
--  1. Redistributions of source code must retain the above copyright       --
--     notice, this list of conditions and the following disclaimer.        --
--  2. Redistributions in binary form must reproduce the above copyright    --
--     notice, this list of conditions and the following disclaimer in      --
--     the documentation and/or other materials provided with the           --
--     distribution.                                                        --
--  3. Neither the name of Samuel Tardieu nor the names of its contributors --
--     may be used to endorse or promote products derived from this         --
--     software without specific prior written permission.                  --
--                                                                          --
--  THIS SOFTWARE IS PROVIDED BY SAMUEL TARDIEU AND CONTRIBUTORS ``AS       --
--  IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          --
--  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       --
--  FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL SAMUEL      --
--  TARDIEU OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,             --
--  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES                --
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR      --
--  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      --
--  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN               --
--  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR            --
--  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,          --
--  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Deallocation;
with Interfaces.C.Strings;       use Interfaces.C, Interfaces.C.Strings;
with Text_io;
with Ada.Exceptions;
with Ada.Characters.Handling;


package body PGAda.Database is
   -- bnl
   --No_Diagnostics_Found : constant String := "No diagnostics found";
     No_Diagnostics_Found : constant String := "";
   -- bnl 
   Exec_Status_Match :
     constant array (Thin.Exec_Status_Type) of Exec_Status_Type :=
       (PGRES_EMPTY_QUERY    => Empty_Query,
        PGRES_COMMAND_OK     => Command_OK,
        PGRES_TUPLES_OK      => Tuples_OK,
        PGRES_COPY_OUT       => Copy_Out,
        PGRES_COPY_IN        => Copy_In,
        PGRES_BAD_RESPONSE   => Bad_Response,
        PGRES_NONFATAL_ERROR => Non_Fatal_Error,
        PGRES_FATAL_ERROR    => Fatal_Error);

   -----------------------
   -- Local subprograms --
   -----------------------

   function C_String_Or_Null(S : String) return Chars_Ptr;
   procedure Free(S : in out Chars_Ptr);
   --  Create a C string or return Null_Ptr if the string is empty, and
   --  free it if needed.

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Result : in out Result_Type) is
   begin
--      Text_io.put_Line("Adjust - Will set Ref_Count set to:" & Natural'Image(Result.Ref_Count.all + 1));
      Result.Ref_Count.all := Result.Ref_Count.all + 1;
--      Text_io.put_Line("Adjust - Has  set Ref_Count set to:" & Natural'Image(Result.Ref_Count.all + 1));
   end Adjust;

   ----------------------
   -- C_String_Or_Null --
   ----------------------

   function C_String_Or_Null(S : String) return Chars_Ptr is
   begin
      if S = "" then
         return Null_Ptr;
      else
         return New_String (S);
      end if;
   end C_String_Or_Null;

   -----------
   -- Clear --
   -----------

   procedure Clear (Result : in out Result_Type) is
   begin
      PQ_Clear (Result.Actual);
      Result.Actual := null;
   end Clear;

   --------------------
   -- Command_Status --
   --------------------

   function Command_Status (Result : Result_Type) return String is
   begin
      return Value (PQ_Cmd_Status (Result.Actual));
   end Command_Status;


-- bnl
   --------------------
   -- Rows_Affected --
   --------------------

   function Rows_Affected (Result : Result_Type) return Natural is
   begin
     return Natural'value(Value(PQ_Cmd_Tuples(Result.Actual)));
   end Rows_Affected;

-- bnl


   --------
   -- DB --
   --------

   function DB (Connection : Connection_Type) return String is
   begin
      return Value (PQ_Db (Connection.Actual));
   end DB;

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message (Connection : Connection_Type) return String is
   begin
      return Value (PQ_Error_Message (Connection.Actual));
   end Error_Message;


--bnl
   function Result_Error_Message (Result : Result_Type) return String is
   begin
      return Value (PQ_Result_Error_Message (Result.Actual));
   end Result_Error_Message;
--bnl

   ----------
   -- Exec --
   ----------

   procedure Exec (Connection : in Connection_Type'Class;
                   Query      : in String;
                   Result     : out Result_Type)
   is
      C_Query : Chars_Ptr := New_String (Query);
   begin
      Result.Actual := PQ_Exec (Connection.Actual, C_Query);
      Interfaces.C.Strings.Free(C_Query);
   end Exec;

   ----------
   -- Exec --
   ----------

   function Exec (Connection : Connection_Type'Class; Query : String)
     return Result_Type
   is
      Result : Result_Type;
   begin
      Exec (Connection, Query, Result);
      return Result;
   end Exec;

   ----------
   -- Exec --
   ----------

--   procedure Exec (Connection : in Connection_Type'Class;
--                   Query      : in String)
--   is
--      Result : Result_Type;
--   begin
--      Exec (Connection, Query, Result);
--   end Exec;

   ----------------
   -- Field_Name --
   ----------------

   function Field_Name (Result      : Result_Type;
                        Field_Index : Field_Index_Type)
     return String is
   begin
      return Value (PQ_F_Name (Result.Actual, int (Field_Index) - 1));
   end Field_Name;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Connection : in out Connection_Type) is
   begin
      if Connection.Actual /= null then
         Finish (Connection);
      end if;
   end Finalize;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Result : in out Result_Type) is
      procedure Free is
         new Ada.Unchecked_Deallocation (Natural, Natural_Access);
   begin
      Result.Ref_Count.all := Result.Ref_Count.all - 1;
      if Result.Ref_Count.all = 0 and then Result.Actual /= null then
         Free(Result.Ref_Count);
         Clear (Result);
      end if;
   end Finalize;

   ------------
   -- Finish --
   ------------

   procedure Finish (Connection : in out Connection_Type) is
   begin
      PQ_Reset (Connection.Actual);
      PQ_Finish (Connection.Actual);
      Connection.Actual := null;
   end Finish;

   ----------
   -- Free --
   ----------

   procedure Free(S : in out Chars_Ptr) is
   begin
      if S /= Null_Ptr then
         Interfaces.C.Strings.Free(S);
      end if;
   end Free;

   ----------------
   -- Get_Length --
   ----------------

   function Get_Length (Result      : Result_Type;
                        Tuple_Index : Tuple_Index_Type;
                        Field_Index : Field_Index_Type)
     return Natural
   is
   begin
      return Natural (PQ_Get_Length (Result.Actual,
                                     int (Tuple_Index) - 1,
                                     int (Field_Index) - 1));
   end Get_Length;


--bnl
   ---------------
   -- Get_Field_Number --
   ---------------

   function Field_Index(Result      : Result_Type;
                        Field_Name  : String)
                        return Field_Index_Type is
     fname : String := Ada.Characters.Handling.To_Lower(Field_Name);
     C_Name       : Chars_Ptr  := New_String(fname);
     Field_Number : Int        := Int'first;
   begin
      Field_Number := PQ_F_Number (Result.Actual, C_Name);
      Free(C_Name);
      if Field_Number = -1 then
           Ada.Exceptions.Raise_Exception(No_such_column'Identity, "Cannot find column: '" & fname & "'" );
      end if;
      return Field_Index_Type(Field_Number + 1);
    end Field_Index;

   ---------------
   -- Get_Value --
   ---------------

   function Get_Value (Result      : Result_Type;
                       Tuple_Index : Tuple_Index_Type;
                       Field_Index : Field_Index_Type)
     return String
   is
   begin
      return Value (PQ_Get_Value (Result.Actual,
                                 int (Tuple_Index) - 1,
                                 int (Field_Index) - 1));
   end Get_Value;

   ---------------
   -- Get_Value --
   ---------------

--   function Get_Value (Result      : Result_Type;
--                       Tuple_Index : Tuple_Index_Type;
--                       Field_Name  : String)
--    return String
--   is
--      Field_Number : Field_Index_Type := Field_Index(Result,Field_Name);
--   begin
--     return Get_Value(Result,Tuple_Index,Field_Number);
--   end Get_Value;


   ---------------
   -- Get_Value --
   ---------------

--   function Get_Value (Result      : Result_Type;
--                       Tuple_Index : Tuple_Index_Type;
--                       Field_Index : Field_Index_Type)
--     return Integer
--   is
--   begin
--      return Integer'Value (Get_Value (Result, Tuple_Index, Field_Index));
--   end Get_Value;

   ---------------
   -- Get_Value --
   ---------------

--   function Get_Value (Result      : Result_Type;
--                       Tuple_Index : Tuple_Index_Type;
--                       Field_Name  : String)
--     return Integer
--   is
--   begin
--      return Integer'Value (Get_Value (Result, Tuple_Index, Field_Name));
--   end Get_Value;

   ----------
   -- Host --
   ----------

   function Host (Connection : Connection_Type) return String is
   begin
      return Value (PQ_Host (Connection.Actual));
   end Host;

   -------------
   -- Is_Null --
   -------------

   function Is_Null (Result      : Result_Type;
                     Tuple_Index : Tuple_Index_Type;
                     Field_Index : Field_Index_Type)
     return Boolean
   is
   begin
      return 1 = PQ_Get_Is_Null
        (Result.Actual, int (Tuple_Index) - 1, int (Field_Index) - 1);
   end Is_Null;

   ----------------
   -- Nbr_Fields --
   ----------------

   function Nbr_Fields (Result : Result_Type) return Natural is
   begin
      return Natural (PQ_N_Fields (Result.Actual));
   end Nbr_Fields;

   ----------------
   -- Nbr_Tuples --
   ----------------

   function Nbr_Tuples (Result : Result_Type) return Natural is
   begin
      return Natural (PQ_N_Tuples (Result.Actual));
   end Nbr_Tuples;

   ----------------
   -- OID_Status --
   ----------------

   function OID_Status (Result : Result_Type) return String is
   begin
      return Value (PQ_Oid_Status (Result.Actual));
   end OID_Status;

   -------------
   -- Options --
   -------------

   function Options (Connection : Connection_Type) return String is
   begin
      return Value (PQ_Options (Connection.Actual));
   end Options;

   ----------
   -- Port --
   ----------

   function Port (Connection : Connection_Type) return Positive is
   begin
      return Positive'Value (Value (PQ_Port (Connection.Actual)));
   end Port;

   -----------
   -- Reset --
   -----------

   procedure Reset (Connection : in Connection_Type) is
   begin
      PQ_Reset (Connection.Actual);
   end Reset;

   -------------------
   -- Result_Status --
   -------------------

   function Result_Status (Result : Result_Type) return Exec_Status_Type is
   begin
      return Exec_Status_Match (PQ_Result_Status (Result.Actual));
   end Result_Status;

   ------------------
   -- Set_DB_Login --
   ------------------

   procedure Set_DB_Login (Connection : in out Connection_Type;
                           Host       : in String  := "";
                           Port       : in Natural := 0;
                           Options    : in String  := "";
                           TTY        : in String  := "";
                           DB_Name    : in String  := "";
                           Login      : in String  := "";
                           Password   : in String  := "")
   is
      C_Host     : Chars_Ptr := C_String_Or_Null(Host);
      C_Port     : Chars_Ptr;
      C_Options  : Chars_Ptr := C_String_Or_Null(Options);
      C_TTY      : Chars_Ptr := C_String_Or_Null(TTY);
      C_DB_Name  : Chars_Ptr := C_String_Or_Null(DB_Name);
      C_Login    : Chars_Ptr := C_String_Or_Null(Login);
      C_Password : Chars_Ptr := C_String_Or_Null(Password);
   begin
      if Port = 0 then
         C_Port := Null_Ptr;
      else
         C_Port := New_String (Positive'Image (Port));
      end if;
      Connection.Actual :=
        PQ_Set_Db_Login (C_Host, C_Port, C_Options, C_TTY, C_DB_Name,
                         C_Login, C_Password);
      Free(C_Host);
      Free(C_Port);
      Free(C_Options);
      Free(C_TTY);
      Free(C_DB_Name);
      Free(C_Login);
      Free(C_Password);
      if Connection.Actual = null then
         raise PG_Error;
      end if;
--    Text_Io.Put_Line("Client_Encoding_Name -> " & Client_Encoding_Name(Connection));
   end Set_DB_Login;

   ------------
   -- Status --
   ------------

   function Status (Connection : Connection_Type)
     return Connection_Status_Type
   is
   begin
      case PQ_Status (Connection.Actual) is
         when CONNECTION_OK =>
            return Connection_OK;
         when CONNECTION_BAD =>
            return Connection_Bad;
      end case;
   end Status;

   ---------
   -- TTY --
   ---------

   function TTY (Connection : Connection_Type) return String is
   begin
      return Value (PQ_TTY (Connection.Actual));
   end TTY;




--bnl
  function PQ_Set_Client_Encoding(Conn     : PG_Conn_Access ;
                                  Encoding : Chars_Ptr) return Int;
  pragma Import(C, PQ_Set_Client_Encoding, "PQsetClientEncoding");
--int PQsetClientEncoding(PGconn *conn, const char *encoding);
--where conn is a connection to the server, and encoding is the
--encoding you want to use. If the function successfully sets
--the encoding, it returns 0, otherwise -1. The current encoding
--for this connection can be determined by using:

  function PQ_Client_Encoding(Conn : PG_Conn_Access) return Int;
  pragma Import(C, PQ_Client_Encoding, "PQclientEncoding");
--int PQclientEncoding(const PGconn *conn);
--Note that it returns the encoding ID, not a symbolic string
--such as EUC_JP. To convert an encoding ID to an
-- encoding name, you can use:

  function Pg_Encoding_To_Char(Encoding_Id : Int) return Chars_Ptr;
  pragma Import(C, Pg_Encoding_To_Char, "pg_encoding_to_char");
--char *pg_encoding_to_char(int encoding_id);
--bnl

  procedure Set_Client_Encoding(Connection : in out Connection_Type;
                                Encoding   : in String) is
    C_Encoding  : Chars_Ptr := C_String_Or_Null(Encoding);
    Result : Int := 0;
  begin
    Result := PQ_Set_Client_Encoding(Connection.Actual, C_Encoding);
    Free(C_Encoding);
    if Result = -1 then
      Ada.Exceptions.Raise_Exception(PG_Error'Identity, "Could not set encoding: '" & Encoding & "'");
    end if;
  end Set_Client_Encoding;

  function Client_Encoding_Code(Connection : Connection_Type) return Natural is
  begin
    return Natural(PQ_Client_Encoding(Connection.Actual));
  end Client_Encoding_Code;

  function Client_Encoding_Name(Connection : Connection_Type) return String is
    Code : Int := PQ_Client_Encoding(Connection.Actual);
  begin
      return Value(Pg_Encoding_To_Char(Code));
  end Client_Encoding_Name;

--  procedure Exec_Prepared(Connection    : in  Connection_Type'Class;
--                          Statment_Name : in  String;
--                          Number_Params : in  Natural;
--                          Param_Values  : in  String_Array_Type;
--                          Param_Lengths : in  Int_Array_Type;
--                          Param_Formats : in  Int_Array_Type;
--                          Result        : out Result_Type) is
--
--      C_Stm_Name     : Chars_Ptr := New_String(Statment_Name);
--      Values         : aliased String_Array_Type := Param_Values;
--      Values_Ptr     : aliased String_Array_Type_Ptr := Values'Unchecked_Access;
--      Values_Ptr_Ptr : String_Array_Type_Ptr_Ptr := Values_Ptr'Unchecked_Access;
--
--      Lengths : aliased Int_Array_Type := Param_Lengths;
--      Lengths_Ptr : Int_Array_Type_Ptr := Lengths'Unchecked_Access;
--
--      Formats : aliased Int_Array_Type := Param_Formats;
--      Formats_Ptr : Int_Array_Type_Ptr := Formats'Unchecked_Access;
--   begin
--      Result.Actual := PQ_Exec_Prepared(
--                                Conn => Connection.Actual,
--                                Stmt_Name => C_Stm_Name,
--                                N_Params => Int(Number_Params),
--                                Param_Values => Values_Ptr_Ptr,
--                                Param_Lengths => Lengths_Ptr,
--                                Param_Formats => Formats_Ptr,
--                                Result_Format => 0); -- text=0 binary=1
--      Interfaces.C.Strings.Free(C_Stm_Name);
--   end Exec_Prepared;

--Submits a request to create a prepared statement with the given parameters,
-- and waits for completion.

--PGresult *PQprepare(PGconn *conn,
--                    const char *stmtName,
--                    const char *query,
--                    int nParams,
--                    const Oid *paramTypes);


--  procedure Prepare(Connection    : in  Connection_Type'Class;
--                    Statment_Name : in  String;
--                    Query         : in  String;
--                    Number_Params : in  Natural;
--                    Param_Types   : in Int_Array_Type;
--                    Result        : out Result_Type) is
--      C_Stm_Name : Chars_Ptr := New_String(Statment_Name);
--      C_Query    : Chars_Ptr := New_String(Query);
--
--      Types : aliased Int_Array_Type := Param_Types;
--      Types_Ptr : Int_Array_Type_Ptr := Types'Unchecked_Access;
--   begin
--      Result.Actual := PQ_Prepare(
--                            Conn        => Connection.Actual,
--                            Stmt_Name   => C_Stm_Name,
--                            Query       => C_Query,
--                            N_Params    => Int(Number_Params),
--                            Param_Types => Types_Ptr);
--      Interfaces.C.Strings.Free(C_Stm_Name);
--      Interfaces.C.Strings.Free(C_Query);
--   end Prepare;


  ----------------------------------------------------------------------------
  function Parameter_Status(Conn : Connection_Type; Parameter : String) return String is   
    C_Name : Chars_Ptr := New_String(Parameter);
  begin
     if not Conn.Get_Connected then 
       Text_io.Put_Line("Not connected to database!");
       Free(C_Name);
       raise PG_Error;
     else
       declare
         Ret : constant String := Value(PQ_Parameter_Status(Conn.Actual, C_Name));
       begin
         Free(C_Name);
         return Ret;
       end;
     end if; 
  end Parameter_Status;
  ----------------------------------------------------------------------------
  function Database_Encoding(Conn : Connection_Type) return String is
  begin
    return Parameter_Status(Conn, "server_encoding");
  end Database_Encoding;
  ----------------------------------------------------------------------------

  function Get_Encoding(Conn : Connection_Type) return Encoding_Type is
  begin
    return Conn.Encoding;
  end Get_Encoding; 
 
  procedure Set_Encoding(Res : in out Result_Type; Encoding : Encoding_Type)  is
  begin
    Res.Encoding := Encoding;
  end Set_Encoding;
  procedure Set_Encoding(Conn : in out Connection_Type; Encoding : Encoding_Type)  is
  begin
    Conn.Encoding := Encoding;
  end Set_Encoding;

  ----------------------------------------------------------------------------
  
  procedure Set_Connected (Connection : in out Connection_Type; Connected : in Boolean) is
  begin
    Connection.Is_Connected := Connected; 
  end Set_Connected;

  function Get_Connected (Connection : Connection_Type) return Boolean is
  begin
    return Connection.Is_Connected ; 
  end Get_Connected;

  -----------------------------------------------------------------------------
  function Error_Severity(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_SEVERITY);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Severity;  

  function Error_Sql_State(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_SQLSTATE);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Sql_State;  

  function Error_Message_Primary(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_MESSAGE_PRIMARY);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Message_Primary;

  function Error_Message_Detail(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_MESSAGE_DETAIL);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Message_Detail;

  function Error_Message_Hint(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_MESSAGE_HINT);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Message_Hint;

  function Error_Statement_Position(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_STATEMENT_POSITION);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Statement_Position;

  function Error_Internal_Position(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_INTERNAL_POSITION);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Internal_Position;

  function Error_Internal_Query(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_INTERNAL_QUERY);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Internal_Query;

  function Error_Context(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_CONTEXT);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Context;

  function Error_Source_File(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_SOURCE_FILE);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Source_File;

  function Error_Source_Line(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_SOURCE_LINE);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Source_Line;

  function Error_Source_Function(Res : Result_Type) return String is
    C_Res : Chars_Ptr := PQ_Result_Error_Field(Res.Actual, PG_DIAG_SOURCE_FUNCTION);
  begin
    if C_Res /= Null_Ptr then
      return Value(C_Res);
    else
      return No_Diagnostics_Found;
    end if;
  end Error_Source_Function;
  ---------------------------------------------------------------------------

  function Escape(Conn   : in Connection_Type;
                  Source : in String) return String is

    Local_Source :  String (1 .. Source'Length) := Source;
    Local_Target :  String (1 .. 2*Local_Source'Length+1) := (others => ' ');
    Err : aliased Int := 0;
    Num : Size_T;
    Lsp : Chars_Ptr := New_String(Local_Source);
    Ltp : Chars_Ptr := New_String(Local_Target);
  begin
    Num := PQ_Escape_String_Conn(Conn.Actual,Ltp,Lsp,Local_Source'Length,Err'access);
    declare
      Result : string := Value(Ltp);
    begin
--      Text_Io.Put_Line("------------------");
--      Text_Io.Put_Line("s: '" & Source & "' " & Integer'Image(Source'length));
--      Text_Io.Put_Line("r: '" & Result & "' " & Integer'Image(Result'length));
--      Text_Io.Put_Line("n: " & size_t'Image(num));
--      Text_Io.Put_Line("------------------");
      Free(Lsp);
      Free(Ltp);
      return "'" & Result(1..Integer(Num)) & "'";
    end;
  end Escape;
  ---------------------------------------------------------------------------



end PGAda.Database;

