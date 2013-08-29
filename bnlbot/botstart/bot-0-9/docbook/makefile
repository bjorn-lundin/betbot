###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

POWERDAYSLIST := 114 214 314 121 221 321 128 228 328 135 235 335
SOURCES := report.xml preface.xml plots.xml database_description.xml \
           horses_plc_fav4_za.chapter \
           horses_plc_fav5_za.chapter \
           horses_plc_fav6_za.chapter \
           horses_plc_lay4_ie.chapter \
           horses_plc_lay5_ie.chapter \
           horses_plc_lay6_ie.chapter \
           horses_win_lay1_ie.chapter \
           horses_win_lay3_gb.chapter \
           horses_win_lay3_ie.chapter \
           horses_win_lay3_za.chapter \
           horses_win_lay4_gb.chapter \
           horses_win_lay4_ie.chapter \
           horses_win_lay4_sg.chapter \
           horses_win_lay5_gb.chapter \
           horses_win_lay5_ie.chapter \
           horses_win_lay5_sg.chapter \
           horses_win_lay6_gb.chapter \
           horses_win_lay6_ie.chapter \
           horses_win_lay6_sg.chapter \
           horses_win_lay5_ie_go.chapter \
           horses_win_lay5_gb_go.chapter \
           horses_win_lay9_ie.chapter \
           horses_win_lay9_ie_go.chapter \
           horses_win_lay9_za.chapter \
           horses_win_lay9_za_go.chapter \
           horses_win_lay8_fr.chapter \
           horses_win_lay8_fr_go.chapter \
           horses_win_lay4_gb_go.chapter \
           horses_win_lay3_sg.chapter \
           
  

all : report.html chunk.html report.pdf

.PRECIOUS : %.chapter

#how to make a chapter file ...
%.chapter : 
	tclsh ../script/tcl/create_xml_chapter.tcl $* > $*.chapter

tables.xml : ../script/tcl/extract_tables_from_db.tcl
	../script/tcl/extract_tables_from_db.tcl > tables.xml
    
database_description.xml: tables.xml ../script/xsl/to_docbook_table.xsl
	xsltproc ../script/xsl/to_docbook_table.xsl tables.xml > database_description.xml      
      
report.html :  $(SOURCES)
	xsltproc -xinclude \
    --stringparam chunker.output.encoding ISO-8859-1 \
    /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/xhtml-1_1/onechunk.xsl report.xml 
	mv -f index.html report.html

report.fo : $(SOURCES)
	xsltproc -xinclude \
    --output report.fo \
    --stringparam paper.type A4 \
    --stringparam page.orientation landscape \
    /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/fo/docbook.xsl \
     report.xml

report.pdf : report.fo 
	fop report.fo -pdf report.pdf

chunk.html : $(SOURCES)
	xsltproc -xinclude \
    --output chunk.html \
    --stringparam chunker.output.encoding ISO-8859-1 \
    --param use.id.as.filename 1 \
    /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/xhtml-1_1/chunk.xsl report.xml 

    
.PHONY : clean
clean :
	rm -rf *.html *.pdf *.fo tables.xml database_description.xml *.chapter
