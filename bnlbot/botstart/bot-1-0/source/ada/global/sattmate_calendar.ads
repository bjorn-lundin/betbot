-------------------------------------------------------------------------------
---
--
--    COPYRIGTH    SattControl AB, Malm|
--
--    FILENAME    SATTMATE_CALENDAR_SPEC.ADA
--
--    RESPONSIBLE    XCP
--
--    DESCRIPTION    This file contains the specification of the
--            package SATTMATE_CALENDAR. The package contains
--            time conversions and time operations.
--
-------------------------------------------------------------------------------
---
--
--    VERSION        5.0
--    AUTHOR        Peter Sacher
--    VERIFIED BY    Henrik Dannberg
--    DESCRIPTION    Orginal version.
--
-------------------------------------------------------------------------------
---
--
--    VERSION        6.0        17-mar-1994
--    AUTHOR        Henrik Dannberg
--    VERIFIED BY    ?
--    DESCRIPTION    NECTAR_TIME_TYPE and NECTAR_DATE_TYPE removed
--
-------------------------------------------------------------------------------
---
--
--    VERSION        8.2        22-Apr-1999
--    AUTHOR        SNE/BTO
--    VERIFIED BY    ?
--    DESCRIPTION    New procedures TO_TIME, TO_INTERVAL, TO_SECONDS.
--
-------------------------------------------------------------------------------
---
--
--    VERSION        8.2b        06-Dec-1999
--    AUTHOR        Irene Olsson
--    VERIFIED BY    ?
--    DESCRIPTION    Function IS_LEGAL is made available
--
-------------------------------------------------------------------------------
---
-- 9.6-11859 2007-05-23 BNL Fixed drifting clock, by using Realtime clock
--                          Also removed any calendar types in spec
-- 9.8-xxxx  2008-12-08 SNE Added a conversion routine TO_TIME_TYPE
-- 9.8-18065 2009-20-11 BNL Moved Clock_Type et al from invenory to here
-- chg-25546 2012-09-08 BNL Fixed month int To_Time_Type. Also introduced
--exception Invalid_Date_Format
-------------------------------------------------------------------------------
---

with Calendar;
with Sattmate_Types; use Sattmate_Types;

