--------------------------------------------------------------------------------
--
--	COPYRIGTH	SattControl AB, Malm|
--
--	FILENAME	SATTMATE_CALENDAR_SPEC.ADA
--
--	RESPONSIBLE	XCP
--
--	DESCRIPTION	This file contains the specification of the 
--			package SATTMATE_CALENDAR. The package contains 
--			time conversions and time operations.
--
--------------------------------------------------------------------------------
--
--	VERSION		5.0
--	AUTHOR		Peter Sacher
--	VERIFIED BY	Henrik Dannberg
--	DESCRIPTION	Orginal version.
--
--------------------------------------------------------------------------------
--
--	VERSION		6.0		17-mar-1994
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	NECTAR_TIME_TYPE and NECTAR_DATE_TYPE removed
--
--------------------------------------------------------------------------------
--
--	VERSION		8.2		22-Apr-1999
--	AUTHOR		SNE/BTO
--	VERIFIED BY	?
--	DESCRIPTION	New procedures TO_TIME, TO_INTERVAL, TO_SECONDS.
--
--------------------------------------------------------------------------------
--
--	VERSION		8.2b		06-Dec-1999
--	AUTHOR		Irene Olsson
--	VERIFIED BY	?
--	DESCRIPTION	Function IS_LEGAL is made available
--
--------------------------------------------------------------------------------
-- 9.6-11859 2007-05-23 BNL Fixed drifting clock, by using Realtime clock
--                          Also removed any calendar types in spec
-- 9.8-xxxx  2008-12-08 SNE Added a conversion routine TO_TIME_TYPE
-- 9.8-18065 2009-20-11 BNL Moved Clock_Type et al from invenory to here
-- chg-25546 2012-09-08 BNL Fixed month int To_Time_Type. Also introduced exception Invalid_Date_Format 
--------------------------------------------------------------------------------

with CALENDAR;
with SATTMATE_TYPES;            use SATTMATE_TYPES; 

package SATTMATE_CALENDAR is

  subtype YEAR_TYPE        is INTEGER_2 range 1901 .. 2099; 
  subtype MONTH_TYPE       is INTEGER_2 range   01 ..   12;
  subtype DAY_TYPE         is INTEGER_2 range   01 ..   31;
  subtype HOUR_TYPE        is INTEGER_2 range   00 ..   23;
  subtype MINUTE_TYPE      is INTEGER_2 range   00 ..   59;
  subtype SECOND_TYPE      is INTEGER_2 range   00 ..   59;
  subtype MILLISECOND_TYPE is INTEGER_2 range  000 ..  999;

  subtype WEEK_TYPE        is INTEGER_2 range 1..53;
  subtype YEAR_DAY_TYPE    is INTEGER_2 range 1..366;
     type WEEK_DAY_TYPE    is
       (MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY);


  subtype INTERVAL_DAY_TYPE is INTEGER_4 range 0..INTEGER_4'LAST;
  subtype SECONDS_TYPE      is INTEGER_4 range 0..INTEGER_4'LAST; --v8.2

  type TIME_TYPE is 
    record 
      YEAR       : YEAR_TYPE;
      MONTH      : MONTH_TYPE;
      DAY        : DAY_TYPE;
      HOUR       : HOUR_TYPE;
      MINUTE     : MINUTE_TYPE;
      SECOND     : SECOND_TYPE;
      MILLISECOND: MILLISECOND_TYPE;
    end record;


  type INTERVAL_TYPE is
    record
      DAYS        : INTERVAL_DAY_TYPE;
      HOURS       : HOUR_TYPE;
      MINUTES     : MINUTE_TYPE;
      SECONDS     : SECOND_TYPE;
      MILLISECONDS: MILLISECOND_TYPE;
    end record;

--9.8-18065 start
  type CLOCK_TYPE is 
    record
      HOUR   : HOUR_TYPE;
      MINUTE : MINUTE_TYPE;
      SECOND : SECOND_TYPE;
    end record;
  function Clock_Of(T : in Time_Type) return Clock_Type;
  function "<=" (Left, Right: in Clock_Type) return Boolean;
  function ">=" (Left, Right: in Clock_Type) return Boolean;
  function To_String(C : in Clock_Type) return String ;
   
