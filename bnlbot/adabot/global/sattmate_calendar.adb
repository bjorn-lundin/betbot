--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SATTMATE_CALENDAR_BODY.ADA
--
--	RESPONSIBLE	XCP
--
--	DESCRIPTION	This file contains the body of the package
--			SATTMATE_CALENDAR. The package contains time 
--			conversions and time operations.
--
--------------------------------------------------------------------------------
--
--	VERSION		5.0
--	AUTHOR		Katarina Pettersson
--	VERIFIED BY	Peter Sacher
--	DESCRIPTION	Original version
--
--------------------------------------------------------------------------------
--
--	VERSION		5.2
--	AUTHOR		Henrik Dannberg		17-jun-1992
--	VERIFIED BY	?
--	DESCRIPTION	Fix added in order to avoid a bug in Alsys Ada
--			version 5.3 on AIX.
--
--------------------------------------------------------------------------------
--
--      VERSION         6.0             17-mar-1994
--      AUTHOR          Henrik Dannberg
--      VERIFIED BY     ?
--      DESCRIPTION     NECTAR_TIME_TYPE and NECTAR_DATE_TYPE removed
--
--------------------------------------------------------------------------------
--
--      VERSION         6.2             4-feb-1997
--      AUTHOR          Henrik Dannberg
--      VERIFIED BY     ?
--      DESCRIPTION     TO_INTERVAL rewritten to support DAY_DURATION'LAST.
--
--------------------------------------------------------------------------------
--
--      VERSION         8.1             22-Jan-1998
--      AUTHOR          JEP
--      VERIFIED BY     ?
--      DESCRIPTION     TO_TIME modified to support DAY_DURATION'LAST.
--
--------------------------------------------------------------------------------
-- Vers.  Author
-- 8.2		SNE/BTO       22-Apr-1999
--        New procedures TO_TIME, TO_INTERVAL, TO_SECONDS.
-- 8.2b		SNE           18-May-1999
--        Bug in function "-" (LEFT, RIGHT: in TIME_TYPE) return INTERVAL_TYPE.
--        When counting days in whole month for RIGHT date, year for LEFT date was
--        used. This caused nbr of days to be incorrect.
--        2001-JAN-01 - 2000-JAN-31  => 335 days (Nbr of days in month FEB was 
--                                                calculated to 28 because year 2001
--                                                was used instead of 2000, for input 
--                                                to function DAYS_IN(YEAR, MONTH)
--        2001-JAN-01 - 2000-FEB-01  => 335 days (OK, because FEB wasn't a whole month)
--------------------------------------------------------------------------------
--9.3-0085 2003-Nov-04  BNL Changed "-" to return interval_time_first, instead of
--                      raising TIME_ERROR, when dealing with Negative time,
--                       to simplify transition to vintertime
--------------------------------------------------------------------------------
-- 9.6-11859 2007-05-23 BNL Fixed drifting clock, by using Realtime clock
--                          Also removed any calendar types in spec
--                          Added function CALENDAR_CLOCK
--------------------------------------------------------------------------------     
-- 9.8-xxxx 2008-12-08 SNE Added a conversion routine TO_TIME_TYPE
-- 9.8-18065 2009-20-11 BNL Moved Clock_Type et al from invenory to here
-- chg-25546 2012-09-08 BNL Fixed month int To_Time_Type. Also introduced exception Invalid_Date_Format 
--------------------------------------------------------------------------------     

with TEXT_IO;

with Ada.Real_Time;
with Ada.Characters.Handling; --v9.8-xxxx


package body SATTMATE_CALENDAR is

  package INTEGER_2_IO is new TEXT_IO.INTEGER_IO (INTEGER_2);
  package INTEGER_4_IO is new TEXT_IO.INTEGER_IO (INTEGER_4);

-- Constants:

  SECONDS_PER_MINUTE: constant INTEGER_4 := 60;
  MINUTES_PER_HOUR  : constant INTEGER_4 := 60;
  HOURS_PER_DAY     : constant INTEGER_4 := 24;

  SECONDS_PER_HOUR  : constant INTEGER_4 := MINUTES_PER_HOUR*SECONDS_PER_MINUTE;
  SECONDS_PER_DAY   : constant INTEGER_4 := HOURS_PER_DAY * SECONDS_PER_HOUR;

  MONTH_DAY : constant array (MONTH_TYPE)
              of YEAR_DAY_TYPE := (31,28,31,30,31,30,31,31,30,31,30,31);


--9.6-11859 start
 Base_R_Clock : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
   --  Base real time clock

   Base_S_Clock : constant Calendar.Time := Calendar.Clock;
   --  Base standard clock
--9.6-11859



  function IS_LEGAL (YEAR : in YEAR_TYPE;
                     MONTH: in MONTH_TYPE;
                     DAY  : in DAY_TYPE) return BOOLEAN is
  begin
    return DAY <= DAYS_IN (YEAR, MONTH);
  end IS_LEGAL;


  function IS_LEGAL (YEAR    : in YEAR_TYPE;
                     YEAR_DAY: in YEAR_DAY_TYPE) return BOOLEAN is
  begin
    return YEAR_DAY < 366 or IS_LEAP_YEAR (YEAR);
  end IS_LEGAL;


  function IS_LEGAL (TIME: in TIME_TYPE) return BOOLEAN is
  begin
    return IS_LEGAL (TIME.YEAR, TIME.MONTH, TIME.DAY);
  end IS_LEGAL;


  procedure TO_MONTH_AND_DAY (YEAR     : in YEAR_TYPE;
			      YEAR_DAY : in YEAR_DAY_TYPE;
			      MONTH    : out MONTH_TYPE;
                              DAY      : out DAY_TYPE) is
    DAYS_LEFT : YEAR_DAY_TYPE := YEAR_DAY;
  begin
    for MONTH_NUMBER in MONTH_TYPE'FIRST..(MONTH_TYPE'LAST) loop
      MONTH := MONTH_NUMBER;
      exit when DAYS_LEFT <= DAYS_IN (YEAR, MONTH_NUMBER);
      DAYS_LEFT := DAYS_LEFT - DAYS_IN (YEAR, MONTH_NUMBER);
    end loop;
    DAY := DAY_TYPE (DAYS_LEFT);
  end;


--Package specified functions:

--9.6-11859 start
   function Clock return TIME_TYPE is
      use type Calendar.Time;
      use type Ada.Real_Time.Time;
      Current : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
      Time_In_Calendar_Format : Calendar.Time ;
   begin
      Time_In_Calendar_Format := Base_S_Clock + Ada.Real_Time.To_Duration (Current - Base_R_Clock);
    return TO_TIME (Time_In_Calendar_Format); 
   end Clock;

  function CALENDAR_CLOCK return CALENDAR.TIME is
  begin
    return To_Calendar_Time(Clock);
  end CALENDAR_CLOCK;
--9.6-11859 stop

  --9.8-xxxx
  function To_Time_Type(Date_Str : String;
                        Time_Str : String) return Time_Type is
    --reindex strings to start with 1
    Date : String(1 .. Date_Str'Last-Date_Str'First +1) := Date_Str;  --     chg-25546
    Time : String(1 .. Time_Str'Last-Time_Str'First +1) := Time_Str;  --     chg-25546
                        
    A_Time_Type : Time_Type := Time_Type_First;
    function Month (Month_Str : in string) return Month_Type is
      Tmp_Month : constant string := Ada.Characters.Handling.To_Upper(Month_Str);
    begin
      if    Tmp_Month = "JAN"  then return  1;
      elsif Tmp_Month = "FEB"  then return  2;
      elsif Tmp_Month = "MAR"  then return  3;
      elsif Tmp_Month = "APR"  then return  4;
      elsif Tmp_Month = "MAY"  then return  5;
      elsif Tmp_Month = "JUN"  then return  6;
      elsif Tmp_Month = "JUL"  then return  7;
      elsif Tmp_Month = "AUG"  then return  8;
      elsif Tmp_Month = "SEP"  then return  9;
      elsif Tmp_Month = "OCT"  then return 10;
      elsif Tmp_Month = "NOV"  then return 11;
      elsif Tmp_Month = "DEC"  then return 12;
      else raise Invalid_Date_Format with "bad month: " & Month_Str;   --     chg-25546
      end if;
    end Month;
  begin

    if Date_Str'length >= 11 then
      A_Time_Type.Year  := Year_Type'value(Date(8..11));
      A_Time_Type.Month := Month(Date(4..6)); --     chg-25546
      A_Time_Type.Day   := Day_Type'value(Date(1..2));
    end if;


    if Time'length  >= 8 then
      A_Time_Type.Hour   := Hour_Type'value(Time(1..2));
      A_Time_Type.Minute := Minute_Type'value(Time(4..5));
      A_Time_Type.Second := Second_Type'value(Time(7..8));
      if Time'length  >= 12 then
        A_Time_Type.Millisecond := Millisecond_Type'value(Time(10..12));
      end if;
    end if;
    return A_Time_Type;
  exception
 --     chg-25546    when others => return Time_Type_First;
    when Constraint_Error => raise Invalid_Date_Format with "Date_Str='" & Date_Str & "' time_str='" & Time_Str & "'" ;  --     chg-25546
  end To_Time_Type;

  function TO_TIME (DATE: in CALENDAR.TIME) return TIME_TYPE is
    SECONDS_TIMES_1000: INTEGER_4 := INTEGER_4 (FLOAT_4 (
                                     CALENDAR.SECONDS (DATE)) * 1000.0);
    SECONDS           : INTEGER_4 := SECONDS_TIMES_1000 / 1000;
  begin
    if SECONDS_TIMES_1000 = 86_400_000 then	    --v8.1
      SECONDS_TIMES_1000 := SECONDS_TIMES_1000 - 1; --v8.1
      SECONDS := SECONDS_TIMES_1000 / 1000;         --v8.1
    end if;                                         --v8.1

    return (YEAR   => YEAR_TYPE (CALENDAR.YEAR (DATE)),
            MONTH  => MONTH_TYPE (CALENDAR.MONTH (DATE)),
            DAY    => DAY_TYPE (CALENDAR.DAY (DATE)),
            HOUR   => HOUR_TYPE (SECONDS / SECONDS_PER_HOUR),
            MINUTE => MINUTE_TYPE ((SECONDS rem SECONDS_PER_HOUR) 
                                    / SECONDS_PER_MINUTE),
            SECOND => SECOND_TYPE ((SECONDS rem SECONDS_PER_HOUR) 
                                    rem SECONDS_PER_MINUTE),
            MILLISECOND => MILLISECOND_TYPE (SECONDS_TIMES_1000 rem 1000));
  end TO_TIME;


  function TO_CALENDAR_TIME (DATE: in TIME_TYPE) return CALENDAR.TIME is
    TIME: CALENDAR.DAY_DURATION;
    -- V5.2
    -- Constants TMP_1 and TMP_2 has been inserted in order to get around
    -- a bug in Alsys Ada version 5.2 on AIX.
    --
    TMP_1 : constant INTEGER_4 := INTEGER_4(DATE.HOUR) * SECONDS_PER_HOUR;
    TMP_2 : constant INTEGER_4 := INTEGER_4 (DATE.MINUTE) * SECONDS_PER_MINUTE;
  begin
--  TIME := CALENDAR.DAY_DURATION (INTEGER_4 (DATE.HOUR) * SECONDS_PER_HOUR) + 
    TIME := CALENDAR.DAY_DURATION(TMP_1) +

--          CALENDAR.DAY_DURATION (INTEGER_4 (DATE.MINUTE) * SECONDS_PER_MINUTE) + 
            CALENDAR.DAY_DURATION (TMP_2) +

            CALENDAR.DAY_DURATION (DATE.SECOND) + 

            CALENDAR.DAY_DURATION (DATE.MILLISECOND) / 1000;

    return CALENDAR.TIME_OF (CALENDAR.YEAR_NUMBER (DATE.YEAR),
			     CALENDAR.MONTH_NUMBER (DATE.MONTH),
			     CALENDAR.DAY_NUMBER (DATE.DAY), TIME);
  end TO_CALENDAR_TIME;


  function TO_TIME (YEAR       : in YEAR_TYPE;
                    YEAR_DAY   : in YEAR_DAY_TYPE;
                    HOUR       : in HOUR_TYPE;
                    MINUTE     : in MINUTE_TYPE;
                    SECOND     : in SECOND_TYPE;
                    MILLISECOND: in MILLISECOND_TYPE) return TIME_TYPE is
  DATE_TIME : TIME_TYPE;
  begin
    if not IS_LEGAL (YEAR, YEAR_DAY) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    TO_MONTH_AND_DAY (YEAR, YEAR_DAY, DATE_TIME.MONTH, DATE_TIME.DAY);
    DATE_TIME.YEAR        := YEAR;
    DATE_TIME.HOUR        := HOUR;
    DATE_TIME.MINUTE      := MINUTE;
    DATE_TIME.SECOND      := SECOND;
    DATE_TIME.MILLISECOND := MILLISECOND;
    return DATE_TIME;
  end TO_TIME;

  -- v8.2
  function TO_TIME (YEAR       : in YEAR_TYPE;
                    WEEK       : in WEEK_TYPE;
                    DAY        : in WEEK_DAY_TYPE;
                    HOUR       : in HOUR_TYPE   := HOUR_TYPE'FIRST;
                    MINUTE     : in MINUTE_TYPE := MINUTE_TYPE'FIRST;
                    SECOND     : in SECOND_TYPE := SECOND_TYPE'FIRST;
                    MILLISECOND: in MILLISECOND_TYPE := MILLISECOND_TYPE'FIRST) 
                                    return TIME_TYPE is
    DECODE_DAY        : INTEGER_2 := WEEK_DAY_TYPE'POS(DAY) + 1;
    END_OF_FIRST_WEEK : YEAR_DAY_TYPE;
    FIRST_WEEK_DAY    : WEEK_DAY_TYPE;   
    MY_YEAR           : YEAR_TYPE;
    MY_JULIAN_DATE    : YEAR_DAY_TYPE;
    TMP_JULIAN_DATE   : INTEGER_2;

  begin

     MY_YEAR := YEAR;
     FIRST_WEEK_DAY := WEEK_DAY_OF(MY_YEAR, 1, 1);

     END_OF_FIRST_WEEK := YEAR_DAY_TYPE(7 - WEEK_DAY_TYPE'POS(FIRST_WEEK_DAY));

     if WEEK = 1 then  -- First week of the year needs special treatment

       if FIRST_WEEK_DAY > THURSDAY then
           --text_io.put_line("1/1 of this year belongs to last years last week 52 or 53");
           MY_JULIAN_DATE := DECODE_DAY + END_OF_FIRST_WEEK;
       elsif DECODE_DAY < WEEK_DAY_TYPE'POS(FIRST_WEEK_DAY) + 1 then 
           --text_io.put_line("1/1 of this year belongs to this years week one but date is last year");
           MY_YEAR := MY_YEAR - 1;
           MY_JULIAN_DATE := YEAR_DAY_OF(MY_YEAR,12,31) - 
                        (WEEK_DAY_TYPE'POS(FIRST_WEEK_DAY) - DECODE_DAY);
       else
         --text_io.put_line("1/1 of this year belongs to this years week one and date is this year");
           MY_JULIAN_DATE := DECODE_DAY - WEEK_DAY_TYPE'POS(FIRST_WEEK_DAY);
       end if;

     else              --week=in the middle of the year              

       if FIRST_WEEK_DAY > THURSDAY then  -- 1/1 belongs to week 52 or 53 of previous year
          TMP_JULIAN_DATE := (WEEK - 1) * 7 + DECODE_DAY + END_OF_FIRST_WEEK;
       else  -- 1/1 belongs to week 1 this year              
          TMP_JULIAN_DATE := (WEEK - 2) * 7 + DECODE_DAY + END_OF_FIRST_WEEK;
       end if;

          -- If last week of this year is in next year
       if TMP_JULIAN_DATE > DAYS_IN (MY_YEAR) then
          MY_JULIAN_DATE := TMP_JULIAN_DATE - DAYS_IN (MY_YEAR);
          MY_YEAR := MY_YEAR + 1;
       else
          MY_JULIAN_DATE := TMP_JULIAN_DATE;
       end if;
     
     end if;         
     return TO_TIME(MY_YEAR, MY_JULIAN_DATE, HOUR, MINUTE, SECOND, MILLISECOND);
  end TO_TIME;


  function "<"  (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN is
  begin
    if LEFT.YEAR /= RIGHT.YEAR then
      return (LEFT.YEAR < RIGHT.YEAR);
    elsif LEFT.MONTH /= RIGHT.MONTH then
      return (LEFT.MONTH < RIGHT.MONTH);
    elsif LEFT.DAY /= RIGHT.DAY then
      return (LEFT.DAY < RIGHT.DAY);
    elsif LEFT.HOUR /= RIGHT.HOUR then
      return (LEFT.HOUR < RIGHT.HOUR);
    elsif LEFT.MINUTE /= RIGHT.MINUTE then
      return (LEFT.MINUTE < RIGHT.MINUTE);
    elsif LEFT.SECOND /= RIGHT.SECOND then
      return (LEFT.SECOND < RIGHT.SECOND);
    elsif LEFT.MILLISECOND /= RIGHT.MILLISECOND then
      return (LEFT.MILLISECOND < RIGHT.MILLISECOND);
    else
      return FALSE;
    end if;
  end "<";


  function "<=" (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN is
  begin
    if LEFT.YEAR /= RIGHT.YEAR then
      return (LEFT.YEAR < RIGHT.YEAR);
    elsif LEFT.MONTH /= RIGHT.MONTH then
      return (LEFT.MONTH < RIGHT.MONTH);
    elsif LEFT.DAY /= RIGHT.DAY then
      return (LEFT.DAY < RIGHT.DAY);
    elsif LEFT.HOUR /= RIGHT.HOUR then
      return (LEFT.HOUR < RIGHT.HOUR);
    elsif LEFT.MINUTE /= RIGHT.MINUTE then
      return (LEFT.MINUTE < RIGHT.MINUTE);
    elsif LEFT.SECOND /= RIGHT.SECOND then
      return (LEFT.SECOND < RIGHT.SECOND);
    elsif LEFT.MILLISECOND /= RIGHT.MILLISECOND then
      return (LEFT.MILLISECOND < RIGHT.MILLISECOND);
    else
      return TRUE;
    end if;
  end "<=";

--

  function ">"  (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN is
  begin
    if LEFT.YEAR /= RIGHT.YEAR then
      return (LEFT.YEAR > RIGHT.YEAR);
    elsif LEFT.MONTH /= RIGHT.MONTH then
      return (LEFT.MONTH > RIGHT.MONTH);
    elsif LEFT.DAY /= RIGHT.DAY then
      return (LEFT.DAY > RIGHT.DAY);
    elsif LEFT.HOUR /= RIGHT.HOUR then
      return (LEFT.HOUR > RIGHT.HOUR);
    elsif LEFT.MINUTE /= RIGHT.MINUTE then
      return (LEFT.MINUTE > RIGHT.MINUTE);
    elsif LEFT.SECOND /= RIGHT.SECOND then
      return (LEFT.SECOND > RIGHT.SECOND);
    elsif LEFT.MILLISECOND /= RIGHT.MILLISECOND then
      return (LEFT.MILLISECOND > RIGHT.MILLISECOND);
    else
      return FALSE;
    end if;
  end ">";

--

  function ">=" (LEFT, RIGHT: in TIME_TYPE) return BOOLEAN is
  begin
    if LEFT.YEAR /= RIGHT.YEAR then
      return (LEFT.YEAR > RIGHT.YEAR);
    elsif LEFT.MONTH /= RIGHT.MONTH then
      return (LEFT.MONTH > RIGHT.MONTH);
    elsif LEFT.DAY /= RIGHT.DAY then
      return (LEFT.DAY > RIGHT.DAY);
    elsif LEFT.HOUR /= RIGHT.HOUR then
      return (LEFT.HOUR > RIGHT.HOUR);
    elsif LEFT.MINUTE /= RIGHT.MINUTE then
      return (LEFT.MINUTE > RIGHT.MINUTE);
    elsif LEFT.SECOND /= RIGHT.SECOND then
      return (LEFT.SECOND > RIGHT.SECOND);
    elsif LEFT.MILLISECOND /= RIGHT.MILLISECOND then
      return (LEFT.MILLISECOND > RIGHT.MILLISECOND);
    else
      return TRUE;
    end if;
  end ">=";

--

  function "<"  (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN is
  begin
    if LEFT.DAYS /= RIGHT.DAYS then
      return (LEFT.DAYS < RIGHT.DAYS);
    elsif LEFT.HOURS /= RIGHT.HOURS then
      return (LEFT.HOURS < RIGHT.HOURS);
    elsif LEFT.MINUTES /= RIGHT.MINUTES then
      return (LEFT.MINUTES < RIGHT.MINUTES);
    elsif LEFT.SECONDS /= RIGHT.SECONDS then
      return (LEFT.SECONDS < RIGHT.SECONDS);
    elsif LEFT.MILLISECONDS /= RIGHT.MILLISECONDS then
      return (LEFT.MILLISECONDS < RIGHT.MILLISECONDS);
    else
      return FALSE;
    end if;
  end "<";

--

  function "<=" (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN is
  begin
    if LEFT.DAYS /= RIGHT.DAYS then
      return (LEFT.DAYS < RIGHT.DAYS);
    elsif LEFT.HOURS /= RIGHT.HOURS then
      return (LEFT.HOURS < RIGHT.HOURS);
    elsif LEFT.MINUTES /= RIGHT.MINUTES then
      return (LEFT.MINUTES < RIGHT.MINUTES);
    elsif LEFT.SECONDS /= RIGHT.SECONDS then
      return (LEFT.SECONDS < RIGHT.SECONDS);
    elsif LEFT.MILLISECONDS /= RIGHT.MILLISECONDS then
      return (LEFT.MILLISECONDS < RIGHT.MILLISECONDS);
    else
      return TRUE;
    end if;
  end "<=";

--

  function ">"  (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN is
  begin
    if LEFT.DAYS /= RIGHT.DAYS then
      return (LEFT.DAYS > RIGHT.DAYS);
    elsif LEFT.HOURS /= RIGHT.HOURS then
      return (LEFT.HOURS > RIGHT.HOURS);
    elsif LEFT.MINUTES /= RIGHT.MINUTES then
      return (LEFT.MINUTES > RIGHT.MINUTES);
    elsif LEFT.SECONDS /= RIGHT.SECONDS then
      return (LEFT.SECONDS > RIGHT.SECONDS);
    elsif LEFT.MILLISECONDS /= RIGHT.MILLISECONDS then
      return (LEFT.MILLISECONDS > RIGHT.MILLISECONDS);
    else
      return FALSE;
    end if;
  end ">";

--

  function ">=" (LEFT, RIGHT: in INTERVAL_TYPE) return BOOLEAN is
  begin
    if LEFT.DAYS /= RIGHT.DAYS then
      return (LEFT.DAYS > RIGHT.DAYS);
    elsif LEFT.HOURS /= RIGHT.HOURS then
      return (LEFT.HOURS > RIGHT.HOURS);
    elsif LEFT.MINUTES /= RIGHT.MINUTES then
      return (LEFT.MINUTES > RIGHT.MINUTES);
    elsif LEFT.SECONDS /= RIGHT.SECONDS then
      return (LEFT.SECONDS > RIGHT.SECONDS);
    elsif LEFT.MILLISECONDS /= RIGHT.MILLISECONDS then
      return (LEFT.MILLISECONDS > RIGHT.MILLISECONDS);
    else
      return TRUE;
    end if;
  end ">=";


-- V6.2 Removed
--  function TO_INTERVAL (DAY_DURATION: in CALENDAR.DAY_DURATION) return INTERVAL_TYPE is
--    SECONDS_TIMES_1000: INTEGER_4 := INTEGER_4 ( 
--                                      FLOAT_4 (DAY_DURATION) * 1000.0);
--    SECONDS           : INTEGER_4 := SECONDS_TIMES_1000 / 1000;
--  begin
--    return (DAYS    => 0,
--            HOURS   => HOUR_TYPE (SECONDS / SECONDS_PER_HOUR),
--            MINUTES => MINUTE_TYPE ((SECONDS rem SECONDS_PER_HOUR) 
--                                     / SECONDS_PER_MINUTE),
--            SECONDS => SECOND_TYPE ((SECONDS rem SECONDS_PER_HOUR) 
--                                     rem SECONDS_PER_MINUTE),
--            MILLISECONDS => MILLISECOND_TYPE (SECONDS_TIMES_1000 rem 1000));
--  end TO_INTERVAL;


-- V6.2 Replaces TO_INTERVAL above
  function TO_INTERVAL (DAY_DURATION: in CALENDAR.DAY_DURATION) return INTERVAL_TYPE is
    HOURS        : INTEGER_4;
    MINUTES      : INTEGER_4;
    SECONDS      : INTEGER_4;
    MILLISECONDS : INTEGER_4 := INTEGER_4(FLOAT_8(DAY_DURATION)*1000.0);
  begin

    if (MILLISECONDS = 86_400_000) then
      --
      -- Special case. 24:00:00.000 is not a legal time. The user has probably
      -- used CALENDAR.DAY_DURATION'LAST. We therefore substract one msec
      -- to get 23:59:59.999 instead.
      --
      MILLISECONDS := MILLISECONDS - 1;
    end if;

    HOURS        := MILLISECONDS / 3_600_000;
    MILLISECONDS := MILLISECONDS - HOURS*3_600_000;    

    MINUTES      := MILLISECONDS / 60_000;
    MILLISECONDS := MILLISECONDS - MINUTES*60_000;

    SECONDS      := MILLISECONDS / 1_000;
    MILLISECONDS := MILLISECONDS - SECONDS*1_000;

    return (DAYS         => 0,
            HOURS        => HOUR_TYPE(HOURS),
            MINUTES      => MINUTE_TYPE(MINUTES),
            SECONDS      => SECOND_TYPE(SECONDS),
            MILLISECONDS => MILLISECOND_TYPE(MILLISECONDS));
  end TO_INTERVAL;

  -- v8.2
  function TO_INTERVAL (SECONDS  : in SECONDS_TYPE)  return INTERVAL_TYPE is
    SECONDS_LEFT  : SECONDS_TYPE := 0;
    TIME_INTERVAL : SATTMATE_CALENDAR.INTERVAL_TYPE := (0,0,0,0,0);
  begin
    TIME_INTERVAL.DAYS    := SECONDS/SECONDS_PER_DAY;
    SECONDS_LEFT          := SECONDS - TIME_INTERVAL.DAYS*SECONDS_PER_DAY;
    TIME_INTERVAL.HOURS   := INTEGER_2(SECONDS_LEFT/SECONDS_PER_HOUR);
    SECONDS_LEFT          := SECONDS_LEFT - 
                             INTEGER_4(TIME_INTERVAL.HOURS)*SECONDS_PER_HOUR;
    TIME_INTERVAL.MINUTES := INTEGER_2(SECONDS_LEFT/SECONDS_PER_MINUTE);
    TIME_INTERVAL.SECONDS := INTEGER_2(SECONDS_LEFT) - 
                             TIME_INTERVAL.MINUTES*INTEGER_2(SECONDS_PER_MINUTE);
    return TIME_INTERVAL;
  end TO_INTERVAL;
  -- v8.2
  function TO_SECONDS  (INTERVAL : in INTERVAL_TYPE) return SECONDS_TYPE is
  begin
    return INTERVAL.DAYS               * SECONDS_PER_DAY    + 
           INTEGER_4(INTERVAL.HOURS)   * SECONDS_PER_HOUR   +
           INTEGER_4(INTERVAL.MINUTES) * SECONDS_PER_MINUTE + 
           INTEGER_4(INTERVAL.SECONDS);
  end TO_SECONDS;

  function TO_DAY_DURATION (INTERVAL: in INTERVAL_TYPE)
    return CALENDAR.DAY_DURATION is
  -- This function does not use the term DAYS.
  begin
    return CALENDAR.DAY_DURATION (
           INTEGER_4 (INTERVAL.HOURS) * SECONDS_PER_HOUR + 

	   INTEGER_4 (INTERVAL.MINUTES) * SECONDS_PER_MINUTE) + 

	   CALENDAR.DAY_DURATION (INTERVAL.SECONDS) +

	   CALENDAR.DAY_DURATION (INTERVAL.MILLISECONDS) / 1000; 
  end TO_DAY_DURATION;

--

  function ADD_DAYS (LEFT : in INTERVAL_TYPE; RIGHT : in INTERVAL_DAY_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS + RIGHT,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      raise TIME_ERROR;
  end ADD_DAYS;
    
  function ADD_HOURS (LEFT : in INTERVAL_TYPE; RIGHT : in HOUR_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS + RIGHT,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_DAYS
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS + RIGHT - 24,
                               LEFT.MINUTES,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS), 1);
  end ADD_HOURS;
    
  function ADD_MINUTES (LEFT : in INTERVAL_TYPE; RIGHT : in MINUTE_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES + RIGHT,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_HOURS 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES + RIGHT - 60,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS), 1);
  end ADD_MINUTES;

  function ADD_SECONDS (LEFT  : in INTERVAL_TYPE; 
                             RIGHT : in SECOND_TYPE) return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS + RIGHT,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_MINUTES 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES,
                               LEFT.SECONDS + RIGHT - 60,
                               LEFT.MILLISECONDS), 1);
  end ADD_SECONDS;

  function ADD_MILLISECONDS (LEFT : in INTERVAL_TYPE; RIGHT : in MILLISECOND_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS + RIGHT);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_SECONDS 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS + RIGHT - 1000), 1);
  end ADD_MILLISECONDS;




  function SUBTRACT_DAYS (LEFT : in INTERVAL_TYPE; RIGHT : in INTERVAL_DAY_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS - RIGHT,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      raise TIME_ERROR;
  end SUBTRACT_DAYS;
    
  function SUBTRACT_HOURS (LEFT : in INTERVAL_TYPE; RIGHT : in HOUR_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS - RIGHT,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_DAYS
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS - RIGHT + 24,
                               LEFT.MINUTES,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS), 1);
  end SUBTRACT_HOURS;
    
  function SUBTRACT_MINUTES (LEFT : in INTERVAL_TYPE; RIGHT : in MINUTE_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES - RIGHT,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_HOURS 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES - RIGHT + 60,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS), 1);
  end SUBTRACT_MINUTES;

  function SUBTRACT_SECONDS (LEFT  : in INTERVAL_TYPE; 
                             RIGHT : in SECOND_TYPE) return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS - RIGHT,
                          LEFT.MILLISECONDS);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_MINUTES 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES,
                               LEFT.SECONDS - RIGHT + 60,
                               LEFT.MILLISECONDS), 1);
  end SUBTRACT_SECONDS;

  function SUBTRACT_MILLISECONDS (LEFT : in INTERVAL_TYPE; RIGHT : in MILLISECOND_TYPE) 
                return INTERVAL_TYPE is
  begin
    return INTERVAL_TYPE'(LEFT.DAYS,
                          LEFT.HOURS,
                          LEFT.MINUTES,
                          LEFT.SECONDS,
                          LEFT.MILLISECONDS - RIGHT);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_SECONDS 
               (INTERVAL_TYPE'(LEFT.DAYS,
                               LEFT.HOURS,
                               LEFT.MINUTES,
                               LEFT.SECONDS,
                               LEFT.MILLISECONDS - RIGHT + 1000), 1);
  end SUBTRACT_MILLISECONDS;






  function ADD_DAYS (LEFT : in TIME_TYPE; RIGHT : in INTERVAL_DAY_TYPE) 
                return TIME_TYPE is
    RESULT : TIME_TYPE         := LEFT;
    DAYS   : INTERVAL_DAY_TYPE := RIGHT + INTERVAL_DAY_TYPE (LEFT.DAY);
  begin
    while DAYS > INTERVAL_DAY_TYPE (DAYS_IN (RESULT.YEAR, RESULT.MONTH)) loop
      DAYS := DAYS - INTERVAL_DAY_TYPE (DAYS_IN (RESULT.YEAR, RESULT.MONTH));
      if RESULT.MONTH = 12 then
        if RESULT.YEAR = YEAR_TYPE'LAST then
          raise TIME_ERROR;
        end if;
        RESULT.MONTH := 1;
        RESULT.YEAR := RESULT.YEAR + 1;
      else
        RESULT.MONTH := RESULT.MONTH + 1;
      end if;
    end loop;
    RESULT.DAY := DAY_TYPE (DAYS);
    return RESULT;
  end ADD_DAYS;
    
  function ADD_HOURS (LEFT : in TIME_TYPE; RIGHT : in HOUR_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR + RIGHT,
                      LEFT.MINUTE,
                      LEFT.SECOND,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_DAYS
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR + RIGHT - 24,
                           LEFT.MINUTE,
                           LEFT.SECOND,
                           LEFT.MILLISECOND), 1);
  end ADD_HOURS;
    
  function ADD_MINUTES (LEFT : in TIME_TYPE; RIGHT : in MINUTE_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE + RIGHT,
                      LEFT.SECOND,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_HOURS 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE + RIGHT - 60,
                           LEFT.SECOND,
                           LEFT.MILLISECOND), 1);
  end ADD_MINUTES;

  function ADD_SECONDS (LEFT  : in TIME_TYPE; 
                             RIGHT : in SECOND_TYPE) return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE,
                      LEFT.SECOND + RIGHT,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_MINUTES 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE,
                           LEFT.SECOND + RIGHT - 60,
                           LEFT.MILLISECOND), 1);
  end ADD_SECONDS;

  function ADD_MILLISECONDS (LEFT : in TIME_TYPE; RIGHT : in MILLISECOND_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE,
                      LEFT.SECOND,
                      LEFT.MILLISECOND + RIGHT);
  exception
    when CONSTRAINT_ERROR =>
      return ADD_SECONDS 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE,
                           LEFT.SECOND,
                           LEFT.MILLISECOND + RIGHT - 1000), 1);
  end ADD_MILLISECONDS;





  function SUBTRACT_DAYS (LEFT : in TIME_TYPE; RIGHT : in INTERVAL_DAY_TYPE) 
                return TIME_TYPE is
    RESULT : TIME_TYPE         := LEFT;
    DAYS   : INTERVAL_DAY_TYPE := RIGHT;
  begin
    while DAYS >= INTERVAL_DAY_TYPE (RESULT.DAY) loop
      DAYS := DAYS - INTERVAL_DAY_TYPE (RESULT.DAY);
      if RESULT.MONTH = 1 then
        if RESULT.YEAR = YEAR_TYPE'FIRST then
          raise TIME_ERROR;
        end if;
        RESULT.MONTH := 12;
        RESULT.YEAR := RESULT.YEAR - 1;
      else
        RESULT.MONTH := RESULT.MONTH - 1;
      end if;
      RESULT.DAY := DAYS_IN (RESULT.YEAR, RESULT.MONTH);
    end loop;
    RESULT.DAY := DAY_TYPE (INTERVAL_DAY_TYPE (RESULT.DAY) - DAYS);
    return RESULT;
  end SUBTRACT_DAYS;
    
  function SUBTRACT_HOURS (LEFT : in TIME_TYPE; RIGHT : in HOUR_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR - RIGHT,
                      LEFT.MINUTE,
                      LEFT.SECOND,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_DAYS
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR - RIGHT + 24,
                           LEFT.MINUTE,
                           LEFT.SECOND,
                           LEFT.MILLISECOND), 1);
  end SUBTRACT_HOURS;
    
  function SUBTRACT_MINUTES (LEFT : in TIME_TYPE; RIGHT : in MINUTE_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE - RIGHT,
                      LEFT.SECOND,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_HOURS 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE - RIGHT + 60,
                           LEFT.SECOND,
                           LEFT.MILLISECOND), 1);
  end SUBTRACT_MINUTES;

  function SUBTRACT_SECONDS (LEFT  : in TIME_TYPE; 
                             RIGHT : in SECOND_TYPE) return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE,
                      LEFT.SECOND - RIGHT,
                      LEFT.MILLISECOND);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_MINUTES 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE,
                           LEFT.SECOND - RIGHT + 60,
                           LEFT.MILLISECOND), 1);
  end SUBTRACT_SECONDS;

  function SUBTRACT_MILLISECONDS (LEFT : in TIME_TYPE; RIGHT : in MILLISECOND_TYPE) 
                return TIME_TYPE is
  begin
    return TIME_TYPE'(LEFT.YEAR,
                      LEFT.MONTH,
                      LEFT.DAY,
                      LEFT.HOUR,
                      LEFT.MINUTE,
                      LEFT.SECOND,
                      LEFT.MILLISECOND - RIGHT);
  exception
    when CONSTRAINT_ERROR =>
      return SUBTRACT_SECONDS 
               (TIME_TYPE'(LEFT.YEAR,
                           LEFT.MONTH,
                           LEFT.DAY,
                           LEFT.HOUR,
                           LEFT.MINUTE,
                           LEFT.SECOND,
                           LEFT.MILLISECOND - RIGHT + 1000), 1);
  end SUBTRACT_MILLISECONDS;







  function "+" (LEFT: in TIME_TYPE; RIGHT: in INTERVAL_TYPE) return TIME_TYPE is
    RESULT : TIME_TYPE := LEFT;
  begin
    if not IS_LEGAL (LEFT) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    RESULT := ADD_MILLISECONDS (RESULT, RIGHT.MILLISECONDS);
    RESULT := ADD_SECONDS      (RESULT, RIGHT.SECONDS);
    RESULT := ADD_MINUTES      (RESULT, RIGHT.MINUTES);
    RESULT := ADD_HOURS        (RESULT, RIGHT.HOURS);
    RESULT := ADD_DAYS         (RESULT, RIGHT.DAYS);
    return RESULT;
  end "+";

