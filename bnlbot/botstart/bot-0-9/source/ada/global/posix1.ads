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
  type MODE_T is range 0..2_147_483_647;
  for MODE_T'SIZE use 32;
  
  type SIZE_T is range -2_147_483_648..2_147_483_647;
  for SIZE_T'SIZE use 32;


  type Pid_T is range -1 .. 2_147_483_647;
  for Pid_T'SIZE use 32;

  O_RDONLY : Int := 8#0#;
  O_WRONLY : Int := 8#1#;
  O_RDWR   : Int   := 8#2#;


-- /usr/include/i386-linux-gnu/bits/fcntl.h
--#define O_ACCMODE	   0003
--#define O_RDONLY	     00
--#define O_WRONLY	     01
--#define O_RDWR		     02
--#define O_CREAT		   0100	/* not fcntl */
--#define O_EXCL		   0200	/* not fcntl */
--#define O_NOCTTY	   0400	/* not fcntl */
--#define O_TRUNC		  01000	/* not fcntl */
--#define O_APPEND	  02000
--#define O_NONBLOCK	  04000
--#define O_NDELAY	O_NONBLOCK
--#define O_SYNC	       04010000
--#define O_FSYNC		 O_SYNC
--#define O_ASYNC		 020000



  function Getpid return Pid_T;
  function Setsid return Pid_T;
  function Fork return Pid_T;
  Fork_Failed : exception;
  
  function Umask(Mask : Mode_T) return Mode_T;
  procedure Do_Exit(Status : int);
  procedure Daemonize ;

  procedure Perror (Msg : String ) ;
  
  
private

  pragma Import (C, Getpid ,"getpid");
  pragma Import (C, Setsid, "setsid");
  pragma Import (C, Fork, "fork");
  pragma Import (C, Umask, "umask");
  pragma Import (C, Do_Exit, "_exit");


end Posix1;


