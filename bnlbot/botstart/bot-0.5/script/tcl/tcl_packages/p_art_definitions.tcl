
package provide ART_Definitions 1.0

package require dom

namespace eval ART_Definitions {

  namespace export Get_Config_File
  namespace export Find_Target_Path
  namespace export Data_Type_To_Numeric
# constants

  namespace export Db_Tables
  namespace export Clreqs
  namespace export Terms
  namespace export Codes
  namespace export Mustang
  namespace export Repository_Root
  namespace export IDF_Root
 
 
  namespace export Unique_List

  namespace export Table_File_Name_Prefix
  namespace export Clreq_File_Name_Prefix
  namespace export Term_File_Name_Prefix 
  namespace export Code_File_Name_Prefix
  namespace export Label_File_Name_Prefix
  
  namespace export Messages_Def_Xml_File
  namespace export Coded_Values_Def_Xml_File
  namespace export Table_Def_Xml_File
  namespace export Ud4_Def_Xml_File


  namespace export Messages_Def_Xml_File_IDF
  namespace export Coded_Values_Def_Xml_File_IDF
  namespace export Table_Def_Xml_File_IDF
  namespace export Ud4_Def_Xml_File_IDF


  namespace export Repository_File_Root
  namespace export IDF_File_Root

  namespace export Zcodint
  namespace export Zcodchar
  namespace export Zonoffcheck
  namespace export Zeditbox

  namespace export Get_Term_From_Label
  
  
  ########################################

  set Db_Tables  1
  set Clreqs     2
  set Terms      3 
  set Codes      4 
  set Mustang    5 
  set Repository_Root 6
  set Labels     7 
  set IDF_Root   8
  set Bin        9
  set Views      10
  
  
  set Table_File_Name_Prefix "table"
  set Clreq_File_Name_Prefix "clreq"
  set Term_File_Name_Prefix "trm"
  set Code_File_Name_Prefix "trm"
  set Label_File_Name_Prefix "lab"
  set View_File_Name_Prefix "view"
  
  set Zcodint  "ZCODINT"
  set Zcodchar "ZCODCHAR"
  set Zonoffcheck "ZONOFFCHECK"
  set Zeditbox "ZEDITBOX"


  proc Get_Config_File {} {
    return [file join $::env(SATTMATE_CONFIG) local stingray sattmate.xml]
  }

  proc Data_Type_To_Numeric {Data_Type} {
    puts stderr "Moved proc Data_Type_To_Numeric to REPO_Utils"
    puts stderr "Please update this code"
    exit 1
  }
  ########################################


  ################ Local procs  ########################