--

  function "+" (LEFT: in INTERVAL_TYPE; RIGHT: in TIME_TYPE) return TIME_TYPE is
  begin
   return RIGHT + LEFT;
  end "+";

--

  function "+" (LEFT: in TIME_TYPE; RIGHT: in YEAR_DAY_TYPE) return TIME_TYPE is
  begin
    return ADD_DAYS (LEFT, INTERVAL_DAY_TYPE (RIGHT));
  end "+";

--

  function "+" (LEFT: in YEAR_DAY_TYPE; RIGHT: in TIME_TYPE) return TIME_TYPE is
  begin
    return RIGHT + LEFT;
  end "+";

--

  function "-" (LEFT, RIGHT: in TIME_TYPE) return INTERVAL_TYPE is
    RESULT : INTERVAL_TYPE := (DAYS         => 0,
                               HOURS        => LEFT.HOUR,
                               MINUTES      => LEFT.MINUTE,
                               SECONDS      => LEFT.SECOND,
                               MILLISECONDS => LEFT.MILLISECOND);
  begin
    if not IS_LEGAL (LEFT) or not IS_LEGAL (RIGHT) then
      raise IN_PARAMETER_INCORRECT;
    elsif LEFT < RIGHT then
--9.3-0085      raise TIME_ERROR;
      return INTERVAL_TYPE_FIRST;  --9.3-0085 
    end if;
    for YEAR_NUMBER in (RIGHT.YEAR + 1)..(LEFT.YEAR - 1) loop
      RESULT.DAYS := RESULT.DAYS + 
                     INTERVAL_DAY_TYPE (DAYS_IN (YEAR_NUMBER));
    end loop;

    if RIGHT.YEAR = LEFT.YEAR then
      for MONTH_NUMBER in (RIGHT.MONTH + 1)..(LEFT.MONTH - 1) loop
        RESULT.DAYS := RESULT.DAYS + 
                       INTERVAL_DAY_TYPE (DAYS_IN (LEFT.YEAR, MONTH_NUMBER));
      end loop;
    else
      for MONTH_NUMBER in (RIGHT.MONTH + 1)..MONTH_TYPE'LAST loop
        RESULT.DAYS := RESULT.DAYS + 
                       INTERVAL_DAY_TYPE (DAYS_IN (RIGHT.YEAR, MONTH_NUMBER));   -- v8.2b
