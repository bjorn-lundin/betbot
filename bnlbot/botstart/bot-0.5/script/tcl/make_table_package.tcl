# Script for generating table_xyz.ad[bs] files from table_xyz.xml definitions
#9.6-10471 make use of package handling, tell where to find the packages we make
#10.1-20890 fix that order by in pks with several fields always orders by ALL PK fields
#CHG-20959 All tables should have procedure FROM_XML,not only S08-tables
#chg-21835 All b*tables use ixxluts instead of ixxluda+ixxluti
# bnl 2011-04-22 new proc Create_Tables_Makefile, used in makefile for tables.
#                Creates a makefile for tables bsed on current repo-data
# -----------------------------------
# chg-25420 2012-09-16 When dumping tables to xml, prefix each row with TABLE_NAME_Row
#                      to handle when a field has the same name as the table itself
# -----------------------------------

#############################################################################
set auto_path [linsert $auto_path 0 [file join $::env(BETBOT_SCRIPT) tcl tcl_packages]]

package require dom
package require Repo_Utils
package require Get_Opt
package require ART_Definitions
##########################################################
## global constant until figured out how to determinie it
set IDF_Numbering I1

#proc Get_Attributes {Element} {
#  set Attr_Ptr [dom::node cget $Element -attributes]
#  upvar $Attr_Ptr Attr
#  return [array get Attr]
#}

proc Is_S08_Table {Name} {
  return [string equal -nocase -length 3 $Name "S08"]
}

proc Table_Caseing {Table} {
#set Caseing_SQL 1 ;# 1= TABLE, FIELD 2= TABLE, field 3=table, field
    switch -exact -- $::Caseing_SQL {
      1 {return [string toupper $Table]}
      2 {return [string toupper $Table]}
      3 {return [string tolower $Table]}
      default  {puts stderr "unknown caseing '$::Caseing_SQL' must be 1 - 3" ; exit 1}
    }
}

proc Field_Caseing {Field} {
#set Caseing_SQL 1 ;# 1= TABLE, FIELD 2= TABLE, field 3=table, field
    switch -exact -- $::Caseing_SQL {
      1 {return [string toupper $Field]}
      2 {return [string tolower $Field]}
      3 {return [string tolower $Field]}
      default  {puts stderr "unknown caseing '$::Caseing_SQL' must be 1 - 3" ; exit 1}
    }
}


proc Setup_Global_Index_Info {Table_Name Table_Type Node Columns} {
  array unset ::Index_Array
  set Indices [::dom::DOMImplementation selectNode $Node $::Index_Element_Name]
  set Has_Index_Element 0
  set Has_Primary_Key 0
  foreach Index $Indices {
    set Has_Index_Element 1
    array set Index_Attributes [Repo_Utils::Get_Attributes $Index]
    set Field_List [split $Index_Attributes(Columns) ","]
    foreach Field $Field_List {
      if {[string equal $Index_Attributes(type) primary]} {
        set Has_Primary_Key 1
      }
      set ::Index_Array($Index_Attributes(type),$Field) 1
    }
  }
  if {! $Has_Index_Element} {
    puts stderr "$Table_Name has no index element."
    puts stderr "It means it has not primary key defined"
    puts stderr "Cannot continue without it, exiting..."
    exit 1
  }
  if {! $Has_Primary_Key} {
    puts stderr "$Table_Name has no primary key defined."
    puts stderr "Cannot continue without it, exiting..."
    exit 1
  }
}

proc Is_Indexed {Field Type} {
  set Result 0
  if { [catch { set Result $::Index_Array($Type,$Field)} ] } {
    set Result 0
  }
  return $Result
}
proc Is_Primary {Field} {
  return [Is_Indexed $Field primary]
}

proc Is_Candidate {Field} {
  return [Is_Indexed $Field candidate]
}


proc Print_Global_Index_Info {} {
  foreach item [array names ::Index_Array] {
    puts "  $item : $::Index_Array($item)"
  }
}

##########################################################
  proc All_Primary_Keys_Fields_Are_Not_Nullable {Name Columns } {
    set Err 0
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if {[Is_Primary $Attributes(Name)]} {
	    if { $Attributes(AllowNull) } {
          puts stderr " $Attributes(Name) is NULLABLE eventhough it is part of Primary Key"
		  set Err 1
        }
      }
    }
	if {$Err} {
      puts stderr " \nNo fields defined as PK may be nullable. Change in xml-file."
      puts stderr " This is in table $Name. Exiting."
	  exit 1
	}
  }
##########################################################
  proc All_Fields_Are_Primary_Keys {Columns {Turns 99999}} {
    set This_Turn 0
    foreach col $Columns {
      incr This_Turn
	  if {$This_Turn > $Turns} {
        break
	  }
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if {! [Is_Primary $Attributes(Name)]} {
#        puts stderr " $Attributes(Name) is NOT primary"
        return 0
      }
    }
    return 1
  }

##########################################################
  proc Primary_Key_List {Columns {Turns 99999}} {
    set TEMP_ORDER_BY_LIST {}
    set This_Turn 0
    foreach col $Columns {
      incr This_Turn
	  if {$This_Turn > $Turns} {
        break
	  }
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if {[Is_Primary $Attributes(Name)]} {
#        set COL_NAME [string toupper $Attributes(Name)]
        set COL_NAME [Field_Caseing $Attributes(Name)]
        append TEMP_ORDER_BY_LIST " $COL_NAME,"
      }
    }
    set Tmp [string replace [string trimright $TEMP_ORDER_BY_LIST] end end ""]

    return [string trimleft $Tmp]
  }
##########################################################

  proc Keyed_Sql_Statment {Stm_Name First_Stm_Row Key Cols {Generate_IXX 0} {Turns 99999} {Order_By_PK 0}} {
    set S "    Sql.Prepare($Stm_Name, \" $First_Stm_Row \" & \n"
    set Keyword where
    set This_Turn 0

    foreach col $Cols {
      incr This_Turn
	  if {$This_Turn > $Turns} {
        break
	  }
      array set Attributes [Repo_Utils::Get_Attributes $col]
      switch -exact -- $Key {
        Primary {
          if {[Is_Primary $Attributes(Name)] } {
#            set COL_NAME [string toupper $Attributes(Name)]
            set COL_NAME [Field_Caseing $Attributes(Name)]
            append S "            \"$Keyword $COL_NAME=:$COL_NAME\" &\n"
            set Keyword " and"
          }
        }
        Unique  {
          if {[Is_Candidate $Attributes(Name)] } {
#            set COL_NAME [string toupper $Attributes(Name)]
            set COL_NAME [Field_Caseing $Attributes(Name)]
            append S "            \"$Keyword $COL_NAME=:$COL_NAME\" &\n"
            set Keyword " and"
          }
        }
        default {
            puts stderr "Keyed_Sql_Statment called with key= '$Key' for col '$Attributes(Name)' ... "
            exit 1
        }
      }
    }
    if {$Generate_IXX} {
      set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Cols]
	  set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Cols]
      if {$Has_IXX} {
        append S "            \" and [Field_Caseing IXXLUPD]=[Field_Caseing :IXXLUPD]\" &\n"
        append S "            \" and [Field_Caseing IXXLUDA]=[Field_Caseing :IXXLUDA]\" &\n"
        append S "            \" and [Field_Caseing IXXLUTI]=[Field_Caseing :IXXLUTI]\" &\n"
      }
      if {$Has_IXX_Ts} {
        append S "            \" and [Field_Caseing IXXLUPD]=[Field_Caseing :IXXLUPD]\" &\n"
        append S "            \" and [Field_Caseing IXXLUTS]=[Field_Caseing :IXXLUTS]\" &\n"
      }
    }



    if {$Order_By_PK} {
#  10.1-20890    append S "            \" order by [Primary_Key_List $Cols $Turns]\"\);"
      append S "            \" order by [Primary_Key_List $Cols]\"\);"
      return $S
	} else {
      set S2 [string replace [string trimright $S] end end \)]
      return "$S2 ;"
	}
  }

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Set_Keyed_Sql_Statment {Stm_Name Cols Key {Generate_IXX 0} {Turns 99999}} {
    set S {}
    set This_Turn 0
    foreach col $Cols {
      incr This_Turn
	  if {$This_Turn > $Turns} {
        break
	  }
      array set Attributes [Repo_Utils::Get_Attributes $col]
      ######
      switch -exact -- $Key {
        Primary {
          if {[Is_Primary $Attributes(Name)] } {
            set Col_Name [string totitle $Attributes(Name)]
            set COL_NAME [Field_Caseing $Attributes(Name)]
            set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
            switch -exact -- $Col_Type {
              STRING_FORMAT    -
              INTEGER_4_FORMAT -
              FLOAT_8_FORMAT {
                append S "    Sql.Set($Stm_Name, \"$COL_NAME\", Data.$Col_Name);\n"
              }
              CLOB_FORMAT {
                append S "    Sql.Set_Clob($Stm_Name, \"$COL_NAME\", Data.$Col_Name);\n"
              }
              DATE_FORMAT {
                append S "    Sql.Set_Date($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              TIME_FORMAT {
                append S "    Sql.Set_Time($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              TIMESTAMP_FORMAT {
                append S "    Sql.Set_Timestamp($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              default {
                puts stderr "Set_Keyed_Sql_Statment I Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
                exit 1
              }
            }
          }
        }
        Unique {
          if {[Is_Candidate $Attributes(Name)] } {
            set Col_Name [string totitle $Attributes(Name)]
            set COL_NAME [Field_Caseing $Attributes(Name)]
            set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
            switch -exact -- $Col_Type {
              STRING_FORMAT    -
              INTEGER_4_FORMAT -
              FLOAT_8_FORMAT {
                append S "    Sql.Set($Stm_Name, \"$COL_NAME\", Data.$Col_Name);\n"
              }
              CLOB_FORMAT {
                append S "    Sql.Set_Clob($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              DATE_FORMAT {
                append S "    Sql.Set_Date($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              TIME_FORMAT {
                append S "    Sql.Set_Time($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              TIMESTAMP_FORMAT {
                append S "    Sql.Set_Timestamp($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
              }
              default {
                puts stderr "Set_Keyed_Sql_Statment II Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
                exit 1
              }
            }
          }
        }
        default {
            puts stderr "Set_Keyed_Sql_Statment called with key= '$Key' for col '$Attributes(Name)' ... "
            exit 1
        }
      }
    }
#    if {$Generate_IXX} {
#    	append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
#        append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing IXXLUDA]\", Data.Ixxluda);\n"
#        append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing IXXLUTI]\", Data.Ixxluti);\n"
#    }

    if {$Generate_IXX} {
      set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Cols]
	  set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Cols]
      if {$Has_IXX} {
    	append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
        append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing IXXLUDA]\", Data.Ixxluda);\n"
        append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing IXXLUTI]\", Data.Ixxluti);\n"
      }
      if {$Has_IXX_Ts} {
    	append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
        append S "    Sql.Set_Timestamp($Stm_Name, \"[Field_Caseing IXXLUTS]\", Data.Ixxluts);\n"
      }
    }



    return $S
  }
  ###################################################################
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Prepare_All_Columns {Stm_Name First_Stm_Row Cols Where_Keys Old_IXX Set_Primary}  {
    set S "    Sql.Prepare($Stm_Name, $First_Stm_Row &\n"
    foreach col $Cols {
      array set Attributes [Repo_Utils::Get_Attributes $col]
#      set COL_NAME [string toupper $Attributes(Name)]
      set COL_NAME [Field_Caseing $Attributes(Name)]
      if {! $Set_Primary} {
        if {[Is_Primary $Attributes(Name)]} {
          continue ;# Skip this coulmn, since it is part of primary key
        }
      }
      append S "            \"$COL_NAME=:$COL_NAME,\" &\n"
    }

	#remove the last ','
	set S_OK {}
	set Last_Comma_Pos [string last , $S]
	if {$Last_Comma_Pos > -1} {
	  set S_OK [string replace $S $Last_Comma_Pos $Last_Comma_Pos  " "]
	}

	set S $S_OK

    set Keyword where
    if {$Where_Keys} {
      foreach col $Cols {
        array set Attributes [Repo_Utils::Get_Attributes $col]
        if {[Is_Primary $Attributes(Name)]} {
#          set COL_NAME [string toupper $Attributes(Name)]
          set COL_NAME [Field_Caseing $Attributes(Name)]
          append S "            \"$Keyword $COL_NAME=:$COL_NAME \" &\n"
          set Keyword "and"
        }
      }
    }
#    if {$Old_IXX} {
#      foreach C "IXXLUPD IXXLUDA IXXLUTI" {
#        append S "            \"and [Field_Caseing $C]=:[Field_Caseing OLD\_$C] \" &\n"
#      }
#    }

    if {$Old_IXX} {
      set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Cols]
	  set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Cols]
	  if {$Has_IXX} {
        foreach C "IXXLUPD IXXLUDA IXXLUTI" {
          append S "            \"and [Field_Caseing $C]=:[Field_Caseing OLD\_$C] \" &\n"
        }
      }

	  if {$Has_IXX_Ts} {
        foreach C "IXXLUPD IXXLUTS" {
          append S "            \"and [Field_Caseing $C]=:[Field_Caseing OLD\_$C] \" &\n"
        }
      }
    }





    set S2 [string replace [string trimright $S] end end \)]
    return "$S2 ;"
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Insert_All_Columns {Stm_Name First_Stm_Row Cols }  {
    set S "    Sql.Prepare($Stm_Name, $First_Stm_Row &\n"
    foreach col $Cols {
      array set Attributes [Repo_Utils::Get_Attributes $col]
#      set COL_NAME [string toupper $Attributes(Name)]
      set COL_NAME [Field_Caseing $Attributes(Name)]
      append S "            \":$COL_NAME, \" &\n"
    }
    set S2 [string replace [string trimright $S] end end \)]
    #OK, now replace the last ',' with '\)', the ',' _within_ the sql this time
    set pos [string last , $S2]
    set S3 [string replace $S2 $pos $pos "\)"]

    return "$S3 ;"
  }
  ##########################################################
  proc Set_All_Columns {Stm_Name Cols Set_Old_IXX Set_Primary}  {
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
    proc Set_Null {Col_Type Stm_Name COL_NAME} {
      set R {}
      switch -exact -- $Col_Type {
        STRING_FORMAT    -
        INTEGER_4_FORMAT -
        CLOB_FORMAT      -
        FLOAT_8_FORMAT {
          append R "Sql.Set_Null($Stm_Name, \"$COL_NAME\");\n"
        }
        DATE_FORMAT {
          append R "Sql.Set_Null_Date($Stm_Name, \"$COL_NAME\");\n"
        }
        TIME_FORMAT {
          # Set_Null_Time does not exists, so Set_Null_Date is used
          append R "Sql.Set_Null_Date($Stm_Name, \"$COL_NAME\");\n"
        }
        TIMESTAMP_FORMAT {
          # Set_Null_Time does not exists, so Set_Null_Date is used
          append R "Sql.Set_Null_Date($Stm_Name, \"$COL_NAME\");\n"
        }
        default {
          puts stderr "Set_All_Columns::Set_Null Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
          exit 1
        }
      }
    }

    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
    proc Index_Sql_Statment {Stm_Name First_Stm_Row Cols Index_Fields Order_By_Primary} {
      set S "    Sql.Prepare($Stm_Name, \" $First_Stm_Row \" & \n"
      set Index_Fields_List [split $Index_Fields "_"]
#      puts stderr "Index_Fields_List -> $Index_Fields_List"
      set Keyword where
      foreach col $Cols {
        array set Attributes [Repo_Utils::Get_Attributes $col]
#        set COL_NAME [string toupper $Attributes(Name)]
        set COL_NAME [Field_Caseing $Attributes(Name)]
        set Indexed 0
        foreach f $Index_Fields_List {
          if {[string equal [string tolower $f] [string tolower $COL_NAME]]} {
              set Indexed 1
              break
          }
        }
#        puts stderr "f, c, Indexed-> [string tolower $f] [string tolower $COL_NAME] , $Indexed"
      # just work on indexed fields
        if {! $Indexed} {
          continue
        }
        append S "            \"$Keyword $COL_NAME=:$COL_NAME\" &\n"
        set Keyword " and"
      }
      set Opk {}
      if {$Order_By_Primary} {
        set Opk "            \" order by [Primary_Key_List $Cols] \" &"
      }
      append S $Opk
      set S2 [string replace [string trimright $S] end end ""]

      return "$S2 \) ;"
    }

    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  proc Set_Index_Sql_Statment {Stm_Name Cols Index_Fields {Generate_IXX 0}} {
    set S {}
    set Index_Fields_List [split $Index_Fields "_"]
    foreach col $Cols {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set Col_Name [string totitle $Attributes(Name)]
#      set COL_NAME [string toupper $Attributes(Name)]
      set COL_NAME [Field_Caseing $Attributes(Name)]
      set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
      set Indexed 0
      foreach f $Index_Fields_List {
        if {[string equal [string tolower $f] [string tolower $COL_NAME]]} {
            set Indexed 1
            break
        }
#        puts stderr "f, c, Indexed-> [string tolower $f] [string tolower $COL_NAME] , $Indexed"
      }
      # just work on indexed fields
      if {! $Indexed} {
        continue
      }

      switch -exact -- $Col_Type {
        STRING_FORMAT    -
        INTEGER_4_FORMAT -
        FLOAT_8_FORMAT {
          append S "    Sql.Set($Stm_Name, \"$COL_NAME\", Data.$Col_Name);\n"
        }
        CLOB_FORMAT {
          append S "    Sql.Set_Clob($Stm_Name, \"$COL_NAME\", Data.$Col_Name);\n"
        }
        DATE_FORMAT {
          append S "    Sql.Set_Date($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
        }
        TIME_FORMAT {
          append S "    Sql.Set_Time($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
        }
        TIMESTAMP_FORMAT {
          append S "    Sql.Set_Timestamp($Stm_Name,\"$COL_NAME\", Data.$Col_Name);\n"
        }
        default {
          puts stderr "Set_Index_Sql_Statment I Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
          exit 1
        }
      }
    }
#    if {$Generate_IXX} {
#        append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
#        append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing IXXLUDA]\", Data.Ixxluda);\n"
#        append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing IXXLUTI]\", Data.Ixxluti);\n"
#   }
   if {$Generate_IXX} {
      set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Cols]
	  set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Cols]
      if {$Has_IXX} {
        append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
        append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing IXXLUDA]\", Data.Ixxluda);\n"
        append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing IXXLUTI]\", Data.Ixxluti);\n"
      }
      if {$Has_IXX_Ts} {
        append S "    Sql.Set($Stm_Name, \"[Field_Caseing IXXLUPD]\", Data.Ixxlupd);\n"
        append S "    Sql.Set_Timestamp($Stm_Name, \"[Field_Caseing IXXLUTS]\", Data.Ixxluts);\n"
      }
    }


    return $S
  }

    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
    proc Set_Non_Null {Col_Type Stm_Name COL_NAME} {
      set Col_Name [string totitle $COL_NAME]
      set R {}
      switch -exact -- $Col_Type {
            STRING_FORMAT    -
            INTEGER_4_FORMAT -
            FLOAT_8_FORMAT {
              append S "Sql.Set($Stm_Name, \"$COL_NAME\",Data.$Col_Name);\n"
            }
            CLOB_FORMAT {
              append S "Sql.Set_Clob($Stm_Name, \"$COL_NAME\",Data.$Col_Name);\n"
            }
            DATE_FORMAT {
              append S "Sql.Set_Date($Stm_Name, \"$COL_NAME\",Data.$Col_Name);\n"
            }
            TIME_FORMAT {
              append S "Sql.Set_Time($Stm_Name, \"$COL_NAME\",Data.$Col_Name);\n"
            }
            TIMESTAMP_FORMAT {
              append S "Sql.Set_Timestamp($Stm_Name, \"$COL_NAME\",Data.$Col_Name);\n"
            }
            default {
              puts stderr "Set_Non_Null Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
              exit 1
            }
      }
    }
    ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--


    set S {}
