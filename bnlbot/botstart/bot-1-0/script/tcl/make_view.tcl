
#9.8 
#chg-21835 added prompt when creating ora view  
set auto_path [linsert $auto_path 0 [file join $env(SATTMATE_SCRIPT) local tcl_packages]]

package require dom
package require Repo_Utils
package require Get_Opt
package require ART_Definitions

##########################################################

proc Create_SQL_Script_Oracle {Out_File View_Node } {
  
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  set Table_Prefix $Repo_Utils::Table_File_Name_Prefix
  set Table_Type $ART_Definitions::Db_Tables
  set Table_Path [ART_Definitions::Find_Target_Path $Table_Type]

  puts $Out_File "prompt \'creating view $View_Attributes(Name)\';"
  puts $Out_File "create or replace view $View_Attributes(Name) \( " 
  set ColumnsParent [::dom::DOMImplementation selectNode $View_Node $::Columns_Element_Name]
  set Columns [::dom::DOMImplementation selectNode $View_Node $::Column_Element_Name]
  set ColumnsChildNodes [dom::node children $ColumnsParent]
  set AllColumns {}
  set AllAsColumns {}
  foreach col $ColumnsChildNodes {
    set NodeName [dom::node cget $col -nodeName]
    if {[string equal $NodeName "Column"]} {
    # We use either As or AsOracle attribute. Only one of them should be present
      set Attributes(As) ""
      set Attributes(AsOracle) ""
      array set Attributes [Repo_Utils::Get_Attributes $col]
      lappend AllColumns $Attributes(Name) 
      set AsAttr $Attributes(As)
      set AsOraAttr $Attributes(AsOracle)
      if {![string equal "" $AsAttr]} {
        if {[string compare -nocase -length 7 $AsAttr "select "] == 0} {
          lappend AllAsColumns ($AsAttr)
        } else {
          lappend AllAsColumns $AsAttr
        }
      } elseif {![string equal "" $AsOraAttr]} {
        if {[string compare -nocase -length 7 $AsOraAttr "select "] == 0} {
          lappend AllAsColumns ($AsOraAttr)
        } else {
          lappend AllAsColumns $AsOraAttr
        }
      } else {
        lappend AllAsColumns $Attributes(Name) 
      }
    } elseif {[string equal $NodeName "Table"]} {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set Table_Name $Attributes(Name) 
      set Table_Node [Open_Table_Node $Table_Prefix $Table_Name $Table_Path]
      set Table_Columns [::dom::DOMImplementation selectNode $Table_Node $::Table_Column_Element_Name]
      foreach tabcol $Table_Columns {
        array set Attributes [Repo_Utils::Get_Attributes $tabcol]
        set ColName $Attributes(Name) 
        if {[lsearch -exact $AllColumns $ColName]>=0} {
        # The column is found in the previous list, don't duplicate it
        } else {
          lappend AllColumns $ColName
          set FullColumn $Table_Name
          append FullColumn "." 
          append FullColumn $ColName 
          lappend AllAsColumns $FullColumn
        }
      }
    }
  }
  set S1 [join $AllColumns ",\n"]
  puts $Out_File $S1
  puts $Out_File ")"

  puts $Out_File "AS\nselect "   
  set S2 [join $AllAsColumns ",\n"]
  puts $Out_File $S2

  set FromText "from "
  set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_Name]
  if {$From == ""} {
    set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_Oracle_Name]
  }
  if {$From == ""} {
    puts stderr "[info level 0] - From -> No legal From Clause..." 
    exit 1
  }
  set TextNode [dom::node cget $From -firstChild]
  set FromClause [dom::node cget $TextNode -nodeValue]
  append FromText $FromClause 
  puts $Out_File [string trim $FromText]

  set Where [::dom::DOMImplementation selectNode $View_Node $::Where_Name]
  if {$Where == ""} {
  } else {
    set TextNode [dom::node cget $Where -firstChild]
    set WhereClause [dom::node cget $TextNode -nodeValue]
    set S1 "where "
    append S1 $WhereClause
    puts $Out_File [string trim $S1]
  }

  puts $Out_File "/"
  puts $Out_File ""
}
# end Create_SQL_Script_Oracle

