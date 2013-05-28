--------------------------------------------------------------------------------
--

package Posix1 is

  type BYTE is range 0..255;
  for BYTE'SIZE use 8;
  
  type SHORT is range -32_768..32_767;
  for SHORT'SIZE use 16;

  type UNSIGNED_SHORT is range 0..2**16-1;  
  for  UNSIGNED_SHORT'SIZE use 16;

  type INT is range -2_147_483_648..2_147_483_647;
  for INT'SIZE use 32;

--------------------------------------------------------------------


  type Pid_T is range 0..2_147_483_647;
  for Pid_T'SIZE use 32;

  O_RDONLY : Int ;
  O_WRONLY : Int;
  O_RDWR : Int;
  function Getpid return Pid_T;
  
private
 

  pragma Import(C,O_RDWR,"O_RDWR");
  pragma Import(C,O_WRONLY,"O_WRONLY");
  pragma Import(C,O_RDONLY,"O_RDONLY");
  pragma Import (C, C_GETPID, "getpid");
 
end Posix1;