#    if {$Set_Old_IXX} {
#      append S "    Sql.Set($Stm_Name, \"[Field_Caseing OLD_IXXLUPD]\",Data.Ixxlupd);\n"
#      append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing OLD_IXXLUDA]\",Data.Ixxluda);\n"
#      append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing OLD_IXXLUTI]\",Data.Ixxluti);\n"
#    }

    if {$Set_Old_IXX} {
      set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Cols]
	  set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Cols]
      if {$Has_IXX} {
        append S "    Sql.Set($Stm_Name, \"[Field_Caseing OLD_IXXLUPD]\",Data.Ixxlupd);\n"
        append S "    Sql.Set_Date($Stm_Name, \"[Field_Caseing OLD_IXXLUDA]\",Data.Ixxluda);\n"
        append S "    Sql.Set_Time($Stm_Name, \"[Field_Caseing OLD_IXXLUTI]\",Data.Ixxluti);\n"
        append S "    if not Keep_Timestamp then\n"
        append S "      null; --for tables without Ixx* \n"
        append S "      Data.Ixxluda := Now;\n"
        append S "      Data.Ixxluti := Now;\n"
        append S "    end if;\n"
      }
      if {$Has_IXX_Ts} {
        append S "    Sql.Set($Stm_Name, \"[Field_Caseing OLD_IXXLUPD]\",Data.Ixxlupd);\n"
        append S "    Sql.Set_Timestamp($Stm_Name, \"[Field_Caseing OLD_IXXLUTS]\",Data.Ixxluts);\n"
        append S "    if not Keep_Timestamp then\n"
        append S "      null; --for tables without Ixx* \n"
        append S "      Data.Ixxluts := Now;\n"
        append S "    end if;\n"
      }
    }



    foreach col $Cols {
      array set Attributes [Repo_Utils::Get_Attributes $col]
#      set COL_NAME [string toupper $Attributes(Name)]
      set COL_NAME [Field_Caseing $Attributes(Name)]
      set Col_Name [string totitle $Attributes(Name)]
      set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
      if {! $Set_Primary} {
        if {[Is_Primary $Attributes(Name)]} {
          continue ;# Skip this coulmn, since it is part of priamry key
        }
      }

      if {$Attributes(AllowNull)} {
        switch -exact -- $Col_Name {
          Ixxluda -
          Ixxluti {
            append S "    if not Keep_Timestamp then\n"
            append S "      null; --for tables without Ixx* \n"
            append S "      Data.$Col_Name := Now;\n"
            append S "    end if;\n"
            append S "    [Set_Non_Null $Col_Type $Stm_Name $COL_NAME]"
          }
          default {
            append S "    if Data.$Col_Name = [Repo_Utils::Null_Data_For_Type_At_Comparison $Attributes(Type) $Attributes(Size) Data.$Col_Name] then\n"
            append S "      [Set_Null $Col_Type $Stm_Name $COL_NAME]"
            append S "    else\n"
            append S "      [Set_Non_Null $Col_Type $Stm_Name $COL_NAME]"
            append S "    end if;\n"
          }
        }
      } else {
        switch -exact -- $Col_Name {
          Ixxlupd {
            append S "    if not Keep_Timestamp then\n"
            append S "      null; --for tables without Ixxlupd\n"
            append S "      Data.Ixxlupd := Process.Name(1..12);\n"
            append S "    end if;\n"
            append S "    [Set_Non_Null $Col_Type $Stm_Name $COL_NAME]"
          }
          default {
            append S "    [Set_Non_Null $Col_Type $Stm_Name $COL_NAME]"
          }
        }
      }
    }
    return $S
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--


  proc Ada_Type {Columns Column_Name} {
  # for a column, return its Ada type
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
	  if {[string equal -nocase $Attributes(Name) $Column_Name]} {
	    return [::Repo_Utils::Type_To_Ada_Type $Attributes(Type) $Attributes(Size) ]
      }
    }
	return "Ada_Type - Found no matching type"
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--



##########################################################
proc Header {Out_File} {
  puts $Out_File [Repo_Utils::Header]
}

##########################################################
proc Print_Header_Spec {Name Type Node Columns Out_File} {
  Header $Out_File
}
##########################################################
proc Print_Withs_Spec {Name Type Node Columns Out_File} {
  puts $Out_File "pragma Warnings(Off);"
  puts $Out_File "with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;"
  puts $Out_File "with Sattmate_Types, Sattmate_Calendar, Uniface_Request, Sql, Simple_List_Class;"
  puts $Out_File ""
}
##########################################################
proc Print_Package_Start_Spec {Name Type Node Columns Out_File} {

  set Mixed_Name [string totitle $Name]
#  set Upper_Name [string toupper $Name]
  set Upper_Name [Table_Caseing $Name]

  puts $Out_File "package Table\_$Mixed_Name is\n"
  puts $Out_File "  use Sattmate_Types, Sattmate_Calendar, Uniface_Request;\n"
  puts $Out_File "  type Data_Type is record"

  set Columns [::dom::DOMImplementation selectNode $Node $::Column_Element_Name]
  set Index_Counter 0
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    #treat Boolean as integer_4
    if {[string equal $Attributes(Type) 7]} {
      set Used_Type 2
    } else {
      set Used_Type $Attributes(Type)
    }

    set Data_Type [Repo_Utils::Type_To_Ada_Type $Used_Type $Attributes(Size)]
    set Range {}
    if {[string equal $Data_Type String]} {
      if {! [ string equal $Attributes(Size) 1]} {
        set Range "\(1..$Attributes(Size)\)"
      }
    }
    set Null_Data [Repo_Utils::Null_Data_For_Type $Used_Type $Attributes(Size)]

    set Comment {--}
    if {[Is_Primary $Attributes(Name)]} {
      incr Index_Counter
      append Comment " Primary Key"
    } elseif {[Is_Candidate $Attributes(Name)]} {
      incr Index_Counter
      append Comment " unique index $Index_Counter"
    } elseif {[Is_Indexed $Attributes(Name) index] || [Is_Indexed $Attributes(Name) foreign] } {
      incr Index_Counter
      append Comment " non unique index $Index_Counter"
    }
    puts $Out_File "      [string totitle $Attributes(Name)] :    $Data_Type $Range := $Null_Data ; $Comment"
  }
  puts $Out_File "  end record;"

#  if {[Is_S08_Table $Name]} {
    puts $Out_File "  Empty_Data : Table_$Mixed_Name.Data_Type;"
#  }

  puts $Out_File "  -- \n  -- Table name as string \n  --"
  puts $Out_File "  Table_$Mixed_Name\_Name : constant String := \"$Upper_Name\";"

  puts $Out_File "  Table_$Mixed_Name\_Set_Name : constant String := \"$Upper_Name\_SET\";"
#chg-25420
  puts $Out_File "  Table_$Mixed_Name\_Row_Name : constant String := \"$Upper_Name\_ROW\";"

  puts $Out_File "  -- \n  -- Column names as strings \n  --"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Mixed_Column_Name [string totitle $Attributes(Name)]
#    set Upper_Column_Name [string toupper $Attributes(Name)]
    set Upper_Column_Name [Field_Caseing $Attributes(Name)]
    puts $Out_File "  $Mixed_Column_Name\_Name : constant String := \"$Upper_Column_Name\";"
  }

  puts $Out_File "  -- \n  -- Column names as enumerator literals \n  --"

  set s "  type Column_Type is \(\n"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Mixed_Column_Name [string totitle $Attributes(Name)]
    append s "        $Mixed_Column_Name,\n"
  }
  set pos [string last , $s]
  set s2 [string replace $s $pos $pos "\)"]
  set s3 [string replace $s2 end end ";"]
  puts $Out_File "$s3\n"

  puts $Out_File "  package $Mixed_Name\_List_Pack is new Simple_List_Class\(Table_$Mixed_Name.Data_Type\);"
}

##########################################################

proc Print_Def_Functions_Spec {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"
  ##--##--##--##--##--##--##--##--
  proc Index_Procs {Field Table_Name} {
    set Ret_Val {}
    regsub -all {,} $Field _ field_name    ; # replace all ',' with '_'
    set Field_Name [string totitle $field_name]
    append Ret_Val "\n"
    append Ret_Val "  procedure Read\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                       List  : in out $Table_Name\_List_Pack.List_Type;\n"
    append Ret_Val "                       Order : in     Boolean := False;\n"
    append Ret_Val "                       Max   : in     Integer_4 := Integer_4'Last);\n"
    append Ret_Val "  --------------------------------------------\n"

    append Ret_Val "\n"
    append Ret_Val "  procedure Read_One\_$Field_Name\(Data       : in out Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                           Order      : in     Boolean := False;\n"
    append Ret_Val "                           End_Of_Set : in out Boolean);\n"
    append Ret_Val "  --------------------------------------------\n"

    append Ret_Val "\n"
    append Ret_Val "  function Count\_$Field_Name\(Data : Table\_$Table_Name.Data_Type) return Integer_4;\n"
    append Ret_Val "  --------------------------------------------\n"
    append Ret_Val "\n"

    append Ret_Val "\n"
    append Ret_Val "  procedure Delete\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type);\n"
    append Ret_Val "  --------------------------------------------\n"

    return $Ret_Val
  }

  ##--##--##--##--##--##--##--##--
  proc Foreign_Procs {Field Table_Name} {
    return [Index_Procs $Field $Table_Name]
  }
  ##--##--##--##--##--##--##--##--
  proc Candidate_Procs {Field Table_Name} {
    set Ret_Val {}
    regsub -all {,} $Field _ field_name    ; # replace all ',' with '_'
    set Field_Name [string totitle $field_name]
    append Ret_Val "\n"
    append Ret_Val "  procedure Read\_$Field_Name\(Data       : in out Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                               End_Of_Set : in out Boolean );\n"
    append Ret_Val "\n"
    append Ret_Val "\n"
    append Ret_Val "  procedure Delete\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type);\n"
    append Ret_Val "  --------------------------------------------\n"

    return $Ret_Val
  }
  ##--##--##--##--##--##--##--##--

  proc Primary_Procs {Fields Table_Name Columns} {
    ## for pk's with several fields
    #puts "-- debug Fields, Table_Name -> $Fields , $Table_Name"
    set Ret_Val {}
    set Field_Name_List [split $Fields ","]
    set Number_Of_Commas_Replaced [regsub -all {,} $Fields _ field_names]   ; # replace all ',' with '_'
    if {! $Number_Of_Commas_Replaced} {
	  # no replacements -> no commas -> only one keyfield -> return
	  return ""
	}
    set Orig_Fld {}
    set Last_Field_Name [lindex $Field_Name_List end] ; # we need this, so we can skip it.
    foreach fld $Field_Name_List {
	  if {[string equal $fld $Last_Field_Name]} {
	    break
	  }
      set fld [string totitle $fld]
      set local_IDF_Numbering $::IDF_Numbering ; # Parameter in? Where do we get it from?
      append Orig_Fld \_$fld
      append Ret_Val "\n"
      append Ret_Val "  procedure Read\_$local_IDF_Numbering$Orig_Fld\(Data  : in     Table\_$Table_Name.Data_Type;\n"
      append Ret_Val "                       List  : in out $Table_Name\_List_Pack.List_Type;\n"
      append Ret_Val "                       Order : in     Boolean := False;\n"
      append Ret_Val "                       Max   : in     Integer_4 := Integer_4'Last);\n"
      append Ret_Val "  --------------------------------------------\n"
      append Ret_Val "\n"
      append Ret_Val "  procedure Delete\_$local_IDF_Numbering$Orig_Fld\(Data  : in     Table\_$Table_Name.Data_Type\);\n"
      append Ret_Val "  --------------------------------------------\n"
      append Ret_Val "\n"
      append Ret_Val "  function Is_Existing\_$local_IDF_Numbering\(\n"
	  set Tmp_Fld_List2 [split $Orig_Fld "_"]
	   ; # first is blank, skip it
	  set Tmp_Fld_List  [lrange $Tmp_Fld_List2 1 end]
      #puts "-- debug Tmp_Fld_List - Orig_Fld -> $Tmp_Fld_List - $Orig_Fld"
      set cnt 0  ; # we need a counter to see if a ';' is needed at end
      set num_flds [llength $Tmp_Fld_List] ; # first is blank ...
	  foreach Tmp_Fld $Tmp_Fld_List {
        incr cnt
        if { $cnt >= $num_flds  } {
          append Ret_Val "                 $Tmp_Fld     : in [Ada_Type $Columns $Tmp_Fld] \) "
		} else {
          append Ret_Val "                 $Tmp_Fld     : in [Ada_Type $Columns $Tmp_Fld] ;\n"
		}
      }
	  append Ret_Val "     return Boolean;\n"
    }
    return $Ret_Val
  }

 ##--##--##--##--##--##--##--##--


  if {[string equal $Type $ART_Definitions::Clreqs]} {
    return 0
  }
  set Table_Name [string totitle $Name]
  set Columns [::dom::DOMImplementation selectNode $Node $::Column_Element_Name]
  set Has_IXX_Fields [Repo_Utils::Table_Has_IXX_Fields_2 $Columns]
  set Has_IXX_Ts_Fields [Repo_Utils::Table_Has_IXX_Timestamp_2 $Columns]

#Functions operating on Primary Key
  puts $Out_File ""
  puts $Out_File "  -- Procedures for DBMS DEF"
  puts $Out_File "  -- Primary key"
  ##############################################################
  puts $Out_File "  function Get(Stm : in Sql.Statement_Type) return Table\_$Table_Name.Data_Type;"
  puts $Out_File "  --------------------------------------------"
  ##############################################################
  puts $Out_File "  procedure Read(Data       : in out Table\_$Table_Name.Data_Type;"
  puts $Out_File "                 End_Of_Set : in out Boolean);"
  puts $Out_File "  --------------------------------------------"
  ##############################################################
  set F "  function Is_Existing("
  set S {}
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    if { [Is_Primary $Attributes(Name)]} {
      set Col_Name [string totitle $Attributes(Name)]
      append S "                       $Col_Name : [Repo_Utils::Type_To_Ada_Type $Attributes(Type) $Attributes(Size)];\n"
    }
  }
  set S2 [string replace [string trim $S] end end \) ]
  puts $Out_File "$F$S2 return Boolean;"
  puts $Out_File "  --------------------------------------------"


  ##############################################################
  set F "  function Get("
  set S {}
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    if { [Is_Primary $Attributes(Name)]} {
      set Col_Name [string totitle $Attributes(Name)]
      append S "                       $Col_Name : [Repo_Utils::Type_To_Ada_Type $Attributes(Type) $Attributes(Size)];\n"
    }
  }
  set S2 [string replace [string trim $S] end end \) ]
  puts $Out_File "$F$S2 return Table\_$Table_Name.Data_Type;"
  puts $Out_File "  --------------------------------------------"

  ##############################################################