--9.8-18065 stop

  TIME_TYPE_FIRST : constant TIME_TYPE :=
                    (YEAR        => YEAR_TYPE'FIRST,
                     MONTH       => MONTH_TYPE'FIRST,
                     DAY         => DAY_TYPE'FIRST,
                     HOUR        => HOUR_TYPE'FIRST,
                     MINUTE      => MINUTE_TYPE'FIRST,
                     SECOND      => SECOND_TYPE'FIRST,
                     MILLISECOND => MILLISECOND_TYPE'FIRST);

  TIME_TYPE_LAST : constant TIME_TYPE :=
                   (YEAR        => YEAR_TYPE'LAST,
                    MONTH       => MONTH_TYPE'LAST,
                    DAY         => DAY_TYPE'LAST,
                    HOUR        => HOUR_TYPE'LAST,
                    MINUTE      => MINUTE_TYPE'LAST,
                    SECOND      => SECOND_TYPE'LAST,
                    MILLISECOND => MILLISECOND_TYPE'LAST);

  INTERVAL_TYPE_FIRST : constant INTERVAL_TYPE :=
                        (DAYS         => INTERVAL_DAY_TYPE'FIRST,
                         HOURS        => HOUR_TYPE'FIRST,
                         MINUTES      => MINUTE_TYPE'FIRST,
                         SECONDS      => SECOND_TYPE'FIRST,
                         MILLISECONDS => MILLISECOND_TYPE'FIRST);


  INTERVAL_TYPE_LAST : constant INTERVAL_TYPE :=
                       (DAYS         => INTERVAL_DAY_TYPE'LAST,
                        HOURS        => HOUR_TYPE'LAST,
                        MINUTES      => MINUTE_TYPE'LAST,
                        SECONDS      => SECOND_TYPE'LAST,
                        MILLISECONDS => MILLISECOND_TYPE'LAST);


  IN_PARAMETER_INCORRECT: exception;
--                        raised when the input date is impossible
--                        (e.g. 1990.02.30) or, in conversions to NECTAR
--			  date, the year is less than 1970.
  TIME_ERROR            : exception;
--                        raised when the result comes to a date before
--                        TIME_TYPE_FIRST or after TIME_TYPE_LAST, or the left 
--			  parameter is less than the right one in subtractions.

-- v8.2b Start
--
  function IS_LEGAL (YEAR : in YEAR_TYPE;
                     MONTH: in MONTH_TYPE;
                     DAY  : in DAY_TYPE) return BOOLEAN;

  function IS_LEGAL (YEAR    : in YEAR_TYPE;
                     YEAR_DAY: in YEAR_DAY_TYPE) return BOOLEAN;

  function IS_LEGAL (TIME: in TIME_TYPE) return BOOLEAN;
--
-- v8.2b End

  function CLOCK return TIME_TYPE;

--9.6-11859 new function, returns SATTMATE_CALENDAR.CLOCK, in CALENDAR.TIME-format
  function CALENDAR_CLOCK return CALENDAR.TIME ;


  --9.8-xxxx New function
  -- Date_Str => "DD-MON-YYYY" ("09-DEC-2008), Time_Str => "HH:MM:SS.ZZZ"("10:01:32.123")
  function To_Time_Type(Date_Str : string;
                        Time_Str : string) return Time_Type;

  Invalid_Date_Format : exception ; -- chg-25546
  -- is raised by bad data in To_Time_Type
  
                        
  function TO_TIME (DATE: in CALENDAR.TIME) return TIME_TYPE;
  function TO_CALENDAR_TIME (DATE: in TIME_TYPE) return CALENDAR.TIME;  
  function TO_TIME (YEAR       : in YEAR_TYPE;
                    YEAR_DAY   : in YEAR_DAY_TYPE;
                    HOUR       : in HOUR_TYPE;
                    MINUTE     : in MINUTE_TYPE;
                    SECOND     : in SECOND_TYPE;
                    MILLISECOND: in MILLISECOND_TYPE) return TIME_TYPE;

  function TO_TIME (YEAR       : in YEAR_TYPE;
                    WEEK       : in WEEK_TYPE;
                    DAY        : in WEEK_DAY_TYPE;
                    HOUR       : in HOUR_TYPE   := HOUR_TYPE'FIRST;
                    MINUTE     : in MINUTE_TYPE := MINUTE_TYPE'FIRST;
                    SECOND     : in SECOND_TYPE := SECOND_TYPE'FIRST;
                    MILLISECOND: in MILLISECOND_TYPE := MILLISECOND_TYPE'FIRST) 
                                    return TIME_TYPE; -- v8.2

  function "<"  (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN;
  function "<=" (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN;
  function ">"  (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN;
  function ">=" (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN;

  function "<"  (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN;
  function "<=" (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN;
  function ">"  (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN;
  function ">=" (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN;


  function TO_INTERVAL (DAY_DURATION: in CALENDAR.DAY_DURATION)
    return INTERVAL_TYPE;
  
  function TO_INTERVAL (SECONDS  : in SECONDS_TYPE)  return INTERVAL_TYPE; -- v8.2
  function TO_SECONDS  (INTERVAL : in INTERVAL_TYPE) return SECONDS_TYPE;  -- v8.2

  function TO_DAY_DURATION (INTERVAL: in INTERVAL_TYPE)
    return CALENDAR.DAY_DURATION;
  -- This function does not use the term DAYS in the record INTERVAL_TYPE.

  function "+" (LEFT: in TIME_TYPE; RIGHT: in INTERVAL_TYPE) return TIME_TYPE;
  function "+" (LEFT: in INTERVAL_TYPE; RIGHT: in TIME_TYPE) return TIME_TYPE;

  function "+" (LEFT: in TIME_TYPE; RIGHT: in YEAR_DAY_TYPE) return TIME_TYPE;
  function "+" (LEFT: in YEAR_DAY_TYPE; RIGHT: in TIME_TYPE) return TIME_TYPE;

  function "-" (LEFT, RIGHT: in TIME_TYPE) return INTERVAL_TYPE;
  function "-" (LEFT: in TIME_TYPE; RIGHT: in INTERVAL_TYPE) return TIME_TYPE;
  function "-" (LEFT: in TIME_TYPE; RIGHT: in YEAR_DAY_TYPE) return TIME_TYPE;

  function "+" (LEFT, RIGHT: in INTERVAL_TYPE) return INTERVAL_TYPE;

  function "-" (LEFT, RIGHT: in INTERVAL_TYPE) return INTERVAL_TYPE;


  function IS_LEAP_YEAR (YEAR: in YEAR_TYPE) return BOOLEAN;

  function YEAR_DAY_OF (DATE : in TIME_TYPE) return YEAR_DAY_TYPE;
  function YEAR_DAY_OF (YEAR : in YEAR_TYPE;
                        MONTH: in MONTH_TYPE;
                        DAY  : in DAY_TYPE) return YEAR_DAY_TYPE;

  function DAYS_IN (YEAR     : in YEAR_TYPE) return YEAR_DAY_TYPE;
  function DAYS_IN (YEAR     : in YEAR_TYPE;
                    MONTH    : in MONTH_TYPE) return DAY_TYPE;

  function WEEK_DAY_OF (DATE : in TIME_TYPE) return WEEK_DAY_TYPE;
  function WEEK_DAY_OF (YEAR : in YEAR_TYPE;
                        MONTH: in MONTH_TYPE;
                        DAY  : in DAY_TYPE) return WEEK_DAY_TYPE;

  function WEEK_OF (DATE     : in TIME_TYPE) return WEEK_TYPE;
  function WEEK_OF (YEAR     : in YEAR_TYPE;
                    MONTH    : in MONTH_TYPE;
                    DAY      : in DAY_TYPE) return WEEK_TYPE;
  function WEEK_OF (YEAR     : in YEAR_TYPE;
		    YEAR_DAY : in YEAR_DAY_TYPE) return WEEK_TYPE;

--9.6-11859 start
--  function STRING_DATE (DATE : in CALENDAR.TIME := CALENDAR.CLOCK) 
  function STRING_DATE (DATE : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK)) 
                        return STRING;
  function STRING_TIME 
--           (DATE         : in CALENDAR.TIME := CALENDAR.CLOCK;
           (DATE         : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK);
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING;
  function STRING_DATE_AND_TIME 
--           (DATE         : in CALENDAR.TIME := CALENDAR.CLOCK;
           (DATE         : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK);
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING;
--9.6-11859 stop

  function STRING_DATE (DATE : in TIME_TYPE) return STRING;
  function STRING_TIME 
           (DATE         : in TIME_TYPE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING;
  function STRING_DATE_AND_TIME 
           (DATE         : in TIME_TYPE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING;


  -- Enter in the BOOLEAN parameters in the STRING_TIME functions the values 
  -- you wish to be returned.
  -- Example of returned date is : 01-Jan-1984
  -- Example of returned time is : 15:30:05.001

  function STRING_INTERVAL 
           (INTERVAL     : in INTERVAL_TYPE;
            DAYS         : in BOOLEAN := TRUE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := TRUE) return STRING;

  -- Enter in the BOOLEAN parameters the values you wish to be returned.
  -- Example of returned a interval is : 00001:15:30:05.003


end SATTMATE_CALENDAR;
