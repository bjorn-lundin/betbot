
with AWS;  use AWS;
with AWS.SMTP; 
with Text_Io;
with AWS.SMTP.Authentication;
with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;

procedure Mailer is
  Auth : aliased constant SMTP.Authentication.Plain.Credential :=
      SMTP.Authentication.Plain.Initialize ("AKIAJZDDS2DVUNB76S6A", 
                      "AhVJXW+YJRE/AMBPoUEOaCjAaWJWWRTDC8JoU039baJG");
  SMTP_Server_Name : constant String := "email-smtp.us-east-1.amazonaws.com";   

  Status : SMTP.Status; 
  SMTP_Server : SMTP.Receiver := SMTP.Client.Initialize
                                (SMTP_Server_Name,
                                 Port       => 2465,
                                 Secure     => True,
                                 Credential => Auth'Unchecked_Access);
begin
  Text_Io.Put_Line ("1");
  SMTP.Client.Send(Server  => SMTP_Server,
                   From    => SMTP.E_Mail ("Nonobet Betbot", "betbot@nonobet.com"),
                   To      => SMTP.E_Mail("B Lundin", "b.f.lundin@gmail.com"),
                   Subject => "About AWS SMTP protocol",
                   Message => "From Amazon",
                   Status  => Status);
  Text_Io.Put_Line ("2");                   
  if not SMTP.Is_Ok (Status) then
    Text_Io.Put_Line ("Can't send message: " & SMTP.Status_Message (Status));
  else
    Text_Io.Put_Line ("Did send message: " & SMTP.Status_Message (Status));  
  end if;                  
end Mailer;