# Always these
  puts $Out_File ""
  puts $Out_File "  procedure Read_List(Stm  : in     Sql.Statement_Type;"
  puts $Out_File "                      List : in out $Table_Name\_List_Pack.List_Type;"
  puts $Out_File "                      Max  : in     Integer_4 := Integer_4'Last);"
  puts $Out_File "  --------------------------------------------"
  ##############################################################

  puts $Out_File "  procedure Read_All(List  : in out $Table_Name\_List_Pack.List_Type;"
  puts $Out_File "                     Order : in     Boolean := False;"
  puts $Out_File "                     Max   : in     Integer_4 := Integer_4'Last);"
  puts $Out_File "  --------------------------------------------"

  ##############################################################

  puts $Out_File "  procedure Delete(Data : in Table\_$Table_Name.Data_Type);"
  puts $Out_File "  --------------------------------------------"
  ##############################################################

  set All_Are_Primary [All_Fields_Are_Primary_Keys $Columns]
  if {! $All_Are_Primary} {
    puts $Out_File "  procedure Update(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False);"
    puts $Out_File "  --------------------------------------------"
  }
  ##############################################################

  puts $Out_File "  procedure Insert(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False);"
  puts $Out_File "  --------------------------------------------"

  ##############################################################
  if {$Has_IXX_Fields || $Has_IXX_Ts_Fields } {
    puts $Out_File "  procedure Delete_Withcheck(Data : in Table\_$Table_Name.Data_Type);"
    puts $Out_File "  --------------------------------------------"
  ##############################################################
    if {! $All_Are_Primary} {
      puts $Out_File "  procedure Update_Withcheck(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False);"
      puts $Out_File "  --------------------------------------------"
    }
  }
  ##############################################################

  set Indices [::dom::DOMImplementation selectNode $Node $::Index_Element_Name]

  foreach Index $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $Index]

    switch -exact -- $Index_Attributes(type) {
      primary {
        puts $Out_File "  -- Primary keys, when several fields"
        puts $Out_File [Primary_Procs $Index_Attributes(Columns) $Table_Name $Columns]
	  }
      candidate {
        puts $Out_File "  -- Candidate key"
        puts $Out_File [Candidate_Procs $Index_Attributes(Columns) $Table_Name]
      }
      index {
        puts $Out_File "  -- Index "
        puts $Out_File [Index_Procs $Index_Attributes(Columns) $Table_Name]
      }
      foreign {
        puts $Out_File "  -- Index Foreign key"
        puts $Out_File [Foreign_Procs $Index_Attributes(Columns) $Table_Name]
      }
      default {
        puts stderr "  Unknown indextype: $Index_Attributes(type)"
        puts stderr "    Valid: primary, candidate, index, foreign"
        exit 1
      }
    }
  }
}

########################################################
proc Print_Ud4_Functions_Spec {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"
  set Table_Name [string totitle $Name]

  puts $Out_File ""
  puts $Out_File "  -- Procedures for DBMS UD4"
  puts $Out_File ""

  puts $Out_File "  --------------------------------------------"
  puts $Out_File "  procedure Get_Values(Request : in     Request_Type;"
  puts $Out_File "                       Data    : in out Table\_$Table_Name.Data_Type);"
  puts $Out_File "  --------------------------------------------"
  puts $Out_File ""
  puts $Out_File "  procedure Set_Values(Reply  : in out Request_Type;"
  puts $Out_File "                       Data   : in     Table\_$Table_Name.Data_Type);"
  puts $Out_File "  --------------------------------------------"
  puts $Out_File ""
  puts $Out_File "  procedure Make_Ud4_Telegram(Request   : in out Uniface_Request.Request_Type;"
  puts $Out_File "                              Operation	: in     Operation_Type := Get_One_Record);"
  puts $Out_File "  --------------------------------------------"
  puts $Out_File ""
  puts $Out_File "  procedure Make_Ud4_Telegram(Request   : in out Uniface_Request.Request_Type;"
  puts $Out_File "                              Data      : in     Table\_$Table_Name.Data_Type;"
  puts $Out_File "                              Operation	: in     Operation_Type := Get_One_Record);"
  puts $Out_File "  --------------------------------------------"
  puts $Out_File "\n\n"

}

########################################################
proc Print_XML_Functions_Spec {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"
  set Table_Name [string totitle $Name]
  puts $Out_File ""
  puts $Out_File "  -- Procedures for all DBMS"
  puts $Out_File ""
  puts $Out_File "  function To_String(Data : in Table\_$Table_Name.Data_Type) return String;"
  puts $Out_File ""

  puts $Out_File "  function To_Xml(Data      : in Table\_$Table_Name.Data_Type;"
  puts $Out_File "                  Ret_Start : in Boolean;"
  puts $Out_File "                  Ret_Data  : in Boolean;"
  puts $Out_File "                  Ret_End   : in Boolean) return String;"
  puts $Out_File ""

#  if {[Is_S08_Table $Name]} {
    puts $Out_File "  procedure From_Xml(Xml_Filename : in Unbounded_String;"
    puts $Out_File "                     A_List       : in out $Table_Name\_List_Pack.List_Type);"
    puts $Out_File ""
#  }
}

########################################################
proc Print_Package_End_Spec {Name Type Node Columns Out_File} {
  set Mixed_Name [string totitle $Name]
  puts $Out_File "end Table\_$Mixed_Name ;\n"
}
########################################################

proc Print_Header_Body {Name Type Node Columns Out_File} {
  Header $Out_File
  puts $Out_File ""
}
########################################################


proc Print_Withs_Body {Name Type Node Columns Out_File} {
  puts $Out_File "pragma Warnings(Off);"
  puts $Out_File "with Process_Io, General_Routines, Text_Io, Standard8, Cgi;"
#  if {[Is_S08_Table $Name]} {
    puts $Out_File "with Ada.Strings.Fixed;"
    puts $Out_File "with Sax.Readers;              use Sax.Readers;"
    puts $Out_File "with Input_Sources.File;       use Input_Sources.File;"
    puts $Out_File "with Unicode.CES;"
    puts $Out_File "with Unicode.Encodings;"
    puts $Out_File "with Sax.Attributes;"
    puts $Out_File ""
#  }
}
########################################################
proc Print_Package_Start_Body {Name Type Node Columns Out_File} {
  set Mixed_Name [string totitle $Name]
  set Upper_Name [string toupper $Name]
  puts $Out_File "package body Table\_$Mixed_Name is\n"
  if {[string equal $Type $ART_Definitions::Db_Tables]} {
    puts $Out_File "  Stm_Select,"
    puts $Out_File "  Stm_Delete,"
    puts $Out_File "  Stm_Update,"
    puts $Out_File "  Stm_Insert,"
    puts $Out_File "  Stm_Select_All,"
    puts $Out_File "  Stm_Select_All_O  : Sql.Statement_Type;\n\n"

    if {[Repo_Utils::Table_Has_IXX_Fields_2 $Columns] || [Repo_Utils::Table_Has_IXX_Timestamp_2 $Columns]} {
      puts $Out_File "  Stm_Delete_With_Check,"
      puts $Out_File "  Stm_Update_With_Check  : Sql.Statement_Type;\n\n"
    }

  set Indices [::dom::DOMImplementation selectNode $Node $::Index_Element_Name]
  foreach Index $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $Index]
    regsub -all {,} $Index_Attributes(Columns) _ field_name    ; # replace all ',' with '_'
    set Field_Name [string totitle $field_name]

    switch -exact -- $Index_Attributes(type) {
      primary {
          set local_IDF_Numbering $::IDF_Numbering ; # Parameter in? Where do we get it from?
	      set Tmp_Fld_List [split $Index_Attributes(Columns) ","]
          set Field_Name_List  [lrange $Tmp_Fld_List 0 end-1]  ; #first is {}, remove it
		  set Orig_Fld {}
          foreach fld $Field_Name_List {
            set fld [string totitle $fld]
            append Orig_Fld \_$fld
            puts $Out_File "  -- Primary key, if several fields"
		    puts $Out_File "  Stm_Select\_$local_IDF_Numbering$Orig_Fld\_O,"
            puts $Out_File "  Stm_Select\_$local_IDF_Numbering$Orig_Fld,"
            puts $Out_File "  Stm_Delete\_$local_IDF_Numbering$Orig_Fld : Sql.Statement_Type; \n"
          }
	  }
      candidate {
        puts $Out_File "  -- Candidate key"
        puts $Out_File "  Stm_Delete\_$Field_Name\_Candidate ,"
        puts $Out_File "  Stm_Select\_$Field_Name\_Candidate : Sql.Statement_Type;\n"
      }
      index {
        puts $Out_File "  -- Index "
        puts $Out_File "  Stm_Select_Count\_$Field_Name ,"
        puts $Out_File "  Stm_Select\_$Field_Name ,"
        puts $Out_File "  Stm_Delete\_$Field_Name ,"
        puts $Out_File "  Stm_Select\_$Field_Name\_O : Sql.Statement_Type;\n"
      }
      foreign {
        puts $Out_File "  -- Index Foreign key"
        puts $Out_File "  Stm_Select_Count\_$Field_Name ,"
        puts $Out_File "  Stm_Select\_$Field_Name ,"
        puts $Out_File "  Stm_Delete\_$Field_Name ,"
        puts $Out_File "  Stm_Select\_$Field_Name\_O : Sql.Statement_Type;\n"

      }
      default {
        puts stderr "  Unknown indextype: $Index_Attributes(type)"
        puts stderr "    Valid: primary, candidate, index, foreign"
        exit 1
      }
    }
  }


  }
}
########################################################

