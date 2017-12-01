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
    <xsl:template match="html:p[matches(normalize-space(.),'^JDCC-[0-9]*\.[0-9]*$')]"/>
    <xsl:template match="html:head"/>
    
    <xsl:template match="html:p[@class='Ent-te']"/>
    <xsl:template match="text()[contains(., 'Page suivante')]"/>
    
    <xsl:template match="html:div[matches(normalize-space(.),'^\([0-9]+\).*[0-9]$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^\([0-9]{4}\)$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^[0-9]{4}$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^[a-zA-Zûé]+\s+[0-9]{4}$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^[IVX\.]+[\sa-zA-Zé]+$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^[0-9]{4}[IVX\.]+[\sa-zA-Zé]+Suite:\s…$')]"/>
    <xsl:template match="html:div[matches(replace(normalize-space(.),' ',''),'^[0-9]+/$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^Page suivante.*Paragraphe suivant.*[0-9]+$')]"/>
    <xsl:template match="html:div[matches(normalize-space(.),'^Paragraphe suivant.*[0-9]+$')]"/>
    
</xsl:stylesheet>