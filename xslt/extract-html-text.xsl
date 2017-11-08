<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*" />
    <xsl:preserve-space elements="html:p html:span"/>
    
    
    <xsl:template match="html:p[starts-with(@class,'Markup')]"/>
    <xsl:template match="html:head"/>
    
</xsl:stylesheet>