proc Print_Def_Functions_Body {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"
  proc Index_Procs {Field Table_Name Columns {Index_Type Indexed}} {
#    set TABLE_NAME [string toupper $Table_Name]
    set TABLE_NAME [Table_Caseing $Table_Name]

    set Ret_Val {}
    regsub -all {,} $Field _ field_name    ; # replace all ',' with '_'
    set Field_Name [string totitle $field_name]
    set FIELD_NAME [string toupper $field_name]

    set Stm "Stm_Select\_$Field_Name"
    append Ret_Val "\n"
    append Ret_Val "  procedure Read\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                       List  : in out $Table_Name\_List_Pack.List_Type;\n"
    append Ret_Val "                       Order : in     Boolean := False;\n"
    append Ret_Val "                       Max   : in     Integer_4 := Integer_4'Last) is\n"
    append Ret_Val "    use Sql;\n"
    append Ret_Val "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);\n"
    append Ret_Val "    Transaction : Sql.Transaction_Type;\n"
    append Ret_Val "  begin\n"
    append Ret_Val "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;\n"
    append Ret_Val "    if Order then\n"
    append Ret_Val "  [Index_Sql_Statment $Stm\_O "select * from $TABLE_NAME" $Columns $Field_Name 1] \n"
    append Ret_Val "  [Set_Index_Sql_Statment $Stm\_O $Columns $Field_Name] \n"
    append Ret_Val "      Read_List($Stm\_O, List, Max);\n"
    append Ret_Val "    else\n"
    append Ret_Val "  [Index_Sql_Statment $Stm "select * from $TABLE_NAME" $Columns $Field_Name 0] \n"
    append Ret_Val "  [Set_Index_Sql_Statment $Stm $Columns $Field_Name] \n"
    append Ret_Val "      Read_List($Stm, List, Max);\n"
    append Ret_Val "    end if;\n"
    append Ret_Val "    if Start_Trans then Sql.Commit(Transaction); end if;\n"
    append Ret_Val "  end Read\_$Field_Name;\n---------------------------------------------\n"
    ######################################################################
    append Ret_Val "  procedure Read_One\_$Field_Name\(Data       : in out Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                           Order      : in     Boolean := False;\n"
    append Ret_Val "                           End_Of_Set : in out Boolean) is\n"
    append Ret_Val "    List : $Table_Name\_List_Pack.List_Type := $Table_Name\_List_Pack.Create;\n"
    append Ret_Val "  begin\n"
    append Ret_Val "    Read\_$Field_Name\(Data, List, Order, 1\);\n"
    append Ret_Val "    if $Table_Name\_List_Pack.Is_Empty(List) then\n"
    append Ret_Val "      End_Of_Set := True;\n"
    append Ret_Val "    else\n"
    append Ret_Val "      End_Of_Set := False;\n"
    append Ret_Val "      $Table_Name\_List_Pack.Remove_From_Head(List, Data);\n"
    append Ret_Val "    end if;\n"
    append Ret_Val "    $Table_Name\_List_Pack.Release(List);\n"
    append Ret_Val "    end Read_One\_$Field_Name;\n---------------------------------------------\n"
    ##########################################################################
    append Ret_Val "\n"

    set Stm "Stm_Select_Count\_$Field_Name"

    append Ret_Val "  function Count\_$Field_Name\(Data : Table\_$Table_Name.Data_Type) return Integer_4 is\n"
    append Ret_Val "    use Sql;\n"
    append Ret_Val "    Count       : Integer_4 := 0;\n"
    append Ret_Val "    End_Of_Set  : Boolean := False;\n"
    append Ret_Val "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);\n"
    append Ret_Val "    Transaction : Sql.Transaction_Type;\n"
    append Ret_Val "  begin\n"
    append Ret_Val "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;\n"

    append Ret_Val "    Sql.Prepare($Stm, \"select count('a') from $TABLE_NAME where $FIELD_NAME = :$FIELD_NAME \");\n"
    append Ret_Val "[Set_Index_Sql_Statment $Stm $Columns $Field_Name] \n"

    append Ret_Val "    Sql.Open_Cursor($Stm);\n"
    append Ret_Val "    Sql.Fetch($Stm, End_Of_Set);\n"
    append Ret_Val "    if not End_Of_Set then\n"
    append Ret_Val "      Sql.Get($Stm, 1, Count);\n"
    append Ret_Val "    end if;\n"
    append Ret_Val "    Sql.Close_Cursor($Stm);\n"
    append Ret_Val "    if Start_Trans then Sql.Commit(Transaction); end if;\n"
    append Ret_Val "    return Count;\n"
    append Ret_Val "  end Count\_$Field_Name;\n---------------------------------------------\n"
    #############################################################################
    set Stm "Stm_Delete\_$Field_Name"
    append Ret_Val "  procedure Delete\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type) is\n"
    append Ret_Val "  begin\n"

    append Ret_Val "  [Index_Sql_Statment $Stm "delete from $TABLE_NAME" $Columns $Field_Name 0] \n"
    append Ret_Val "  [Set_Index_Sql_Statment $Stm $Columns $Field_Name] \n"

    append Ret_Val "    Sql.Execute($Stm);\n"
    append Ret_Val "  end Delete\_$Field_Name;\n---------------------------------------------\n"
    append Ret_Val "\n"
    ################################################################################
    return $Ret_Val
  }
  ##--##--##--##--##--##--##--##--

  proc Foreign_Procs {Field Table_Name Columns } {
    return [Index_Procs $Field $Table_Name $Columns Foreign]
  }
  ##--##--##--##--##--##--##--##--
  proc Candidate_Procs {Field Table_Name Columns} {
    set Ret_Val {}
    regsub -all {,} $Field _ field_name    ; # replace all ',' with '_'
#    set TABLE_NAME [string toupper $Table_Name]
    set TABLE_NAME [Table_Caseing $Table_Name]
    set Field_Name [string totitle $field_name]

    append Ret_Val "\n"
    set Stm "Stm_Select\_$Field_Name\_Candidate"
    append Ret_Val "  procedure Read\_$Field_Name\(Data       : in out Table\_$Table_Name.Data_Type;\n"
    append Ret_Val "                               End_Of_Set : in out Boolean ) is\n"

    append Ret_Val "    use Sql;\n"
    append Ret_Val "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);\n"
    append Ret_Val "    Transaction : Sql.Transaction_Type;\n"
    append Ret_Val "  begin\n"
    append Ret_Val "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;\n"
    append Ret_Val "[Keyed_Sql_Statment $Stm "select * from $TABLE_NAME" Unique $Columns] \n"

    append Ret_Val "[Set_Keyed_Sql_Statment $Stm $Columns Unique 0] \n"

    append Ret_Val "    Sql.Open_Cursor($Stm);\n"
    append Ret_Val "    Sql.Fetch($Stm, End_Of_Set);\n"
    append Ret_Val "    if not End_Of_Set then\n"
    append Ret_Val "      Data := Get($Stm);\n"
    append Ret_Val "    end if;\n"
    append Ret_Val "    Sql.Close_Cursor($Stm);\n"
    append Ret_Val "    if Start_Trans then Sql.Commit(Transaction); end if;\n"
    append Ret_Val "  end Read\_$Field_Name;\n---------------------------------------------\n"
    append Ret_Val "\n"
    ########################################################################
    set Stm "Stm_Delete\_$Field_Name\_Candidate"

    append Ret_Val "  procedure Delete\_$Field_Name\(Data  : in     Table\_$Table_Name.Data_Type) is\n"
    append Ret_Val "  begin\n"
    append Ret_Val "[Keyed_Sql_Statment $Stm "delete from $TABLE_NAME" Unique $Columns] \n"
    append Ret_Val "[Set_Keyed_Sql_Statment $Stm $Columns Unique 0] \n"

    append Ret_Val "    Sql.Execute($Stm);\n"
    append Ret_Val "  end Delete\_$Field_Name;\n---------------------------------------------\n"
    append Ret_Val "\n"
    #########################################################################
    return $Ret_Val
  }

  ##--##--##--##--##--##--##--##--

  proc Primary_Procs {Fields Table_Name Columns} {
    ## for pk's with several fields
    #puts "-- debug Fields, Table_Name -> $Fields , $Table_Name"
    set Ret_Val {}
    set Field_Name_List [split $Fields ","]
    set Number_Of_Commas_Replaced [regsub -all {,} $Fields _ field_names]   ; # replace all ',' with '_'
    if {! $Number_Of_Commas_Replaced} {
	  # no replacements -> no commas -> only one keyfield -> return
	  return ""
	}
#    set TABLE_NAME [string toupper $Table_Name]
    set TABLE_NAME [Table_Caseing $Table_Name]

    set Number_Of_Primary_Fields_To_Process 0
    set Orig_Fld {}
    set Last_Field_Name [lindex $Field_Name_List end] ; # we need this, so we can skip it.
    foreach fld $Field_Name_List {
	  if {[string equal $fld $Last_Field_Name]} {
	    break
	  }
      incr Number_Of_Primary_Fields_To_Process
      set fld [string totitle $fld]
      set local_IDF_Numbering $::IDF_Numbering ; # Parameter in? Where do we get it from?
      append Orig_Fld \_$fld
      append Ret_Val "\n"
      append Ret_Val "  procedure Read\_$local_IDF_Numbering$Orig_Fld\(Data  : in     Table\_$Table_Name.Data_Type;\n"
      append Ret_Val "                       List  : in out $Table_Name\_List_Pack.List_Type;\n"
      append Ret_Val "                       Order : in     Boolean := False;\n"
      append Ret_Val "                       Max   : in     Integer_4 := Integer_4'Last) is\n"
      append Ret_Val "    use Sql;\n"
      append Ret_Val "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);\n"
      append Ret_Val "    Transaction : Sql.Transaction_Type;\n"
      append Ret_Val "  begin\n"
      append Ret_Val "    if (Start_Trans) then Sql.Start_Read_Write_Transaction(Transaction); end if;\n"
      append Ret_Val "    if Order then\n"
      append Ret_Val "  [Keyed_Sql_Statment Stm_Select\_$local_IDF_Numbering$Orig_Fld\_O "select * from $TABLE_NAME" Primary $Columns 0 $Number_Of_Primary_Fields_To_Process 1] \n"
      append Ret_Val "  [Set_Keyed_Sql_Statment Stm_Select\_$local_IDF_Numbering$Orig_Fld\_O $Columns Primary 0 $Number_Of_Primary_Fields_To_Process] \n"
      append Ret_Val "      Read_List\(Stm_Select\_$local_IDF_Numbering$Orig_Fld\_O, List, Max);\n"
      append Ret_Val "    else\n"
      append Ret_Val "  [Keyed_Sql_Statment Stm_Select\_$local_IDF_Numbering$Orig_Fld "select * from $TABLE_NAME" Primary $Columns 0 $Number_Of_Primary_Fields_To_Process] \n"
      append Ret_Val "  [Set_Keyed_Sql_Statment Stm_Select\_$local_IDF_Numbering$Orig_Fld $Columns Primary 0 $Number_Of_Primary_Fields_To_Process] \n"
      append Ret_Val "      Read_List\(Stm_Select\_$local_IDF_Numbering$Orig_Fld, List, Max);\n"
      append Ret_Val "    end if;\n"
      append Ret_Val "    if (Start_Trans) then Sql.Commit(Transaction); end if;\n"
      append Ret_Val "  end Read\_$local_IDF_Numbering$Orig_Fld;\n"

      append Ret_Val "  --------------------------------------------\n"
      ######################################################################
      append Ret_Val "\n"
      append Ret_Val "  procedure Delete\_$local_IDF_Numbering$Orig_Fld\(Data  : in     Table\_$Table_Name.Data_Type\) is\n"
      append Ret_Val "  begin\n"
      append Ret_Val "  [Keyed_Sql_Statment Stm_Delete\_$local_IDF_Numbering$Orig_Fld "delete from $TABLE_NAME" Primary $Columns 0 $Number_Of_Primary_Fields_To_Process 0] \n"
      append Ret_Val "  [Set_Keyed_Sql_Statment Stm_Delete\_$local_IDF_Numbering$Orig_Fld $Columns Primary 0 $Number_Of_Primary_Fields_To_Process] \n"
      append Ret_Val "    Sql.Execute\(Stm_Delete\_$local_IDF_Numbering$Orig_Fld\);\n"
      append Ret_Val "  end Delete\_$local_IDF_Numbering$Orig_Fld;\n"
      append Ret_Val "  --------------------------------------------\n"

      ######################################################################
      append Ret_Val "\n"
      append Ret_Val "  function Is_Existing\_$local_IDF_Numbering\(\n"
	  set Tmp_Fld_List2 [split $Orig_Fld "_"]
	   ; # first is blank, skip it
	  set Tmp_Fld_List  [lrange $Tmp_Fld_List2 1 end]
      #puts "-- debug Tmp_Fld_List - Orig_Fld -> $Tmp_Fld_List - $Orig_Fld"
      set cnt 0  ; # we need a counter to see if a ';' is needed at end
      set num_flds [llength $Tmp_Fld_List] ; # first is blank ...
	  set Fill_Data {}
	  foreach Tmp_Fld $Tmp_Fld_List {
        incr cnt
        if { $cnt >= $num_flds  } {
          append Ret_Val "                 $Tmp_Fld     : in [Ada_Type $Columns $Tmp_Fld] \)"
		} else {
          append Ret_Val "                 $Tmp_Fld     : in [Ada_Type $Columns $Tmp_Fld] ;\n"
		}
        append Fill_Data "    Data.$Tmp_Fld := $Tmp_Fld ; \n"
      }
	  append Ret_Val "     return Boolean is\n"
      append Ret_Val "    Data       : Table\_$Table_Name.Data_Type;\n"
      append Ret_Val "    End_Of_Set : Boolean := False;\n"
      append Ret_Val "    Is_Exist   : Boolean := False;\n"
      append Ret_Val "    List       : $Table_Name\_List_Pack.List_Type := $Table_Name\_List_Pack.Create;\n"
      append Ret_Val "  begin\n"
      append Ret_Val $Fill_Data
      append Ret_Val "    Read\_$local_IDF_Numbering$Orig_Fld\(Data, List, False, 1\);\n"
      append Ret_Val "    Is_Exist := not $Table_Name\_List_Pack.Is_Empty\(List\);\n"
      append Ret_Val "    $Table_Name\_List_Pack.Release\(List\);\n"
      append Ret_Val "    return Is_Exist;\n"
      append Ret_Val "  end Is_Existing\_$local_IDF_Numbering ;\n"
      append Ret_Val "  --------------------------------------------\n"
    }
    return $Ret_Val
  }

 ##--##--##--##--##--##--##--##--

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Get {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
    set TABLE_NAME [string toupper $Name]
    #################################################################################
    puts $Out_File "  function Get(Stm : in Sql.Statement_Type) return Table\_$Table_Name.Data_Type is"
    puts $Out_File "    Data : Table\_$Table_Name.Data_Type;"
    puts $Out_File "  begin"
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
#      set COL_NAME [string toupper $Attributes(Name)]
      set COL_NAME [Field_Caseing $Attributes(Name)]
      set Col_Name [string totitle $Attributes(Name)]
      puts $Out_File "    if not Sql.Is_Null(Stm, \"$COL_NAME\") then"
      set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]

      switch -exact -- $Col_Type {
        STRING_FORMAT    -
        INTEGER_4_FORMAT -
        FLOAT_8_FORMAT {
          puts $Out_File "      Sql.Get(Stm, \"$COL_NAME\", Data.$Col_Name);"
        }
        CLOB_FORMAT {
          puts $Out_File "      Sql.Get_Lob(Stm, \"$COL_NAME\", Data.$Col_Name);"
        }
        DATE_FORMAT {
          puts $Out_File "      Sql.Get_Date(Stm, \"$COL_NAME\", Data.$Col_Name);"
        }
        TIME_FORMAT {
          puts $Out_File "      Sql.Get_Time(Stm, \"$COL_NAME\", Data.$Col_Name);"
        }
        TIMESTAMP_FORMAT {
          puts $Out_File "      Sql.Get_Timestamp(Stm, \"$COL_NAME\", Data.$Col_Name);"
        }
        default {
          puts stderr "Get I Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
          exit 1
        }
      }

      puts $Out_File "    else"
      puts $Out_File "      Data.$Col_Name := [Repo_Utils::Null_Data_For_Type_In_Db $Attributes(Type) $Attributes(Size)];"
      puts $Out_File "    end if;"
    }
    puts $Out_File "  return Data;"
    puts $Out_File "  end Get;\n---------------------------------------------\n"
    ##########################################################################
  }

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Read {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ########################################################################
    puts $Out_File "  procedure Read(Data       : in out Table\_$Table_Name.Data_Type;"
    puts $Out_File "                 End_Of_Set : in out Boolean) is"
    puts $Out_File "    use Sql;"
    puts $Out_File "    Start_Trans   : constant Boolean := (Sql.Transaction_Status = Sql.None);"
    puts $Out_File "    Transaction   : Sql.Transaction_Type;"
    puts $Out_File "  begin"
    puts $Out_File "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;"

    puts $Out_File [Keyed_Sql_Statment Stm_Select "select * from $TABLE_NAME" Primary $Columns]
    puts $Out_File [Set_Keyed_Sql_Statment Stm_Select $Columns Primary]

    puts $Out_File "    Sql.Open_Cursor(Stm_Select);"
    puts $Out_File "    Sql.Fetch(Stm_Select, End_Of_Set);"
    puts $Out_File "    if not End_Of_Set then"
    puts $Out_File "      Data := Get(Stm_Select);"
    puts $Out_File "    end if;"
    puts $Out_File "    Sql.Close_Cursor(Stm_Select);"
    puts $Out_File "    if Start_Trans then Sql.Commit(Transaction); end if;"
    puts $Out_File "  end Read;\n---------------------------------------------\n"
    #############################################################################
  }

#start
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Get_On_Key {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    #############################################################################
    set F "  function Get("
    set S {}
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if { [Is_Primary $Attributes(Name)]} {
        set Col_Name [string totitle $Attributes(Name)]
        append S "                       $Col_Name : [Repo_Utils::Type_To_Ada_Type $Attributes(Type) $Attributes(Size)];\n"
      }
    }
    set S2 [string replace [string trim $S] end end \) ]
    puts $Out_File "$F$S2 return Table\_$Table_Name.Data_Type is"
    puts $Out_File "    Data       : Table\_$Table_Name.Data_Type;"
    puts $Out_File "    End_Of_Set : Boolean := True;"
    puts $Out_File "  begin"
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if { [Is_Primary $Attributes(Name)]} {
        set Col_Name [string totitle $Attributes(Name)]
        puts $Out_File "    Data.$Col_Name := $Col_Name;"
      }
    }
    puts $Out_File "    Read(Data, End_Of_Set);"
    puts $Out_File "    return Data;"
    puts $Out_File "  end Get;\n--------------------------------------------\n"
    ##############################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Is_Existing {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    #############################################################################
    set F "  function Is_Existing("
    set S {}
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if { [Is_Primary $Attributes(Name)]} {
        set Col_Name [string totitle $Attributes(Name)]
        append S "                       $Col_Name : [Repo_Utils::Type_To_Ada_Type $Attributes(Type) $Attributes(Size)];\n"
      }
    }
    set S2 [string replace [string trim $S] end end \) ]
    puts $Out_File "$F$S2 return Boolean is"
    puts $Out_File "    Data       : Table\_$Table_Name.Data_Type;"
    puts $Out_File "    End_Of_Set : Boolean := True;"
    puts $Out_File "  begin"
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if { [Is_Primary $Attributes(Name)]} {
        set Col_Name [string totitle $Attributes(Name)]
        puts $Out_File "    Data.$Col_Name := $Col_Name;"
      }
    }
    puts $Out_File "    Read(Data, End_Of_Set);"
    puts $Out_File "    return not End_Of_Set;"
    puts $Out_File "  end Is_Existing;\n--------------------------------------------\n"
    ##################################################################################
  }

