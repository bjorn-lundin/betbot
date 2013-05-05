#
#
# 9.8 ? Added Change_File_Encoding
# chg-21835 bnl 2011-04-13 Added Table_Has_IXX_Timestamp
# chg-26694 2013-02-18 use varchar2 instead of char in oracle
# -----------------------------------

package require ART_Definitions
package require dom

package provide Repo_Utils 1.0

namespace eval Repo_Utils {

  namespace export Write_Ma_Xml
  namespace export Set_Table_Attributes
  namespace export Set_Column_Attributes
  namespace export Set_Index
  namespace export Set_Term_Attributes
  namespace export Set_Label_Attributes
  namespace export Set_Presentation_Attributes
  namespace export Set_Code_List_Attributes
  namespace export Set_Code_Item_Attributes
  namespace export Set_Translation_Attributes
  namespace export Set_Code_Item_Term_Attributes
  namespace export Set_Snapshot_Settings
  namespace export Set_MaAstro_Attributes
  namespace export Find_Target_Path
  namespace export Type_To_String
  namespace export Table_List
  namespace export All_Fields_Are_Keys
  namespace export Delete
  namespace export Print_Paths
  namespace export Header
  namespace export Table_Has_IXX_Fields
  namespace export Table_Has_IXX_Fields_2
  namespace export Table_Has_IXX_Timestamp
  namespace export Table_Has_IXX_Timestamp_2
  namespace export Get_Attributes
  namespace export To_M2_Lang
  namespace export Data_Type_To_Numeric
  namespace export Type_To_Ada_Type
  namespace export Type_To_SQL_Type
  namespace export Default_Values
  namespace export Get_Tablespace
  namespace export Null_Data_For_Type
  namespace export Null_Data_For_Type_At_Comparison
  namespace export Null_Data_For_Type_In_Db
  namespace export Coded_Values_List
  namespace export Coded_Values_File_List
  namespace export Create_Document_From_XML
  namespace export Escape
  namespace export Info
  namespace export Debug
  namespace export Change_File_Encoding
  namespace export View_List

# constants

  namespace export Verbosity

  namespace export Loadable
  namespace export Not_Loadable

  ########################################

  set Not_Loadable 0
  set Loadable 1

  set Verbosity 0
  global Global_Cv_List
  set Global_Cv_List {}

  proc Get_Config_File {} {
    return [file join $::env(SATTMATE_CONFIG) local stingray sattmate.xml]
  }

