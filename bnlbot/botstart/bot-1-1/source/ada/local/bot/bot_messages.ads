
with Sattmate_Types;  use Sattmate_Types;
with Process_Io;
pragma Elaborate_All(Process_Io);--9.3-0028


package Bot_Messages is

  subtype Bot_Messages is Process_Io.Identity_Type range 2000..2099;

  Market_Notification_Message : constant Process_io.Identity_Type := 2000;
  New_Winners_Arrived_Notification_Message : constant Process_io.Identity_Type := 2001;

  ----------------------------------------------------------------
  type Market_Notification_Record is record
      Market_Id : String(1..11) := (others => ' ');
  end record;
  for Market_Notification_Record'alignment use 4;
  for Market_Notification_Record use record
      Market_Id at 0 range 0..8*11-1;
  end record;
  for Market_Notification_Record'Size use 8*11;

  ----------------------------------------------------------------
  
  package Market_Notification_Package is new Process_Io.Generic_Io
          (Identity        => Market_Notification_Message,
           Data_Type       => Market_Notification_Record,
           Data_Descriptor => (1 => Process_Io.String_Type(11)));
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
end Bot_Messages;