--v8.2b                       INTERVAL_DAY_TYPE (DAYS_IN (LEFT.YEAR, MONTH_NUMBER));
      end loop;
      for MONTH_NUMBER in MONTH_TYPE'FIRST..(LEFT.MONTH-1) loop
        RESULT.DAYS := RESULT.DAYS + 
                       INTERVAL_DAY_TYPE (DAYS_IN (LEFT.YEAR, MONTH_NUMBER));
      end loop;
    end if;

    if RIGHT.YEAR  = LEFT.YEAR and then
       RIGHT.MONTH = LEFT.MONTH then
      RESULT.DAYS := RESULT.DAYS + 
                     INTERVAL_DAY_TYPE (LEFT.DAY) -
                     INTERVAL_DAY_TYPE (RIGHT.DAY );
    else
      RESULT.DAYS := RESULT.DAYS + 
                     INTERVAL_DAY_TYPE (
                     DAYS_IN (RIGHT.YEAR, RIGHT.MONTH) - RIGHT.DAY) +
                     INTERVAL_DAY_TYPE (LEFT.DAY);
    end if;

    RESULT := SUBTRACT_MILLISECONDS (RESULT, RIGHT.MILLISECOND);
    RESULT := SUBTRACT_SECONDS      (RESULT, RIGHT.SECOND);
    RESULT := SUBTRACT_MINUTES      (RESULT, RIGHT.MINUTE);
    RESULT := SUBTRACT_HOURS        (RESULT, RIGHT.HOUR);

    return RESULT;
  end "-";

