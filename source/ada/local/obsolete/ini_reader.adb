

with Gnat.Command_Line; use Gnat.Command_Line;
with Ini;
with Text_Io;
with Gnat.Strings;


procedure Ini_Reader is

   Sa_Ini_File : aliased Gnat.Strings.String_Access;
   Sa_Section  : aliased Gnat.Strings.String_Access;
   Sa_Variable : aliased Gnat.Strings.String_Access;
   Sa_Default  : aliased Gnat.Strings.String_Access;

   Config : Command_Line_Configuration;

begin

   Define_Switch
     (Config,
      Sa_Ini_File'access,
      "-i:",
      Long_Switch => "--ini=",
      Help        => "ini file");

   Define_Switch
     (Config,
      Sa_Section'access,
      "-s:",
      Long_Switch => "--section=",
      Help        => "section");

   Define_Switch
     (Config,
      Sa_Variable'access,
      "-v:",
      Long_Switch => "--variable=",
      Help        => "variable");

   Define_Switch
     (Config,
      Sa_Default'access,
      "-d:",
      Long_Switch => "--default=",
      Help        => "default");

   Getopt (Config);  -- process the command line
   --   Display_Help (Config);

   Ini.Load(File_Name => Sa_Ini_File.all);


   Text_Io.Put_Line( Ini.Get_Value (Section  => Sa_Section.all,
                                    Variable => Sa_Variable.all,
                                    Default  => Sa_Default.all));

end Ini_Reader;