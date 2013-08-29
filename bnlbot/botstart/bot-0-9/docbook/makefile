###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

POWERDAYSLIST := 114 214 314 121 221 321 128 228 328 135 235 335
SOURCES := report.xml preface.xml plots.xml database_description.xml \
           horses_plc_fav4_za.xml \
           horses_plc_fav5_za.xml \
           horses_plc_fav6_za.xml \
           horses_plc_lay4_ie.xml \
           horses_plc_lay5_ie.xml \
           horses_plc_lay6_ie.xml \
           horses_win_lay1_ie.xml \
           horses_win_lay3_gb.xml \
           horses_win_lay3_ie.xml \
           horses_win_lay3_za.xml \
           horses_win_lay4_gb.xml \
           horses_win_lay4_ie.xml \
           horses_win_lay4_sg.xml \
           horses_win_lay5_gb.xml \
           horses_win_lay5_ie.xml \
           horses_win_lay5_sg.xml \
           horses_win_lay6_gb.xml \
           horses_win_lay6_ie.xml \
           horses_win_lay6_sg.xml \
           horses_win_lay5_ie_go.xml \
           horses_win_lay5_gb_go.xml \
           horses_win_lay9_ie.xml \
           horses_win_lay9_ie_go.xml \
           horses_win_lay9_za.xml \
           horses_win_lay9_za_go.xml \
           horses_win_lay8_fr.xml \
           horses_win_lay8_fr_go.xml \
           horses_win_lay4_gb_go.xml \
           
           
           
           
PNGS :=    horses_plc_fav4_za.png \
           horses_plc_fav5_za.png \
           horses_plc_fav6_za.png \
           horses_plc_lay4_ie.png \
           horses_plc_lay5_ie.png \
           horses_plc_lay6_ie.png \
           horses_win_lay1_ie.png \
           horses_win_lay3_gb.png \
           horses_win_lay3_ie.png \
           horses_win_lay3_za.png \
           horses_win_lay4_gb.png \
           horses_win_lay4_ie.png \
           horses_win_lay4_sg.png \
           horses_win_lay5_gb.png \
           horses_win_lay5_ie.png \
           horses_win_lay5_sg.png \
           horses_win_lay6_gb.png \
           horses_win_lay6_ie.png \
           horses_win_lay6_sg.png \

all : report.html chunk.html report.pdf

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
	rm -rf *.html *.pdf *.fo tables.xml database_description.xml