--

  function "-" (LEFT: in TIME_TYPE; RIGHT: in INTERVAL_TYPE) return TIME_TYPE is
    RESULT : TIME_TYPE := LEFT;
  begin
    if not IS_LEGAL (LEFT) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    RESULT := SUBTRACT_MILLISECONDS (RESULT, RIGHT.MILLISECONDS);
    RESULT := SUBTRACT_SECONDS      (RESULT, RIGHT.SECONDS);
    RESULT := SUBTRACT_MINUTES      (RESULT, RIGHT.MINUTES);
    RESULT := SUBTRACT_HOURS        (RESULT, RIGHT.HOURS);
    RESULT := SUBTRACT_DAYS         (RESULT, RIGHT.DAYS);
    return RESULT;
  end "-";

--

  function "-" (LEFT: in TIME_TYPE; RIGHT: in YEAR_DAY_TYPE) return TIME_TYPE is
  begin
    return SUBTRACT_DAYS (LEFT, INTERVAL_DAY_TYPE (RIGHT));
  end "-";

--

  function "+" (LEFT, RIGHT: in INTERVAL_TYPE) return INTERVAL_TYPE is
    RESULT : INTERVAL_TYPE := LEFT;
  begin
    RESULT := ADD_MILLISECONDS (RESULT, RIGHT.MILLISECONDS);
    RESULT := ADD_SECONDS      (RESULT, RIGHT.SECONDS);
    RESULT := ADD_MINUTES      (RESULT, RIGHT.MINUTES);
    RESULT := ADD_HOURS        (RESULT, RIGHT.HOURS);
    RESULT := ADD_DAYS         (RESULT, RIGHT.DAYS);
    return RESULT;
  end "+";