  set Table_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables prefix]
  set Clreq_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs prefix]
  set Term_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Terms prefix]
  set Code_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Codes prefix]
  set Label_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Labels prefix]
  set View_File_Name_Prefix [ART_Definitions::Find_Target_Path $ART_Definitions::Views prefix]

  proc Debug {what} {
    if {$Repo_Utils::Verbosity >= 2} {
      puts stderr $what
    }
  }
  #########################################################################
  proc Info {what} {
    if {$Repo_Utils::Verbosity >= 1} {
      puts stderr $what
    }
  }
  #########################################################################


  ######## Global variables, local to package #########
  set Verbosity 0
  ########################################

  ##### Exported procedures ##############

  proc Get_Attributes {Element} {
    set Attr_Ptr [dom::node cget $Element -attributes]
    upvar $Attr_Ptr Attr
    return [array get Attr]
  }

  #########################################################################

  proc Set_Table_Attributes {t Wiz Desc Name Loadable Tablespace {LicId 0} {LogMask 0} {LogicId 0} {SafeAdd 0} {StorageClass 0} {CleanSetup 0} {CleanProd 0} } {
  #Wiz="1" Desc="PlanCalc request    " Name="P06T91  " LicId="0" LogMask="0" LogicId="0" SafeAdd="0" Loadable="0
  # The default ones are not needed by M2, hence we don't care either
    ::dom::element setAttribute $t Wiz          $Wiz
    ::dom::element setAttribute $t Desc         $Desc
    ::dom::element setAttribute $t Name         $Name
    ::dom::element setAttribute $t Tablespace   $Tablespace
    ::dom::element setAttribute $t LicId        $LicId
    ::dom::element setAttribute $t LogMask      $LogMask
    ::dom::element setAttribute $t LogicId      $LogicId
    ::dom::element setAttribute $t SafeAdd      $SafeAdd
    ::dom::element setAttribute $t Loadable     $Loadable
    ::dom::element setAttribute $t StorageClass $StorageClass
    ::dom::element setAttribute $t CleanSetup   $CleanSetup
    ::dom::element setAttribute $t CleanProd    $CleanProd
  }

  #########################################################################

  proc Set_Snapshot_Settings {s {SnapshotBase 1} {TruncateBase 1} {SnapshotData 1} {TruncateData 1} {SnapshotEdu 1} {TruncateEdu 1} {SnapshotFull 1} {TruncateFull 1} } {
    ::dom::element setAttribute $s SnapshotBase $SnapshotBase
    ::dom::element setAttribute $s TruncateBase $TruncateBase
    ::dom::element setAttribute $s SnapshotData $SnapshotData
    ::dom::element setAttribute $s TruncateData $TruncateData
    ::dom::element setAttribute $s SnapshotEdu  $SnapshotEdu
    ::dom::element setAttribute $s TruncateEdu  $TruncateEdu
    ::dom::element setAttribute $s SnapshotFull $SnapshotFull
    ::dom::element setAttribute $s TruncateFull $TruncateFull
    ::dom::element setAttribute $s SnapshotBase $SnapshotBase
    ::dom::element setAttribute $s SnapshotBase $SnapshotBase
    ::dom::element setAttribute $s SnapshotBase $SnapshotBase
  }

  #########################################################################
  proc Set_Column_Attributes {c Name Primary Size Type {Foreign 0} {Indexed 0} {Unique 0} {AllowNull 0} {Description ""} {NA 0} {Owned 0} {Right 0} {Setup 3} } {
  #  <Column NA="0" Name="p08id   " Size="4" Type="4" Owned="0" Right="0" Setup="0" Unique="0" Foreign="0" Indexed="0" Primary="1"/>
  # Nothing is needed by M2, hence we don't care either
    ::dom::element setAttribute $c Name      $Name
    ::dom::element setAttribute $c Primary   $Primary
    ::dom::element setAttribute $c Size      $Size
    ::dom::element setAttribute $c Type      $Type
    ::dom::element setAttribute $c Foreign   $Foreign
    ::dom::element setAttribute $c Indexed   $Indexed
    ::dom::element setAttribute $c Unique    $Unique
    ::dom::element setAttribute $c AllowNull $AllowNull
    ::dom::element setAttribute $c NA        $NA
    ::dom::element setAttribute $c Owned     $Owned
    ::dom::element setAttribute $c Right     $Right
    ::dom::element setAttribute $c Setup     $Setup
#BNL Added Description 2008-01-23
    ::dom::element setAttribute $c Description $Description

  }
  #########################################################################
  proc Set_MaAstro_Attributes {e {Default_Namespace "http://www.consafelogistics.com/sattmate" }} {
  # it seems that the parser cannot parse a document with xmlns in it :-(
  # code commented, but one day...
  # calls are in make_stingray_reposity.tcl
  #  ::dom::element setAttribute $e xmlns $Default_Namespace
  }
  #########################################################################

  proc Set_Index {Index Fields Type} {
    ::dom::element setAttribute $Index Columns $Fields
    ::dom::element setAttribute $Index type $Type
  }
  #########################################################################

  proc Set_Term_Attributes {e Name Type Size} {
    ::dom::element setAttribute $e Name $Name
    ::dom::element setAttribute $e Type $Type
    ::dom::element setAttribute $e Size $Size
  }
  #########################################################################
  proc Set_Label_Attributes {e Name Type Size {Level B}} {
    ::dom::element setAttribute $e Name $Name
    ::dom::element setAttribute $e Type $Type
    ::dom::element setAttribute $e Size $Size
    ::dom::element setAttribute $e Level $Level ; #9.8-17468 added the Level
  }
  #########################################################################

  proc Set_Presentation_Attributes {e Size Long_Description} {
    ::dom::element setAttribute $e Size     $Size
    ::dom::element setAttribute $e LongDesc $Long_Description
  }
  #########################################################################

  proc Set_Code_List_Attributes {e Define Description} {
    ::dom::element setAttribute $e Define $Define
    ::dom::element setAttribute $e Description $Description
  }
  #########################################################################

  proc Set_Code_Item_Attributes {e Code Text Define} {
    ::dom::element setAttribute $e Code   $Code
    ::dom::element setAttribute $e Text   $Text
    ::dom::element setAttribute $e Define $Define
  }
  #########################################################################

  proc Set_Translation_Attributes {e Language Long_Description Short_Description} {
    ::dom::element setAttribute $e Language $Language
    ::dom::element setAttribute $e LongDesc $Long_Description
    ::dom::element setAttribute $e ShortDesc $Short_Description
  }
  #########################################################################
  proc Set_Code_Item_Term_Attributes {e Code Text} {
    ::dom::element setAttribute $e Code   $Code
    ::dom::element setAttribute $e Text   $Text
  }

  #########################################################################

  proc Write_Ma_Xml {The_Term The_Target_Path The_Doc The_Prefix} {
    set t [string tolower $The_Term]
    set Target $The_Prefix\_$t.xml
    if {[catch \
           {set File_Ptr \
              [open [file join $The_Target_Path $Target] {WRONLY CREAT TRUNC}]} \
           Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }
#    puts $File_Ptr [::dom::DOMImplementation serialize $The_Doc -indent 2 -encoding iso8859-1]
#    fconfigure $File_Ptr -encoding iso8859-1
    puts $File_Ptr [::dom::DOMImplementation serialize $The_Doc -indent 2]
    catch {close $File_Ptr}
  }
  ########################################################
  proc Find_Table_Packages_Target_Path {The_Type} {
    puts stderr "This is [info level 0]"
    puts stderr "Should call Find_Target_Path instead"
    if { [catch { set tmp [info level -1]} ] } {

    } else {
      puts stderr "Called from: \n $tmp"
    }
    return [Find_Target_Path $The_Type]
  }
  ########################################################

    proc Data_Type_To_Numeric {Data_Type} {
    # 1  -> Char
    # 2  -> Int        -- 32 bit signed
    # 3  -> Short      -- 16 bit signed
    # 4  -> Long
    # 5  -> Float
    # 6  -> Double
    # 7  -> Boolean
    # 8  -> Char-code
    # 9  -> Short-code
    # 10 -> Date
    # 11 -> Time
    # 15 -> Timestamp
    # 23 -> Clob
    # 24 -> Nclob
    # 26 -> Blob
    set dt [string tolower $Data_Type]
    if {[string equal $dt char]} {
      return 1
    } elseif {[string equal $dt int]} {
      return 2
    } elseif {[string equal $dt short]} {
      return 3
    } elseif {[string equal $dt long]} {
      return 4
    } elseif {[string equal $dt float]} {
      return 5
    } elseif {[string equal $dt double]} {
      return 6
    } elseif {[string equal $dt boolean]} {
      return 7
    } elseif {[string equal $dt char-code]} {
      return 8
    } elseif {[string equal $dt short-code]} {
      return 9
    } elseif {[string equal $dt date]} {
      return 10
    } elseif {[string equal $dt time]} {
      return 11
    } elseif {[string equal $dt timestamp]} {
      return 15
    } elseif {[string equal $dt clob]} {
      return 23
    } elseif {[string equal $dt nclob]} {
      return 24
    } elseif {[string equal $dt blob]} {
      return 26
    } else {
      error "No such type: $Data_Type"
    }
  }
  ########################################


  proc Type_To_String {Type} {
    switch -exact -- $Type {
      1  {return "STRING_FORMAT"}
      2  {return "INTEGER_4_FORMAT"}
      3  {return "INTEGER_8_FORMAT"}
      6  {return "FLOAT_8_FORMAT"}
      7  {return "INTEGER_4_FORMAT"}
      9  {return "INTEGER_4_FORMAT"}
      10 {return "DATE_FORMAT"}
      11 {return "TIME_FORMAT"}
      15 {return "TIMESTAMP_FORMAT"}
      23 {return "CLOB_FORMAT"}
      24 {return "NCLOB_FORMAT"}
      26 {return "BLOB_FORMAT"}
      default {
          puts stderr "[info level 0] - Type -> $Type is unknown..."
          exit 1
        }
    }
  }

########################################################
  proc Type_To_Ada_Type {Type Size} {
    switch -exact -- $Type {
      1  {
        if {[string equal $Size 1]} {
          return "Character"
        } else {
          return "String"
        }
      }
      2  {return "Integer_4"}
      3  {return "Integer_8"}
      6  {return "Float_8"}
      7  {return "Boolean"}
      9  {return "Integer_4"}
      10 {return "Time_Type"}
      11 {return "Time_Type"}
      15 {return "Time_Type"}
      23 {return "Clob"}
      24 {return "Nclob"}
      26 {return "Blob"}
      default {
          puts stderr "[info level 0] - Type -> $Type is unknown..."
          exit 1
      }
    }
  }

########################################################
  proc Type_To_SQL_Type {Database Type {Size 0}} {
#chg-26694
#   if {$Size < 256 }  {
#   return "CHAR"
# } else {
#   return "VARCHAR2"
# }

    switch -exact -- $Database {
      oracle {
        switch -exact -- $Type {
          1  {return "VARCHAR2" ;# chg-26694}
          2  {return "NUMBER(9)"}
          6  {return "NUMBER"}
          7  {return "NUMBER(9)"}
          9  {return "NUMBER(9)"}
          10 {return "DATE"}
          11 {return "DATE"}
          15 {return "TIMESTAMP(3)"}
          23 {return "CLOB"}
          24 {return "NCLOB"}
          26 {return "BLOB"}
          default {
              puts stderr "[info level 0] - Type -> $Type is unknown..."
              exit 1
          }
        }
      }
      postgresql {
        switch -exact -- $Type {
          1  {return "varchar" ;# "text"}
          2  {return "integer"}
          3  {return "bigint"}
          6  {return "float"}
          7  {return "integer"}
          9  {return "integer"}
          10 {return "date"}
          11 {return "time without time zone"}
          15 {return "timestamp without time zone"}
          23 {return "varchar"}
          24 {return "varchar"}
          26 {return "bytea"}
          default {
              puts stderr "[info level 0] - Type -> $Type is unknown..."
              exit 1
          }
        }
      }
      sqlserver {
        switch -exact -- $Type {
          1  {return "varchar"}
          2  {return "integer"}
          6  {return "float"}
          7  {return "integer"}
          9  {return "integer"}
          10 {return "datetime2(3)"}
          11 {return "datetime2(3)"}
          15 {return "datetime2(3)" ; # timestamp is set by sql-server itself, and cannot be used}
          23 {return "text"}
          24 {return "ntext"}
          26 {return "blob"}
          default {
              puts stderr "[info level 0] - Type -> $Type is unknown..."
              exit 1
          }
        }
      }
      default {
        puts stderr "[info level 0] - Type -> $Type is unknown..."
        exit 1
      }
    }
  }
########################################################
  proc Null_Data_For_Type {Type Size} {
    switch -exact $Type {
      1  {
        if {[string equal $Size 1]} {
          return "' '"
        } else {
          return "\(others => ' '\)"
        }
      }
      2  {return "0"}
      3  {return "0"}
      6  {return "0.0"}
      7  {return "0" ; # We never use boolean in db "False"}
      9  {return "0"}
      10 {return "Time_Type_First"}
      11 {return "Time_Type_First"}
      15 {return "Time_Type_First"}
      23 {return "Null_Unbounded_String"}
      24 {return "\(others => ' '\)"}
      26 {return "\(others => ' '\)"}
      default {
          puts stderr "[info level 0] - Type -> $Type is unknown..."
          exit 1
        }
    }
  }

########################################################
  proc Null_Data_For_Type_At_Comparison {Type Size Var_Name} {
    switch -exact $Type {
      1  {
        if {[string equal $Size 1]} {
          return "' '"
        } else {
          return "\($Var_Name'Range => ' '\)"
        }
      }
      23 {return "Null_Unbounded_String"}
      24 {return "Null_Unbounded_String"}
      26 {return "Null_Unbounded_String"}
      default {
          return [Null_Data_For_Type $Type $Size]
      }
    }
  }

########################################################3
  proc Null_Data_For_Type_In_Db {Type Size} {
    # 7 -> 2 ; Boolean -> Integer_4
    switch -exact $Type {
      7       {return [Null_Data_For_Type 2 $Size]}
      default {return [Null_Data_For_Type $Type $Size]}
    }
  }
########################################################3

proc Default_Values {Used_Type db} {
  set R {}
  switch -exact -- $db {
    oracle {
      switch -exact -- $Used_Type {
          1  {set R "default ' '" }
          6  {set R "default 0.0" }
          2 -
          3 -
          4 -
          7 -
          9  {set R "default 1" }
      }
    }
    sqlserver {
      switch -exact -- $Used_Type {
          1  {set R "default ' '" }
          6  {set R "default 0.0" }
          2 -
          3 -
          4 -
          7 -
          9  {set R "default 1" }
      }
    }
    postgresql {
      switch -exact -- $Used_Type {
          1  {set R "default ' '" }
          6  {set R "default 0.0" }
          2 -
          3 -
          4 -
          7 -
          9  {set R "default 1" }
      }
    }
    default {puts stderr "Default_Values - unsupported db - '$db'" ; exit 1}
  }
  return $R
}
##############################################################

  proc Table_List {{Type 0} {Fullnames 0}} {
#    puts "in Table_List Type = $Type"
    set Clreqs_Tables {}
    set Tables_Tables {}
    ####################

    set Return_List {}
    set DB_Dir [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables]
    set CL_Dir [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs]
    set Table_Files [lsort [glob -nocomplain -directory $DB_Dir $ART_Definitions::Table_File_Name_Prefix\_*.xml]]
    set Clreq_Files [lsort [glob -nocomplain -directory $CL_Dir $ART_Definitions::Clreq_File_Name_Prefix\_*.xml]]
    set Files {}
    set Dir $DB_Dir
    switch -exact $Type {
      0 { set Files [concat $Table_Files $Clreq_Files] }
      1 { set Files $Table_Files }
      2 { set Files $Clreq_Files ; set Dir $CL_Dir}
      default {
          puts stderr "Type -> $Type is unknown..."
          exit 1
      }
    }

    if {$Fullnames} {
      foreach File $Files {
        lappend Return_List [file join $Dir $File]
      }
    } else {
      foreach File $Files {
        if {[catch {set File_Ptr [open $File {RDONLY}]}  Result]} {
          puts stderr "Open - File - '$File'"
          puts stderr "[info level 0] - $Result"
          exit 1
        }

        if {[catch { set Local_Doc [::dom::DOMImplementation parse [read $File_Ptr]]}  Result]} {
          puts stderr "Open - File - '$File'"
          puts stderr "[info level 0] - $Result"
          exit 1
        }
  #      set Local_Doc [::dom::DOMImplementation parse [read $File_Ptr]]
        catch {close $File_Ptr}
        set Pattern "/MaAstro/Table"
        set Items [::dom::DOMImplementation selectNode $Local_Doc $Pattern]
        foreach Item $Items {
          array set Attributes [Repo_Utils::Get_Attributes $Item]
          lappend Return_List $Attributes(Name)
        }
        ::dom::DOMImplementation destroy $Local_Doc
      }
    }

    return $Return_List
  }

########################################################3

  proc Get_Tablespace {Table_Name} {
    set Tablespace {}
    set Lower_Table_Name [string tolower $Table_Name]
    if {[catch {set Table_Ptr [open [Get_Config_File] {RDONLY}]} Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }
    set Local_Doc [::dom::DOMImplementation parse [read $Table_Ptr]]
    catch {close $Table_Ptr}

    #These db-tables will be processed
    set Pattern "/Process/tables/table"
    set Items [::dom::DOMImplementation selectNode $Local_Doc $Pattern]
    foreach Item $Items {
      array set Attributes [Repo_Utils::Get_Attributes $Item]
      set Item_Name [string tolower $Attributes(name)]
      if {[string equal $Lower_Table_Name $Item_Name]} {
        set Tablespace $Attributes(tablespace)
        break
      }
    }
    ::dom::DOMImplementation destroy $Local_Doc
    return $Tablespace
  }

########################################################3

  proc All_Fields_Are_Keys {Table Path} {
    set Return_Value 1
    set f [string tolower $ART_Definitions::Table_File_Name_Prefix\_$Table.xml]
    if {[catch {set Table_Ptr [open [file join $Path $f] {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }
    set Local_Doc [::dom::DOMImplementation parse [read $Table_Ptr]]
    catch {close $Table_Ptr}
    set Pattern "/MaAstro/Table/Column"
    set Columns [::dom::DOMImplementation selectNode $Local_Doc $Pattern]
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set Is_Key $Attributes(Primary)
      if {! $Is_Key} {
        set Return_Value 0
        break
      }
    }
    ::dom::DOMImplementation destroy $Local_Doc
    return $Return_Value
  }

########################################################3

proc Print_Paths {} {
    puts "-----------------------------------------------"
    puts "Main config file -> [Get_Config_File]"
    puts "-----------------------------------------------"
    puts "Output locations, defined in Main config file"
    puts "  -----------------------------------------------"
    puts "  Tables          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables]"
    puts "  Pattern         -> [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables pattern]"
    puts "  Prefix          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables prefix]"
    puts "  -----------------------------------------------"
    puts "  Clreqs          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs]"
    puts "  Pattern         -> [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs pattern]"
    puts "  Prefix          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs prefix]"
    puts "  -----------------------------------------------"
    puts "  Terms           -> [ART_Definitions::Find_Target_Path $ART_Definitions::Terms]"
    puts "  Pattern         -> [ART_Definitions::Find_Target_Path $ART_Definitions::Terms pattern]"
    puts "  Prefix          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Terms prefix]"
    puts "  -----------------------------------------------"
    puts "  Codes           -> [ART_Definitions::Find_Target_Path $ART_Definitions::Codes]"
    puts "  Pattern         -> [ART_Definitions::Find_Target_Path $ART_Definitions::Codes pattern]"
    puts "  Prefix          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Codes prefix]"
    puts "  -----------------------------------------------"
    puts "  Labels          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Labels]"
    puts "  Pattern         -> [ART_Definitions::Find_Target_Path $ART_Definitions::Labels pattern]"
    puts "  Prefix          -> [ART_Definitions::Find_Target_Path $ART_Definitions::Labels prefix]"
    puts "-----------------------------------------------"
    puts "Input definitions, defined in Main config file"
    puts "  Repository_Root -> [ART_Definitions::Find_Target_Path $ART_Definitions::Repository_Root]"
    puts "  M2 modules      -> [ART_Definitions::Find_Target_Path $ART_Definitions::Mustang module]"
    puts "  M2 r-menus      -> [ART_Definitions::Find_Target_Path $ART_Definitions::Mustang r-menu]"
    puts "  -----------------------------------------------"
    puts "  Defined by Repository_Root + Repo::Utils"
    puts "  Messages        -> $ART_Definitions::Messages_Def_Xml_File"
    puts "  Coded values    -> $ART_Definitions::Coded_Values_Def_Xml_File"
    puts "  Tables          -> $ART_Definitions::Table_Def_Xml_File"
    puts "  Ud4             -> $ART_Definitions::Ud4_Def_Xml_File"
    puts "  -----------------------------------------------"
    puts "  List of tables defined in reg directory"
    puts "  [Repo_Utils::Table_List $ART_Definitions::Db_Tables]"
    puts "  -----------------------------------------------"
    puts "  List of clreqs defined in clreq directory"
    puts "  [Repo_Utils::Table_List $ART_Definitions::Clreqs]"
    puts "  -----------------------------------------------"
  }
############################################################

  proc Delete {{Type 0 }} {
    ##################################
    proc Delete_One_Type {Path Prefix} {
      set PWD [pwd]
      cd $Path
      set Delete_List [glob -nocomplain $Prefix\_*.xml]
      foreach f $Delete_List {
        if {[catch {file delete $f} Result]} {
          puts stderr "[info level 0] - delete - $Result"
          exit 1
        }
      }
      cd $PWD
    }
    ##################################
    set Delete($ART_Definitions::Db_Tables) 0
    set Delete($ART_Definitions::Clreqs)    0
    set Delete($ART_Definitions::Terms)     0
    set Delete($ART_Definitions::Codes)     0
    set Delete($ART_Definitions::Labels)    0

    switch -exact $Type {
      0 {
          set Delete($ART_Definitions::Db_Tables) 1
          set Delete($ART_Definitions::Clreqs)    1
          set Delete($ART_Definitions::Terms)     1
          set Delete($ART_Definitions::Codes)     1
          set Delete($ART_Definitions::Labels)    1
      }
      1 { set Delete($ART_Definitions::Db_Tables) 1}
      2 { set Delete($ART_Definitions::Clreqs)    1}
      3 { set Delete($ART_Definitions::Terms)     1}
      4 { set Delete($ART_Definitions::Codes)     1}
      7 { set Delete($ART_Definitions::Labels)    1}
      default {
          puts stderr "[info level 0] - Type -> $Type is unknown..."
          exit 1
      }
    }

    if {$Delete($ART_Definitions::Db_Tables)} {
         set Path [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables]
         Delete_One_Type $Path $ART_Definitions::Table_File_Name_Prefix
    }
    if {$Delete($ART_Definitions::Clreqs)} {
         set Path [ART_Definitions::Find_Target_Path $ART_Definitions::Clreqs]
         Delete_One_Type $Path $ART_Definitions::Clreq_File_Name_Prefix
    }
    if {$Delete($ART_Definitions::Terms)} {
         set Path [ART_Definitions::Find_Target_Path $ART_Definitions::Terms]
         Delete_One_Type $Path $ART_Definitions::Term_File_Name_Prefix
    }
    if {$Delete($ART_Definitions::Codes)} {
         set Path [ART_Definitions::Find_Target_Path $ART_Definitions::Codes]
         Delete_One_Type $Path $ART_Definitions::Code_File_Name_Prefix
    }
    if {$Delete($ART_Definitions::Labels)} {
         set Path [ART_Definitions::Find_Target_Path $ART_Definitions::Labels]
         Delete_One_Type $Path $ART_Definitions::Label_File_Name_Prefix
    }
  }

  #########################################################
  # Common header for the autgenerated files
  proc Header {} {
    set l    "-----------------------------------------------------\n"
    append l "-- This file is AUTOGENERATED by                     \n"
    append l "-- $::argv0 at                                       \n"
#    append l "-- [clock format [clock seconds] -format "%d-%b-%Y"] \n"
    append l "--9.6-10510                                          \n"
    append l "----CHANGES HERE WILL BE LOST NEXT GENERATE!!!!----- \n"
    append l "-----------DO NOT EDIT THIS FILE!!!!---------------- \n"
    append l "-----------------------------------------------------\n\n\n"
    return $l
  }


########################################################
  proc Table_Has_IXX_Fields_2 {Columns} {
    set Has_Upd 0
    set Has_Luda 0
    set Has_Luti 0
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set name [string tolower $Attributes(Name)]
      if {[string equal $name "ixxlupd"]} {
        set Has_Upd 1
      } elseif {[string equal $name "ixxluda"]} {
        set Has_Luda 1
      } elseif {[string equal $name "ixxluti"]} {
        set Has_Luti 1
      }
    }
    if {$Has_Upd && $Has_Luda && $Has_Luti} {
      return 1
    } else {
      return 0
    }
  }

########################################################
  proc Table_Has_IXX_Timestamp_2 {Columns} {
    set Has_Upd 0
    set Has_Luts 0
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set name [string tolower $Attributes(Name)]
      if {[string equal $name "ixxlupd"]} {
        set Has_Upd 1
      } elseif {[string equal $name "ixxluts"]} {
        set Has_Luts 1
      }
    }
    if {$Has_Upd && $Has_Luts} {
      return 1
    } else {
      return 0
    }
  }




########################################################
  proc Table_Has_IXX_Timestamp {Table Path} {
    set Return_Value 0
    set f [string tolower $ART_Definitions::Table_File_Name_Prefix\_$Table.xml]
    if {[catch {set Table_Ptr [open [file join $Path $f] {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }
    set Local_Doc [::dom::DOMImplementation parse [read $Table_Ptr]]
    catch {close $Table_Ptr}
    set Pattern "/MaAstro/Table/Column"
    set Columns [::dom::DOMImplementation selectNode $Local_Doc $Pattern]

    set Return_Value [Table_Has_IXX_Timestamp_2 $Columns]

    ::dom::DOMImplementation destroy $Local_Doc
    return $Return_Value
  }

########################################################
  proc Table_Has_IXX_Fields {Table Path} {
    set Return_Value 0
    set f [string tolower $ART_Definitions::Table_File_Name_Prefix\_$Table.xml]
    if {[catch {set Table_Ptr [open [file join $Path $f] {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }
    set Local_Doc [::dom::DOMImplementation parse [read $Table_Ptr]]
    catch {close $Table_Ptr}
    set Pattern "/MaAstro/Table/Column"
    set Columns [::dom::DOMImplementation selectNode $Local_Doc $Pattern]

    set Return_Value [Table_Has_IXX_Fields_2 $Columns]

    ::dom::DOMImplementation destroy $Local_Doc
    return $Return_Value
  }


#  ######################################################
  proc To_M2_Lang {Lang} {
    if {[string equal $Lang "N"]} {
      return "nor"
    } elseif {[string equal $Lang "USA"]} {
      return "eng"
    } elseif {[string equal $Lang "NL"]} {
      return "nld"
    } elseif {[string equal $Lang "DK"]} {
      return "den"
    } elseif {[string equal $Lang "S"]} {
      return "swe"
    } else {
      return "eng"
    }
  }
  ######################################################

  proc Create_Document_From_XML {Xml_File} {
    set File_Ptr [open $Xml_File {RDONLY}]
    set All_Text [read $File_Ptr [file size $Xml_File]]
    close $File_Ptr
    if {[catch {set Doc [::dom::DOMImplementation parse $All_Text]}  Result]} {
        puts stderr "Parse error - File - '$Xml_File'"
        puts stderr "[info level 0] - $Result"
        exit 1
    }
#    set Doc [::dom::DOMImplementation parse $All_Text]
    return $Doc
  }
  ######################################################

  proc Coded_Values_List {} {
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
    proc Local_Coded_Value {Term_Doc} {
      set Pattern "/MaAstro/Term"
      set Term_Nodes [::dom::selectNode $Term_Doc $Pattern]
      foreach Term_Node $Term_Nodes {
        array set Attributes [Repo_Utils::Get_Attributes $Term_Node]
        if {[string equal $Attributes(Type) [Repo_Utils::Data_Type_To_Numeric short-code]]} {
          return [string tolower $Attributes(Name)]
        } else {
          return ""
        }
      }
    }
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
#    if {[string equal $Repo_Utils::Global_Cv_List ""]} {
      set Term_Path    [ART_Definitions::Find_Target_Path $ART_Definitions::Terms]
      set Term_Pattern [ART_Definitions::Find_Target_Path $ART_Definitions::Terms pattern]
      set Tmp_Term_File_List  [glob -nocomplain -directory $Term_Path $Term_Pattern]
      set Term_File_List [lsort $Tmp_Term_File_List]
      foreach Term_File $Term_File_List {
        set Term_Doc [Repo_Utils::Create_Document_From_XML $Term_File ]
        set Code_Name [Local_Coded_Value $Term_Doc]
        if {! [string equal "" $Code_Name] } {
          lappend ::Global_Cv_List $Code_Name
        }
      }
#    }
    return $::Global_Cv_List
  }

  ###############################################################
  proc Coded_Values_File_List {} {
    set File_List {}
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
    proc Local_Coded_Value {Term_Doc} {
      set Pattern "/MaAstro/Term"
      set Term_Nodes [::dom::selectNode $Term_Doc $Pattern]
      foreach Term_Node $Term_Nodes {
        array set Attributes [Repo_Utils::Get_Attributes $Term_Node]
        if {[string equal $Attributes(Type) [Repo_Utils::Data_Type_To_Numeric short-code]]} {
          return 1
        } else {
          return 0
        }
      }
    }
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
      set Term_Path    [ART_Definitions::Find_Target_Path $ART_Definitions::Terms]
      set Term_Pattern [ART_Definitions::Find_Target_Path $ART_Definitions::Terms pattern]
      set Tmp_Term_File_List  [glob -nocomplain -directory $Term_Path $Term_Pattern]
      set Term_File_List [lsort $Tmp_Term_File_List]
      foreach Term_File $Term_File_List {
        set Term_Doc [Repo_Utils::Create_Document_From_XML $Term_File ]
        set Is_Coded_Value [Local_Coded_Value $Term_Doc]
        if {$Is_Coded_Value } {
          lappend File_List $Term_File
        }
      }
    return $File_List
  }
  ###############################################################
  proc Escape {What {With ""}} {
  # remove certain characters, and replace with $With or if not given '-'
    set Tmp {}
    regsub -all {'} $What $With Tmp    ; # replace all ' with -
# use 'set define off;# instead
#    regsub -all {&} $What {\\&} Tmp    ; # replace all & with \&, so sqlplus does not ask for values
    return $Tmp
  }
  ###############################################################

  proc Change_File_Encoding {From_File_Name To_File_Name From_Encoding To_Encoding} {
      #utf-8 iso8859-1
    set From_File_Ptr [open $From_File_Name {RDONLY}]

    if {[string equal "" $To_File_Name]} {
      set Local_To_File_Name $From_File_Name.$To_Encoding
    } else {
      set Local_To_File_Name $To_File_Name
    }

    set To_File_Ptr [open $Local_To_File_Name {WRONLY CREAT TRUNC}]

    fconfigure $From_File_Ptr -encoding $From_Encoding
    fconfigure $To_File_Ptr -encoding $To_Encoding

    while {[gets $From_File_Ptr Line] >= 0} {
      if {[string equal $From_Encoding utf-8] && [string equal $To_Encoding iso8859-1]} {
        if {[string first "<?xml version=" $Line] > -1 && [string first "UTF-8" [string toupper $Line]] > -1 } {
          puts $To_File_Ptr "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"
        } else {
          puts $To_File_Ptr $Line
        }
      } else {
        puts $To_File_Ptr $Line
      }
    }

    close $To_File_Ptr
    close $From_File_Ptr
    return 0
  }

########################################################3
  proc View_List {} {

    set Return_List {}
    set View_Dir [ART_Definitions::Find_Target_Path $ART_Definitions::Views]
    set View_Files [lsort [glob -nocomplain -directory $View_Dir $ART_Definitions::View_File_Name_Prefix\_*.xml]]
    set Files {}
    set Files $View_Files

#    puts $Files
    foreach File $Files {
      if {[catch {set File_Ptr [open $File {RDONLY}]}  Result]} {
        puts stderr "Open - File - '$File'"
        puts stderr "[info level 0] - $Result"
        exit 1
      }

      if {[catch { set Local_Doc [::dom::DOMImplementation parse [read $File_Ptr]]}  Result]} {
        puts stderr "Open - File - '$File'"
        puts stderr "[info level 0] - $Result"
        exit 1
      }
#      set Local_Doc [::dom::DOMImplementation parse [read $File_Ptr]]
      catch {close $File_Ptr}
      set Pattern "/MaAstro/View"
      set Items [::dom::DOMImplementation selectNode $Local_Doc $Pattern]
      foreach Item $Items {
        array set Attributes [Repo_Utils::Get_Attributes $Item]
        set View_Prefix ""
        set View_Name $Attributes(Name)
#        switch -exact -- $Attributes(Type) {
#          2 {set View_Prefix "CNT_"}
#          default { }
#        }
        lappend Return_List $View_Prefix$View_Name
      }
      ::dom::DOMImplementation destroy $Local_Doc
    }

    return $Return_List
  }

###namespace end
}


