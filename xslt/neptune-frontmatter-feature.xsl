<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:include href="neptune-frontmatter.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="nextPageRef"></xsl:param>
    
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=fmvol001bio'"/>
            <xsl:copy-of select="(//processing-instruction('textpage'))[1]"/>
            <fm:body>
                <fm:no-title-pg/>
                <xsl:call-template name="feature"/>
            </fm:body>
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="feature">
        <fm:feature>
            <xsl:apply-templates select="part/partintro"/>
        </fm:feature>
    </xsl:template>
    
    <xsl:template match="sect1/title">
        <core:generic-hd typestyle="bf">
            <xsl:apply-templates/>
        </core:generic-hd>
    </xsl:template>
    
    <xsl:template name="signed">
        <xsl:param name="set"/>
        <xsl:variable name="names" select="$set[(position() mod 5) = 1]"/>
        <fm:signed>
            <fm:signed-line>
                <xsl:for-each select="$names">
                    <fm:right>
                        <xsl:apply-templates/>
                        <xsl:for-each select="following-sibling::*[position() &lt; 5]">
                            <xsl:apply-templates/>
                            <xsl:if test="position() != last()">
                                <core:nl/>
                            </xsl:if>
                        </xsl:for-each>
                    </fm:right>
                </xsl:for-each>
            </fm:signed-line>
        </fm:signed>
    </xsl:template>
    
    <xsl:template match="para[contains(@role, 'Align-center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
    <xsl:template match="para[starts-with(normalize-space(.), 'ISBN')]">
        <fm:isbn>
            <xsl:value-of select="normalize-space()"/>
        </fm:isbn>
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
        <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
    </xsl:template>
    
    <xsl:template match="tocentry">
        <fm:toc-entry lev="unclassified">
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
    
    <xsl:template match="(//processing-instruction('textpage'))[1]"/>
    
</xsl:transform>