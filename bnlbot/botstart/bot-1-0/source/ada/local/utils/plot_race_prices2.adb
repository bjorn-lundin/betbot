
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Text_Io;
with Table_Apricesfinish;
with Table_Arunners;
with Table_Amarkets;
with Table_Abets;
with Calendar2; use Calendar2;
with Logging; use Logging;
with Utils; use Utils;

with Ada.Containers.Doubly_Linked_Lists;
procedure Plot_Race_Prices2 is

  Winner_Market_Not_Found ,
  Place_Market_Not_Found   : exception ;

  History : Table_Apricesfinish.Data_Type;
  Runner  : Table_Arunners.Data_Type;                   
  Bets    : Table_Abets.Data_Type;                   
  type H_Type is record
    Marketid  : Market_Id_Type := (others => ' ');
    Selectionid : Integer_4 := 0;
  end record;     

  package H_Pack is new Ada.Containers.Doubly_Linked_Lists(H_Type);       
  
  H_List : H_Pack.List;      
  H_Data :H_Type;                       
  
  T            : Sql.Transaction_Type;
  Find_Plc_Market,
  Stm_Select_Bets,
  Select_All,
  Stm_Select_Eventid_Selectionid_O : Sql.Statement_Type;
  
  Eos             : Boolean := False;
  
  Suffix           : String (1..2) := (others => ' ');

  F : Text_Io.File_Type;
   
  type Market_Type is (Win, Place);
  Markets : array (Market_Type'range) of Table_Amarkets.Data_Type;
   
begin
      
--   Getopt (Config);  -- process the command line
   
   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "nono",
      Login    => "bnl",
      Password => "bnl");

    Main : loop
      T.Start;
      
        Select_All.Prepare (
            "select PF. MARKETID, PF.SELECTIONID " &
            "from APRICESFINISH PF, AMARKETS MW " &
            "where PF.MARKETID = MW.MARKETID " &
            "and MW.MARKETTYPE = 'WIN' " &        
            "group by PF.MARKETID, PF.SELECTIONID " &
            "order by PF.MARKETID, PF.SELECTIONID");

