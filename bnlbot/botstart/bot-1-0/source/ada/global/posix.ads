--------------------------------------------------------------------------------
--
with Interfaces.C;
with Interfaces.C.Strings;
with Sattmate_Types; use Sattmate_Types;
with C_Constants;

package Posix is

  type Byte is new Sattmate_Types.Byte;
  type Short is new Integer_2;
  type Unsigned_Short is new Word;
  type Int is new Integer_4;

--------------------------------------------------------------------
  type Mode_T is range 0..2_147_483_647;
  for Mode_T'size use 32;
  
  type Size_T is new Integer_4;


  type Pid_T is range -1 .. 2_147_483_647;
  for Pid_T'size use 32;

  O_RDONLY   : constant Int := Int(C_Constants.O_RDONLY);    -- open for reading only
  O_WRONLY   : constant Int := Int(C_Constants.O_WRONLY);    -- open for writing only
  O_RDWR     : constant Int := Int(C_Constants.O_RDWR);      -- open for reading and writing
  O_CREAT    : constant Int := Int(C_Constants.O_CREAT);     -- no file? create it
  O_EXCL     : constant Int := Int(C_Constants.O_EXCL);      -- lock file (see below)
  O_NOCTTY   : constant Int := Int(C_Constants.O_NOCTTY);    -- if tty, don't acquire it
  O_TRUNC    : constant Int := Int(C_Constants.O_TRUNC);     -- file exists? truncate it
  O_APPEND   : constant Int := Int(C_Constants.O_APPEND);    -- file exists? move to end
  O_NONBLOCK : constant Int := Int(C_Constants.O_NONBLOCK);  -- if pipe, don't wait for data
  O_SYNC     : constant Int := Int(C_Constants.O_SYNC);      -- don't cache writes
  O_ASYNC    : constant Int := Int(C_Constants.O_ASYNC);     -- async. IO via SIGIO
  O_DIRECT   : constant Int := Int(C_Constants.O_DIRECT);    -- direct disk access
  O_LARGEFILE: constant Int := Int(C_Constants.O_LARGEFILE); -- not implemented in Linux (yet)
  O_DIRECTORY: constant Int := Int(C_Constants.O_DIRECTORY); -- error if file isn't a dir
  O_NOFOLLOW : constant Int := Int(C_Constants.O_NOFOLLOW);  -- if sym link, open link itself  

   ------------ lock files start --------------
   type Short_Integer is new Sattmate_Types.Integer_2;
   
   type aLock is new Short_Integer;
   F_RDLCK : constant aLock := aLock(C_Constants.F_RDLCK); -- read lock
   F_WRLCK : constant aLock := aLock(C_Constants.F_WRLCK); -- write lock
   F_UNLCK : constant aLock := aLock(C_Constants.F_UNLCK); -- unlock (remove a lock)
   F_EXLCK : constant aLock := aLock(C_Constants.F_EXLCK); -- exclusive lock
   F_SHLCK : constant aLock := aLock(C_Constants.F_SHLCK); -- shared lock
   
   F_DUPFD  : constant Int := Int(C_Constants.F_DUPFD);
   F_GETFD  : constant Int := Int(C_Constants.F_GETFD);
   F_SETFD  : constant Int := Int(C_Constants.F_SETFD);
   F_GETFL  : constant Int := Int(C_Constants.F_GETFL);
   F_SETFL  : constant Int := Int(C_Constants.F_SETFL);
   F_GETLK  : constant Int := Int(C_Constants.F_GETLK);
   F_SETLK  : constant Int := Int(C_Constants.F_SETLK);
   F_SETLKW : constant Int := Int(C_Constants.F_SETLKW);
   F_SETOWN : constant Int := Int(C_Constants.F_SETOWN);
   F_GETOWN : constant Int := Int(C_Constants.F_GETOWN);
   F_SETSIG : constant Int := Int(C_Constants.F_SETSIG);
   F_GETSIG : constant Int := Int(C_Constants.F_GETSIG);   
   
   type aWhenceMode is new Short_Integer;
   SEEK_SET : constant aWhenceMode := aWhenceMode(C_Constants.SEEK_SET); -- absolute position
   SEEK_CUR : constant aWhenceMode := aWhenceMode(C_Constants.SEEK_CUR); -- offset from current position
   SEEK_END : constant aWhenceMode := aWhenceMode(C_Constants.SEEK_END); -- offset from end of file  
   
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


