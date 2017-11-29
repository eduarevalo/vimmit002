<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    
    <xsl:variable name="mediaobject" select="part/info/cover/mediaobject[1] "/>
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=ptoc01'"/>
            <fm:pub-toc>
                <fm:toc>
                    <xsl:apply-templates select="part/toc"/>
                </fm:toc>
            </fm:pub-toc>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="l-running-hd">
            <core:emph typestyle="smcaps"><xsl:value-of select="$leftHeader"/></core:emph>
        </core:title-alt>
        <core:title-alt use4="r-running-hd">
            <core:emph typestyle="smcaps"><xsl:value-of select="$rightHeader"/></core:emph>
        </core:title-alt>
    </xsl:template>
    
    <xsl:template match="tocentry">
        <xsl:variable name="level">
            <xsl:choose>
                <xsl:when test="emphasis[contains(@role,'fascicule')]">ch</xsl:when>
                <xsl:when test="contains(@role, '-I-')">ch-pt</xsl:when>
                <xsl:when test="contains(@role, '-A-')">ch-ptsub1</xsl:when>
                <xsl:when test="contains(@role, '-1-')">ch-ptsub2</xsl:when>
                <xsl:when test="contains(@role, '-a-')">ch-ptsub3</xsl:when>
                <xsl:when test="contains(@role, '-i-')">ch-ptsub4</xsl:when>
                <xsl:otherwise>unclassified</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fm:toc-entry lev="{$level}">
            <core:entry-title>
                <xsl:apply-templates select="emphasis"/>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:apply-templates select="emphasis/following-sibling::text()"/>
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="tocdiv">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates />
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
</xsl:transform>