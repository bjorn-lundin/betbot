
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Text_Io;
with Table_Araceprices;
--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;
with Calendar2; use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;

with Utils; use Utils;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Plot_Race_Prices is
    History : Table_Araceprices.Data_Type;
--    Bad_Input : exception;
                     
    type H_Type is record
      Marketid  : Market_Id_Type := (others => ' ');
      Selectionid : Integer_4 := 0;
    end record;     
                     
    package H_Pack is new Simple_List_Class(H_Type);       
    H_List : H_Pack.List_Type := H_Pack.Create;      
    H_Data :H_Type;                       

   T            : Sql.Transaction_Type;
   Select_All,
   Stm_Select_Eventid_Selectionid_O : Sql.Statement_Type;
   
   Eos,
   Eos2             : Boolean := False;

--   Config           : Command_Line_Configuration;

--  Secs : Integer_4 := 0;
   F : Text_Io.File_Type;
   
   
begin
      
--   Getopt (Config);  -- process the command line

   
   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bnl",
      Login    => "bnl",
      Password => "bnl");

    Main : loop
      T.Start;
      
        Select_All.Prepare (
            "select MARKETID,SELECTIONID " &
            "from ARACEPRICES " &
--            "where MARKETID = '1.113237240' " &
            "group by MARKETID,SELECTIONID " &
            "order by MARKETID,SELECTIONID");

--      Text_IO.Put_Line(Text_IO.Standard_Error,"--------------------------");
      Select_All.Open_Cursor;
      loop
        Select_All.Fetch(Eos);
        exit when Eos;
        Select_All.Get("MARKETID", H_Data.Marketid);
        Select_All.Get("SELECTIONID", H_Data.Selectionid);
        H_Pack.Insert_At_Tail(H_List,H_Data);
      end loop;        
      Select_All.Close_Cursor;      
      Stm_Select_Eventid_Selectionid_O.Prepare( "select * " & 
            "from ARACEPRICES " &
            "where MARKETID = :MARKETID " &
            "and SELECTIONID = :SELECTIONID " &
            "order by PRICETS"  ) ;

      Loop_All : while not H_Pack.Is_Empty(H_List) loop
          H_Pack.Remove_From_Head(H_List, H_Data);           
          Stm_Select_Eventid_Selectionid_O.Set("MARKETID", H_Data.Marketid);
          Stm_Select_Eventid_Selectionid_O.Set("SELECTIONID", H_Data.Selectionid);
          Stm_Select_Eventid_Selectionid_O.Open_Cursor;
          History := Table_Araceprices.Empty_Data;
          
          Log("MARKETID: " & H_Data.Marketid);
          
          Text_Io.Create(F, Text_Io.Out_File,
          Skip_All_Blanks(H_Data.Marketid & '_' & H_Data.Selectionid'Img & ".dat"));
          
          Loop_Runner : loop
            Stm_Select_Eventid_Selectionid_O.Fetch(Eos2);
            exit Loop_Runner when Eos2;
            History := Table_Araceprices.Get(Stm_Select_Eventid_Selectionid_O);           
            
            Text_IO.Put_Line(F, Calendar2.String_Date_Time_ISO(History.Pricets, " ", "") & " | " & 
                              History.Marketid & " | " & 
                              History.Selectionid'Img & " | " & 
                              History.Status(1..11) & " | " & 
                              F8_Image(History.Backprice) & " | " & 
                              F8_Image(History.Layprice)   );    
    
          end loop Loop_Runner;            
          Stm_Select_Eventid_Selectionid_O.Close_Cursor;
          Text_Io.Close(F);
         --new runner ...
         
      end loop Loop_All;
      T.Commit ;
      exit;
   end loop Main;

   Sql.Close_Session;

exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Plot_Race_Prices;