########################################################
proc Create_SQL_Script_Sql_Server {Out_File View_Node } {
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  set Table_Prefix $Repo_Utils::Table_File_Name_Prefix
  set Table_Type $ART_Definitions::Db_Tables
  set Table_Path [ART_Definitions::Find_Target_Path $Table_Type]

  puts $Out_File ""
  puts $Out_File "if exists (select TABLE_NAME from INFORMATION_SCHEMA.VIEWS"
  puts $Out_File " where TABLE_NAME = '$View_Attributes(Name)') drop view $View_Attributes(Name)"
  puts $Out_File "go"
  puts $Out_File ""
  puts $Out_File "create view $View_Attributes(Name) \( " 
  set ColumnsParent [::dom::DOMImplementation selectNode $View_Node $::Columns_Element_Name]
  set Columns [::dom::DOMImplementation selectNode $View_Node $::Column_Element_Name]
  set ColumnsChildNodes [dom::node children $ColumnsParent]
  set AllColumns {}
  set AllAsColumns {}
  foreach col $ColumnsChildNodes {
    set NodeName [dom::node cget $col -nodeName]
    if {[string equal $NodeName "Column"]} {
    # We use either As or AsSqlServer attribute. Only one of them should be present
      set Attributes(As) ""
      set Attributes(AsSqlServer) ""
      array set Attributes [Repo_Utils::Get_Attributes $col]
      lappend AllColumns $Attributes(Name) 
      set AsAttr $Attributes(As)
      set AsSqlAttr $Attributes(AsSqlServer)
      if {![string equal "" $AsAttr]} {
        if {[string compare -nocase -length 7 $AsAttr "select "] == 0} {
          lappend AllAsColumns ($AsAttr)
        } else {
          lappend AllAsColumns $AsAttr
        }
      } elseif {![string equal "" $AsSqlAttr]} {
        if {[string compare -nocase -length 7 $AsSqlAttr "select "] == 0} {
          lappend AllAsColumns ($AsSqlAttr)
        } else {
          lappend AllAsColumns $AsSqlAttr
        }
      } else {
        lappend AllAsColumns $Attributes(Name) 
      }
    } elseif {[string equal $NodeName "Table"]} {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set Table_Name $Attributes(Name) 
      set Table_Node [Open_Table_Node $Table_Prefix $Table_Name $Table_Path]
      set Table_Columns [::dom::DOMImplementation selectNode $Table_Node $::Table_Column_Element_Name]
      foreach tabcol $Table_Columns {
        array set Attributes [Repo_Utils::Get_Attributes $tabcol]
        set ColName $Attributes(Name) 
        if {[lsearch -exact $AllColumns $ColName]>=0} {
        # The column is found in the previous list, don't duplicate it
        } else {
          lappend AllColumns $ColName
          set FullColumn $Table_Name
          append FullColumn "." 
          append FullColumn $ColName 
          lappend AllAsColumns $FullColumn
        }
      }
    }
  }
  set S1 [join $AllColumns ",\n"]
  puts $Out_File $S1
  puts $Out_File ")"

  puts $Out_File "AS\nselect "   
  set S2 [join $AllAsColumns ",\n"]
  puts $Out_File $S2

  set FromText "from "
  set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_Name]
  if {$From == ""} {
    set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_SqlServer_Name]
  }
  if {$From == ""} {
    puts stderr "[info level 0] - From -> No legal From Clause..." 
    exit 1
  }
  set TextNode [dom::node cget $From -firstChild]
  set FromClause [dom::node cget $TextNode -nodeValue]
  append FromText $FromClause 
  puts $Out_File [string trim $FromText]

  set Where [::dom::DOMImplementation selectNode $View_Node $::Where_Name]
  if {$Where == ""} {
  } else {
    set TextNode [dom::node cget $Where -firstChild]
    set WhereClause [dom::node cget $TextNode -nodeValue]
    set S1 "where "
    append S1 $WhereClause
    puts $Out_File [string trim $S1]
  }
   
  puts $Out_File "go"
  puts $Out_File ""
}
# end Create_SQL_Script_Sql_Server
########################################################

