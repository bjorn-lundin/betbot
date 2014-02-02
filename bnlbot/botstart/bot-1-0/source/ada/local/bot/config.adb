--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Logging; use Logging;
with General_Routines; use General_Routines;

with Ini;

package body Config is
  Me : constant String := "Config.";
  Bad_Data : exception;
  -------------------------------------------------------------
  function Create(Filename : String) return Config_Type is
    Cfg : Config_Type;
  begin
     Ini.Load(Filename);
     Cfg.Size                 := Bet_Size_Type'Value(Ini.Get_Value("finish","size","30.0")); 
     Cfg.Fav_Max_Price        := Back_Price_Type'Value(Ini.Get_Value("finish","fav_max_price","1.15")); 
     Cfg.Second_Fav_Min_Price := Back_Price_Type'Value(Ini.Get_Value("finish","2nd_min_price","7.0")); 
     Cfg.Enabled              := Ini.Get_Value("finish","enabled",false); 
     Cfg.Max_Loss_Per_Day     := Float_8'Value(Ini.Get_Value("finish","max_loss_per_day","-500.0")); 
     Cfg.Allowed_Countries    := To_Unbounded_String(Ini.Get_Value("finish","countries",""));
     return Cfg;
  end Create;
  -------------------------------------------------------------  
  function To_String(Cfg : Config_Type) return String is
  begin
    return
      "<config>" &
        "<size>" & F8_Image(Float_8(Cfg.Size)) & "</size>" &
        "<max_loss_per_day>" & F8_Image(Cfg.Max_Loss_Per_Day) & "</max_loss_per_day>" &
        "<fav_max_price>" & F8_Image(Float_8(Cfg.Fav_Max_Price)) & "</fav_max_price>" &
        "<second_fav_min_price>" & F8_Image(Float_8(Cfg.Second_Fav_Min_Price)) & "</second_fav_min_price>" &
        "<max_turns_not_started_race>" & Cfg.Max_Turns_Not_Started_Race'Img & "</max_turns_not_started_race>" &
        "<enabled>" & Cfg.Enabled'Img & "</enabled>" &
        "<allowed_countries>" & To_String(Cfg.Allowed_Countries) & "</allowed_countries>" &
      "</config>"
      ;    
  end To_String;
  -------------------------------------------------------------
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean is
    Service : constant String := "Country_Is_Ok";
  -- Allowed country ?
  --Countries is a ',' separated list of 2 char abbrevations.
    Countries : String := Upper_Case(To_String(Cfg.Allowed_Countries));
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