# Always these
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Read_List {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    ########################################################################
    puts $Out_File ""
    puts $Out_File "  procedure Read_List(Stm  : in     Sql.Statement_Type;"
    puts $Out_File "                      List : in out $Table_Name\_List_Pack.List_Type;"
    puts $Out_File "                      Max  : in     Integer_4 := Integer_4'Last) is"
    puts $Out_File "    use Sql;"
    puts $Out_File "    Count       : Integer_4 := 0;"
    puts $Out_File "    Data        : Table\_$Table_Name.Data_Type;"
    puts $Out_File "    Eos         : Boolean := False;"
    puts $Out_File "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);"
    puts $Out_File "    Transaction  : Sql.Transaction_Type;"
    puts $Out_File "  begin"
    puts $Out_File "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;"
    puts $Out_File "    Sql.Open_Cursor(Stm);"
    puts $Out_File "    loop"
    puts $Out_File "      Sql.Fetch(Stm, Eos); "
    puts $Out_File "      exit when Eos or Count > Max;"
    puts $Out_File "      Data := Get(Stm);"
    puts $Out_File "      $Table_Name\_List_Pack.Insert_At_Tail(List, Data);"
    puts $Out_File "      Count := Count +1;"
    puts $Out_File "    end loop;"
    puts $Out_File "    Sql.Close_Cursor(Stm);"
    puts $Out_File "    if Start_Trans then Sql.Commit(Transaction); end if;"
    puts $Out_File "  end Read_List;\n--------------------------------------------\n"
    ##################################################################################
  }

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  proc Read_All {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ###########################################################################
    puts $Out_File "  procedure Read_All(List  : in out $Table_Name\_List_Pack.List_Type;"
    puts $Out_File "                     Order : in     Boolean := False;"
    puts $Out_File "                     Max   : in     Integer_4 := Integer_4'Last) is"
    puts $Out_File "    use Sql;"
    puts $Out_File "    Start_Trans : constant Boolean := (Sql.Transaction_Status = Sql.None);"
    puts $Out_File "    Transaction  : Sql.Transaction_Type;"
    puts $Out_File "  begin"
    puts $Out_File "    if Start_Trans then Sql.Start_Read_Write_Transaction(Transaction); end if;"
    puts $Out_File "    if Order then"

    set Order_By_List [Primary_Key_List $Columns]

    puts $Out_File "      Sql.Prepare(Stm_Select_All_O, \"select * from $TABLE_NAME order by $Order_By_List\");"
    puts $Out_File "      Read_List(Stm_Select_All_O, List, Max);"
    puts $Out_File "    else"
    puts $Out_File "      Sql.Prepare(Stm_Select_All, \"select * from $TABLE_NAME\");"
    puts $Out_File "      Read_List(Stm_Select_All, List, Max);"
    puts $Out_File "    end if;"
    puts $Out_File "    if Start_Trans then Sql.Commit(Transaction); end if;"
    puts $Out_File "  end Read_All;\n--------------------------------------------\n"
    ##############################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  proc Delete {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ###############################################################################
    puts $Out_File "  procedure Delete(Data : in Table\_$Table_Name.Data_Type) is"
    puts $Out_File "  begin"
    puts $Out_File [Keyed_Sql_Statment Stm_Delete "delete from $TABLE_NAME" Primary $Columns]
    puts $Out_File [Set_Keyed_Sql_Statment Stm_Delete $Columns Primary]
    puts $Out_File "    Sql.Execute(Stm_Delete);"
    puts $Out_File "  end Delete;\n--------------------------------------------\n"
    ###############################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--


  proc Update {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    #################################################################################
    puts $Out_File "  procedure Update(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False) is"
    puts $Out_File "    Now     : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;"
    puts $Out_File "    Process : Process_Io.Process_Type     := Process_Io.This_Process;"
    puts $Out_File "  begin"

    puts $Out_File [Prepare_All_Columns Stm_Update "\"update $TABLE_NAME set \""  $Columns 1 0 0]
    puts $Out_File [Set_All_Columns Stm_Update $Columns 0 1]

    puts $Out_File "    Sql.Execute(Stm_Update);"
    puts $Out_File "  end Update;\n--------------------------------------------\n"
    #################################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  proc Insert {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ###################################################################################
    puts $Out_File "  procedure Insert(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False) is"
    puts $Out_File "    Now     : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;"
    puts $Out_File "    Process : Process_Io.Process_Type     := Process_Io.This_Process;"
    puts $Out_File "  begin"
    set Has_IXX [Repo_Utils::Table_Has_IXX_Fields_2 $Columns]
    set Has_IXX_Ts [Repo_Utils::Table_Has_IXX_Timestamp_2 $Columns]
    puts $Out_File  "    if not Keep_Timestamp then"
    puts $Out_File  "      null; --for tables without IXX*"

    if {$Has_IXX} {
        puts $Out_File  "    Data.Ixxluda := Now;"
        puts $Out_File  "    Data.Ixxluti := Now;"
    }
    if {$Has_IXX_Ts} {
        puts $Out_File  "    Data.Ixxluts := Now;"
    }
    puts $Out_File  "    end if;"
    puts $Out_File [Insert_All_Columns Stm_Insert "\"insert into $TABLE_NAME values \(\"" $Columns]

    puts $Out_File [Set_All_Columns Stm_Insert $Columns 0 1]

    puts $Out_File "    Sql.Execute(Stm_Insert);"
    puts $Out_File "  end Insert;\n--------------------------------------------\n"
    ###################################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  proc Delete_Withcheck {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ###################################################################################
    puts $Out_File "  procedure Delete_Withcheck(Data : in Table\_$Table_Name.Data_Type) is"
    puts $Out_File "  begin"
    puts $Out_File [Keyed_Sql_Statment Stm_Delete_With_Check "delete from $TABLE_NAME" Primary $Columns 1]
    puts $Out_File [Set_Keyed_Sql_Statment Stm_Delete_With_Check $Columns Primary 1]

    puts $Out_File "    Sql.Execute(Stm_Delete_With_Check);"
    puts $Out_File "  end Delete_Withcheck;\n--------------------------------------------\n"
    ###################################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  proc Update_Withcheck {Name Type Node Columns Out_File} {
    set Table_Name [string totitle $Name]
#    set TABLE_NAME [string toupper $Name]
    set TABLE_NAME [Table_Caseing $Name]
    ###################################################################################
    puts $Out_File "  procedure Update_Withcheck(Data : in out Table\_$Table_Name.Data_Type; Keep_Timestamp : in Boolean := False) is"
    puts $Out_File "    Now     : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;"
    puts $Out_File "    Process : Process_Io.Process_Type     := Process_Io.This_Process;"
    puts $Out_File "  begin"
    puts $Out_File ""
    puts $Out_File [Prepare_All_Columns Stm_Update_With_Check "\"update $TABLE_NAME set \""  $Columns 1 1 0]
    puts $Out_File [Set_All_Columns Stm_Update_With_Check $Columns 1 1]
    puts $Out_File "    Sql.Execute(Stm_Update_With_Check);"
    puts $Out_File "  end Update_Withcheck;\n--------------------------------------------\n"
    ###################################################################################
  }
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

# Begin
  if {[string equal $Type $ART_Definitions::Clreqs]} {
    return 0
  }

  set Has_IXX_Fields [Repo_Utils::Table_Has_IXX_Fields_2 $Columns]
  set Has_IXX_Ts_Fields [Repo_Utils::Table_Has_IXX_Timestamp_2 $Columns]
  set All_Are_Primary [All_Fields_Are_Primary_Keys $Columns]

#Functions operating on Primary Key
  puts $Out_File ""
  puts $Out_File "  -- Procedures for DBMS DEF"
  puts $Out_File "  -- Primary key"

  Get         $Name $Type $Node $Columns $Out_File
  Get_On_Key  $Name $Type $Node $Columns $Out_File
  Read_All    $Name $Type $Node $Columns $Out_File
  Read_List   $Name $Type $Node $Columns $Out_File
  Is_Existing $Name $Type $Node $Columns $Out_File
  Read        $Name $Type $Node $Columns $Out_File
  Delete      $Name $Type $Node $Columns $Out_File
  if {! $All_Are_Primary} {
    Update      $Name $Type $Node $Columns $Out_File
  }
  Insert      $Name $Type $Node $Columns $Out_File
  if {$Has_IXX_Fields || $Has_IXX_Ts_Fields} {
    Delete_Withcheck $Name $Type $Node $Columns $Out_File
    if {! $All_Are_Primary} {
      Update_Withcheck $Name $Type $Node $Columns $Out_File
    }
  }

  set Indices [::dom::DOMImplementation selectNode $Node $::Index_Element_Name]
  set Table_Name [string totitle $Name]

  foreach Index $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $Index]
    switch -exact -- $Index_Attributes(type) {
      primary {
        puts $Out_File "  -- Primary key, when several fields"
        puts $Out_File [Primary_Procs $Index_Attributes(Columns) $Table_Name $Columns]
	  }
      candidate {
        puts $Out_File "  -- Candidate key"
        puts $Out_File [Candidate_Procs $Index_Attributes(Columns) $Table_Name $Columns]
      }
      index {
        puts $Out_File "  -- Index "
        puts $Out_File [Index_Procs $Index_Attributes(Columns) $Table_Name $Columns]
      }
      foreign {
        puts $Out_File "  -- Index Foreign key"
        puts $Out_File [Foreign_Procs $Index_Attributes(Columns) $Table_Name $Columns]
      }
      default {
        puts stderr "  Unknown indextype: $Index_Attributes(type)"
        puts stderr "    Valid: primary, candidate, index, foreign"
        exit 1
      }
    }
  }

}

########################################################
proc Print_Ud4_Functions_Body {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"
  set Table_Name [string totitle $Name]
  set TABLE_NAME [string toupper $Name]
  set Columns [::dom::DOMImplementation selectNode $Node $::Column_Element_Name]
  set Num_Cols [llength $Columns]

  puts $Out_File ""
  puts $Out_File "  procedure Get_Values(Request : in     Request_Type;"
  puts $Out_File "                       Data    : in out Table\_$Table_Name.Data_Type) is"
  puts $Out_File "  begin"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set COL_NAME [string toupper $Attributes(Name)]
    set Col_Name [string totitle $Attributes(Name)]
    set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]

#    puts $Out_File "    if Has_Value(Request, \"$COL_NAME\") then"
    switch -exact -- $Col_Type {
      STRING_FORMAT    -
      INTEGER_4_FORMAT -
      FLOAT_8_FORMAT {
         puts $Out_File "    if Has_Value(Request, \"$COL_NAME\") then"
         puts $Out_File "      Get_Value(Request, \"$COL_NAME\", Data.$Col_Name);"
         puts $Out_File "    end if;"
      }
      DATE_FORMAT {
        puts $Out_File "    if Has_Value(Request, \"$COL_NAME\") then"
        puts $Out_File "      Get_Date_Value(Request, \"$COL_NAME\", Data.$Col_Name);"
        puts $Out_File "    end if;"
      }
      TIME_FORMAT {
        puts $Out_File "    if Has_Value(Request, \"$COL_NAME\") then"
        puts $Out_File "      Get_Time_Value(Request, \"$COL_NAME\", Data.$Col_Name);"
        puts $Out_File "    end if;"
      }
      TIMESTAMP_FORMAT {
        puts $Out_File "    if Has_Value(Request, \"$COL_NAME\") then"
        puts $Out_File "      Get_Timestamp_Value(Request, \"$COL_NAME\", Data.$Col_Name);"
        puts $Out_File "    end if;"
      }
      CLOB_FORMAT  -
      NCLOB_FORMAT -
      BLOB_FORMAT {
        puts $Out_File "    null; -- not supported datatype for UD4 $Col_Type"
        puts $Out_File "    -- if Has_Value(Request, \"$COL_NAME\") then"
        puts $Out_File "    --  Get_Value(Request, \"$COL_NAME\", Data.$Col_Name);"
        puts $Out_File "    -- end if;"
      }
      default {
        puts stderr "Print_Ud4_Functions_Body I : Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
        exit 1
      }
    }
#    puts $Out_File "    end if;"

  }
  puts $Out_File "  end Get_Values;\n--------------------------------------------\n"
  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

  puts $Out_File ""
  puts $Out_File "  procedure Set_Values(Reply  : in out Request_Type;"
  puts $Out_File "                       Data   : in     Table\_$Table_Name.Data_Type) is"
  puts $Out_File "  begin"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set COL_NAME [string toupper $Attributes(Name)]
    set Col_Name [string totitle $Attributes(Name)]
    set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]

    switch -exact -- $Col_Type {
      STRING_FORMAT    -
      INTEGER_4_FORMAT -
      FLOAT_8_FORMAT {
        puts $Out_File "    Set_Value(Reply, \"$COL_NAME\", Data.$Col_Name);"
      }
      DATE_FORMAT {
        puts $Out_File "    Set_Date_Value(Reply, \"$COL_NAME\", Data.$Col_Name);"
      }
      TIME_FORMAT {
        puts $Out_File "    Set_Time_Value(Reply, \"$COL_NAME\", Data.$Col_Name);"
      }
      TIMESTAMP_FORMAT {
        puts $Out_File "    Set_Timestamp_Value(Reply, \"$COL_NAME\", Data.$Col_Name);"
      }
      CLOB_FORMAT      -
      NCLOB_FORMAT     -
      BLOB_FORMAT {
        puts $Out_File "      null; -- not supported datatype for UD4 $Col_Type"
      }
      default {
        puts stderr "Print_Ud4_Functions_Body II Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
        exit 1
      }
    }
  }
  puts $Out_File "  end Set_Values;\n--------------------------------------------\n"

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  puts $Out_File ""
  puts $Out_File "  procedure Make_Ud4_Telegram(Request   : in out Uniface_Request.Request_Type;"
  puts $Out_File "                              Operation	: in     Operation_Type := Get_One_Record) is"
  puts $Out_File "    use Uniface_Request;"
  puts $Out_File "    Next_Column : Integer_2;"
  puts $Out_File "    Offset      : Natural := 0;"
  puts $Out_File "  begin"
  puts $Out_File "    Construct_Ud4_Record(Request, \"$TABLE_NAME\", $Num_Cols, Next_Column, Offset, Operation);"

  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set COL_NAME [string toupper $Attributes(Name)]
    set Col_Name [string totitle $Attributes(Name)]
    set COL_TYPE [Repo_Utils::Type_To_String $Attributes(Type)]

    switch -exact -- $COL_TYPE {
      STRING_FORMAT    {
        puts $Out_File "    Add_Column(Request, \"$COL_NAME\", $COL_TYPE, Offset, $Attributes(Size));"
      }
      INTEGER_4_FORMAT -
      FLOAT_8_FORMAT -
      DATE_FORMAT -
      TIME_FORMAT -
      TIMESTAMP_FORMAT {
        puts $Out_File "    Add_Column(Request, \"$COL_NAME\", $COL_TYPE, Offset);"
      }
      CLOB_FORMAT  -
      NCLOB_FORMAT -
      BLOB_FORMAT      {
        puts $Out_File "      null; -- not supported datatype for UD4 $COL_TYPE"
      }
      default {
        puts stderr "Print_Ud4_Functions_Body III Table -> $Name , Col_Name -> $Col_Name Coltype -> $COL_TYPE is unknown..."
        exit 1
      }
    }
  }
  puts $Out_File "    Init_Values(Request,Offset);"
  puts $Out_File "  end Make_Ud4_Telegram;\n--------------------------------------------\n"


  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--
  puts $Out_File ""
  puts $Out_File "  procedure Make_Ud4_Telegram(Request   : in out Uniface_Request.Request_Type;"
  puts $Out_File "                              Data      : in     Table\_$Table_Name.Data_Type;"
  puts $Out_File "                              Operation	: in     Operation_Type := Get_One_Record) is"
  puts $Out_File "  begin"
  puts $Out_File "    Make_Ud4_Telegram(Request, Operation);"
  puts $Out_File "    Set_Values(Request, Data);"
  puts $Out_File "  end Make_Ud4_Telegram;\n--------------------------------------------\n"
  puts $Out_File "\n\n"

  ##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--

}

