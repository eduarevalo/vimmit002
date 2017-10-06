<?xml version="1.0"?>
<xsl:transform 
    xmlns="http://docbook.org/ns/docbook"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">
    
    <xsl:output method="text" />
    
    <xsl:template match="*|text()">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="db:emphasis">
           <xsl:text>&#xA;</xsl:text>
           <xsl:apply-templates select="*|@*"/>
    </xsl:template>
    
    <!--<xsl:template match="@*">
        <xsl:for-each select="ancestor::*">
            <xsl:value-of select="concat('/',name(.))"/>
        </xsl:for-each>
        <xsl:text>/@</xsl:text>
        <xsl:value-of select="name(.)"/>
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>-->
    
    <xsl:template match="@*">
        <xsl:text>[@</xsl:text>
        <xsl:value-of select="name(.)"/>
        <xsl:text>=</xsl:text>
        <xsl:value-of select="."/>   
        <xsl:text>]</xsl:text>
    </xsl:template>
    
</xsl:transform>