--

  function "-" (LEFT, RIGHT : in INTERVAL_TYPE) return INTERVAL_TYPE is 
    RESULT : INTERVAL_TYPE := LEFT;
  begin
    RESULT := SUBTRACT_MILLISECONDS (RESULT, RIGHT.MILLISECONDS);
    RESULT := SUBTRACT_SECONDS      (RESULT, RIGHT.SECONDS);
    RESULT := SUBTRACT_MINUTES      (RESULT, RIGHT.MINUTES);
    RESULT := SUBTRACT_HOURS        (RESULT, RIGHT.HOURS);
    RESULT := SUBTRACT_DAYS         (RESULT, RIGHT.DAYS);
    return RESULT;
  end "-";

--

  function IS_LEAP_YEAR (YEAR: in YEAR_TYPE) return BOOLEAN is
  begin
    if YEAR mod 100 = 0 then
      return YEAR mod 400 = 0;
    else
      return YEAR mod 4 = 0;
    end if;
  end IS_LEAP_YEAR;

--

  function YEAR_DAY_OF (DATE : in TIME_TYPE) return YEAR_DAY_TYPE is
  begin
    return YEAR_DAY_OF (DATE.YEAR, DATE.MONTH, DATE.DAY);
  end YEAR_DAY_OF;

--

  function YEAR_DAY_OF (YEAR : in YEAR_TYPE;
                        MONTH: in MONTH_TYPE;
                        DAY  : in DAY_TYPE) return YEAR_DAY_TYPE is
    CUMULATIVE_DAYS : YEAR_DAY_TYPE := YEAR_DAY_TYPE (DAY);
  begin
    if not IS_LEGAL (YEAR, MONTH, DAY) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    for MONTH_NUMBER in MONTH_TYPE'FIRST..(MONTH-1) loop
      CUMULATIVE_DAYS := CUMULATIVE_DAYS + YEAR_DAY_TYPE (
                                           DAYS_IN (YEAR, MONTH_NUMBER));
    end loop;
    return CUMULATIVE_DAYS;
  end YEAR_DAY_OF;

