
with Games;
with Aliases;
with Unknowns;

with Gnat; use Gnat;
with Gnat.Awk;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions;
with Logging; use Logging;
with Ada.Command_Line;
with Stacktrace;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Calendar2;
with Gnat.Os_Lib;



procedure Football_Live_Feed is

  Global_Filename : String := "/home/bnl/tmp/score2.dat";
  Global_Url : String := "http://www.goalserve.com/updaters/soccerupdate.aspx?ts=" & Calendar2.Clock.To_String;

  Debug : Boolean := False;
  procedure D(What : String) is
  begin
    if Debug then
      Put_Line(What);
    end if;
  end D;


  procedure Retrieve(Url,Filename : String) is
    Arg_List : Gnat.Os_Lib.Argument_List(1..6);
    Success : Boolean := False;
    Return_Code : Integer := 0;
  begin
    Arg_List(1) := new String'("-dump");
    Arg_List(2) := new String'("--image_links=0");
    Arg_List(3) := new String'("--hiddenlinks=ignore");
    Arg_List(4) := new String'("--notitle");
    Arg_List(5) := new String'("--nolist");
    Arg_List(6) := new String'(Global_Url);

    Gnat.Os_Lib.Spawn(Program_Name => "/usr/bin/lynx",
                      Args         => Arg_List,
                      Output_File  => Filename,
                      Success      => Success,
                      Return_Code  => Return_Code,
                      Err_To_Out   => True);

    for I in Arg_List'Range loop
      Gnat.Os_Lib.Free(X => Arg_List(I));
    end loop;


  end Retrieve;
