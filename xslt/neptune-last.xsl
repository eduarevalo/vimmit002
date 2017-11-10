<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:se="http://www.lexisnexis.com/namespace/sslrp/se"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <!--<xsl:output indent="yes"></xsl:output>-->
    
    <xsl:variable name="firstFootnote" select="(//fn:footnote-id[@fr='*'])[1]"/>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="core:emph[child::* intersect $firstFootnote]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node() except fn:footnote-id[@fr='*']"/>
        </xsl:copy>
        <xsl:copy-of select="//fn:footnote[@fr='*'][following-sibling::core:comment-prelim][preceding-sibling::core:byline]"/>
    </xsl:template>
    
    <xsl:template match="fn:footnote[@fr='*'][following-sibling::core:comment-prelim][preceding-sibling::core:byline]"/>
    
    <xsl:template match="text()[parent::core:entry-title]">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    <xsl:template match="text()[parent::core:desig]">
        <xsl:value-of select="replace(.,' ','')"/>
    </xsl:template>
    
    <xsl:template match="core:emph[@typestyle='upper']">
        <xsl:value-of select="upper-case(.)"/>
    </xsl:template>
    
</xsl:transform>