########################################################
proc Print_XML_Functions_Body {Name Type Node Columns Out_File} {
#  puts $Out_File "[info level 0]"

  set Table_Name [string totitle $Name]
  set TABLE_NAME [string toupper $Name]
  set Columns [::dom::DOMImplementation selectNode $Node $::Column_Element_Name]
  set Num_Cols [llength $Columns]


  puts $Out_File ""
  puts $Out_File "  -- Procedures for all DBMS"
  puts $Out_File ""
#To_String

  puts $Out_File ""
  puts $Out_File "  function Date_To_String(Date : in Sattmate_Calendar.Time_Type) return String is"
  puts $Out_File "    package Integer_2_Io is new Text_Io.Integer_Io(Integer_2);"
  puts $Out_File "    Date_String : String(1..10) := \"yyyy-mm-dd\";"
  puts $Out_File "  begin"
  puts $Out_File "    Integer_2_Io.Put(Date_String(9..10), Date.Day);"
  puts $Out_File "    Integer_2_Io.Put(Date_String(6..7), Date.Month);"
  puts $Out_File "    Integer_2_Io.Put(Date_String(1..4), Date.Year);"
  puts $Out_File "    if Date_String(9) = ' ' then Date_String(9) := '0'; end if;"
  puts $Out_File "    if Date_String(6) = ' ' then Date_String(6) := '0'; end if;"
  puts $Out_File "    return Date_String;"
  puts $Out_File "  end Date_To_String;\n--------------------------------------------\n"
  puts $Out_File ""
  puts $Out_File ""


  puts $Out_File "  function To_String(Data : in Table\_$Table_Name.Data_Type) return String is"
  puts $Out_File "  begin"
  puts $Out_File "    return"

  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
    set Col_Name [string totitle $Attributes(Name)]
    switch -exact -- $Col_Type {
      STRING_FORMAT {
        if {[string equal $Attributes(Size) 1]} {
          puts $Out_File "          \" $Col_Name = \" & Data.$Col_Name &"
        } else {
          puts $Out_File "          \" $Col_Name = \" & General_Routines.Skip_Trailing_Blanks(Data.$Col_Name) &"
        }
      }
      INTEGER_4_FORMAT {
        puts $Out_File "          \" $Col_Name = \" & Integer_4'Image(Data.$Col_Name) &"
      }
      FLOAT_8_FORMAT {
        puts $Out_File "          \" $Col_Name = \" &  General_Routines.F8_To_String(Data.$Col_Name) &"
      }
      DATE_FORMAT {
        puts $Out_File "          \" $Col_Name = \" & Sattmate_Calendar.String_Date(Data.$Col_Name) &"
      }
      TIME_FORMAT {
        puts $Out_File "          \" $Col_Name = \" & Sattmate_Calendar.String_Time(Data.$Col_Name) &"
      }
      TIMESTAMP_FORMAT {
        puts $Out_File "          \" $Col_Name = \" & Sattmate_Calendar.String_Date_And_Time(Data.$Col_Name, Milliseconds => true) &"
      }
      CLOB_FORMAT  {
        puts $Out_File "          \" $Col_Name = \" & Ada.Strings.Unbounded.To_String(Data.$Col_Name) &"
      }
      default {
        puts stderr "Print_XML_Functions_Body I Table -> $Name , Col_Name -> $Col_Name Coltype -> $Col_Type is unknown..."
        exit 1
      }
    }
  }
  puts $Out_File "          \"\";"
  puts $Out_File "  end To_String;\n--------------------------------------------\n"

#Format_String
#
  puts $Out_File "  function Format_String(S : in String) return String is"
  puts $Out_File "    use Standard8; use CGI;"
  puts $Out_File "  begin"
  puts $Out_File "     return General_Routines.Skip_Trailing_Blanks(To_String(Cgi.Cvtput_Xml(To_String8(S))));"
  puts $Out_File "  end Format_String;\n--------------------------------------------\n"


  puts $Out_File "  function To_Xml(Data      : in Table\_$Table_Name.Data_Type;"
  puts $Out_File "                  Ret_Start : in Boolean;"
  puts $Out_File "                  Ret_Data  : in Boolean;"
  puts $Out_File "                  Ret_End   : in Boolean) return String is"
#  puts $Out_File "    --Ls      : constant Character := Ascii.LF;"
  puts $Out_File "    Ls      : constant String := \"\";"
  puts $Out_File "    S_Start : constant String := \"\<$TABLE_NAME\_ROW>\"  & Ls;"
  puts $Out_File "    S_End   : constant String := \"\</$TABLE_NAME\_ROW>\" & Ls;"

  set Column_Counter 0
  foreach col $Columns {
    incr Column_Counter
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Col_Type [Repo_Utils::Type_To_String $Attributes(Type)]
    set COL_NAME [string toupper $Attributes(Name)]
    set Col_Name [string totitle $Attributes(Name)]
    puts $Out_File "    S$Column_Counter : constant String :="

    switch -exact -- $Col_Type {
      STRING_FORMAT {
        if {[string equal $Attributes(Size) 1]} {
          puts $Out_File "          \"\<$COL_NAME\>\" & Data.$Col_Name & \"\</$COL_NAME\>\" & Ls;"
        } else {
          puts $Out_File "          \"\<$COL_NAME\>\" & Format_String(General_Routines.Skip_Trailing_Blanks(Data.$Col_Name)) & \"\</$COL_NAME\>\" & Ls;"
        }
      }
      INTEGER_4_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" &  General_Routines.Trim(Integer_4'Image(Data.$Col_Name)) & \"\</$COL_NAME\>\" & Ls;"
      }
      FLOAT_8_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" &  General_Routines.F8_To_String(Data.$Col_Name) & \"\</$COL_NAME\>\" & Ls;"
      }
      DATE_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" & Sattmate_Calendar.String_Date(Data.$Col_Name) & \"\</$COL_NAME\>\" & Ls;"
      }
      TIME_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" & Sattmate_Calendar.String_Time(Data.$Col_Name) & \"\</$COL_NAME\>\" & Ls;"
      }
      TIMESTAMP_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" & Sattmate_Calendar.String_Date_And_Time(Data.$Col_Name, Milliseconds => true) & \"\</$COL_NAME\>\" & Ls;"
      }
      CLOB_FORMAT {
        puts $Out_File "          \"\<$COL_NAME\>\" & Ada.Strings.Unbounded.To_String(Data.$Col_Name) & \"\</$COL_NAME\>\" & Ls;"
      }
      default {
        puts stderr "Print_XML_Functions_Body II Table -> $Name , Col_Name -> $COL_NAME Coltype -> $Col_Type is unknown..."
        exit 1
      }
    }
  }
  puts $Out_File "    --------------------------------"
  puts $Out_File "    function Get_String(S : in String; Ret : in Boolean) return String is"
  puts $Out_File "      use Standard8;"
  puts $Out_File "    begin"
  puts $Out_File "      if Ret then return S; else return \"\"; end if;"
  puts $Out_File "    end Get_String;"
  puts $Out_File "    --------------------------------"

  puts $Out_File "  begin"
  puts $Out_File "    return Get_String(S_Start, Ret_Start) & "
  puts $Out_File "           Get_String("

  set S {}
  for {set x 1} {$x<=$Column_Counter} {incr x} {
   append S " S$x &"
   if {![expr $x % 10]} {
     # linebreak every 10 items
     append S "\n           "
   } elseif {$x < 10} {
     append S " "
   }
  }
  set S2 [string replace [string trim $S] end end ,]

  puts $Out_File "            $S2"
  puts $Out_File "            Ret_Data) &"
  puts $Out_File "           Get_String(S_End, Ret_End) & Ascii.LF;"
  puts $Out_File "  end To_Xml;\n  --------------------------------------------\n"


