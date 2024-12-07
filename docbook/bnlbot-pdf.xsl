<?xml version='1.0'?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:fo="http://www.w3.org/1999/XSL/Format">
    
<xsl:import href="/usr/share/xml/docbook/stylesheet/docbook-xsl-ns/fo/docbook.xsl"/>
<xsl:param name="admon.graphics" select="1"/>

<xsl:template match="processing-instruction('hard-pagebreak')">
   <fo:block break-after='page'/>
</xsl:template>
 

</xsl:stylesheet>