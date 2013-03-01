


with Table_Dry_Markets;
with Table_Dry_Runners;
with Table_Dry_Results;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);
with Sattmate_Calendar;

package Races is

   type Race_Type is tagged record
      Market       : Table_Dry_Markets.Data_Type;
      Runners_List : Table_Dry_Runners.Dry_Runners_List_Pack.List_Type :=
                       Table_Dry_Runners.Dry_Runners_List_Pack.Create;
      Winners_List : Table_Dry_Results.Dry_Results_List_Pack.List_Type :=
                       Table_Dry_Results.Dry_Results_List_Pack.Create;
   end record;

   procedure Get_Runners(Race : in out Race_Type);
   procedure Get_Winners (Race : in out Race_Type);
   function No_Of_Runners (Race : in Race_Type) return Natural;
   function No_Of_Winners (Race : in Race_Type) return Natural;
   procedure Show_Runners (Race : in out Race_Type) ;


   package Race_Package is new Simple_List_Class (Race_Type);
   Race_List     : Race_Package.List_Type := Race_Package.Create;


   type Bet_Type_Type is (Place, Winner);
   type Animal_Type is (Horse, Hound);


   procedure Get_Database_Data (Race_List   : in out Race_Package.List_Type;
                                Bet_Type : in Bet_Type_Type;
                                Animal      : Animal_Type;
                                Start_Date  : Sattmate_Calendar.Time_Type;
                                Stop_Date  : Sattmate_Calendar.Time_Type
                               ) ;


end Races;
