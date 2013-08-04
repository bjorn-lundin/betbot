with AWS.SMTP, AWS.SMTP.Client, AWS.SMTP.Authentication.Plain;
with Ada.Text_IO;
use  Ada, AWS;
 
procedure Send_aws_mail is
   Status : SMTP.Status;
--   Auth : aliased constant SMTP.Authentication.Plain.Credential :=
--      SMTP.Authentication.Plain.Initialize ("bnlbetbot@gmail.com", "Alice2010");
   Isp : SMTP.Receiver;
begin
   Isp :=
      SMTP.Client.Initialize
        ("smtp.telenor.se",
         Port       => 25);
   SMTP.Client.Send
     (Isp,
      From    => SMTP.E_Mail ("Me", "bnlbetbot@gmail.com"),
      To      => SMTP.E_Mail ("You", "b.f.lundin@gmail.com"),
      Subject => "subject",
      Message => "Here is the text",
      Status  => Status);
   if not SMTP.Is_Ok (Status) then
      Text_IO.Put_Line
        ("Can't send message :" & SMTP.Status_Message (Status));
   end if;
end Send_aws_mail;
 