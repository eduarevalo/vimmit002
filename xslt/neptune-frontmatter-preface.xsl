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
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="1">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=fmvol001preface'"/>
            <fm:body>
                <xsl:call-template name="preface"/>
            </fm:body>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="preface">
        <fm:preface>
            <xsl:variable name="firstSignature" select="part/partintro/para[string-length(normalize-space(.)) &lt; 50]"/>
            <xsl:apply-templates select="part/partintro/title"/>
            <xsl:apply-templates select="part/partintro/title/following-sibling::* except $firstSignature except $firstSignature/following-sibling::*"/>
            <xsl:call-template name="signed">
                <xsl:with-param name="set" select="part/partintro/title/following-sibling::* intersect ($firstSignature | $firstSignature/following-sibling::*)"/>
            </xsl:call-template>
        </fm:preface>
    </xsl:template>
    
    <xsl:template name="signed">
        <xsl:param name="set"/>
        <xsl:variable name="names" select="$set[(position() mod 5) = 1]"/>
        <fm:signed>
            <fm:signed-line>
                <xsl:for-each select="$names">
                    <fm:right>
                        <xsl:apply-templates/>
                        <xsl:for-each select="following-sibling::*[position() &lt; 4]">
                            <xsl:apply-templates/>
                            <xsl:if test="position() != last()">
                                <core:nl/>
                            </xsl:if>
                        </xsl:for-each>>
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

    <xsl:template match="para">
        <core:para>
            <xsl:apply-templates/>
        </core:para>
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="l-running-hd">TODO</core:title-alt>
        <core:title-alt use4="r-running-hd">TODO</core:title-alt>
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
    
</xsl:transform>