--

  function DAYS_IN (YEAR: in YEAR_TYPE) return YEAR_DAY_TYPE is
  begin
    if IS_LEAP_YEAR (YEAR) then
      return 366;
    else
      return 365;
    end if;
  end DAYS_IN;

--

  function DAYS_IN (YEAR     : in YEAR_TYPE;
                    MONTH    : in MONTH_TYPE) return DAY_TYPE is
  begin
    if IS_LEAP_YEAR (YEAR) and MONTH = 2 then
      return 29;
    else
      return MONTH_DAY (MONTH);
    end if;
  end DAYS_IN;

--

  function WEEK_DAY_OF (DATE : in TIME_TYPE) return WEEK_DAY_TYPE is
  begin
    return WEEK_DAY_OF (DATE.YEAR, DATE.MONTH, DATE.DAY);
  end WEEK_DAY_OF;

--

  function WEEK_DAY_OF (YEAR : in YEAR_TYPE;
                        MONTH: in MONTH_TYPE;
                        DAY  : in DAY_TYPE) return WEEK_DAY_TYPE is
  -- For every non leap year that elapses from a given date the week day
  -- is modified by one (365 days = 52 weeks of seven days + 1 day).
  -- Leap years modifies the week day by two. 
  -- Our reference point in time is 31/12 1899, that happened to be a
  -- Sunday. From this point the number of modifications to the week-day
  -- is calculated. The calculated value modulus seven gives 
  -- the offset from Sunday to the current week-day.
    THE_ELAPSED_YEARS : constant INTEGER_2 := INTEGER_2 (YEAR) - 1900;
    ADJUSTMENT        : INTEGER_2 := 
                      ((THE_ELAPSED_YEARS  - 1) / 4 + THE_ELAPSED_YEARS +
                        INTEGER_2(YEAR_DAY_OF(YEAR, MONTH, DAY))) mod 7;
  begin
    if not IS_LEGAL (YEAR, MONTH, DAY) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    if ADJUSTMENT = 0 then
      ADJUSTMENT := 7;
    end if;
    return WEEK_DAY_TYPE'VAL (ADJUSTMENT-1);
  end WEEK_DAY_OF;

