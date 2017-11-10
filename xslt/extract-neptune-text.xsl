<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output omit-xml-declaration="yes" indent="no"/>
    
    <xsl:template match="fn:endnote">
        <xsl:value-of select="concat(@er,'. ')"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fn:endnote-id">
        <xsl:value-of select="@*"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fn:footnote">
        <xsl:value-of select="@fr"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fn:footnote-id">
        <xsl:value-of select="@*"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="core:title-alt"/>
    
</xsl:stylesheet>