package Sattmate_Calendar is

   subtype Year_Type is Integer_2 range 1901 .. 2099;
   subtype Month_Type is Integer_2 range 01 .. 12;
   subtype Day_Type is Integer_2 range 01 .. 31;
   subtype Hour_Type is Integer_2 range 00 .. 23;
   subtype Minute_Type is Integer_2 range 00 .. 59;
   subtype Second_Type is Integer_2 range 00 .. 59;
   subtype Millisecond_Type is Integer_2 range 000 .. 999;

   subtype Week_Type is Integer_2 range 1 .. 53;
   subtype Year_Day_Type is Integer_2 range 1 .. 366;
   type Week_Day_Type is (
                          Monday,
                          Tuesday,
                          Wednesday,
                          Thursday,
                          Friday,
                          Saturday,
                          Sunday);

   subtype Interval_Day_Type is Integer_4 range 0 .. Integer_4'Last;
   subtype Seconds_Type is Integer_4 range 0 .. Integer_4'Last; --v8.2

   type Time_Type is record
      Year        : Year_Type;
      Month       : Month_Type;
      Day         : Day_Type;
      Hour        : Hour_Type;
      Minute      : Minute_Type;
      Second      : Second_Type;
      Millisecond : Millisecond_Type;
   end record;

   type Interval_Type is record
      Days         : Interval_Day_Type;
      Hours        : Hour_Type;
      Minutes      : Minute_Type;
      Seconds      : Second_Type;
      Milliseconds : Millisecond_Type;
   end record;

   --9.8-18065 start
   type Clock_Type is record
      Hour   : Hour_Type;
      Minute : Minute_Type;
      Second : Second_Type;
   end record;
   function Clock_Of (T : in Time_Type) return Clock_Type;
   function "<=" (Left, Right : in Clock_Type) return Boolean;
   function ">=" (Left, Right : in Clock_Type) return Boolean;
   function To_String (C : in Clock_Type) return String;

   --9.8-18065 stop

   Time_Type_First : constant Time_Type :=
                       (Year        => Year_Type'First,
                        Month       => Month_Type'First,
                        Day         => Day_Type'First,
                        Hour        => Hour_Type'First,
                        Minute      => Minute_Type'First,
                        Second      => Second_Type'First,
                        Millisecond => Millisecond_Type'First);

   Time_Type_Last : constant Time_Type :=
                      (Year        => Year_Type'Last,
                       Month       => Month_Type'Last,
                       Day         => Day_Type'Last,
                       Hour        => Hour_Type'Last,
                       Minute      => Minute_Type'Last,
                       Second      => Second_Type'Last,
                       Millisecond => Millisecond_Type'Last);

   Interval_Type_First : constant Interval_Type :=
                           (Days         => Interval_Day_Type'First,
                            Hours        => Hour_Type'First,
                            Minutes      => Minute_Type'First,
                            Seconds      => Second_Type'First,
                            Milliseconds => Millisecond_Type'First);

   Interval_Type_Last : constant Interval_Type :=
                          (Days         => Interval_Day_Type'Last,
                           Hours        => Hour_Type'Last,
                           Minutes      => Minute_Type'Last,
                           Seconds      => Second_Type'Last,
                           Milliseconds => Millisecond_Type'Last);

   In_Parameter_Incorrect : exception;
   --                        raised when the input date is impossible
   --                        (e.g. 1990.02.30) or, in conversions to NECTAR
   --              date, the year is less than 1970.
   Time_Error             : exception;
   --                        raised when the result comes to a date before
   --                        TIME_TYPE_FIRST or after TIME_TYPE_LAST, or the
   --left
   --              parameter is less than the right one in subtractions.

   -- v8.2b Start
   --
   function Is_Legal
     (Year  : in Year_Type;
      Month : in Month_Type;
      Day   : in Day_Type)
      return  Boolean;

   function Is_Legal
     (Year     : in Year_Type;
      Year_Day : in Year_Day_Type)
      return     Boolean;

   function Is_Legal (Time : in Time_Type) return Boolean;
   --
   -- v8.2b End

   function Clock return Time_Type;

   --9.6-11859 new function, returns SATTMATE_CALENDAR.CLOCK, in
   --CALENDAR.TIME-format
   function Calendar_Clock return  Calendar.Time;

   --9.8-xxxx New function
   -- Date_Str => "DD-MON-YYYY" ("09-DEC-2008), Time_Str =>
   --"HH:MM:SS.ZZZ"("10:01:32.123")
   function To_Time_Type
     (Date_Str : String;
      Time_Str : String)
      return     Time_Type;

   Invalid_Date_Format : exception; -- chg-25546
   -- is raised by bad data in To_Time_Type

   function To_Time (Date : in Calendar.Time) return Time_Type;
   function To_Calendar_Time (Date : in Time_Type) return Calendar.Time;
   function To_Time
     (Year        : in Year_Type;
      Year_Day    : in Year_Day_Type;
      Hour        : in Hour_Type;
      Minute      : in Minute_Type;
      Second      : in Second_Type;
      Millisecond : in Millisecond_Type)
      return        Time_Type;

   function To_Time
     (Year        : in Year_Type;
      Week        : in Week_Type;
      Day         : in Week_Day_Type;
      Hour        : in Hour_Type        := Hour_Type'First;
      Minute      : in Minute_Type      := Minute_Type'First;
      Second      : in Second_Type      := Second_Type'First;
      Millisecond : in Millisecond_Type := Millisecond_Type'First)
      return        Time_Type; -- v8.2

   function "<" (Left, Right : in Time_Type) return Boolean;
   function "<=" (Left, Right : in Time_Type) return Boolean;
   function ">" (Left, Right : in Time_Type) return Boolean;
   function ">=" (Left, Right : in Time_Type) return Boolean;

   function "<" (Left, Right : in Interval_Type) return Boolean;
   function "<=" (Left, Right : in Interval_Type) return Boolean;
   function ">" (Left, Right : in Interval_Type) return Boolean;
   function ">=" (Left, Right : in Interval_Type) return Boolean;

   function To_Interval
     (Day_Duration : in Calendar.Day_Duration)
      return         Interval_Type;

   function To_Interval (Seconds : in Seconds_Type) return Interval_Type;
   -- v8.2
   function To_Seconds (Interval : in Interval_Type) return Seconds_Type;
   -- v8.2

   function To_Day_Duration
     (Interval : in Interval_Type)
      return     Calendar.Day_Duration;
   -- This function does not use the term DAYS in the record INTERVAL_TYPE.

   function "+"
     (Left  : in Time_Type;
      Right : in Interval_Type)
      return  Time_Type;
   function "+"
     (Left  : in Interval_Type;
      Right : in Time_Type)
      return  Time_Type;

   function "+"
     (Left  : in Time_Type;
      Right : in Year_Day_Type)
      return  Time_Type;
   function "+"
     (Left  : in Year_Day_Type;
      Right : in Time_Type)
      return  Time_Type;

   function "-" (Left, Right : in Time_Type) return Interval_Type;
   function "-"
     (Left  : in Time_Type;
      Right : in Interval_Type)
      return  Time_Type;
   function "-"
     (Left  : in Time_Type;
      Right : in Year_Day_Type)
      return  Time_Type;

   function "+" (Left, Right : in Interval_Type) return Interval_Type;

   function "-" (Left, Right : in Interval_Type) return Interval_Type;

   function Is_Leap_Year (Year : in Year_Type) return Boolean;

   function Year_Day_Of (Date : in Time_Type) return Year_Day_Type;
   function Year_Day_Of
     (Year  : in Year_Type;
      Month : in Month_Type;
      Day   : in Day_Type)
      return  Year_Day_Type;

   function Days_In (Year : in Year_Type) return Year_Day_Type;
   function Days_In
     (Year  : in Year_Type;
      Month : in Month_Type)
      return  Day_Type;

   function Week_Day_Of (Date : in Time_Type) return Week_Day_Type;
   function Week_Day_Of
     (Year  : in Year_Type;
      Month : in Month_Type;
      Day   : in Day_Type)
      return  Week_Day_Type;

   function Week_Of (Date : in Time_Type) return Week_Type;
   function Week_Of
     (Year  : in Year_Type;
      Month : in Month_Type;
      Day   : in Day_Type)
      return  Week_Type;
   function Week_Of
     (Year     : in Year_Type;
      Year_Day : in Year_Day_Type)
      return     Week_Type;

   --9.6-11859 start
   function String_Date
     (Date : in Calendar.Time := To_Calendar_Time (Clock))
      return String;

   function String_Date_ISO (Date : in Time_Type) return String ;
   function String_Date_Time_ISO (Date : in Time_Type; T : String := "T"; TZ : String := "Z") return String ;


   function String_Time
     (Date         : in Calendar.Time := To_Calendar_Time (Clock);
      Hours        : in Boolean       := True;
      Minutes      : in Boolean       := True;
      Seconds      : in Boolean       := True;
      Milliseconds : in Boolean       := False)
      return         String;
   function String_Date_And_Time
     (Date         : in Calendar.Time := To_Calendar_Time (Clock);
      Hours        : in Boolean       := True;
      Minutes      : in Boolean       := True;
      Seconds      : in Boolean       := True;
      Milliseconds : in Boolean       := False)
      return         String;
   --9.6-11859 stop

   function String_Date (Date : in Time_Type) return String;
   function String_Time
     (Date         : in Time_Type;
      Hours        : in Boolean := True;
      Minutes      : in Boolean := True;
      Seconds      : in Boolean := True;
      Milliseconds : in Boolean := False)
      return         String;
   function String_Date_And_Time
     (Date         : in Time_Type;
      Hours        : in Boolean := True;
      Minutes      : in Boolean := True;
      Seconds      : in Boolean := True;
      Milliseconds : in Boolean := False)
      return         String;

   -- Enter in the BOOLEAN parameters in the STRING_TIME functions the values
   -- you wish to be returned.
   -- Example of returned date is : 01-Jan-1984
   -- Example of returned time is : 15:30:05.001

   function String_Interval
     (Interval     : in Interval_Type;
      Days         : in Boolean := True;
      Hours        : in Boolean := True;
      Minutes      : in Boolean := True;
      Seconds      : in Boolean := True;
      Milliseconds : in Boolean := True)
      return         String;

   -- Enter in the BOOLEAN parameters the values you wish to be returned.
   -- Example of returned a interval is : 00001:15:30:05.003

end Sattmate_Calendar;
