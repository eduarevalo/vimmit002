<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:em="http://www.lexisnexis.com/namespace/sslrp/em"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Endmatter v018//EN//XML" doctype-system="endmatterxV018-0000.dtd"/>
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        <xsl:comment select="concat('pub-num=', $pubNum)"/>
        <xsl:comment select="'ch-num=tos001'"/>
        <em:table>
            <xsl:variable name="title" select="part/partintro/para[contains(upper-case(normalize-space(.)), 'INDEX DE LA LÉGISLATION')]"/>
            <xsl:variable name="noteExplicative" select="$title/following-sibling::*[starts-with(lower-case(normalize-space(.)), 'note explicative')]"/>
            <xsl:call-template name="title">
                <xsl:with-param name="titleNode" select="$title"/>
            </xsl:call-template>
            <xsl:call-template name="noteExplicative">
                <xsl:with-param name="noteExplicativeNode" select="$noteExplicative"/>
            </xsl:call-template>
            <xsl:call-template name="index">
                <xsl:with-param name="set" select="$noteExplicative/following-sibling::*"/>
            </xsl:call-template>
        </em:table>
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:param name="titleNode"/>
        <core:title>
            <xsl:apply-templates select="$titleNode/*"/>
        </core:title>
        <core:title-alt use4="l-running-hd">
            <core:emph typestyle="smcaps"><xsl:value-of select="$leftHeader"/></core:emph>
        </core:title-alt>
        <core:title-alt use4="r-running-hd">
            <core:emph typestyle="smcaps"><xsl:value-of select="$rightHeader"/></core:emph>
        </core:title-alt>
    </xsl:template>
    
    <xsl:template name="noteExplicative">
        <xsl:param name="noteExplicativeNode"/>
        <core:comment type="other">
            <core:para>
                <xsl:apply-templates select="$noteExplicativeNode/*"/>
            </core:para>
        </core:comment>
    </xsl:template>
    
    <xsl:template name="index">
        <xsl:param name="set"/>
        <xsl:variable name="title" select="$set[contains(upper-case(normalize-space(.)), 'LOIS CONSTITUTIONNELLES')][1]"/>
        <table typesize="small" colsep="0" frame="none" rowsep="0">
            <tgroup cols="1">
                <colspec align="left" colname="col0" colnum="1" colwidth="336.00pt"/>
                <tbody valign="bottom">
                    <row>
                        <entry colname="col0">
                            <xsl:apply-templates select="$title/(*|text())"/>
                        </entry>
                    </row>
                    <xsl:for-each select="$set except $title">
                        <row>
                            <entry colname="col0">
                                <xsl:apply-templates/>
                            </entry>
                        </row>
                    </xsl:for-each>
                </tbody>
            </tgroup>
        </table>
    </xsl:template>
    
</xsl:transform>