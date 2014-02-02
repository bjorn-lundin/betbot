
with AWS;  use AWS;
with AWS.SMTP; 
with Text_Io;
with AWS.SMTP.Authentication;
with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;
with AWS.Net;
procedure Mailer is
  Auth : aliased constant SMTP.Authentication.Plain.Credential :=
      SMTP.Authentication.Plain.Initialize ("AKIAIZJNVMLZKG27FQTA", 
                      "AmGnNLwlPS4q8K6QwrnL5OlYuS+7E8WcIqVfD3pHxC0Z");
  SMTP_Server_Name : constant String := "email-smtp.us-east-1.amazonaws.com";   
--  SMTP_Server_Name : constant String := "localhost";   

  Status : SMTP.Status; 
  SMTP_Server : SMTP.Receiver := SMTP.Client.Initialize
                                (SMTP_Server_Name,
                                 Port       => 2465,
                                 Secure     => True,
                                 Family     => Net.Family_Inet,
                                 Credential => Auth'Unchecked_Access);
--  SMTP_Server : SMTP.Receiver := SMTP.Client.Initialize
--                                (SMTP_Server_Name,
--                                 Port       => 2002
--                                 Secure     => True,
--                                 Credential => Auth'Unchecked_Access
--                                 );
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