  proc Find_Target_Path {The_Type {The_Item directory}} {
    set Path [Get_Config_File]

    if {[catch {set Path_Ptr [open $Path {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }   	
    set Local_Doc [::dom::DOMImplementation parse [read $Path_Ptr]] 
    catch {close $Path_Ptr}
  
    set Pattern "/Process/paths"
    # For some reason, switch won't take $::Db_Tables or $::Clreqs as labels
    # $::Db_Tables -> 1
    # $::Clreqs    -> 2
    # $::Terms     -> 3 
    # $::Codes     -> 4 
    # $::Mustang   -> 5 
    # $::Repository_Root -> 6
    # $::Labels -> 7
    # $::IDF_Root -> 8
    # $::Bin -> 9
    # $::Views -> 10

    switch -exact $The_Type {
      1       {append Pattern "/tables"}
      2       {append Pattern "/clreqs"}
      3       {append Pattern "/terms"}
      4       {append Pattern "/codes"}
      5       {append Pattern "/mustang"}
      6       {append Pattern "/repositoryRoot"}
      7       {append Pattern "/labels"}
      8       {append Pattern "/IDFRoot"}
      9       {append Pattern "/bin"}
     10       {append Pattern "/views"}

      default {
                puts stderr "Find_Target_Path - wrong argument $The_Type"
                exit 1
               }
    }
      append Pattern "/definitions"
      append Pattern "/$The_Item"
    
    set Loc [::dom::DOMImplementation selectNode $Local_Doc $Pattern]
    set fc [::dom::node cget $Loc -firstChild]
    set Xml_Doc_Path [::dom::node cget $fc -nodeValue] 
  
    ::dom::DOMImplementation destroy $Local_Doc

# is the path 'clean' or does it have os specific environment syntax,
# like %SATTMATE_ROOT% or $SATTMATE_ROOT ?

    set Dollar_Pos [string first \$ $Xml_Doc_Path]
    set Percent_Pos1 [string first % $Xml_Doc_Path]
    if {$Dollar_Pos > -1} {
      # we got some kind of unix, find the environment variable, should end before next '/'
      set A_Tmp [file split $Xml_Doc_Path]             ; # split it to the parts
      set First_Item [lindex $A_Tmp 0]                 ;# Assume the first_item in the list is the %bla% one
      set First_Item [string range $First_Item 1 [expr [string length $First_Item] - 1]]

      set New_List [file split $::env($First_Item)]  ;# replace the first item in the list with the expanded item
      foreach Element $A_Tmp {
        if {[string first \$ $Element] > -1} {
          continue
        }
        lappend New_List $Element
        }
        set Tmp_Path ""
        foreach Element $New_List {
          set Tmp_Path [file join $Tmp_Path $Element ]  
        } 
        set Xml_Doc_Path $Tmp_Path  
    }	elseif {$Percent_Pos1 > -1} {
        # we got windows
        set Percent_Pos2 [string first % $Xml_Doc_Path] ; # find the next '%'
        set A_Tmp [file split $Xml_Doc_Path]             ; # split it to the parts
        set First_Item [lindex $A_Tmp 0]                 ;# Assume the first_item in the list is the %bla% one
        set First_Item [string range $First_Item 1 [expr [string length $First_Item] - 2]]
        set New_List [file split $::env($First_Item)]  ;# replace the first item in the list with the expanded item
        foreach Element $A_Tmp {
          if {[string first % $Element] > -1} {
            continue
          }
          lappend New_List $Element
        }
        set Tmp_Path ""
        foreach Element $New_List {
          set Tmp_Path [file join $Tmp_Path $Element ]  
        } 
        set Xml_Doc_Path $Tmp_Path  
    }
    return $Xml_Doc_Path
  }

  set Repository_File_Root [Find_Target_Path $ART_Definitions::Repository_Root]
  set IDF_File_Root [Find_Target_Path $ART_Definitions::IDF_Root]

  set Messages_Def_Xml_File     [file join $Repository_File_Root messages.xml]
  set Coded_Values_Def_Xml_File [file join $Repository_File_Root coded_values.xml]
  set Table_Def_Xml_File        [file join $Repository_File_Root deftables.xml]
  set Ud4_Def_Xml_File          [file join $Repository_File_Root ud4tables.xml]

  set Messages_Def_Xml_File_IDF     [file join $IDF_File_Root messages.xml]
  set Coded_Values_Def_Xml_File_IDF [file join $IDF_File_Root coded_values.xml]
  set Table_Def_Xml_File_IDF        [file join $IDF_File_Root deftables.xml]
  set Ud4_Def_Xml_File_IDF          [file join $IDF_File_Root ud4tables.xml]


  #############################################33
  proc Unique_List {A_List} {
    set Temp_List {}
    Debug "- start"
    foreach Item $A_List {
#    set Item [lindex $Item2 0]
      Debug "Unique_List - checking $Item"
      if {[lsearch -exact $Temp_List $Item] < 0} {
        lappend Temp_List "$Item"
        Debug "Unique_List - $Item inserted"
      } else {
       Debug "Unique_List - $Item skipped"
      }
    }
    return $Temp_List
  }
  #############################################33


  proc Get_Term_From_Label {Label} {
    set The_End [string first "_LABEL" $Label]
    Debug "$Label -> _LABEL -> $The_End"         
    if {! [expr $The_End > -1]} {
      set The_End [string first "_TITEL" $Label]         
      Debug "$Label -> _TITEL -> $The_End"         
    }

    if {! [expr $The_End > -1]} {
      set The_End [string first "_LABLE" $Label]         
      Debug "$Label -> _LABLE -> $The_End"         
    }

    if {! [expr $The_End > -1]} {
      set The_End [string first "_TITLE" $Label]         
      Debug "$Label -> _TITLE -> $The_End"         
    }

    if {[expr $The_End > -1]} {
      incr The_End -1 
      set New_Label [string tolower [string range $Label 0 $The_End]]            
      Debug "Making New_Label -> '$Label' -> 0 .. $The_End -> $New_Label"         
    } else {
      set New_Label $Label     
      Debug "Using old Label -> '$New_Label'"         
    }
    return $New_Label
  }

  
}
