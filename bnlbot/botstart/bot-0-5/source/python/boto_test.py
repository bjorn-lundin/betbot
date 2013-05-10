from boto import ses
connection = ses.connect_to_region(
    'us-east-1',
    aws_access_key_id='AKIAJZDDS2DVUNB76S6A',
    aws_secret_access_key='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'
)

from_address = '"Nonobet Betbot" <betbot@nonobet.com>'
subject = 'Daily betting report'
body = 'Here comes a report...'
sendlist = ['b.f.lundin@gmail.com', 'joakim@birgerson.com']

connection.send_email(
    from_address,
    subject,
    body,
    sendlist
)