#  if {[Is_S08_Table $Name]} {
    puts $Out_File ""
    puts $Out_File "  --------------------------------------------"
    puts $Out_File "  type $Table_Name\_Reader is new Sax.Readers.Reader with record"
    puts $Out_File "    Current_Tag    : Unbounded_String := Null_Unbounded_String;"
    puts $Out_File "    Accumulated    : Unbounded_String := Null_Unbounded_String;"
    puts $Out_File "    OK             : Boolean := True;"
    puts $Out_File "    Found_Set      : Boolean := True;"
    puts $Out_File "    $Table_Name\_List     : Table\_$Table_Name\.$Table_Name\_List_Pack.List_Type;"
    puts $Out_File "    $Table_Name\_Data     : Table\_$Table_Name\.Data_Type := Empty_Data;"
    puts $Out_File "  end record;"
    puts $Out_File ""
    puts $Out_File "  overriding procedure Start_Element(Handler       : in out $Table_Name\_Reader;"
    puts $Out_File "                                     Namespace_URI : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                                     Local_Name    : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                                     Qname         : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                                     Atts          : Sax.Attributes.Attributes\'Class);"
    puts $Out_File ""
    puts $Out_File "  overriding procedure End_Element(Handler         : in out $Table_Name\_Reader;"
    puts $Out_File "                                   Namespace_URI   : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                                   Local_Name      : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                                   Qname           : Unicode.CES.Byte_Sequence := \"\") ;"
    puts $Out_File ""
    puts $Out_File "  overriding procedure Characters(Handler          : in out $Table_Name\_Reader;"
    puts $Out_File "                                  Ch               : Unicode.CES.Byte_Sequence := \"\");"
    puts $Out_File ""

    puts $Out_File "  --------------------------------------------"
    puts $Out_File "  procedure Start_Element(Handler       : in out $Table_Name\_Reader;"
    puts $Out_File "                          Namespace_URI : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                          Local_Name    : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                          Qname         : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                          Atts          : Sax.Attributes.Attributes\'Class) is"
    puts $Out_File "    pragma Warnings(Off,Namespace_URI);"
    puts $Out_File "    pragma Warnings(Off,Qname);"
    puts $Out_File "    pragma Warnings(Off,Atts);"
    puts $Out_File "    The_Tag : constant String := Local_Name;"
    puts $Out_File "  begin"
    puts $Out_File "    Handler.Current_Tag := To_Unbounded_String(The_Tag);"
    puts $Out_File "    Handler.Accumulated := Null_Unbounded_String;"
    puts $Out_File "    if The_Tag = Table\_$Table_Name\_Set_Name then"
    puts $Out_File "      Handler.Found_Set := true;"
    puts $Out_File "    end if;"
    puts $Out_File "  exception"
    puts $Out_File "    when Ada.Strings.Length_Error => Handler.OK := False;"
    puts $Out_File "    when Constraint_Error         => Handler.OK := False;"
    puts $Out_File "  end Start_Element;"
    puts $Out_File "  --------------------------------------------"
    puts $Out_File ""

    puts $Out_File "  --------------------------------------------"
    puts $Out_File "  procedure End_Element(Handler       : in out $Table_Name\_Reader;"
    puts $Out_File "                        Namespace_URI : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                        Local_Name    : Unicode.CES.Byte_Sequence := \"\";"
    puts $Out_File "                        Qname         : Unicode.CES.Byte_Sequence := \"\") is"
    puts $Out_File "    pragma Warnings(Off,Namespace_URI);"
    puts $Out_File "    pragma Warnings(Off,Qname);"
    puts $Out_File "    The_Tag : constant String := Local_Name;"
    puts $Out_File "  begin"
    puts $Out_File "    if The_Tag = Table\_$Table_Name\_Set_Name then"
    puts $Out_File "      Handler.Found_Set := false;"
    puts $Out_File "    elsif The_Tag = Table\_$Table_Name\_Row_Name then"
    puts $Out_File "      if Handler.Found_Set then"
    puts $Out_File "        Table\_$Table_Name\.$Table_Name\_List_Pack.Insert_At_Tail(Handler\.$Table_Name\_List, Handler\.$Table_Name\_Data);"
    puts $Out_File "        Handler\.$Table_Name\_Data := Empty_Data;"
    puts $Out_File "      end if;"
    puts $Out_File "    end if;"
    puts $Out_File "  exception"
    puts $Out_File "    when Ada.Strings.Length_Error => Handler.OK := False;"
    puts $Out_File "  end End_Element;"
    puts $Out_File "  --------------------------------------------"
    puts $Out_File ""

    puts $Out_File "  --------------------------------------------"
    puts $Out_File "  procedure Characters(Handler          : in out $Table_Name\_Reader;"
    puts $Out_File "                       Ch               : Unicode.CES.Byte_Sequence := \"\") is"
    puts $Out_File "    function To_Iso_Latin_15(Str : Unicode.CES.Byte_Sequence) return String is"
    puts $Out_File "      use Unicode.Encodings;"
    puts $Out_File "    begin"
    puts $Out_File "      return  Convert(Str, Get_By_Name(\"utf-8\"),Get_By_Name(\"iso-8859-15\"));"
    puts $Out_File "    end To_Iso_Latin_15;"
    puts $Out_File "    The_Tag   : constant String := To_String(Handler.Current_Tag);"
    puts $Out_File "    The_Value : constant string := To_Iso_Latin_15(Ch);"
    puts $Out_File "    procedure Fix_String (Value    : string;"
    puts $Out_File "                          Variable : in out string) is"
    puts $Out_File "    begin"
    puts $Out_File "      Append(Handler.Accumulated, The_Value);"
    puts $Out_File "      Ada.Strings.Fixed.Move(To_String(Handler.Accumulated), Variable);"
    puts $Out_File "    end Fix_String;"
    puts $Out_File "  begin"
    puts $Out_File "    if Handler.Found_Set then"
    set Condition_Text "if   "
    foreach col $Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      set COL_NAME [string toupper $Attributes(Name)]
      set Col_Name [string totitle $Attributes(Name)]
      set COL_TYPE [Repo_Utils::Type_To_String $Attributes(Type)]

      switch -exact -- $COL_TYPE {
        #STRING_FORMAT    { set Cvtstr "Ada.Strings.Fixed.Move(The_Value, Handler\.$Table_Name\_Data\.$Col_Name)" }
        #STRING_FORMAT    { set Cvtstr "Fix_String(The_Value, Handler\.$Table_Name\_Data\.$Col_Name)" }
        STRING_FORMAT {
          if {[string equal $Attributes(Size) 1]} {
            set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := The_Value(1)"
          } else {
            set Cvtstr "Fix_String(The_Value, Handler\.$Table_Name\_Data\.$Col_Name)"
          }
        }
        INTEGER_4_FORMAT { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Integer_4\'value(The_Value)" }
        FLOAT_8_FORMAT   { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Float_8\'value(The_Value)" }
        DATE_FORMAT      { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Sattmate_Calendar.To_Time_Type(The_Value,\"00:00:00.000\")" }
        TIME_FORMAT      { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Sattmate_Calendar.To_Time_Type(\"01-JAN-1901\", The_Value)" }
        TIMESTAMP_FORMAT { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Sattmate_Calendar.To_Time_Type(The_Value(1..11), The_Value(13..24))" }
        CLOB_FORMAT      { set Cvtstr "Handler\.$Table_Name\_Data\.$Col_Name := Handler\.$Table_Name\_Data\.$Col_Name & Ada.Strings.Unbounded.To_Unbounded_String(The_Value)" }
        default          { set Cvtstr "null;-- No definitions for this field $Col_Name )" }
      }
      puts $Out_File "      $Condition_Text The_Tag = $COL_NAME\_Name then \n        $Cvtstr;"
      set Condition_Text "elsif"
    }
    puts $Out_File "      end if;"
    puts $Out_File "    end if;"
    puts $Out_File "  exception"
    puts $Out_File "    when Ada.Strings.Length_Error => Handler.OK := False;"
    puts $Out_File "  end Characters;"
    puts $Out_File ""

    puts $Out_File "  --------------------------------------------"
    puts $Out_File "  procedure From_Xml(Xml_Filename : in Unbounded_String;"
    puts $Out_File "                     A_List       : in out $Table_Name\_List_Pack.List_Type) is"
    puts $Out_File "    My_Reader   : $Table_Name\_Reader;"
    puts $Out_File "    Input       : File_Input;"
    puts $Out_File "  begin"
    puts $Out_File "    My_Reader\.$Table_Name\_List := A_List;"
    puts $Out_File "    My_Reader.Current_Tag := Null_Unbounded_String;"
    puts $Out_File "    Open(To_String(Xml_Filename), Input);"
    puts $Out_File "    My_Reader.Set_Feature(Validation_Feature,False);"
    puts $Out_File "    My_Reader.Parse(Input);"
    puts $Out_File "    Input.Close;"
    puts $Out_File "    if not My_Reader.OK then"
    puts $Out_File "       Table\_$Table_Name\.$Table_Name\_List_Pack.Remove_All(My_Reader\.$Table_Name\_List);"
    puts $Out_File "    end if;"
    puts $Out_File "    A_List := My_Reader\.$Table_Name\_List;"
    puts $Out_File "  end From_Xml;"
    puts $Out_File ""
#  }
}

########################################################
proc Print_Package_End_Body {Name Type Node Columns Out_File} {
  Print_Package_End_Spec $Name $Type $Node $Columns $Out_File
}

########################################################
proc Create_Ada_Spec {Name Type Node Columns Out_File} {
  #spec
  Print_Header_Spec        $Name $Type $Node $Columns $Out_File
  Print_Withs_Spec         $Name $Type $Node $Columns $Out_File
  Print_Package_Start_Spec $Name $Type $Node $Columns $Out_File
  Print_Def_Functions_Spec $Name $Type $Node $Columns $Out_File
  Print_Ud4_Functions_Spec $Name $Type $Node $Columns $Out_File
  Print_XML_Functions_Spec $Name $Type $Node $Columns $Out_File
  Print_Package_End_Spec   $Name $Type $Node $Columns $Out_File
}
########################################################
proc Create_Ada_Body {Name Type Node Columns Out_File} {
  #body
  Print_Header_Body        $Name $Type $Node $Columns $Out_File
  Print_Withs_Body         $Name $Type $Node $Columns $Out_File
  Print_Package_Start_Body $Name $Type $Node $Columns $Out_File
  Print_Def_Functions_Body $Name $Type $Node $Columns $Out_File
  Print_Ud4_Functions_Body $Name $Type $Node $Columns $Out_File
  Print_XML_Functions_Body $Name $Type $Node $Columns $Out_File
  Print_Package_End_Body   $Name $Type $Node $Columns $Out_File
}

########################################################
proc Is_Constrained_Character_Type {Type} {
  set type  [string tolower $Type]
  switch -exact -- $type {
      char     {return 1}
      varchar  {return 1 ; used by sql-server}
      varchar2 {return 1}
      default  {return 0}
  }
}

proc Create_SQL_Script_Oracle {Out_File Table_Node } {

  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]

  puts $Out_File ""
  puts $Out_File "prompt \'creating table $Table_Attributes(Name)\';"
  puts $Out_File "create table $Table_Attributes(Name) \( "
  set Columns [::dom::DOMImplementation selectNode $Table_Node $::Column_Element_Name]
  set Index_Counter 0
  set Primary_Key_Fields {}
  set Candidate_Key_Fields {}
  set Candidate_Key_Present 0

  set DDL {}
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    #treat Boolean as integer_4
    if {[string equal $Attributes(Type) 7]} {
      set Used_Type 2
    } else {
      set Used_Type $Attributes(Type)
    }

    set Data_Type [Repo_Utils::Type_To_SQL_Type oracle $Used_Type $Attributes(Size)]
    if {[Is_Constrained_Character_Type $Data_Type]} {
      set Range "\($Attributes(Size)\)"
    } else {
      set Range {}
    }

    if {$Attributes(AllowNull)} {
      set Nullable {}
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable [Repo_Utils::Default_Values $Used_Type oracle]
      #}
    } else {
      set Nullable "not null"
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable "[Repo_Utils::Default_Values $Used_Type oracle] $Nullable"
      #}
    }
    set Comment {}
    if {[Is_Primary $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- Primary Key"
    } elseif {[Is_Candidate $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- unique index $Index_Counter"
    } elseif {[Is_Indexed $Attributes(Name) index] || [Is_Indexed $Attributes(Name) foreign]} {
      incr Index_Counter
      append Comment "-- non unique index $Index_Counter"
    }
    append DDL "  [string toupper $Attributes(Name)] [string tolower $Data_Type]$Range $Nullable , $Comment\n"
  }
  # remove last ','
  set Last_Comma [string last "," $DDL ]
  set S2 [string replace [string trimright $DDL] $Last_Comma $Last_Comma ""]
  append S2 "\n\)"
  puts $Out_File $S2
  if {! [string equal "" $Table_Attributes(Tablespace)]} {
    puts $Out_File " tablespace $Table_Attributes(Tablespace)"
  }
  puts $Out_File "/"
  puts $Out_File ""

# primary, index, foreign ,candidate
  set Indices [::dom::DOMImplementation selectNode $Table_Node $::Index_Element_Name]
  set Index_Counter 0
  foreach idx $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $idx]
    incr Index_Counter
    if {[string equal $Index_Attributes(type) index] || [string equal $Index_Attributes(type) foreign] } {
      puts $Out_File "create index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns) "
      puts $Out_File "\)"
      if {! [string equal "" $Table_Attributes(Tablespace)]} {
        puts $Out_File " tablespace $Table_Attributes(Tablespace)"
      }
      puts $Out_File "/"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) primary] } {
      puts $Out_File "alter table $Table_Attributes(Name) add constraint $Table_Attributes(Name)P$Index_Counter primary key \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\)"
      puts $Out_File "/"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) candidate] } {
      puts $Out_File "create unique index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns) "
      puts $Out_File "\)"
      if {! [string equal "" $Table_Attributes(Tablespace)]} {
        puts $Out_File " tablespace $Table_Attributes(Tablespace)"
      }
      puts $Out_File "/"
      puts $Out_File ""
    }
  }
  set Tab_Comment_1 $Table_Attributes(Desc)
  regsub -all \' $Tab_Comment_1 ` Tab_Comment    ; # replace all ' with `
  puts $Out_File "prompt \'comment on table $Table_Attributes(Name) is \'$Tab_Comment\' \';"
  puts $Out_File "comment on table  $Table_Attributes(Name) is '$Tab_Comment'"
  puts $Out_File "/"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Col_Comment_1 $Attributes(Description)
    regsub -all \' $Col_Comment_1 ` Col_Comment    ; # replace all ' with -
    puts $Out_File "prompt \'comment on column $Table_Attributes(Name).$Attributes(Name) is \'$Col_Comment\' \';"
    puts $Out_File "comment on column $Table_Attributes(Name).$Attributes(Name) is '$Col_Comment'"
    puts $Out_File "/"
  }
  puts $Out_File ""

}
########################################################
proc Create_SQL_Script_Sql_Server {Out_File Table_Node } {
  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]

  puts $Out_File ""
  puts $Out_File "create table $Table_Attributes(Name) \( "
  set Columns [::dom::DOMImplementation selectNode $Table_Node $::Column_Element_Name]
  set Index_Counter 0
  set Primary_Key_Fields {}
  set Candidate_Key_Fields {}
  set Candidate_Key_Present 0

  set DDL {}
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    #treat Boolean as integer_4
    if {[string equal $Attributes(Type) 7]} {
      set Used_Type 2
    } else {
      set Used_Type $Attributes(Type)
    }
    set Collate {}
    set Data_Type [Repo_Utils::Type_To_SQL_Type sqlserver $Used_Type]
    if {[Is_Constrained_Character_Type $Data_Type]} {
      set Range "\($Attributes(Size)\)"
      set Collate "COLLATE SQL_Latin1_General_CP1_CS_AS"
    } else {
      set Range {}
    }

    if {$Attributes(AllowNull)} {
      set Nullable {}
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable [Repo_Utils::Default_Values $Used_Type sqlserver]
      #}
    } else {
      set Nullable "not null"
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable "[Repo_Utils::Default_Values $Used_Type sqlserver] $Nullable"
      #}
    }
    set Comment {}
    if {[Is_Primary $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- Primary Key"
    } elseif {[Is_Candidate $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- unique index $Index_Counter"
    } elseif {[Is_Indexed $Attributes(Name) index] || [Is_Indexed $Attributes(Name) foreign]} {
      incr Index_Counter
      append Comment "-- non unique index $Index_Counter"
    }
    append DDL "  [string toupper $Attributes(Name)] [string tolower $Data_Type]$Range $Collate $Nullable , $Comment\n"
  }
  # remove last ','
  set Last_Comma [string last "," $DDL ]
  set S2 [string replace [string trimright $DDL] $Last_Comma $Last_Comma ""]

  puts $Out_File $S2
  puts $Out_File "\)"
  puts $Out_File "go"
  puts $Out_File ""

# primary, index, foreign ,candidate
  set Indices [::dom::DOMImplementation selectNode $Table_Node $::Index_Element_Name]
  set Index_Counter 0
  foreach idx $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $idx]
    incr Index_Counter
    if {[string equal $Index_Attributes(type) index] || [string equal $Index_Attributes(type) foreign] } {
      puts $Out_File "create index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\)"
      puts $Out_File "go"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) primary] } {
      puts $Out_File "alter table $Table_Attributes(Name) add constraint $Table_Attributes(Name)P$Index_Counter primary key \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\)"
      puts $Out_File "go"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) candidate] } {
      puts $Out_File "create unique index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\)"
      puts $Out_File "go"
      puts $Out_File ""
    }
  }
  #Unfortuantly, SqlServer does not support 'comment on'
#  set Tab_Comment_1 $Table_Attributes(Desc)
#  regsub -all \' $Tab_Comment_1 ` Tab_Comment    ; # replace all ' with `
#  puts $Out_File "comment on table  $Table_Attributes(Name) is '$Tab_Comment'"
#  puts $Out_File "go"
#  foreach col $Columns {
#    array set Attributes [Repo_Utils::Get_Attributes $col]
#    set Col_Comment_1 $Attributes(Description)
#    regsub -all \' $Col_Comment_1 ` Col_Comment    ; # replace all ' with -
#    puts $Out_File "comment on column $Table_Attributes(Name).$Attributes(Name) is '$Col_Comment'"
#    puts $Out_File "go"
#  }
#  puts $Out_File ""
}
# end Create_SQL_Script_Sql_Server
########################################################

########################################################
proc Create_SQL_Script_PostgreSQL {Out_File Table_Node } {

  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]

  puts $Out_File ""
  puts $Out_File "begin;"
  puts $Out_File "create table $Table_Attributes(Name) \( "
  set Columns [::dom::DOMImplementation selectNode $Table_Node $::Column_Element_Name]
  set Index_Counter 0
  set Primary_Key_Fields {}
  set Candidate_Key_Fields {}
  set Candidate_Key_Present 0

  set DDL {}
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
#    #treat Boolean as integer_4
#    if {[string equal $Attributes(Type) 7]} {
#      set Used_Type 2
#    } else {
      set Used_Type $Attributes(Type)
#    }

    set Data_Type [Repo_Utils::Type_To_SQL_Type postgresql $Used_Type]
    if {[Is_Constrained_Character_Type $Data_Type]} {
      set Range "\($Attributes(Size)\)"
    } else {
      set Range {}
    }

    if {$Attributes(AllowNull)} {
      set Nullable {}
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable [Repo_Utils::Default_Values $Used_Type postgresql]
      #}
    } else {
      set Nullable "not null"
      #if { [Is_S08_Table $Table_Attributes(Name)] } {
        set Nullable "[Repo_Utils::Default_Values $Used_Type postgresql] $Nullable"
      #}
    }
    set Comment {}
    if {[Is_Primary $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- Primary Key"
    } elseif {[Is_Candidate $Attributes(Name)]} {
      incr Index_Counter
      append Comment "-- unique index $Index_Counter"
    } elseif {[Is_Indexed $Attributes(Name) index] || [Is_Indexed $Attributes(Name) foreign]} {
      incr Index_Counter
      append Comment "-- non unique index $Index_Counter"
    }
    append DDL "  [string toupper $Attributes(Name)] [string tolower $Data_Type]$Range $Nullable , $Comment\n"
  }
  # remove last ','
  set Last_Comma [string last "," $DDL ]
  set S2 [string replace [string trimright $DDL] $Last_Comma $Last_Comma ""]

  puts $Out_File $S2
  puts $Out_File "\) without OIDS ;"
  puts $Out_File ""

# primary, index, foreign ,candidate
  set Indices [::dom::DOMImplementation selectNode $Table_Node $::Index_Element_Name]
  set Index_Counter 0
  foreach idx $Indices {
    array set Index_Attributes [Repo_Utils::Get_Attributes $idx]
    incr Index_Counter
    if {[string equal $Index_Attributes(type) index] || [string equal $Index_Attributes(type) foreign] } {
      puts $Out_File "create index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\) ;"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) primary] } {
      puts $Out_File "alter table $Table_Attributes(Name) add constraint $Table_Attributes(Name)P$Index_Counter primary key \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\) ;"
      puts $Out_File ""
    } elseif { [string equal $Index_Attributes(type) candidate] } {
      puts $Out_File "create unique index $Table_Attributes(Name)I$Index_Counter on $Table_Attributes(Name) \("
      puts $Out_File "  $Index_Attributes(Columns)"
      puts $Out_File "\) ;"
      puts $Out_File ""
    }
  }
  set Tab_Comment_1 $Table_Attributes(Desc)
  regsub -all \' $Tab_Comment_1 ` Tab_Comment    ; # replace all ' with `
  puts $Out_File "comment on table  $Table_Attributes(Name) is '$Tab_Comment' ;"
  foreach col $Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
    set Col_Comment_1 $Attributes(Description)
    regsub -all \' $Col_Comment_1 ` Col_Comment    ; # replace all ' with -
    puts $Out_File "comment on column $Table_Attributes(Name).$Attributes(Name) is '$Col_Comment' ;"
  }
  puts $Out_File ""
  puts $Out_File "commit;"
  puts $Out_File ""

}
# end Create_SQL_Script_PostgreSQL
########################################################


proc Drop_SQL_Script_PostgreSQL {Out_File Table_Node } {
  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]
  puts $Out_File "begin;"
  puts $Out_File "drop table if exists $Table_Attributes(Name);"
  puts $Out_File "commit;"
}

proc Drop_SQL_Script_Oracle {Out_File Table_Node } {
  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]
  puts $Out_File "prompt \'dropping table $Table_Attributes(Name)\';"
  puts $Out_File "drop table $Table_Attributes(Name)"
  puts $Out_File "/"
}

