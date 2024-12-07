 select distinct(runnername) 
 from arunners 
 where selectionid > 30 
 and runnername not in ('Any Other Home Win','Any Other Draw','Any Other Away Win','The Draw')
  and runnername not in (select teamname from aaliases)