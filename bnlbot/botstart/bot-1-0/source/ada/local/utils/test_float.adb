with text_io;

with bot_types ; use bot_types;

procedure test_float is
    Price_String  : String         := "1.01"; --Price; --F8_Image(Fixed_Type(Price)); -- 2 decimals only
    Local_Price   : Bet_Price_Type := Bet_Price_Type'Value(Price_String); -- to avoid INVALID_BET_PRICE
    f : float := Float(Local_Price);
begin
  text_io.put_line(F'img);
end test_float;

