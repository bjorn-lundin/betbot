--------------------------------------------------------------------------------
--

with Interfaces.C.Strings;
with Sattmate_Types; use Sattmate_Types;

package Posix is




  type Byte is new Sattmate_Types.Byte;

  type Short is new Integer_2;

  type Unsigned_Short is new Word;

  type INT is new Integer_4;

--------------------------------------------------------------------
  type MODE_T is range 0..2_147_483_647;
  for MODE_T'SIZE use 32;
  
  type SIZE_T is new Integer_4;


  type Pid_T is range -1 .. 2_147_483_647;
  for Pid_T'SIZE use 32;

  O_RDONLY   : constant Int :=      8#00#; -- open for reading only
  O_WRONLY   : constant Int :=      8#01#; -- open for writing only
  O_RDWR     : constant Int :=      8#02#; -- open for reading and writing
  O_CREAT    : constant Int :=    8#0100#; -- no file? create it
  O_EXCL     : constant Int :=    8#0200#; -- lock file (see below)
  O_NOCTTY   : constant Int :=    8#0400#; -- if tty, don't acquire it
  O_TRUNC    : constant Int :=   8#01000#; -- file exists? truncate it
  O_APPEND   : constant Int :=   8#02000#; -- file exists? move to end
  O_NONBLOCK : constant Int :=   8#04000#; -- if pipe, don't wait for data
  O_SYNC     : constant Int :=  8#010000#; -- don't cache writes
  O_ASYNC    : constant Int :=  8#020000#; -- async. IO via SIGIO
  O_DIRECT   : constant Int :=  8#040000#; -- direct disk access
  O_LARGEFILE: constant Int := 8#0100000#; -- not implemented in Linux (yet)
  O_DIRECTORY: constant Int := 8#0200000#; -- error if file isn't a dir
  O_NOFOLLOW : constant Int := 8#0400000#; -- if sym link, open link itself  

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





   ------------ lock files start --------------
   type Short_Integer is new Sattmate_Types.Integer_2;
   
   type aLock is new Short_Integer;
   F_RDLCK : constant aLock := 0; -- read lock
   F_WRLCK : constant aLock := 1; -- write lock
   F_UNLCK : constant aLock := 2; -- unlock (remove a lock)
   F_EXLCK : constant aLock := 3; -- exclusive lock
   F_SHLCK : constant aLock := 4; -- shared lock
   
   F_DUPFD  : constant int :=  0;
   F_GETFD  : constant int :=  1;
   F_SETFD  : constant int :=  2;
   F_GETFL  : constant int :=  3;
   F_SETFL  : constant int :=  4;
   F_GETLK  : constant int :=  5;
   F_SETLK  : constant int :=  6;
   F_SETLKW : constant int :=  7;
   F_SETOWN : constant int :=  8;
   F_GETOWN : constant int :=  9;
   F_SETSIG : constant int := 10;
   F_GETSIG : constant int := 11;   
   
   
   type aWhenceMode is new Short_Integer;
   SEEK_SET : constant aWhenceMode := 0; -- absolute position
   SEEK_CUR : constant aWhenceMode := 1; -- offset from current position
   SEEK_END : constant aWhenceMode := 2; -- offset from end of file  
   
   type Lockstruct is record
     L_Type   : Alock;         -- type of lock
     L_Whence : Short_Integer; -- how to interpret l_start
     L_Start  : Integer;       -- offset or position
     L_Len    : Integer;       -- number of bytes to lock (0 for all)
     L_Pid    : Integer;       -- with GETLK, process ID owning lock
   end record;  
   procedure fcntl( result : out int; fd : in Int; operation : in int; lock : in out lockstruct ) ;
   --return integer
   pragma import( C, fcntl, "fcntl" );
   pragma import_valued_procedure( fcntl );   
   --------------- lockfiles stop --------------




  function Getpid return Pid_T;
  
  
  function Setsid return Pid_T;
  function Fork return Pid_T;
  Fork_Failed : exception;
  
  function Umask(Mask : Mode_T) return Mode_T;
  procedure Do_Exit(Status : int);
  procedure Daemonize ;

  procedure Perror (Msg : String ) ;
  function Open(Path : Interfaces.C.Strings.Chars_Ptr ; flags : int ; mode : mode_t) return Int; 
  function Close(Fd : Int) return Int; 
  function Errno return Int;
  
  function Write(Fd : Int; Buf : Interfaces.C.Strings.Chars_Ptr; Count : Size_T) return Size_T;
  
private

  pragma Import (C, Getpid ,"getpid");
  pragma Import (C, Setsid, "setsid");
  pragma Import (C, Fork, "fork");
  pragma Import (C, Umask, "umask");
  pragma Import (C, Do_Exit, "_exit");

  pragma Import (C, open, "open");
  pragma Import (C, close, "close");
  --int creat(const char *pathname, mode_t mode);
  pragma Import (C, Errno, "__get_errno");   
--ssize_t write(int fd, const void *buf, size_t count); 
  pragma Import(C, Write, "write");
end Posix;