--  http://www.goalserve.com/updaters/soccerupdate.aspx

  procedure Parse_File(Filename : String) is
    Score : AWK.Session_Type;
    use type Awk.Count;
    Football_Fields : array(1..2) of Awk.Count := (3,0);
    Score_Field : Awk.Count := 0;
    type Team_Field_Type is (Home,Away);
    Teamnames : array(Team_Field_Type'Range) of Unbounded_String;
    Scores : array(Team_Field_Type'Range) of Integer;
    Cc : String(1..2) := "  ";

    Game           : Games.Game_Type;
    Alias          : Aliases.Alias_Type;
    Unknown        : Unknowns.Unknown_Type;
    Eos            : Boolean := False;
    Highlight_Seen : Boolean := False;

  begin
    AWK.Set_Current (Score);
    AWK.Open (Separators => "", Filename => Filename);
    while not Awk.End_Of_File loop
      Awk.Get_Line;
      D("--------------------------------------------");
      Football_Fields(2) := 0;
      Score_Field := 0;
      for N of Teamnames loop
        N := Null_Unbounded_String;
      end loop;


      if Awk.Number_Of_Fields(Session => Score) < 2 then
        if Highlight_Seen then
          Cc := (others => ' ');
        end if;

      elsif Awk.Number_Of_Fields(Session => Score) > 3 then
         for I in 1 .. Awk.Number_Of_Fields(Session => Score) loop
           D(I'Img & ":" & Awk.Field (i));
         end loop;
         D("");

        if Awk.Field(2) = "Belgium" and then Awk.Field(4) = "Jupiler" and then Awk.Field(5) = "League" then
          Cc :="BE";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Denmark" and then Awk.Field(4) = "Superliga" then
          Cc :="DK";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "England" and then Awk.Field(4) = "Premier" and then Awk.Field(5) = "League" then
          Cc :="GB";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "France" and then Awk.Field(4) = "Ligue" and then Awk.Field(5) = "1" then
          Cc :="FR";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Germany" and then Awk.Field(4) = "Bundesliga" then
          Cc :="DE";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Italy" and then Awk.Field(4) = "Serie" and then Awk.Field(5) = "A" then
          Cc :="IT";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Netherlands" and then Awk.Field(4) = "Eredivisie" then
          Cc :="NL";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Portugal" and then Awk.Field(4) = "Primeira" and then Awk.Field(5) = "Liga" then
          Cc :="PT";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Scotland" and then Awk.Field(4) = "Premiership" then
          Cc :="GB";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Spain" and then Awk.Field(4) = "Laliga" then
          Cc :="ES";
          Highlight_Seen := False;
        elsif Awk.Field(2) = "Sweden" and then Awk.Field(4) = "Allsvenskan" then
          Cc :="SE";
          Highlight_Seen := False;

        elsif Awk.Number_Of_Fields(Session => Score) >= 6 and then Awk.Field(6) = "Highlights!" then
          Highlight_Seen := True;

        elsif Awk.Field (Football_Fields(1)) = "Football" then
          for I in Football_Fields(1)+1 .. Awk.Number_Of_Fields(Session => Score) loop
            D(I'Img & "::" & Awk.Field (I) );
            if Awk.Field(I) = "Football" then
              Football_Fields(2) := I;
            end if;

            declare
              F : String := Awk.Field(I);
            begin
              for J in F'Range loop
                case F(J) is
                  when '[' =>  Score_Field := I;
                  when others => null;
                end case;
              end loop;
            end;
          end loop;

          if Football_Fields(2) >  Football_Fields(1) then
            D("-------------------");
            D( Awk.Field (0));
            D("-------------------");
          end if;
          if Score_Field > 0 then
            D("---- score----------");
            D( Awk.Field (Score_Field));
            D("-------------------");
            declare
              Left_Bracket,
              Dash,
              Right_Bracket : Integer := 0;
              F : String := Awk.Field (Score_Field);
            begin
              for M in F'Range loop
                case F(M) is
                  when '[' => Left_Bracket := M;
                  when '-' => Dash := M;
                  when ']' => Right_Bracket := M;
                  when others => null;
                end case;

                if Left_Bracket > 0 and then
                  Dash  > Left_Bracket and then
                  Right_Bracket > Dash then

                  if F(Left_Bracket+1 ..  Dash-1) = "?" then
                    Scores(Home) := 0;
                  else
                    Scores(Home) := Integer'Value(F(Left_Bracket+1 .. Dash-1));
                  end if;

                  if F(Dash+1 ..  Right_Bracket-1) = "?" then
                    Scores(Away) := 0;
                  else
                    Scores(Away) := Integer'Value(F(Dash+1 ..  Right_Bracket-1));
                  end if;
                end if;
              end loop;
              for H in Team_Field_Type'Range loop
                D("Score " & H'Img & "=" & Scores(H)'Img );
              end loop;
            end ;
          end if;

          for K in Football_Fields(1)+1 .. Score_Field-1 loop
            Append(Teamnames(Home),Awk.Field(K) & " ");
          end loop;

          for K in Score_Field+1 .. Football_Fields(2)-1 loop
            Append(Teamnames(Away),Awk.Field(K) & " ");
          end loop;

          D("---- Home----------");
          D( To_String(Teamnames(Home)));
          D("-------------------");

          D("---- Away----------");
          D( To_String(Teamnames(Away)));
          D("-------------------");

          if Cc /= "  " then
            declare
              Unknown_Present : Boolean := True;
            begin
              -- check to se if both teams are known
              for H in Team_Field_Type'Range loop
                Move(To_String(Teamnames(H)), Alias.Teamname);
                Eos := True;
                --Alias.Read_Teamname(Eos);
                if not Eos then
                  null;
                else
                  Unknown_Present := True;
                  Unknown.Countrycode := Cc;
                  Unknown.Teamname := Alias.Teamname;
                  Put_Line(Unknown.To_String);
                  --Unknown.Insert;
                end if;
              end loop;

              --if not Unknown_Present then
              --  Game
              --
              --end if;

            end;
          end if;
        end if;
      end if;
    end loop;

    Awk.Close (Score);

  end Parse_File;



begin

  Retrieve(Url => Global_Url, Filename => Global_Filename);
  Parse_File(Filename => Global_Filename);

exception
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;


end Football_Live_Feed;
