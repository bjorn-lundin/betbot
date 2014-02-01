with AWS.SMTP, AWS.SMTP.Client, AWS.SMTP.Authentication.Plain;
with Ada.Text_IO;
use  Ada, AWS;
 
procedure Send_aws_mail is
   Status : SMTP.Status;
   Auth   : aliased constant SMTP.Authentication.Plain.Credential :=
           SMTP.Authentication.Plain.Initialize ("AKIAJZDDS2DVUNB76S6A",
                                                 "AhVJXW+YJRE/AMBPoUEOaCjAaWJWWRTDC8JoU039baJG");
   Isp : SMTP.Receiver;
   SMTP_Server: String := "email-smtp.eu-west-1.amazonaws.com";
begin
   Isp :=
     Server : SMTP.Receiver := SMTP.Client.Initialize
                                (SMTP_Server,
                                 Port       => 465,
                                 Secure     => True,
                                 Credential => Auth'Unchecked_Access);

   SMTP.Client.Send
     (Isp,
      From    => SMTP.E_Mail ("Nonobet Betbot", "betbot@nonobet.com"),
      To      => SMTP.E_Mail ("Björn Lundin", "b.f.lundin@gmail.com"),
      Subject => "subject",
      Message => "Here is the text",
      Status  => Status);
   if not SMTP.Is_Ok (Status) then
      Text_IO.Put_Line
        ("Can't send message :" & SMTP.Status_Message (Status));
   end if;
end Send_aws_mail;
 