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
     Cfg.Size                 := Bet_Size_Type'Value(Ini.Get_Value("finish","size","30.0")); 
     Cfg.Fav_Max_Price        := Back_Price_Type'Value(Ini.Get_Value("finish","fav_max_price","1.15")); 
     Cfg.Second_Fav_Min_Price := Back_Price_Type'Value(Ini.Get_Value("finish","2nd_min_price","7.0")); 
     Cfg.Enabled              := Ini.Get_Value("finish","enabled",false); 
     Cfg.Max_Loss_Per_Day     := Float_8'Value(Ini.Get_Value("finish","max_loss_per_day","-500.0")); 
     Cfg.Allowed_Countries    := To_Unbounded_String(Ini.Get_Value("finish","countries",""));
     Cfg.Allow_Lay_During_Race := Ini.Get_Value("finish","allow_lay_during_race",false); 
    
    declare
      use Ada.Characters.Handling;
      use Ada.Strings.Fixed;
      Days : String := Ini.Get_Value("finish","allowed_days","al");
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
        "<size>" & F8_Image(Float_8(Cfg.Size)) & "</size>" &
        "<max_loss_per_day>" & F8_Image(Cfg.Max_Loss_Per_Day) & "</max_loss_per_day>" &
        "<fav_max_price>" & F8_Image(Float_8(Cfg.Fav_Max_Price)) & "</fav_max_price>" &
        "<second_fav_min_price>" & F8_Image(Float_8(Cfg.Second_Fav_Min_Price)) & "</second_fav_min_price>" &
        "<max_turns_not_started_race>" & Cfg.Max_Turns_Not_Started_Race'Img & "</max_turns_not_started_race>" &
        "<enabled>" & Cfg.Enabled'Img & "</enabled>" &
        "<allow_lay_during_race>" & Cfg.Allow_Lay_During_Race'Img & "</allow_lay_during_race>" &
        "<allowed_countries>" & To_String(Cfg.Allowed_Countries) & "</allowed_countries>" ;
    Part3 : String := "</config>";
    Days : Unbounded_String := Null_Unbounded_String;
  begin

        Append(Days, "<days>");
        for i in Week_Day_Type'range loop
          Append(Days, "<" & To_Lower(i'Img) & ">" & 
                       To_Lower(Cfg.Allowed_Days(i)'Img) &
                        "</" & To_Lower(i'Img) & ">" );
        end loop;
        Append(Days, "</days>");
      
        return Part1 & To_String(Days) & Part3;   
      
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