proc Create_SQL_Script_PostgreSQL {Out_File View_Node } {
  
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]

  puts $Out_File ""
  puts $Out_File "begin;"

  
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  set Table_Prefix $Repo_Utils::Table_File_Name_Prefix
  set Table_Type $ART_Definitions::Db_Tables
  set Table_Path [ART_Definitions::Find_Target_Path $Table_Type]

  puts $Out_File "create or replace view $View_Attributes(Name) \( " 
  set ColumnsParent [::dom::DOMImplementation selectNode $View_Node $::Columns_Element_Name]
  set Columns [::dom::DOMImplementation selectNode $View_Node $::Column_Element_Name]
  set ColumnsChildNodes [dom::node children $ColumnsParent]
  set AllColumns {}
  set AllAsColumns {}
  foreach col $ColumnsChildNodes {
    set NodeName [dom::node cget $col -nodeName]
    if {[string equal $NodeName "Column"]} {
    # We use either As or AsOracle attribute. Only one of them should be present
      set Attributes(As) ""
      set Attributes(AsOracle) ""
      array set Attributes [Repo_Utils::Get_Attributes $col]
      lappend AllColumns $Attributes(Name) 
      set AsAttr $Attributes(As)
      set AsOraAttr $Attributes(AsOracle)
      if {![string equal "" $AsAttr]} {
        if {[string compare -nocase -length 7 $AsAttr "select "] == 0} {
          lappend AllAsColumns ($AsAttr)
        } else {
          lappend AllAsColumns $AsAttr
        }
      } elseif {![string equal "" $AsOraAttr]} {
        if {[string compare -nocase -length 7 $AsOraAttr "select "] == 0} {
          lappend AllAsColumns ($AsOraAttr)
        } else {
          lappend AllAsColumns $AsOraAttr
        }
      } else {
        lappend AllAsColumns $Attributes(Name) 
      }
    } elseif {[string equal $NodeName "Table"]} {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set Table_Name $Attributes(Name) 
      set Table_Node [Open_Table_Node $Table_Prefix $Table_Name $Table_Path]
      set Table_Columns [::dom::DOMImplementation selectNode $Table_Node $::Table_Column_Element_Name]
      foreach tabcol $Table_Columns {
        array set Attributes [Repo_Utils::Get_Attributes $tabcol]
        set ColName $Attributes(Name) 
        if {[lsearch -exact $AllColumns $ColName]>=0} {
        # The column is found in the previous list, don't duplicate it
        } else {
          lappend AllColumns $ColName
          set FullColumn $Table_Name
          append FullColumn "." 
          append FullColumn $ColName 
          lappend AllAsColumns $FullColumn
        }
      }
    }
  }
  set S1 [join $AllColumns ",\n"]
  puts $Out_File $S1
  puts $Out_File ")"

  puts $Out_File "AS\nselect "   
  set S2 [join $AllAsColumns ",\n"]
  puts $Out_File $S2

  set FromText "from "
  set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_Name]
  if {$From == ""} {
    set From [::dom::DOMImplementation selectNode $View_Node $::From_Sql_Oracle_Name]
  }
  if {$From == ""} {
    puts stderr "[info level 0] - From -> No legal From Clause..." 
    exit 1
  }
  set TextNode [dom::node cget $From -firstChild]
  set FromClause [dom::node cget $TextNode -nodeValue]
  append FromText $FromClause 
  puts $Out_File [string trim $FromText]

  set Where [::dom::DOMImplementation selectNode $View_Node $::Where_Name]
  if {$Where == ""} {
  } else {
    set TextNode [dom::node cget $Where -firstChild]
    set WhereClause [dom::node cget $TextNode -nodeValue]
    set S1 "where "
    append S1 $WhereClause
    puts $Out_File [string trim $S1]
  }

  puts $Out_File ";"
  puts $Out_File ""
  
  
  
  
  puts $Out_File ""
  puts $Out_File "commit;"
  puts $Out_File ""

}
# end Create_SQL_Script_PostgreSQL
########################################################


proc Drop_SQL_Script_PostgreSQL {Out_File View_Node } {
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  puts $Out_File "begin;" 
  puts $Out_File "drop view $View_Attributes(Name);" 
  puts $Out_File "commit;" 
} 

proc Drop_SQL_Script_Oracle {Out_File View_Node } {
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  puts $Out_File "drop view $View_Attributes(Name)" 
  puts $Out_File "/" 
} 

proc Drop_SQL_Script_Sql_Server {Out_File View_Node } {
  array set View_Attributes [Repo_Utils::Get_Attributes $View_Node]
  puts $Out_File "drop view $View_Attributes(Name)" 
  puts $Out_File "go" 
} 

