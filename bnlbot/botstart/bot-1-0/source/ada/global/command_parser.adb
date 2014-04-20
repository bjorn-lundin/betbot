-- chg-21958 BNL 2011-04-28 Added env var SATTMATE_OPTION_MARKER, 
-- if defined properly it overrides the option marker character
----------------------------------------------------------------
--chg-23068 2011-10-26 a string containing the OPTION_MARKER character was illegal, like -test=asd-vf
--
----------------------------------------------------------------
with ADA.COMMAND_LINE;

package body COMMAND_PARSER is

  subtype STRING_INDEX is NATURAL range 0..256;  --v9.2-0104

  type STRING_DESCRIPTOR (LENGTH: STRING_INDEX:=0) is
    record
      DATA: STRING(1..LENGTH);
    end record;

  OPTION_VALUE    : array (OPTION_NAMES)    of STRING_DESCRIPTOR;
  PARAMETER_VALUE : array (PARAMETER_INDEX) of STRING_DESCRIPTOR;
  LATEST_OPTION   : STRING_DESCRIPTOR;


  function OPTION_MARK return CHARACTER is
    Option_Marker :  Character := '-'; --chg-21958
  begin
    --chg-21958 start
--    begin
--        Option_Marker := System_Services.Get_Symbol(String'("SATTMATE_OPTION_MARKER"))(1) ;
--        if Option_Marker /= ' ' then
            return Option_Marker;
--        end if;    
--    exception -- we'll get and exception if nothing is defined in 
--              -- Character'range, and then fall back on the old behaviour
--      when others => null;
--    end;
	--chg-21958 stop
--    case SYSTEM_SERVICES.OPERATING_SYSTEM is
--      when SYSTEM_SERVICES.VAX_VMS => return '/';
--      when SYSTEM_SERVICES.UNIX    => return '-';
--      when SYSTEM_SERVICES.WIN32   => return '/';
--    end case;
  end OPTION_MARK;
     

  function RECORD_AGGREGATE (S: STRING) return STRING_DESCRIPTOR is
    RESULT: constant STRING(1..S'LENGTH) := S;
  begin
    return (RESULT'LENGTH, RESULT);
  end RECORD_AGGREGATE;


  function UPPER_CASE (S: STRING) return STRING is
    RESULT: STRING(S'RANGE) := S;
  begin
    for I in RESULT'RANGE loop
      if RESULT(I) in 'a'..'z' then
        RESULT(I) := CHARACTER'VAL(CHARACTER'POS(RESULT(I))-32);
      end if;
    end loop;
    return RESULT;
  end UPPER_CASE;


  function ADJUST (LINE: STRING) return STRING is
    --
    -- a) Replace ASCII.HT and ' ' with ASCII.NUL
    --
    -- b) Add ASCII.NUL at the end of the line
    --
    -- c) Remove double quotes according to DCL conventions for string literals
    --
    RESULT        : STRING(1..LINE'LAST);
    WITHIN_QUOTES : BOOLEAN := FALSE;
    I             : INTEGER := LINE'FIRST;
    INDEX         : INTEGER := RESULT'FIRST - 1;
  begin
    while I in LINE'RANGE loop
      if LINE(I) = '"' then
        if WITHIN_QUOTES then
          if I = LINE'LAST then
            WITHIN_QUOTES := FALSE;
          elsif LINE(I+1) = '"' then
            I := I + 1;
            INDEX := INDEX + 1;
            RESULT(INDEX) := '"';
          else
            WITHIN_QUOTES := FALSE;
          end if;
        else
          WITHIN_QUOTES := TRUE;
        end if;
      elsif WITHIN_QUOTES then
        INDEX := INDEX + 1;
        RESULT(INDEX) := LINE(I);
      else
        INDEX := INDEX + 1;
        if (LINE(I) = ASCII.HT) or (LINE(I) = ' ') then
          RESULT(INDEX) := ASCII.NUL;
        else
          RESULT(INDEX) := LINE(I);
        end if;
      end if;
      I := I + 1;
    end loop;
    return RESULT(1..INDEX) & ASCII.NUL;
  end ADJUST;


  procedure PARSE_VALUE (OPTION: OPTION_NAMES;
                         I     : in out NATURAL;
                         LINE  : STRING) is
    FROM : NATURAL := I + 1;
  begin
    I := I + 1;
--chg-23068   while not (LINE(I) = ASCII.NUL or LINE(I) = OPTION_MARK) loop
    while LINE(I) /= ASCII.NUL loop --chg-23068
      I := I + 1;
    end loop;
    OPTION_VALUE(OPTION) := RECORD_AGGREGATE(LINE(FROM..I-1));
  end PARSE_VALUE;


  procedure PARSE_OPTION (OPTION_SETTINGS : in out OPTION_ARRAY;
                          VALUES_ALLOWED  : OPTION_ARRAY;
                          I               : in out NATURAL;
                          LINE            : STRING) is
    FROM        : NATURAL := I + 1;
    OPTION_FLAG : BOOLEAN;
  begin
    I := I + 1;
    while I <= LINE'LAST loop
--chg-23068     if LINE(I) = OPTION_MARK or LINE(I) = ASCII.NUL or LINE(I) = '=' then
      if LINE(I) = ASCII.NUL or LINE(I) = '=' then --chg-23068
--        if LINE(FROM..FROM+1) = "NO" then
        if UPPER_CASE(LINE(FROM..FROM+1)) = "NO" then   -- V5.1.1
          OPTION_FLAG := FALSE;
          FROM := FROM + 2;
        else
          OPTION_FLAG := TRUE;
        end if;
        declare
          NAME  : constant STRING(1..I-FROM) := UPPER_CASE(LINE(FROM..I-1));
          FOUND : BOOLEAN := FALSE;
          OPTION_FOUND : OPTION_NAMES := OPTION_NAMES'first; -- 9.2-0054
        begin
          LATEST_OPTION := (NAME'LENGTH, NAME);
          for OPTION in OPTION_NAMES loop
            declare
              IMAGE  : constant STRING := OPTION_NAMES'IMAGE(OPTION);
              LENGTH : NATURAL := IMAGE'LENGTH;
            begin
              if NAME'LENGTH = LENGTH then
                if NAME = IMAGE then
                  FOUND := TRUE; OPTION_FOUND := OPTION;
                  exit;
                end if;
              elsif NAME'LENGTH < LENGTH then
                if NAME = IMAGE(IMAGE'FIRST..IMAGE'FIRST+NAME'LENGTH-1) then
                  if FOUND then raise AMBIGOUS_OPTION; end if;
                  FOUND := TRUE; OPTION_FOUND := OPTION;
                end if;
              end if;
            end;
          end loop;
          if FOUND then
            if LINE(I) = '=' then
              if VALUES_ALLOWED(OPTION_FOUND) then
                PARSE_VALUE(OPTION_FOUND, I, LINE(I..LINE'LAST));
              else
                raise VALUE_NOT_ALLOWED;
              end if;
            end if;
            OPTION_SETTINGS(OPTION_FOUND) := OPTION_FLAG;
          else
            raise UNDEFINED_OPTION;
          end if;
        end;
        exit;
      else
        I := I + 1;
      end if;
    end loop;
  end PARSE_OPTION;


  procedure PARSE_PARAMETER (NUMBER: POSITIVE;
                             I     : in out NATURAL;
                             LINE  : in STRING) is
    FROM : NATURAL := I;
  begin
    while I <= LINE'LAST loop
--chg-23068     if LINE(I) = OPTION_MARK or LINE(I) = ASCII.NUL then
      if LINE(I) = ASCII.NUL then --chg-23068
        PARAMETER_VALUE(NUMBER) := RECORD_AGGREGATE(LINE(FROM..I-1));
        exit;
      end if;
      I := I + 1;
    end loop;
  end PARSE_PARAMETER;


  procedure PARSE_COMMAND (OPTION_SETTINGS : in out OPTION_ARRAY;
                           VALUES_ALLOWED  : OPTION_ARRAY;
                           LINE            : STRING) is
    I : NATURAL := LINE'FIRST;
    PARAMETER_NUMBER : POSITIVE := 1;
  begin
    while I <= LINE'LAST loop
      if LINE(I) = OPTION_MARK then
        PARSE_OPTION(OPTION_SETTINGS, VALUES_ALLOWED, I, LINE);
      elsif LINE(I) = ASCII.NUL then
        I := I + 1;
      elsif PARAMETER_NUMBER > MAX_PARAMETERS then
        raise TOO_MANY_PARAMETERS;
      else
        PARSE_PARAMETER(PARAMETER_NUMBER,I,LINE);
        PARAMETER_NUMBER := PARAMETER_NUMBER + 1;
      end if;
    end loop;
  end PARSE_COMMAND;

  
  
  function GET_COMMAND_LINE return STRING is
    function ARGV (N: NATURAL) return STRING is
    begin
      if N = 0 then
        return "";
      else
        return ARGV(N-1) & " " & ADA.COMMAND_LINE.ARGUMENT(N);
      end if;
    end ARGV;
  begin
    return ARGV(ADA.COMMAND_LINE.ARGUMENT_COUNT);
  end GET_COMMAND_LINE;

  procedure PARSE (OPTION_SETTINGS : in out OPTION_ARRAY;
                   VALUES_ALLOWED  : OPTION_ARRAY := (others => FALSE)) is
    COMMAND_LINE : constant STRING := GET_COMMAND_LINE;
  begin
    PARSE_COMMAND (OPTION_SETTINGS, VALUES_ALLOWED, ADJUST(COMMAND_LINE));
  end PARSE;


  function VALUE (OPTION: OPTION_NAMES) return STRING is
  begin
    return OPTION_VALUE(OPTION).DATA;
  end VALUE;


  function PARAMETER (NUMBER: PARAMETER_INDEX) return STRING is
  begin
    return PARAMETER_VALUE(NUMBER).DATA;
  end PARAMETER;


  function ILLEGAL_OPTION return STRING is
  begin
    return OPTION_MARK & LATEST_OPTION.DATA;
  end ILLEGAL_OPTION;

end COMMAND_PARSER;
