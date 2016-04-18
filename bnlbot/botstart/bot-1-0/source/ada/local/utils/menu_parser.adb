with Ada.Exceptions;
with Ada.Command_Line;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Text_io;
with Ada.Direct_IO ;

with Ada.Directories;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Logging; use Logging;

with Gnatcoll.JSON ;use Gnatcoll.JSON;

with Stacktrace;

procedure  Menu_Parser is
  Cmd_Line           : Command_Line_Configuration;
  Sa_Input_File      : aliased Gnat.Strings.String_Access;
  Me : constant String := "Menu_Parser.Main";
  -----------------
  function Load_File(Filename : in String) return String is
     use Ada.Directories;
     File_Size    : constant Natural := Natural (Size (Filename));
     subtype JSON_String is String (1 .. File_Size);
     type JSON_String_Ptr is access JSON_String;
     Content : constant JSON_String_Ptr := new JSON_String; 
     package File_IO is new Ada.Direct_IO(JSON_String);
     File : File_IO.File_Type;
  begin
     File_IO.Open (File => File, Mode => File_IO.In_File, Name => Filename);
     File_IO.Read (File => File, Item => Content.all);
     File_IO.Close(File => File);
     return Content.all;    
  end Load_File;
  --------------------------  
  Menu : Json_Value;
  Children : array (1..7) of JSON_Array := (others => Empty_Array);


  
begin
   Define_Switch
    (Cmd_Line,
     Sa_Input_File'access,
     Long_Switch => "--file=",
     Help        => "input json file");

   Getopt (Cmd_Line);  -- process the command line
   Menu := Read (Strm     => Load_File(Sa_Input_File.all),
                 Filename => "debug.out");

   Log("0 type:" & Menu.Get("type") & " name:" & Menu.Get("name"));
   if Menu.Has_Field("children") then
     Children(1) := Menu.Get("children");
     for i in 1 .. Length(Children(1)) loop
       declare
         Child1 : Json_Value := Get(Children(1),i);
       begin
         if Child1.Has_Field("children") and then Child1.Get("type") = "EVENT_TYPE" and then  Child1.Get("name") ="Soccer" then 
           Log("    1 type:" & Child1.Get("type") & " name:" & Child1.Get("name"));
           Children(2) := Child1.Get("children");
           for j in 1 .. Length(Children(2)) loop
             declare
               Child2 : Json_Value := Get(Children(2),j);
             begin
               if Child2.Has_Field("children") and then Child2.Get("type") = "GROUP" and then
                  (--Child2.Get("name") = "Argentinian Soccer" or
                   Child2.Get("name") = "Belgian Soccer" or
                  -- Child2.Get("name") = "Brazilian Soccer" or
                   Child2.Get("name") = "Danish Soccer" or
                   Child2.Get("name") = "Dutch Soccer" or
                   Child2.Get("name") = "English Soccer" or
                   Child2.Get("name") = "German Soccer" or
                   Child2.Get("name") = "Italian Soccer" or
                   Child2.Get("name") = "Portuguese Soccer" or
                   Child2.Get("name") = "Spanish Soccer" or
                   Child2.Get("name") = "Swedish Soccer" ) then
                  
                 Log("        2 type:" & Child2.Get("type") & " name:" & Child2.Get("name"));
                 Children(3) := Child2.Get("children");
                 for k in 1 .. Length(Children(3)) loop
                   declare
                     Child3 : Json_Value := Get(Children(3),k);
                   begin
                     if Child3.Has_Field("children") and then Child3.Get("type") = "EVENT" and then
                        (Child3.Get("name") = "Belgian Jupiler League" or  -- belgien
                         Child3.Get("name") = "Danish Superliga" or        -- danmark
                         Child3.Get("name") = "Eredivisie" or              -- holland
                         Child3.Get("name") = "Barclays Premier League" or -- england
                         Child3.Get("name") = "Bundesliga 1" or            -- tyskland
                         Child3.Get("name") = "Bundesliga 2" or            -- tyskland
                         Child3.Get("name") = "Serie A" or                 -- italien
                         Child3.Get("name") = "Primeira Liga" or           -- portugal
                         Child3.Get("name") = "Allsvenskan" or             -- sverige
                         Child3.Get("name") = "Primera Division" ) then    -- spanien
                       Log("            3 type:" & Child3.Get("type") & " name:" & Child3.Get("name"));
                       Children(4) := Child3.Get("children");
                       for l in 1 .. Length(Children(4)) loop
                         declare
                           Child4 : Json_Value := Get(Children(4),l);
                         begin
                           if Child4.Has_Field("children") and then Child4.Get("type") = "GROUP" and then Child4.Get("name")(1..8) = "Fixtures" then
                             Log("                4 type:" & Child4.Get("type") & " name:" & Child4.Get("name"));
                             Children(5) := Child4.Get("children");
                             for m in 1 .. Length(Children(5)) loop
                               declare
                                 Child5 : Json_Value := Get(Children(5),m);
                               begin
                                 if Child5.Has_Field("children") then
                                   Log("                    5 type:" & Child5.Get("type") & " name:" & Child5.Get("name"));
                                   Children(6) := Child5.Get("children");
                                   for n in 1 .. Length(Children(6)) loop
                                     declare
                                       Child6 : Json_Value := Get(Children(6),n);
                                     begin
                                         --Log("                        6 type:" & Child6.Get("type") & " name:" & Child6.Get("name"));
                                       if Child6.Get("type") = "MARKET" and then
                                          Child6.Get("exchangeId") = "1" and then
                                          (Child6.Get("marketType") = "MATCH_ODDS" or 
                                           Child6.Get("marketType") = "CORRECT_SCORE" ) then   
                                         Log("                        6 id:" & Child6.Get("id") & " name:" & Child6.Get("name"));
                                         -- do stuff here
                                         --insert into new table
                                       end if;
                                     end;
                                   end loop;
                                 end if;
                               end;
                             end loop;
                           end if;
                         end;
                       end loop;
                     end if;
                   end;
                 end loop;
               end if;
             end;
           end loop;
         end if;
       end;
     end loop;
   end if;

                 
--   Log(Me,Menu.Write); 
exception
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Text_io.Put_Line(Last_Exception_Name);
      Text_io.Put_Line("Message : " & Last_Exception_Messsage);
      Text_io.Put_Line(Last_Exception_Info);
      Text_io.Put_Line("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

end Menu_Parser;

