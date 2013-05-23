

with Sattmate_Types; use Sattmate_Types;
with Table_Drymarkets;
with Table_Dryrunners;
with Table_Dryresults;
with Simple_List_Class;
pragma Elaborate_All (Simple_List_Class);
with Sattmate_Calendar;
with Unchecked_Conversion;

package Races is
   Not_Implemented : exception;

   type Bet_Name_Type is (Place, Winner);
--   type Bet_Name_Type is ( Winner);
   type Bet_Type_Type is (Lay, Back, Lay_Favorite);
--   type Bet_Type_Type is (Lay, Back);
   type Animal_Type is (Horse, Hound);
   type Graph_Type is (Weekly,
                       Four_Weeks,
                       Eight_Weeks,
                       Twenty_Six_Weeks,
                       Fifty_Two_Weeks,
                       Seventy_Eight_Weeks,
                       One_Hundred_And_Four_Weeks);
   for Graph_Type'Size use Integer_4'Size ;
   for Graph_Type use (Weekly                     =>   1,
                       Four_Weeks                 =>   4,
                       Eight_Weeks                =>   8,
                       Twenty_Six_Weeks           =>  26,
                       Fifty_Two_Weeks            =>  52,
                       Seventy_Eight_Weeks        =>  78,
                       One_Hundred_And_Four_Weeks => 104);

   function Graph is new Unchecked_Conversion(Graph_Type, Integer_4);
   function Graph is new Unchecked_Conversion(Integer_4, Graph_Type);

   type Variant_Type is (Normal,
                         Max_3,
                         Max_5);
   for Variant_Type'Size use Integer_4'Size ;
   for Variant_Type use (Normal =>  0,
                         Max_3  =>  3,
                         Max_5  =>  5);
   function Variant is new Unchecked_Conversion(Variant_Type, Integer_4);
   function Variant is new Unchecked_Conversion(Integer_4, Variant_Type);



   type Profit_Type is new Float_8;
   type Saldo_Type is new Float_8;
   type Max_Daily_Loss_Type is new Float_8;
   type Max_Daily_Loss_Type_Type is (Minus_750,
                                     Minus_500,
                                     Minus_250 ,
                                     Minus_100  );
   for Max_Daily_Loss_Type_Type'Size use Integer_4'Size ;
   for Max_Daily_Loss_Type_Type use (Minus_750 => -750,
                                     Minus_500 => -500,
                                     Minus_250 => -250,
                                     Minus_100 => -100);
   function Max_Daily_Loss is new Unchecked_Conversion(Max_Daily_Loss_Type_Type, Integer_4);
   function Max_Daily_Loss is new Unchecked_Conversion(Integer_4, Max_Daily_Loss_Type_Type);



   type Max_Profit_Factor_Type is new Float_8;
   type Max_Price_Type is new Float_8;
   type Min_Price_Type is new Float_8;
   type Size_Type is new Float_8;
   type Price_Type is new Float_8;
   type Back_Price_Type is new Float_8;
   type Delta_Price_Type is new Float_8;


   type Race_Type is tagged record
      Market       : Table_Drymarkets.Data_Type;
      Runners_List : Table_Dryrunners.Dryrunners_List_Pack.List_Type :=
                       Table_Dryrunners.Dryrunners_List_Pack.Create;
      Winners_List : Table_Dryresults.Dryresults_List_Pack.List_Type :=
                       Table_Dryresults.Dryresults_List_Pack.Create;
      Selectionid  : Integer_4 := 0;
      Price        : Price_Type := 0.0;
      Size         : Size_Type := 0.0;
   end record;

   procedure Get_Runners (Race : in out Race_Type);
   procedure Get_Winners (Race : in out Race_Type);
   function No_Of_Runners (Race : in Race_Type) return Natural;
   function No_Of_Winners (Race : in Race_Type) return Natural;
   procedure Show_Runners (Race : in out Race_Type) ;
   procedure Clear (Race : in out Race_Type);

   procedure Make_Lay_Bet (Race              : in out Race_Type;
                           Bet_Laid          : in out Boolean ;
                           Profit            : in  Profit_Type ;
                           Last_Loss         : in Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Max_Daily_Loss    : in Max_Daily_Loss_Type;
                           Max_Profit_Factor : in Max_Profit_Factor_Type ;
                           Size              : in Size_Type;
                           Min_Price         : in Min_Price_Type;
                           Max_Price         : in Max_Price_Type ) ;

   procedure Make_Lay_Favorite_Bet
                          (Race              : in out Race_Type;
                           Bet_Laid          : in out Boolean ;
                           Profit            : in  Profit_Type ;
                           Last_Loss         : in Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Max_Daily_Loss    : in Max_Daily_Loss_Type;
                           Max_Profit_Factor : in Max_Profit_Factor_Type ;
                           Size              : in Size_Type;
                           Min_Price         : in Min_Price_Type;
                           Max_Price         : in Max_Price_Type ) ;


   procedure Make_Back_Bet (Race                   : in out Race_Type;
                            Bet_Laid               : in out Boolean ;
                            Profit                 : in  Profit_Type ;
                            Last_Loss              : in  Sattmate_Calendar.Time_Type;
                            Saldo                  : in out Saldo_Type ;
                            Max_Daily_Loss         : in Max_Daily_Loss_Type;
                            Max_Profit_Factor      : in Max_Profit_Factor_Type ;
                            Size                   : in Size_Type;
                            Favorite_By            : in Float_8;
                            Back_Price             : in Back_Price_Type;
                            Delta_Price            : in Delta_Price_Type )  ;

   procedure Check_Result (Race              : in out Race_Type;
                           Profit            : in out Profit_Type;
                           Last_Loss         : in out Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Bet_Won           : in out Boolean ;
                           Bet_Type          : in Bet_Type_Type ) ;



   type Race_Pointer_Type is access all Race_Type;

   package Race_Package is new Simple_List_Class (Race_Type);
   Race_List     : Race_Package.List_Type := Race_Package.Create;




   procedure Get_Database_Data (Race_List   : in out Race_Package.List_Type;
                                Db_Name     : in String;
                                Bet_Type    : in Bet_Name_Type;
                                Animal      : Animal_Type;
                                Start_Date  : Sattmate_Calendar.Time_Type;
                                Stop_Date   : Sattmate_Calendar.Time_Type
                               ) ;


end Races;
