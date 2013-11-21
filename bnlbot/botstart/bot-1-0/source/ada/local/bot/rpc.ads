
with Gnatcoll.Json; use Gnatcoll.Json;
with Sattmate_Types; use Sattmate_Types;
with Token;
with Bot_Types; use Bot_Types;
-- with Table_Awinners;
-- with Table_Anonrunners;
with Table_Amarkets;

package RPC is

  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean ;
  procedure Bet_Is_Matched(Betid             : Integer_8 ; 
                           Tkn               : Token.Token_Type; 
                           Is_Removed        : out Boolean; 
                           Is_Matched        : out Boolean; 
                           AVG_Price_Matched : out Bet_Price_Type;
                           Size_Matched      : out Bet_Size_Type
                           ) ;
  
  procedure Market_Status_Is_Changed(Market     : in out Table_Amarkets.Data_Type;
                                     Tkn        : in     Token.Token_Type;
                                     Is_Changed :    out Boolean);

--  procedure Check_Market_Result(Market_Id       : in Market_Id_Type;
--                                Tkn             : in Token.Token_Type;
--                                Winner_List     : in out Table_Awinners.Awinners_List_Pack.List_Type;
--                                Non_Runner_List : in out Table_Anonrunners.Anonrunners_List_Pack.List_Type);

  
end RPC;    