--      Text_IO.Put_Line(Text_IO.Standard_Error,"--------------------------");
      Select_All.Open_Cursor;
      loop
        Select_All.Fetch(Eos);
        exit when Eos;
        Select_All.Get("MARKETID", H_Data.Marketid);
        Select_All.Get("SELECTIONID", H_Data.Selectionid);
        H_List.Append(H_Data);
      end loop;        
      Select_All.Close_Cursor;      
      Stm_Select_Eventid_Selectionid_O.Prepare( "select * " & 
            "from APRICESFINISH " &
            "where MARKETID = :MARKETID " &
            "and SELECTIONID = :SELECTIONID " &
            "order by PRICETS") ;

      Find_Plc_Market.Prepare(
        "select MP.* from AMARKETS MW, AMARKETS MP " &
        "where MW.EVENTID = MP.EVENTID " &
        "and MW.STARTTS = MP.STARTTS " &
        "and MW.MARKETID = :WINMARKETID " &
        "and MP.MARKETTYPE = 'PLACE' " &
        "and MW.MARKETTYPE = 'WIN' ") ;
        
        
      Stm_Select_Bets.Prepare(
        "select * from ABETS " & 
        "where MARKETID = :MARKETID " & 
        "and BETNAME like 'MR_%' " &
        "order by BETPLACED");
          
      Loop_All : for h of H_List loop
          H_Data := h;
          Stm_Select_Eventid_Selectionid_O.Set("MARKETID", H_Data.Marketid);
          Stm_Select_Eventid_Selectionid_O.Set("SELECTIONID", H_Data.Selectionid);
          Stm_Select_Eventid_Selectionid_O.Open_Cursor;
          History := Table_Apricesfinish.Empty_Data;
          
          Markets(Win).Marketid := H_Data.Marketid;
          Markets(Win).Read(Eos);
          if Eos then
            raise Winner_Market_Not_Found with Markets(Win).Marketid;
          end if;
          
          Find_Plc_Market.Set("WINMARKETID", Markets(Win).Marketid);
          Find_Plc_Market.Open_Cursor;
          Find_Plc_Market.Fetch(Eos);
          if not Eos then
            Markets(Place) := Table_Amarkets.Get(Find_Plc_Market);
            if Markets(Win).Startts /= Markets(Place).Startts then
              raise Place_Market_Not_Found with Markets(Win).Marketid;
            end if;
          else
            raise Place_Market_Not_Found with Markets(Win).Marketid;
          end if;
          Find_Plc_Market.Close_Cursor;

          Log("WIN Marketid: " & H_Data.Marketid & " PLACE Marketid " & Markets(Place).Marketid) ;

          Runner.Marketid    := Markets(Place).Marketid;
          Runner.Selectionid := H_Data.Selectionid;
          -- get the placed runners
          Suffix := "re";
          Runner.Read(Eos);
          if not Eos then
            if Runner.Status(1..6) = "WINNER" then
              Suffix := "wp";
            elsif Runner.Status(1..5) = "LOSER" then
              Suffix := "lo";            
            end if;
          end if;

          -- get the winner runner
          Runner.Marketid    := Markets(Win).Marketid;
          Runner.Selectionid := H_Data.Selectionid;
          
          Runner.Read(Eos);
          if not Eos then
            if Runner.Status(1..6) = "WINNER" then
              Suffix := "ww";
            end if;
          end if;
          
          Text_Io.Create(F, Text_Io.Out_File,
          Skip_All_Blanks(H_Data.Marketid & '_' & H_Data.Selectionid'Img & "_" & Suffix & ".dat"));
          
          Loop_Runner : loop
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos);
            exit Loop_Runner when Eos;
            History := Table_Apricesfinish.Get(Stm_Select_Eventid_Selectionid_O);           
            
            Text_IO.Put_Line(F, Calendar2.String_Date_Time_ISO(History.Pricets, " ", "") & " | " & 
                              History.Marketid & " | " & 
                              History.Selectionid'Img & " | " & 
                              F8_Image(History.Backprice) & " | " & 
                              F8_Image(History.Layprice)   );    
    
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
          Text_Io.Close(F);
          
          
          -- now create files for the bets
          
          
          Stm_Select_Bets.Set("MARKETID", Markets(Place).Marketid); -- bets are on PLACE market
          Stm_Select_Bets.Open_Cursor;
          Loop_Bets : loop
            Stm_Select_Bets.Fetch(Eos);
            exit Loop_Bets when Eos;
            Bets := Table_Abets.Get(Stm_Select_Bets);           
            if Bets.Betwon and then Bets.Status(1..7) = "SETTLED" then
              Suffix := "wi";
            elsif not Bets.Betwon and then Bets.Status(1..7) = "SETTLED" then
              Suffix := "lo";
            else
              Suffix := "nm";
            end if;             
            
	    -- use Place data but name it Win market
            Text_Io.Create(F, Text_Io.Out_File,
            Skip_All_Blanks("bets_" & H_Data.Marketid & "_" & Bets.Betname & "_" & Suffix & ".dat"));
            Log("bet " & Trim(Bets.Betname)) ;
            
            Text_IO.Put_Line(F, Calendar2.String_Date_Time_ISO(Bets.Betplaced, " ", "") & " | " & 
                                Trim(Bets.Betname) & " | " & 
                                F8_Image(Bets.Size) & " | " & 
                                F8_Image(Bets.Price) & " | " & 
                                F8_Image(Bets.Sizematched) & " | " & 
                                F8_Image(Bets.Pricematched)   );    

            Text_Io.Close(F);
          end loop Loop_Bets;            
          Stm_Select_Bets.Close_Cursor;
          
         -- get the new runner ...
         
      end loop Loop_All;
      
      T.Commit ;
      exit;
   end loop Main;

   Sql.Close_Session;

exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Plot_Race_Prices2;
