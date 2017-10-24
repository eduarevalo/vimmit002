<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    
    <xsl:variable name="mediaobject" select="db:part/db:info/db:cover/db:mediaobject[1] "/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="1">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=ptoc01'"/>
            <fm:pub-toc>
                <fm:toc>
                    <xsl:apply-templates select="db:part/db:toc"/>
                </fm:toc>
            </fm:pub-toc>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template match="db:title[parent::db:partintro or parent::db:toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="l-running-hd">TODO</core:title-alt>
        <core:title-alt use4="r-running-hd">TODO</core:title-alt>
    </xsl:template>
    
    <xsl:template match="db:tocentry">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates select="db:emphasis"/>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:apply-templates select="db:emphasis/following-sibling::text()"/>
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="db:tocdiv">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates />
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
</xsl:transform>