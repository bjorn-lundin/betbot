
with AWS;  use AWS;
with AWS.SMTP; -- use AWS.SMTP;
with Text_Io;
with AWS.SMTP.Authentication;
with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;

procedure Mailer is
  Auth : aliased constant SMTP.Authentication.Plain.Credential :=
      SMTP.Authentication.Plain.Initialize ("AKIAJZDDS2DVUNB76S6A", "AhVJXW+YJRE/AMBPoUEOaCjAaWJWWRTDC8JoU039baJG");
    
--      email-smtp.us-east-1.amazonaws.com
  SMTP_Server : constant String := "email-smtp.eu-west-1.amazonaws.com";   
  Status : SMTP.Status; 
  Server : SMTP.Receiver := SMTP.Client.Initialize
                                (SMTP_Server,
                                 Port       => 465,
                                 Secure     => True,
                                 Credential => Auth'Unchecked_Access);
begin

  SMTP.Client.Send(SMTP_Server,
                   From    => SMTP.E_Mail ("Nonobet Betbot", "betbot@nonobet.com"),
                   To      => "b.f.lundin@gmail.com",
                   Subject => "About AWS SMTP protocol",
                   Message => "From Amazon",
                   Status  => Status);
                   
  if not SMTP.Is_Ok (Status) then
    Text_Io.Put_Line ("Can't send message: " & SMTP.Status_Message (Status));
  else
    Text_Io.Put_Line ("Did send message: " & SMTP.Status_Message (Status));  
  end if;                  
end Mailer