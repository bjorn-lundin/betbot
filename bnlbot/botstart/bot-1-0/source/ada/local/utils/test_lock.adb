

with Lock ;
with Logging; use Logging;

procedure Test_Lock is

  My_Lock  : Lock.Lock_Type;

begin

  Log("About to take lock 'test_lock'");
  My_Lock.Take("test_lock");
  Log("About to delay 10 s");
  delay 10.0;
  Log("done");

end Test_Lock;
