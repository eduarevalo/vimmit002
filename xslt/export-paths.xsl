<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    
    <xsl:output method="text" />
    
    <xsl:template match="node()">
        <xsl:for-each select="ancestor-or-self::*">
            <xsl:value-of select="concat('/',name(.))"/>
            <xsl:apply-templates select="@*"/>
        </xsl:for-each>
        <xsl:text>&#xA;</xsl:text>
        <xsl:apply-templates/>
        <!--<xsl:apply-templates select="*|@*"/>-->
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
        <xsl:text>]</xsl:text>
    </xsl:template>
    
</xsl:transform>