

package body Runners is


   procedure Fix_Average(R : in out Runners_Type; This_Ts :  Time_Type) is
   begin
     R.A2_Back := R.A_Back;
     R.A2_Lay  := R.A_Lay;
          
     R.V_Back(5) := R.V_Back(4); 
     R.V_Back(4) := R.V_Back(3); 
     R.V_Back(3) := R.V_Back(2); 
     R.V_Back(2) := R.V_Back(1); 
     R.V_Back(1) := R.Back_Price; 
     
     R.A_Back := 0.0;
     for i in R.V_Back'range loop
       R.A_Back := R.A_Back + R.V_Back(i);
     end loop;
     R.A_Back := R.A_Back / Float_8(R.V_Back'Length);  

     R.V_Lay(5) := R.V_Lay(4); 
     R.V_Lay(4) := R.V_Lay(3); 
     R.V_Lay(3) := R.V_Lay(2); 
     R.V_Lay(2) := R.V_Lay(1); 
     R.V_Lay(1) := R.Lay_Price; 
     
     R.A_Lay := 0.0;
     for i in R.V_Lay'range loop
       R.A_Lay := R.A_Lay + R.V_Lay(i);
     end loop;
     R.A_Lay := R.A_Lay / Float_8(R.V_Lay'Length);  


     -- slope back
     declare 
       Denominator : Seconds_Type := To_Seconds(This_Ts - R.Last_Ts);
     begin
       if Denominator > 0 then
         R.K_Back := ( R.V_Back(1) - R.V_Back(2) ) / Float_8(Denominator);
       else
         R.K_Back := 0.0;
       end if;       
     end ;
     
     R.K_Back_V(5) := R.K_Back_V(4); 
     R.K_Back_V(4) := R.K_Back_V(3); 
     R.K_Back_V(3) := R.K_Back_V(2); 
     R.K_Back_V(2) := R.K_Back_V(1); 
     R.K_Back_V(1) := R.K_Back; 
     
     R.K_Back_Avg := 0.0;
     for i in R.K_Back_V'range loop
       R.K_Back_Avg := R.K_Back_Avg + R.K_Back_V(i);
     end loop;
     R.K_Back_Avg := R.K_Back_Avg / Float_8(R.K_Back_V'Length);     

     -- slope lay
     declare 
       Denominator : Seconds_Type := To_Seconds(This_Ts - R.Last_Ts);
     begin
       if Denominator > 0 then
         R.K_Lay := ( R.V_Lay(1) - R.V_Lay(2) ) / Float_8(Denominator);
       else
         R.K_Lay := 0.0;
       end if;       
     end ;
     
     R.K_Lay_V(5) := R.K_Lay_V(4); 
     R.K_Lay_V(4) := R.K_Lay_V(3); 
     R.K_Lay_V(3) := R.K_Lay_V(2); 
     R.K_Lay_V(2) := R.K_Lay_V(1); 
     R.K_Lay_V(1) := R.K_Lay; 
     
     R.K_Lay_Avg := 0.0;
     for i in R.K_Lay_V'range loop
       R.K_Lay_Avg := R.K_Lay_Avg + R.K_Lay_V(i);
     end loop;
     R.K_Lay_Avg := R.K_Lay_Avg / Float_8(R.K_Lay_V'Length);  
     
     R.Last_Ts := This_Ts;
   end Fix_Average;
   ---------------------------------------------------

end Runners;

