#!/usr/bin/python
import smtplib
 
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
 
sender = 'bnlbetbot@gmail.com'
recipient = 'b.f.lundin@gmail.com'
subject = 'Gmail SMTP Test'
body = 'Dags att flytta betbot-pengar'
password = 'Alice2010'
 
"Sends an e-mail to the specified recipient."
 
body = "" + body + ""
 
headers = ["From: " + sender,
           "Subject: " + subject,
           "To: " + recipient,
           "MIME-Version: 1.0",
           "Content-Type: text/html"]
headers = "\r\n".join(headers)
 
session = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
 
session.ehlo()
session.starttls()
session.ehlo
session.login(sender, password)
 
session.sendmail(sender, recipient, headers + "\r\n\r\n" + body)
session.quit()

