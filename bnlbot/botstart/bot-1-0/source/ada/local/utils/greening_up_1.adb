
with Types; use Types;
with Calendar2; use Calendar2;

with GNAT; use GNAT;
with GNAT.AWK;
with Text_Io; use Text_Io;


procedure Greening_Up_1 is
  Computer_File : AWK.Session_Type;
  Is_First_Line : Boolean := True;
  Race_Start, T : Calendar2.Time_Type;
  
  Min_Odds   : constant Float_8 := 11.0;
  Max_Odds   : constant Float_8 := 20.0;
  Delta_Odds : constant Float_8 := 1.0;
  Current_Odds, Back_Odds, Lay_Odds : Float_8 := 0.0;
  Selection_Id, Current_Selection_Id : Integer_4 := 0;
  Global_Profit, Profit : Float_8 := 0.0;
  
  Back_Size : Float_8 := 100.0;
  Lay_Size  : Float_8 := 0.0;
  
  Income, Stake: Float_8 := 0.0;
  
  type Outcome_Type is (Both, Back_Ok, Back_Bad, None);
  Outcome : Outcome_Type := None;
  type Stats_Type is record
    Hits : Integer_4 := 0;
    Profit : Float_8 := 0.0;
  end record ;
  
  Stats : array (Outcome_Type'range) of Stats_Type;
  
  Win_Flag : Boolean := False;
  
  -----------------------------------------------------  
  function To_Time(S2: String) return Calendar2.Time_Type is
    
    Tmp : Time_Type;
    S : String (1 .. S2'Last - S2'First + 1) := S2; 
    
    
  begin
    -- '22-01-2013 11:09:06'  
    
    Tmp.Year  := Year_Type'Value (S (7 .. 10));
    Tmp.Month := Month_Type'Value (S (4 .. 5));
    Tmp.Day   := Day_Type'Value (S (1 .. 2));

    Tmp.Hour   := Hour_Type'Value (S (12 .. 13));
    Tmp.Minute := Minute_Type'Value (S (15 .. 16));
    if S'length = 19 then
      Tmp.Second := Second_Type'Value (S (18 .. 19));
    else
      Tmp.Second := 0;
    end if;  
    return Tmp;
  end To_Time;
  -----------------------------------------------------  
  
begin
  AWK.Set_Current (Computer_File);
  AWK.Open (Separators => ",",  
            Filename   => "/home/bnl/bnlbot/botstart/bot-0-9/history/data/untreated/2013_horses.dat");
 
  while not AWK.End_Of_File loop
    AWK.Get_Line;
    if Is_First_Line then
      Is_First_Line := False;
    else
      if AWK.Field(4)  = "GB" and then
        AWK.Field (18) = "PE"  and then 
        AWK.Field (8)  = "TO BE PLACED" and then 
        AWK.Field (5)  /= "GB/Daily Win Dist Odds"        
        then    
--        Set_Col(1);Put(AWK.Field (4));
--        Set_Col(4);Put(AWK.Field (7));
--        Set_Col(21);Put(AWK.Field (8));
--        Set_Col(34);Put(AWK.Field (10));
--        Set_Col(44);Put(AWK.Field (12));
--        Set_Col(49);Put(AWK.Field (16));
--        Set_Col(69);Put(AWK.Field (15));
--        Set_Col(89);Put(AWK.Field (17));
--        Set_Col(91);Put(AWK.Field (18));    
        
        Race_Start           := To_Time(AWK.Field(7));
        T                    := To_Time(AWK.Field(16));
        Current_Selection_Id := Integer_4'Value(AWK.Field(10));
        Current_Odds         := Float_8'Value(AWK.Field(12));
        Win_Flag             := AWK.Field(17) = "1";
        
        
        if Race_Start - T > (0,1,10,0,0) then
           if Outcome /= Back_Ok then
              if Min_Odds <= Current_Odds and then
                 Current_Odds <= Max_Odds then
                 Back_Odds := Current_Odds;
                 Outcome := Back_Ok;
                 -- do the back bet                 
              end if;   
           end if;
   
           if Outcome = Back_Ok then
           -- if odds are lower, lay bet it
              if Current_Odds <= Back_Odds - Delta_Odds  then
                 Lay_Odds := Current_Odds;
                 Lay_Size := (Back_Size * Back_Odds) / Lay_Odds ;
                 Outcome := Both;         
                 -- we now have our green up done
                 
--                 Put_Line( "Lay_size " & Integer_4(Lay_Size)'Img & 
--                           " Back_size " & Integer_4(Back_Size)'Img & 
--                           " Back_Odds " & Integer_4(Back_Odds)'Img & 
--                           " Lay_Odds " & Integer_4(Lay_Odds)'Img 
--                            ); 
                 
              end if;   
           end if;
    
          if Current_Selection_Id /= Selection_Id then

            -- new runner !

            if Outcome = Back_Ok then 
              if not Win_Flag then 
                 Outcome := Back_Bad;
              end if;
            end if;
          
          
            case Outcome is 
              when None =>
                Profit := 0.0;
              when Back_Ok =>
                Income := 0.95 * Back_Size * Back_Odds;            
                --cost 
                Stake := Back_Size;
                Profit := Income - Stake;
              when Back_Bad =>
                Profit := -Back_Size;
              when Both =>
                if Win_Flag then 
                  -- income is from backbet
                  Income := 0.95 * Back_Size * Back_Odds;            
                  --cost 
                  Stake :=( Lay_Odds -1.0) * Lay_Size + Back_Size;
                else
                  -- income is from laybet
                  Income := 0.95 * Lay_Size;            
                  --cost 
                  Stake := Back_Size;
                end if;                  
                Profit := Income - Stake;
            end case;  
            Stats(Outcome).Hits := Stats(Outcome).Hits + 1; 
            Stats(Outcome).Profit := Stats(Outcome).Profit + Profit;           
          
            if  Integer_4(Profit) /= 0 then
          
              Put_Line( AWK.Field (5) & " | " & 
                        AWK.Field (8) & " | " & 
                        AWK.Field (2) & " | " & 
                        AWK.Field (11) & " | " & 
                        Integer_4(Back_Odds)'Img & " | " &
                        Integer_4(Lay_Odds)'Img & " | " &                    
                        Integer_4(Back_Size)'Img & " | " &                    
                        Integer_4(Lay_Size)'Img & " | " &                    
                        Integer_4(Profit)'Img );    
            end if;
            
            Global_Profit := Global_Profit + Profit;          
            
            Selection_Id := Current_Selection_Id;
            Lay_Size := 0.0;
            Lay_Odds := 0.0;
            Back_Odds := 0.0;
            Outcome := None;
            
          end if;
        end if;           
      end if;
    end if;    
  end loop;  
  AWK.Close (Computer_File);

  Put_Line("Total profit = " & Integer_4(Global_Profit)'Img);  
  for i in Outcome_Type'range loop  
    Put_Line(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);        
  end loop;
  

end Greening_Up_1;