########################################################
proc Open_Table_Node {Prefix Table Path} {
    set Return_Value 1
    set f [string tolower $Prefix\_$Table.xml]
    if {[catch {set Table_Ptr [open [file join $Path $f] {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }   	
    set Local_Doc [::dom::DOMImplementation parse [read $Table_Ptr]] 
    catch {close $Table_Ptr}
    set A_Table [::dom::DOMImplementation selectNode $Local_Doc "/MaAstro/Table"]
    return $A_Table
}
########################################################
proc Open_View_Node {Prefix View Path} {
    set Return_Value 1
    set f [string tolower $Prefix\_$View.xml]
    if {[catch {set View_Ptr [open [file join $Path $f] {RDONLY}]}  Result]} {
      puts stderr "[info level 0] - $Result"
      exit 1
    }   	
    set Local_Doc [::dom::DOMImplementation parse [read $View_Ptr]] 
    catch {close $View_Ptr}
    set A_View [::dom::DOMImplementation selectNode $Local_Doc "/MaAstro/View"]
    return $A_View
}
########################################################
proc Usage {} {
    puts stderr ""
    puts stderr "This tool generates :"
    puts stderr "  View_XYZ.sql"
    puts stderr "  on standard output."
    puts stderr ""
    puts stderr "  The View_XYZ.sql are divided into Oracle and SqlServer."
    puts stderr "  Sql server is NOT supported by Sattmate at the moment"
    puts stderr ""
    puts stderr "Input is xml files at"
    puts stderr "  [ART_Definitions::Find_Target_Path $ART_Definitions::Views]"
    puts stderr ""
    puts stderr "  -a 1|2|3|4|5"
    puts stderr "    ALL views of one kind where"
    puts stderr "    1 -> Oracle sql files"
    puts stderr "    2 -> SqlServer sql files"
    puts stderr "    3 -> DROP ALL views, Oracle"
    puts stderr "    4 -> DROP ALL views, SqlServer"
    puts stderr "    5 -> DROP ALL views, PostgreSQL"
    puts stderr ""
    puts stderr "  With ALL views, we mean the ones listed by -f"
    puts stderr ""
    puts stderr "  -f List all defined views"
    puts stderr "  -h This info"
    puts stderr "  -o viewname -> ONE XYZ.sql for given  view, Oracle."
    puts stderr "  -P viewname -> ONE XYZ.sql for given  view, Postgresql."
    puts stderr "  -s viewname -> ONE XYZ.sql for given  view, SqlServer."
    puts stderr ""
    exit 1
}
########################################################

set Table_Column_Element_Name Column
set Column_Element_Name Columns/Column
set From_Sql_Name From
set From_Sql_Oracle_Name FromOracle
set From_Sql_SqlServer_Name FromSqlServer
set Where_Name Where

set Columns_Element_Name Columns
set Table_Element_Name Columns/Table

set Out_File stdout
set Path {}
set Prefix {}
set Action {}
#set Caseing_SQL 1 ;# 1= TABLE, FIELD 2= TABLE, field 3=table, field

while {[ set err [ getopt $argv "a:fho:p:s:v" opt arg ]] } {
  if {$err < 0} {
    puts $arg
    puts stderr " -h for help"
    exit 1
  } else {
    switch -exact -- $opt {
      a { 
          set Choise [lindex $arg 0]
          if {[string equal $Choise 1]} {
            set Action createDbOracle
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix

          } elseif {[string equal $Choise 2]} {
            set Action createDbSqlServer
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix

          } elseif {[string equal $Choise 3]} {
            set Action dropDbOracle
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix

          } elseif {[string equal $Choise 4]} {
            set Action dropDbSqlServer
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix

          } elseif {[string equal $Choise 5]} {
            set Action dropDbPostgreSQL
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix
            
          } elseif {[string equal $Choise 6]} {
            set Action createDbPostgreSQL
            set View_Type $ART_Definitions::Views
            set View_List [Repo_Utils::View_List]
            set Prefix $Repo_Utils::View_File_Name_Prefix
        } 
      }
      f {
          puts stderr "List of views"
          puts [Repo_Utils::View_List]
          exit 0    
      }
      h {Usage}

      o { set View_Type $ART_Definitions::Views
          set View_List [lindex $arg 0]
          set Prefix $Repo_Utils::View_File_Name_Prefix
          set Action createDbOracle
      }
      p { set View_Type $ART_Definitions::Views
          set View_List [lindex $arg 0]
          set Prefix $Repo_Utils::View_File_Name_Prefix
          set Action createDbPostgreSQL
      }

      s { set View_Type $ART_Definitions::Views
          set View_List [lindex $arg 0]
          set Prefix $Repo_Utils::View_File_Name_Prefix
          set Action createDbSqlServer
      }
      
      v {incr Repo_Utils::Verbosity}
      default { puts "in default"; Usage}
    }
  }
}

#      C { set Caseing_SQL  [lindex $arg 0]      }


if {[string equal {} $Action]} {
  puts "Action is blank"; Usage
}


set Path [ART_Definitions::Find_Target_Path $View_Type]

foreach View_Name $View_List {
  set View_Node [Open_View_Node $Prefix $View_Name $Path]
  
  switch -exact -- $Action {
      createDbOracle  {
            Create_SQL_Script_Oracle $Out_File $View_Node
      }
      createDbSqlServer  {  
            Create_SQL_Script_Sql_Server $Out_File $View_Node
      }
      createDbPostgreSQL  {  
            Create_SQL_Script_PostgreSQL $Out_File $View_Node
      }
      dropDbOracle {
            Drop_SQL_Script_Oracle $Out_File $View_Node
      }
      dropDbSqlServer {  
            Drop_SQL_Script_Sql_Server $Out_File $View_Node
      }
      dropDbPostgreSQL {  
            Drop_SQL_Script_PostgreSQL $Out_File $View_Node
      }
    default {
        puts stderr "Action '$Action' not in known actions"
    	Usage
    }
  }
}

  



  