proc Drop_SQL_Script_Sql_Server {Out_File Table_Node } {
  array set Table_Attributes [Repo_Utils::Get_Attributes $Table_Node]
  puts $Out_File "drop table $Table_Attributes(Name)"
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

# makefile of tables
proc Create_Tables_Makefile {} {
  set Table_Prefix $Repo_Utils::Table_File_Name_Prefix
  set Clreq_Prefix $Repo_Utils::Clreq_File_Name_Prefix
  set Repo_Path [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables]
  set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
  set Clreq_List [Repo_Utils::Table_List $ART_Definitions::Clreqs]
  puts "# Autogenerated makefile for tables"
  puts "# via \$(SATTMATE_SCRIPT)/local/make_table_package.tcl -m"
  puts ""
  puts "include  \$(subst \\,/, \$(SATTMATE_MAKEFILE_INC))"
#  puts "THE_PATH  := \$(subst \\,/, \$(SATTMATE_ADA_LIB_ROOT)/global)"
  puts "KTA  := \$(subst \\,/, \$(SATTMATE_SOURCE)/kernel/tables/$::env(APPLICATION_TYPE))"
  puts "REPO_PATH := $Repo_Path"
  puts "SCRIPT    := \$(subst \\,/, \$(SATTMATE_SCRIPT)/local/make_table_package.tcl)"
  puts "ENGINE    := tclsh \$\(SCRIPT\)"
  puts ""
  puts ".PHONY : all"
  set All "all : \\\n" ;# \$(THE_PATH)/$Prefix\_*.o	"
  foreach TABLE $Table_List {
    set table [string tolower $TABLE]
    append All "     $Table_Prefix\_$table.adb \\\n"
#    append All "     \$(THE_PATH)/$Table_Prefix\_$table.o \\\n"
  }
  foreach CLREQ $Clreq_List {
    set clreq [string tolower $CLREQ]
    append All "     $Table_Prefix\_$clreq.adb \\\n"
#    append All "     \$(THE_PATH)/$Table_Prefix\_$clreq.o \\\n"
  }
  puts $All
  puts ""
  foreach TABLE $Table_List {
    set table [string tolower $TABLE]
    puts ""
    puts "########## start $table ###################"
#    puts "\$(THE_PATH)/$Table_Prefix\_$table.o : $Table_Prefix\_$table.adb"
#    puts "\t \$(ADA) c $Table_Prefix\_$table.adb"
    puts ""
    puts "$Table_Prefix\_$table.adb : \$(REPO_PATH)/$Table_Prefix\_$table.xml \$\(SCRIPT\)"
	catch {}

    if {[catch {set Database_Type [string tolower $::env(SATTMATE_DATABASE_TYPE)]} Result]} {
      set Database_Type oracle ; #default ora
    }
#    puts "Database_Type - $Database_Type - $::env(SATTMATE_DATABASE_TYPE)"
	set Option {}
	set rp {}
	if {[catch {set rp $::env(SATTMATE_MAKE_RECIPE_PREFIX)}] } {
	  set rp \t
	}
	switch -exact $Database_Type {
	  oci        {set Option "-o"}
	  oracle     {set Option "-o"}
	  sqlserver  {set Option "-s"}
	  postgresql {set Option "-p"}
	  default {puts stderr "Not a valid db: '$Database_Type' " ; exit 1}
	}
    puts "$rp \$(ENGINE) $Option $table > $table.sql"
    puts "$rp \$(ENGINE) -t $table > $Table_Prefix\_$table.ada"
#    puts "$rp \$(ADA) f $Table_Prefix\_$table.ada >  $Table_Prefix\_$table.pp"
    puts "$rp gnatchop -gnat05 -w $Table_Prefix\_$table.ada"
#    puts "$rp gnatchop -gnat05 -w $Table_Prefix\_$table.pp"
    puts "$rp rm -f $Table_Prefix\_$table.ada"
#    puts "$rp rm -f $Table_Prefix\_$table.pp"
    puts "########## stop $table ###################"
    puts ""
  }
  foreach CLREQ $Clreq_List {
    set clreq [string tolower $CLREQ]
    puts ""
    puts "########## start $clreq ###################"
    puts "\$(THE_PATH)/$Table_Prefix\_$clreq.o : $Table_Prefix\_$clreq.adb \$\(SCRIPT\)"
    puts "$rp \$(ADA) c $Table_Prefix\_$clreq.adb"
    puts ""
    puts "$Table_Prefix\_$clreq.adb : \$(REPO_PATH)/$Clreq_Prefix\_$clreq.xml"
    puts "$rp \$(ENGINE) -c $clreq > $Table_Prefix\_$clreq.ada"
#    puts "$rp \$(ADA) f $Table_Prefix\_$clreq.ada >  $Table_Prefix\_$clreq.pp"
    puts "$rp gnatchop -gnat05 -w $Table_Prefix\_$clreq.ada"
#    puts "$rp gnatchop -gnat05 -w $Table_Prefix\_$clreq.pp"
    puts "$rp rm -f $Table_Prefix\_$clreq.ada"
#    puts "$rp rm -f $Table_Prefix\_$clreq.pp"
    puts "########## stop $clreq ###################"
    puts ""
  }
  puts "# delete all tables"
  puts ".PHONY : clean"
  puts "clean :"

  set tp [file join $::env(SATTMATE_KERNEL) tables $::env(APPLICATION_TYPE)]
  foreach f [glob -nocomplain -directory $tp -- $Table_Prefix\_*.ads] {
    puts "$rp rm -f $f"
  }
  foreach f [glob -nocomplain -directory $tp -- $Table_Prefix\_*.adb] {
    puts "$rp rm -f $f"
  }
  exit 0
}
########################################################
proc Sanity_Check_Table {Table_Name Table_Type Table_Node Table_Columns } {
  array unset ::Tmp_Index_Array
  set Indices [::dom::DOMImplementation selectNode $Table_Node $::Index_Element_Name]
  set Has_Index_Element 0
  set Has_Primary_Key 0
  set PK_List {}
#  puts "Table_name - $Table_Name"
  foreach Index $Indices {
    set Has_Index_Element 1
    array set Index_Attributes [Repo_Utils::Get_Attributes $Index]
    set Field_List [split $Index_Attributes(Columns) ","]
    foreach Field $Field_List {
      if {[string equal $Index_Attributes(type) primary]} {
        set Has_Primary_Key 1
		lappend PK_List $Field
#		puts "added  $Field to PK_List"
      }
      set ::Tmp_Index_Array($Index_Attributes(type),$Field) 1
    }
  }
#   puts "PK_List - $PK_List"

  if {! $Has_Index_Element} {
    puts stderr "$Table_Name has no index element."
    puts stderr "It means it has not primary key defined"
    puts stderr "Cannot continue without it, exiting..."
    exit 1
  }
  if {! $Has_Primary_Key} {
    puts stderr "$Table_Name has no primary key defined."
    puts stderr "Cannot continue without it, exiting..."
    exit 1
  }

  # search each pk marked field for presence in idx/pk tag
  foreach col $Table_Columns {
    array set Attributes [Repo_Utils::Get_Attributes $col]
#	puts $Attributes(Name)
    if { $Attributes(Primary)} {
	  set R [lsearch -exact $PK_List $Attributes(Name)]
	  if {$R < 0} {
	    puts stderr "Fix xmlfile, table '$Table_Name'! Field '$Attributes(Name)' is marked as PK, but not present in the PK index tag!"
	  }
	}
  }

  # search each field in idx/pk tag for pk marking on field level. S2 NEEDS it

  foreach f $PK_List {
    foreach col $Table_Columns {
      array set Attributes [Repo_Utils::Get_Attributes $col]
      if {[string equal $f $Attributes(Name)]} {
	    if {! $Attributes(Primary)} {
	      puts stderr "Fix xmlfile, table '$Table_Name'! Field '$Attributes(Name)' is NOT marked as PK, but present in the PK index tag!"
	    }
      }
    }
  }



}

########################################################
proc Usage {} {
    puts stderr ""
    puts stderr "This tool generates :"
    puts stderr "  Table_XYZ.ad\[bs\]"
    puts stderr "  XYZ.sql"
    puts stderr "  on standard output."
    puts stderr "  The file is NOT split into a body and spec file, use gnatchop for that"
    puts stderr ""
    puts stderr "  The Table_XYZ.ad\[bs\] are divided into database tables"
    puts stderr "  and clreqs. The clreq ones do NOT have any sql statements."
    puts stderr ""
    puts stderr "  The XYZ.sql are divided into Oracle, PostgreSQL and SqlServer."
    puts stderr "  Sql server and PostgreSQL are NOT supported by Sattmate at the moment"
    puts stderr ""
    puts stderr "Input is xml files at"
    puts stderr "  [ART_Definitions::Find_Target_Path $ART_Definitions::Db_Tables]"
    puts stderr ""
    puts stderr "  -a 1|2|3|4|5"
    puts stderr "    ALL tables of one kind where"
    puts stderr "    1 -> Oracle sql files"
    puts stderr "    2 -> SqlServer sql files"
    puts stderr "    3 -> Table_XYZ.\[bs\] for clreqs.          Use gnatchop on result "
    puts stderr "    4 -> Table_XYZ.\[bs\] for database tables. Use gnatchop on result "
    puts stderr "    5 -> PostgreSQL sql files"
    puts stderr "    6 -> DROP ALL tables, Oracle"
    puts stderr "    7 -> DROP ALL tables, SqlServer"
    puts stderr "    8 -> DROP ALL tables, PostgreSQL"
    puts stderr ""
    puts stderr "  With ALL tables/clreqs, we mean the ones listed by -f and/or -g"
    puts stderr ""
    puts stderr "  -c clreqname -> ONE Table_XYZ.\[bs\] for given clreq."
    puts stderr "  -f List all defined database tables"
    puts stderr "  -g List all defined clreq    tables"
    puts stderr "  -F List all defined database tables, full filename"
    puts stderr "  -G List all defined clreq    tables, full filename"
    puts stderr "  -h This info"
    puts stderr "  -o tablename -> ONE XYZ.sql for given database table, Oracle."
    puts stderr "  -p tablename -> ONE XYZ.sql for given database table, PostgreSQL."
    puts stderr "  -s tablename -> ONE XYZ.sql for given database table, SqlServer."
    puts stderr "  -t tablename -> ONE Table_XYZ.\[bs\] for given database table."
    puts stderr ""
    puts stderr "  -C 1|2|3 For sqls in table_packages:"
    puts stderr "            1-> TABLE,FIELD, 2 -> TABLE,field, 3-> table,field"
    puts stderr "            only useful together with -t switch"
    puts stderr ""
    puts stderr "  -T Do some sanity checks on all table xmls"
    puts stderr ""
    puts stderr "  -v For each v, increase verbosity, 0 - silent, 1 - info, 2 - debug"
    puts stderr ""
    exit 1
}
########################################################

set Column_Element_Name Column
set Index_Element_Name Index

set Table_Name {}
set Table_Type -1
set Out_File stdout
set Path {}
set Prefix {}
set Action {}
set Caseing_SQL 1 ;# 1= TABLE, FIELD 2= TABLE, field 3=table, field

while {[ set err [ getopt $argv "a:c:C:fFgGhmo:p:s:t:Tv" opt arg ]] } {
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
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 2]} {
            set Action createDbSqlServer
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 3]} {
            set Action createAdaClreqs
            set Table_Type $ART_Definitions::Clreqs
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Clreqs]
            set Prefix $Repo_Utils::Clreq_File_Name_Prefix

          } elseif {[string equal $Choise 4]} {
            set Action createAdaTables
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 5]} {
            set Action createDbPostgreSQL
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 6]} {
            set Action dropDbOracle
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 7]} {
            set Action dropDbSqlServer
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix

          } elseif {[string equal $Choise 8]} {
            set Action dropDbPostgreSQL
            set Table_Type $ART_Definitions::Db_Tables
            set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
            set Prefix $Repo_Utils::Table_File_Name_Prefix
        }
      }
      c { set Table_Type $ART_Definitions::Clreqs
          set Table_List [lindex $arg 0]
          set Action createAdaClreqs
          set Prefix $Repo_Utils::Clreq_File_Name_Prefix
      }
      C { set Caseing_SQL  [lindex $arg 0]
      }
      f {
          #puts stderr "List of tables"
          puts [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
          exit 0
      }
      F {
          #puts stderr "List of tables"
          puts [Repo_Utils::Table_List $ART_Definitions::Db_Tables 1]
          exit 0
      }
      g {
          #puts stderr "List of clreqs"
          puts [Repo_Utils::Table_List $ART_Definitions::Clreqs]
          exit 0
      }
      G {
          #puts stderr "List of clreqs"
          puts [Repo_Utils::Table_List $ART_Definitions::Clreqs 1]
          exit 0
      }
      h {Usage}
      m {Create_Tables_Makefile}

      p { set Table_Type $ART_Definitions::Db_Tables;
          set Table_List [lindex $arg 0]
          set Prefix $Repo_Utils::Table_File_Name_Prefix
          set Action createDbPostgreSQL
      }

      o { set Table_Type $ART_Definitions::Db_Tables
          set Table_List [lindex $arg 0]
          set Prefix $Repo_Utils::Table_File_Name_Prefix
          set Action createDbOracle
      }

      s { set Table_Type $ART_Definitions::Db_Tables
          set Table_List [lindex $arg 0]
          set Prefix $Repo_Utils::Table_File_Name_Prefix
          set Action createDbSqlServer
      }

      t { set Table_Type $ART_Definitions::Db_Tables
          set Table_List [lindex $arg 0]
          set Prefix $Repo_Utils::Table_File_Name_Prefix
          set Action createAdaTables
      }
	  T {
         set Table_Type $ART_Definitions::Db_Tables
         set Prefix $Repo_Utils::Table_File_Name_Prefix
         set Table_List [Repo_Utils::Table_List $ART_Definitions::Db_Tables]
         set Action sanityCheckTable
	  }

      v {incr Repo_Utils::Verbosity}
      default { puts "in default"; Usage}
    }
  }
}

if {[string equal {} $Action]} {
  puts "Action is blank"; Usage
}


set Path [ART_Definitions::Find_Target_Path $Table_Type]
foreach Table_Name $Table_List {
  set Table_Node [Open_Table_Node $Prefix $Table_Name $Path]
  set Table_Columns [::dom::DOMImplementation selectNode $Table_Node $::Column_Element_Name]

  Setup_Global_Index_Info $Table_Name $Table_Type $Table_Node $Table_Columns
  All_Primary_Keys_Fields_Are_Not_Nullable $Table_Name $Table_Columns
#  Print_Global_Index_Info

  switch -exact -- $Action {
      createDbOracle  {
            Create_SQL_Script_Oracle $Out_File $Table_Node
      }
      createDbSqlServer  {
            Create_SQL_Script_Sql_Server $Out_File $Table_Node
      }
      createDbPostgreSQL  {
            Create_SQL_Script_PostgreSQL $Out_File $Table_Node
      }
      createAdaTables        -
      createAdaClreqs  {
            Create_Ada_Spec $Table_Name $Table_Type $Table_Node $Table_Columns $Out_File
            Create_Ada_Body $Table_Name $Table_Type $Table_Node $Table_Columns $Out_File
      }
      dropDbOracle {
            Drop_SQL_Script_Oracle $Out_File $Table_Node
      }
      dropDbSqlServer {
            Drop_SQL_Script_Sql_Server $Out_File $Table_Node
      }
      dropDbPostgreSQL {
            Drop_SQL_Script_PostgreSQL $Out_File $Table_Node
      }
	  sanityCheckTable {
	        Sanity_Check_Table $Table_Name $Table_Type $Table_Node $Table_Columns
	  }
    default {
        puts stderr "Action '$Action' not in known actions"
    	Usage
    }
  }
}






