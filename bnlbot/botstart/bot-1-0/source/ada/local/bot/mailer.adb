with Ada;
with Ada.Directories;
with Ada.Environment_Variables;
with Text_Io;

with AWS;  use AWS;
with AWS.SMTP; 
with AWS.SMTP.Authentication;
with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;

with Sattmate_Calendar;

procedure Mailer is
  SMTP_Server_Name : constant String := "email-smtp.eu-west-1.amazonaws.com"; 
                                        -- "email-smtp.us-east-1.amazonaws.com";   
  Status : SMTP.Status; 

begin
  Ada.Directories.Set_Directory(Ada.Environment_Variables.Value("BOT_CONFIG") & "/sslcert");
  declare
    Auth : aliased constant SMTP.Authentication.Plain.Credential :=
                              SMTP.Authentication.Plain.Initialize ("AKIAJZDDS2DVUNB76S6A", 
                                            "AhVJXW+YJRE/AMBPoUEOaCjAaWJWWRTDC8JoU039baJG");
    SMTP_Server : SMTP.Receiver := SMTP.Client.Initialize
                                (SMTP_Server_Name,
                                 Port       => 2465,
                                 Secure     => True,
                                 Credential => Auth'Unchecked_Access);
  begin   

    SMTP.Client.Send(Server  => SMTP_Server,
                     From    => SMTP.E_Mail ("Nonobet Betbot", "betbot@nonobet.com"),
                     To      => SMTP.E_Mail("B Lundin", "b.f.lundin@gmail.com"),
                     Subject => "About AWS SMTP protocol",
                     Message => "From Amazon, via " & SMTP_Server_Name & Sattmate_Calendar.String_Date_And_Time,
                     Status  => Status);
  end;                   
  if not SMTP.Is_Ok (Status) then
    Text_Io.Put_Line ("Can't send message: " & SMTP.Status_Message (Status));
  end if;                  
end Mailer;
