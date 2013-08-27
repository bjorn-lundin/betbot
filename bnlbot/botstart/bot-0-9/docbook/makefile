###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

POWERDAYSLIST := 114 214 314 121 221 321 128 228 328 135 235 335
SOURCES := report.xml preface.xml plots.xml
DOCBOOK_VERSION := 5.1


all : \
      horses_plc_fav4_za.png \
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

report.html : $(SOURCES)
#	xmlto  --skip-validation xhtml-nochunks report.xml
	xsltproc -xinclude -o report.html /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/xhtml-1_1/docbook.xsl report.xml 
report.fo : $(SOURCES)
#	xmlto dblatex report.xml
	xsltproc -xinclude -o report.fo /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/fo/docbook.xsl report.xml
report.pdf : report.fo
	fop report.fo -pdf report.pdf
	    
.PHONY : clean
clean :
	rm -rf *.html *.pdf *.fo
