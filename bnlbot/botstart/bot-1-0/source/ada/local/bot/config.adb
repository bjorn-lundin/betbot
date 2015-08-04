with Ada.Strings.Fixed;
with Logging; use Logging;
with Ada.Characters.Handling;
with Ini;
with Utils;


package body Config is
  Me : constant String := "Config.";
  Bad_Data : exception;
  -------------------------------------------------------------
  function Create(Filename : String) return Config_Type is
    Service : constant String := "Create";
    Cfg : Config_Type;
  begin
     Log(Me & Service, "read ini file :'" & Filename & "'");

     Ini.Load(Filename);
     Cfg.Enabled              := Ini.Get_Value("global","enabled",false); 
     Cfg.Allowed_Countries    := To_Unbounded_String(Ini.Get_Value("global","countries",""));
     
     for i in Bet_Type'range loop
       Cfg.Bet(i).Size := Bet_Size_Type'Value(Ini.Get_Value(i'Img,"size","0.0")); 
       Cfg.Bet(i).Max_Loss_Per_Day := Float_8'Value(Ini.Get_Value(i'img,"max_loss_per_day","0.0")); 
       Cfg.Bet(i).Enabled := Ini.Get_Value(i'img,"enabled",false); 
     end loop;
     
    
    declare
      use Ada.Characters.Handling;
      use Ada.Strings.Fixed;
      Days : String := Ini.Get_Value("global","allowed_days","al");
      use Calendar2;
      Zero : Natural := 0;
    begin
      if To_Lower(Days) /= "al" then
        for i in Week_Day_Type'range loop
          Cfg.Allowed_Days(i) := Index(To_Lower(Days), To_Lower(i'Img)(1..2)) > Zero;
          Log(Me & Service, i'img & " Index(To_Lower(Days), To_Lower(i'Img)(1..2))" &  Index(To_Lower(Days), To_Lower(i'Img(1..2)))'Img );

        end loop;
      else
        for i in Week_Day_Type'range loop
          Cfg.Allowed_Days(i) := Index(To_Lower(Days), "al") > Zero;
        end loop;
      end if;      
    end; 
     return Cfg;
  end Create;
  -------------------------------------------------------------  
  function To_String(Cfg : Config_Type) return String is
    use Utils;
    use Calendar2;
    use Ada.Characters.Handling;
    part1 : String := 
      "<config>" &
        "<enabled>" & Cfg.Enabled'Img & "</enabled>" &
        "<max_turns_not_started_race>" & Cfg.Max_Turns_Not_Started_Race'Img & "</max_turns_not_started_race>" &
        "<allowed_countries>" & To_String(Cfg.Allowed_Countries) & "</allowed_countries>" ;
    Part3 : String := "</config>";
    Days : Unbounded_String := Null_Unbounded_String;
    Bets : Unbounded_String := Null_Unbounded_String;
  begin

        Append(Days, "<days>");
        for i in Week_Day_Type'range loop
          Append(Days, "<" & To_Lower(i'Img) & ">" & 
                       To_Lower(Cfg.Allowed_Days(i)'Img) &
                        "</" & To_Lower(i'Img) & ">" );
        end loop;
        Append(Days, "</days>");
        
        Append(Bets, "<bets>");
        for i in Bet_Type'range loop
          Append(Bets, "<" & To_Lower(i'Img) & ">" & 
                           "<size>" & F8_Image(Float_8(Cfg.Bet(i).Size)) & "</size>" &
                           "<max_loss_per_day>" & F8_Image(Cfg.Bet(i).Max_Loss_Per_Day) & "</max_loss_per_day>" &
                           "<enabled>" & Cfg.Bet(i).Enabled'Img & "</enabled>" &
                        "</" & To_Lower(i'Img) & ">" );
        end loop;
        Append(Bets, "</bets>");
      
        return Part1 & To_String(Days) & To_String(Bets) & Part3;   
      
  end To_String;
  -------------------------------------------------------------
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean is
    Service : constant String := "Country_Is_Ok";
  -- Allowed country ?
  --Countries is a ',' separated list of 2 char abbrevations.
    Countries : String := Utils.Upper_Case(To_String(Cfg.Allowed_Countries));
    Cntry : String(1..2) := (others => ' ');
    Index : Integer := 1;
    Found : Boolean := False;
  begin
    for i in Countries'range loop
      case Countries(i) is
        when ',' =>
          if Cntry = Country_Code then
            Found := True;
            exit;
          end if;
        when others =>
          case Index is
            when 1 =>
              Cntry(1) := Countries(i);
              Index := 2;
            when 2 =>
              Cntry(2) := Countries(i);
              Index := 1;
            when others => raise Bad_Data with "Index = " & Index'Img;
          end case;
      end case;
    end loop;
    -- check also for the last entry (EN,IE)
    if Cntry = Country_Code then
      Found := True;
    elsif Cntry = "AL" then
      Found := True;
    elsif Countries = "AL" then
      Found := True;
    end if;
    
    if not Found then
        Log(Me & Service, "wrong country. OK countries are :'" & Countries & "' market country is '" & Country_Code & "'");
    end if;
    return Found;    
  end Country_Is_Ok;
  -------------------------------------------------------------
end Config;