--

  function WEEK_OF (DATE: in TIME_TYPE) return WEEK_TYPE is
  -- This version only works for the ISO R-2015 standard for week-numbers.
  begin
    return WEEK_OF (DATE.YEAR, YEAR_DAY_OF (DATE.YEAR, DATE.MONTH, DATE.DAY));
  end WEEK_OF;

--

  function WEEK_OF (YEAR     : in YEAR_TYPE;
                    MONTH    : in MONTH_TYPE;
                    DAY      : in DAY_TYPE) return WEEK_TYPE is
  -- This version only works for the ISO R-2015 standard for week-numbers.
  begin
    return WEEK_OF (YEAR, YEAR_DAY_OF (YEAR, MONTH, DAY));
  end WEEK_OF;

--

  function WEEK_OF (YEAR     : in YEAR_TYPE;
		    YEAR_DAY : in YEAR_DAY_TYPE) return WEEK_TYPE is
  -- This version of only works for the ISO R-2015 standard for week-numbers.
  -- This standard dates back to 30 June, 1972.

  -- According to ISO R-2015 the first week of a year containing a Thursday
  -- is labeled week one. This definition makes calculation of week numbers
  -- a bit tricky. Observe also that there is room for some ambiguity since
  -- dates at both the start and end of a year might belong to week one or
  -- week fifty-three.
    FIRST_WEEK_DAY     : constant WEEK_DAY_TYPE := WEEK_DAY_OF (YEAR, 1, 1);
    END_OF_FIRST_WEEK  : constant YEAR_DAY_TYPE := 
                                  YEAR_DAY_TYPE (7 - 
                                  WEEK_DAY_TYPE'POS (FIRST_WEEK_DAY));
    LAST_WEEK_DAY      : constant WEEK_DAY_TYPE := WEEK_DAY_OF (YEAR, 12, 31);
    START_OF_LAST_WEEK : constant YEAR_DAY_TYPE := DAYS_IN (YEAR) - 
                                  WEEK_DAY_TYPE'POS (LAST_WEEK_DAY);
  begin
    if not IS_LEGAL (YEAR, YEAR_DAY) then
      raise IN_PARAMETER_INCORRECT;
    end if;
    if YEAR_DAY >= START_OF_LAST_WEEK and then LAST_WEEK_DAY < THURSDAY then
      -- Year_Day belongs to the last week of the year and this week
      -- is numbered one since Thursday is part of the next year.  
      return 1;
    elsif FIRST_WEEK_DAY > THURSDAY then
      -- The first day of Year does not belong to week one since Thursday
      -- of this week is part of the previous year.
      if YEAR_DAY <= END_OF_FIRST_WEEK then
        -- Year_Day belongs to this week.
        return WEEK_OF (YEAR - 1, 12, 31);
      else
        -- Year_Day does not belong to this week.
        return WEEK_TYPE ((YEAR_DAY - END_OF_FIRST_WEEK - 1) / 7 + 1);
      end if;
    else
      -- The first day of the year is part of week one.
      return WEEK_TYPE (
            (YEAR_DAY + WEEK_DAY_TYPE'POS (FIRST_WEEK_DAY) - 1) / 7 + 1);
    end if;
  end WEEK_OF;


  function STRING_DATE (DATE : in TIME_TYPE) return STRING is
    function MONTH_NAME (MONTH : in MONTH_TYPE) return STRING is
    begin
      case MONTH is
        when  1 => return "Jan";
        when  2 => return "Feb";
        when  3 => return "Mar";
        when  4 => return "Apr";
        when  5 => return "May";
        when  6 => return "Jun";
        when  7 => return "Jul";
        when  8 => return "Aug";
        when  9 => return "Sep";
        when 10 => return "Oct";
        when 11 => return "Nov";
        when 12 => return "Dec";
--        when others => return "   ";
      end case;
    end MONTH_NAME;
  begin
    declare
      DATE_STRING: STRING (1..11) := "dd-mmm-yyyy";
    begin
      INTEGER_2_IO.PUT (DATE_STRING (1..2), DATE.DAY);
                        DATE_STRING (4..6) := MONTH_NAME (DATE.MONTH);
      INTEGER_2_IO.PUT (DATE_STRING (8..11), DATE.YEAR);
      if DATE_STRING (1) = ' ' then DATE_STRING (1) := '0'; end if;
      return DATE_STRING;
    end;
  end STRING_DATE;


  function STRING_TIME 
           (DATE         : in TIME_TYPE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING is
    RESULT : STRING (1..12) := (others => ' ');
    CURR   : POSITIVE := RESULT'FIRST;
  begin
    if HOURS then
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), DATE.HOUR);
      CURR := CURR + 2;
    end if;
    if MINUTES then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := ':';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), DATE.MINUTE);
      CURR := CURR + 2;
    end if;
    if SECONDS then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := ':';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), DATE.SECOND);
      CURR := CURR + 2;
    end if;
    if MILLISECONDS then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := '.';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 2), DATE.MILLISECOND);
      CURR := CURR + 3;
    end if;
    for I in RESULT'FIRST..CURR - 1 loop
      if RESULT (I) = ' ' then RESULT (I) := '0'; end if;
    end loop;
    return RESULT (RESULT'FIRST..CURR-1);
  end STRING_TIME;


  function STRING_DATE_AND_TIME 
           (DATE         : in TIME_TYPE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := FALSE) return STRING is
  begin
    return STRING_DATE (DATE) & " " & 
           STRING_TIME (DATE, HOURS, MINUTES, SECONDS, MILLISECONDS);
  end STRING_DATE_AND_TIME;

--9.6-11859 start
--  function STRING_DATE (DATE : in CALENDAR.TIME := CALENDAR.CLOCK) 
  function STRING_DATE (DATE : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK)) 
                        return STRING is
  begin
    return STRING_DATE (TO_TIME (DATE));
  end STRING_DATE;


  function STRING_TIME 
