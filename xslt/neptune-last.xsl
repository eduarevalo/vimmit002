<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:in="http://www.lexisnexis.com/namespace/sslrp/in"
    xmlns:se="http://www.lexisnexis.com/namespace/sslrp/se"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
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
    
    <xsl:template match="core:entry-title/text()[not(preceding-sibling::*)][normalize-space(.)='']"/>
    
    <xsl:template match="text()[parent::core:desig]">
        <xsl:value-of select="replace(.,' ','')"/>
    </xsl:template>
    
    <xsl:template match="core:emph[@typestyle='upper']">
        <xsl:value-of select="upper-case(.)"/>
    </xsl:template>
    
    <xsl:template match="comment()">
        <xsl:choose>
            <xsl:when test=".='VimmitArtIndent'">
                <xsl:text disable-output-escaping="yes"><![CDATA[&#x2003;&#x2003;]]></xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()[parent::in:alpha-letter]">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
</xsl:transform>