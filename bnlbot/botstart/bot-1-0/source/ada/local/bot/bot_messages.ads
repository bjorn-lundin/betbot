
with Types;  use Types;
with Process_Io;
with Bot_Types; use Bot_Types;
pragma Elaborate_All(Process_Io);--9.3-0028


package Bot_Messages is

  subtype Bot_Messages is Process_Io.Identity_Type range 2000..2099;

  Market_Notification_Message : constant Process_io.Identity_Type := 2000;
  New_Winners_Arrived_Notification_Message : constant Process_io.Identity_Type := 2001;
  Place_Back_Bet_Message : constant Process_io.Identity_Type := 2002;
  Place_Lay_Bet_Message : constant Process_io.Identity_Type := 2003;
  New_Bet_Placed_Notification_Message : constant Process_io.Identity_Type := 2004;
  Poll_State_Message : constant Process_io.Identity_Type := 2005;
  

  ----------------------------------------------------------------
  type Market_Notification_Record is record
      Market_Id : Marketid_Type := (others => ' ');
  end record;
  for Market_Notification_Record'alignment use 4;
  for Market_Notification_Record use record
      Market_Id at 0 range 0..8*11 -1;
  end record;
  for Market_Notification_Record'Size use 96; --8*11;

  ----------------------------------------------------------------

  package Market_Notification_Package is new Process_Io.Generic_Io
          (Identity        => Market_Notification_Message,
           Data_Type       => Market_Notification_Record,
           Data_Descriptor => (1 => Process_Io.String_Type(Marketid_Type'length)));
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  Market_Notification_Record
            renames Market_Notification_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : Market_Notification_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames Market_Notification_Package.Send;

  -----------------------------------------------------------------------

   ----------------------------------------------------------------
  type New_Winners_Arrived_Notification_Record is record
      Dummy : Integer_4 := 0;
  end record;
  for New_Winners_Arrived_Notification_Record'alignment use 4;
  for New_Winners_Arrived_Notification_Record use record
      Dummy at 0 range 0..8*4-1;
  end record;
  for New_Winners_Arrived_Notification_Record'Size use 8*4;

  ----------------------------------------------------------------

  package New_Winners_Arrived_Notification_Package is new Process_Io.Generic_Io
          (Identity        => New_Winners_Arrived_Notification_Message,
           Data_Type       => New_Winners_Arrived_Notification_Record,
           Data_Descriptor => (1 => Process_Io.Integer_4_Type));
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  New_Winners_Arrived_Notification_Record
            renames New_Winners_Arrived_Notification_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : New_Winners_Arrived_Notification_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames New_Winners_Arrived_Notification_Package.Send;
  ---------------------------------------------------------------------------

  ----------------------------------------------------------------
  type Place_Back_Bet_Record is record
      Bet_Name     : Betname_Type    := (others => ' ');
      Market_Id    : Marketid_Type   := (others => ' ');
      Selection_Id : Integer_4        := 0;
      Size         : String(1..7)     := (others => ' ');
      Price        : String(1..6)     := (others => ' ');
      Match_Directly : Integer_4      := 0;
  end record;

--  for Place_Back_Bet_Record'alignment use 4;
--  for Place_Back_Bet_Record use record
--      Bet_Name at 0 range 0..8*100-1;
--      Bet_Name     : Bet_Name_Type    := (others => ' ');
--      Market_Id    : Market_Id_Type   := (others => ' ');
--      Selection_Id : Integer_4        := 0;
--      Size         : String(1..7);    := (others => ' ');
--      Price        : String(1..4);    := (others => ' ');
--  end record;
--  for Market_Notification_Record'Size use 8*11;

  ----------------------------------------------------------------

  package Place_Back_Bet_Package is new Process_Io.Generic_Io
          (Identity        => Place_Back_Bet_Message,
           Data_Type       => Place_Back_Bet_Record,
           Data_Descriptor => (1 => Process_Io.String_Type(100),
                               2 => Process_Io.String_Type(11),
                               3 => Process_Io.Integer_4_Type,
                               4 => Process_Io.String_Type(7),
                               5 => Process_Io.String_Type(6),
                               6 => Process_Io.Integer_4_Type
                              )
           );
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  Place_Back_Bet_Record
            renames Place_Back_Bet_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : Place_Back_Bet_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames Place_Back_Bet_Package.Send;

  -----------------------------------------------------------------------

  ----------------------------------------------------------------
  type Place_Lay_Bet_Record is record
      Bet_Name     : Betname_Type    := (others => ' ');
      Market_Id    : Marketid_Type   := (others => ' ');
      Selection_Id : Integer_4        := 0;
      Size         : String(1..7)     := (others => ' ');
      Price        : String(1..6)     := (others => ' ');
      Match_Directly : Integer_4      := 0;
  end record;

--  for Place_Back_Bet_Record'alignment use 4;
--  for Place_Back_Bet_Record use record
--      Bet_Name at 0 range 0..8*100-1;
--      Bet_Name     : Bet_Name_Type    := (others => ' ');
--      Market_Id    : Market_Id_Type   := (others => ' ');
--      Selection_Id : Integer_4        := 0;
--      Size         : String(1..7);    := (others => ' ');
--      Price        : String(1..4);    := (others => ' ');
--  end record;
--  for Market_Notification_Record'Size use 8*11;

  ----------------------------------------------------------------

  package Place_Lay_Bet_Package is new Process_Io.Generic_Io
          (Identity        => Place_Lay_Bet_Message,
           Data_Type       => Place_Lay_Bet_Record,
           Data_Descriptor => (1 => Process_Io.String_Type(100),
                               2 => Process_Io.String_Type(11),
                               3 => Process_Io.Integer_4_Type,
                               4 => Process_Io.String_Type(7),
                               5 => Process_Io.String_Type(6),
                               6 => Process_Io.Integer_4_Type
                              )
           );
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  Place_Lay_Bet_Record
            renames Place_Lay_Bet_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : Place_Lay_Bet_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames Place_Lay_Bet_Package.Send;

  -----------------------------------------------------------------------
  
     ----------------------------------------------------------------
  type New_Bet_Placed_Notification_Record is record
      Dummy : Integer_4 := 0;
  end record;
  for New_Bet_Placed_Notification_Record'alignment use 4;
  for New_Bet_Placed_Notification_Record use record
      Dummy at 0 range 0..8*4-1;
  end record;
  for New_Bet_Placed_Notification_Record'Size use 8*4;

  ----------------------------------------------------------------

  package New_Bet_Placed_Notification_Package is new Process_Io.Generic_Io
          (Identity        => New_Winners_Arrived_Notification_Message,
           Data_Type       => New_Bet_Placed_Notification_Record,
           Data_Descriptor => (1 => Process_Io.Integer_4_Type));
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  New_Bet_Placed_Notification_Record
            renames New_Bet_Placed_Notification_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : New_Bet_Placed_Notification_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames New_Bet_Placed_Notification_Package.Send;
  ---------------------------------------------------------------------------


  
  ----------------------------------------------------------------
  type Poll_State_Record is record
      Free : Integer_4 := 0;
      Name : Process_Io.Name_Type := (others => ' ');
      Node : Process_Io.Name_Type := (others => ' ');
  end record;
  
  for Poll_State_Record'alignment use 4;
  for Poll_State_Record use record
      Free at 0 range 0..8*4-1;
      Name at 4 range 0..8*15-1;
      Node at 20 range 0..8*15-1;
  end record;
  for Poll_State_Record'Size use 8*36; 
  

  package Poll_State_Package is new Process_Io.Generic_Io
          (Identity        => Poll_State_Message,
           Data_Type       => Poll_State_Record,
           Data_Descriptor => (1 => Process_Io.Integer_4_Type,
                               2 => Process_Io.String_Type(15),
                               3 => Process_Io.String_Type(15)));
  --
  function  Data   (Message: Process_Io.Message_Type)
            return  Poll_State_Record
            renames Poll_State_Package.Data;
  --
  procedure Send   (Receiver  : Process_Io.Process_Type;
                    Data      : Poll_State_Record;
                    Connection: Process_Io.Connection_Type:=Process_Io.Permanent)
            renames Poll_State_Package.Send;
  ---------------------------------------------------------------------------

  
end Bot_Messages;