--          (DATE         : in CALENDAR.TIME := CALENDAR.CLOCK;
          (DATE         : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK);
           HOURS        : in BOOLEAN := TRUE;
           MINUTES      : in BOOLEAN := TRUE;
           SECONDS      : in BOOLEAN := TRUE;
           MILLISECONDS : in BOOLEAN := FALSE) return STRING is
  begin
    return STRING_TIME (TO_TIME (DATE), HOURS, MINUTES, SECONDS, MILLISECONDS);
  end STRING_TIME;


  function STRING_DATE_AND_TIME 
--          (DATE         : in CALENDAR.TIME := CALENDAR.CLOCK;
          (DATE         : in CALENDAR.TIME := TO_CALENDAR_TIME(CLOCK);
           HOURS        : in BOOLEAN := TRUE;
           MINUTES      : in BOOLEAN := TRUE;
           SECONDS      : in BOOLEAN := TRUE;
           MILLISECONDS : in BOOLEAN := FALSE) return STRING is
  begin
    return STRING_DATE_AND_TIME 
           (TO_TIME (DATE), HOURS, MINUTES, SECONDS, MILLISECONDS);
  end STRING_DATE_AND_TIME;
--9.6-11859 stop

  function STRING_INTERVAL 
           (INTERVAL     : in INTERVAL_TYPE;
            DAYS         : in BOOLEAN := TRUE;
            HOURS        : in BOOLEAN := TRUE;
            MINUTES      : in BOOLEAN := TRUE;
            SECONDS      : in BOOLEAN := TRUE;
            MILLISECONDS : in BOOLEAN := TRUE) return STRING is
    RESULT : STRING (1..18) := (others => ' ');
    CURR   : NATURAL := RESULT'FIRST;
  begin
    if DAYS then
      INTEGER_4_IO.PUT (RESULT (CURR..CURR + 4), INTERVAL.DAYS);
      CURR := CURR + 5;
    end if;
    if HOURS then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := ':';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), INTERVAL.HOURS);
      CURR := CURR + 2;
    end if;
    if MINUTES then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := ':';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), INTERVAL.MINUTES);
      CURR := CURR + 2;
    end if;
    if SECONDS then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := ':';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 1), INTERVAL.SECONDS);
      CURR := CURR + 2;
    end if;
    if MILLISECONDS then
      if CURR /= RESULT'FIRST then
        RESULT (CURR) := '.';
        CURR := CURR + 1;
      end if;
      INTEGER_2_IO.PUT (RESULT (CURR..CURR + 2), INTERVAL.MILLISECONDS);
      CURR := CURR + 3;
    end if;
    for I in RESULT'FIRST..CURR - 1 loop
      if RESULT (I) = ' ' then RESULT (I) := '0'; end if;
    end loop;
    return RESULT (RESULT'FIRST..CURR-1);
  end STRING_INTERVAL;

  
--9.8-18065
  function Clock_Of(T : in Time_Type) return Clock_Type is
  begin
    return(T.Hour, T.MInute, T.Second);
  end Clock_Of;

--9.8-18065
  function "<=" (Left, Right: in Clock_Type) return Boolean is
    DummyLeft  : Time_Type := Clock;
    DummyRight : Time_Type := DummyLeft;
  begin
    DummyLeft.Hour := Left.Hour;
    DummyLeft.Minute := Left.Minute;
    DummyLeft.Second := Left.Second;
    DummyRight.Hour := Right.Hour;
    DummyRight.Minute := Right.Minute;
    DummyRight.Second := Right.Second;
    return "<="(DummyLeft, DummyRight);
  end "<=";

--9.8-18065
  function ">=" (Left, Right: in Clock_Type) return Boolean is    
    DummyLeft  : Time_Type := Clock;
    DummyRight : Time_Type := DummyLeft;
  begin
    DummyLeft.Hour := Left.Hour;
    DummyLeft.Minute := Left.Minute;
    DummyLeft.Second := Left.Second;
    DummyRight.Hour := Right.Hour;
    DummyRight.Minute := Right.Minute;
    DummyRight.Second := Right.Second;
    return ">="(DummyLeft, DummyRight);
  end ">=";
  
--9.8-18065
  function To_String(C : in Clock_Type) return String is
    Dummy : Time_Type := Clock;
  begin
    Dummy.Hour := C.Hour;
    Dummy.Minute := C.Minute;
    Dummy.Second := C.Second;
    return String_Time(Dummy);
  end To_String;
  
end SATTMATE_CALENDAR;
