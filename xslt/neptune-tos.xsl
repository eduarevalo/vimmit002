<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:em="http://www.lexisnexis.com/namespace/sslrp/em"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <!--<xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Endmatter v018//EN//XML" doctype-system="endmatterxV018-0000.dtd"/>-->
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="nextPageRef"></xsl:param>
    
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        <xsl:comment select="concat('pub-num=', $pubNum)"/>
        <xsl:comment select="'ch-num=tos001'"/>
        <xsl:copy-of select="(//processing-instruction('textpage'))[1]"/>
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
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
        </em:table>
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:param name="titleNode"/>
        <core:title>
            <xsl:value-of select="$titleNode/*"/>
        </core:title>
        <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
        <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
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
        <!--<xsl:variable name="title" select="$set[contains(upper-case(normalize-space(.)), 'LOIS CONSTITUTIONNELLES')][1]"/>-->
        <table typesize="reg" colsep="0" frame="none" rowsep="0">
            <tgroup cols="1">
                <colspec align="left" colname="col0" colnum="1" colwidth="336.00pt"/>
                <tbody valign="top">
                    <xsl:for-each select="$set">
                        <row>
                            <entry colname="col0">
                                <xsl:apply-templates select="."/>
                            </entry>
                        </row>
                    </xsl:for-each>
                </tbody>
            </tgroup>
        </table>
    </xsl:template>
    
    <xsl:template match="title">
        <xsl:variable name="typestyle">
            <xsl:call-template name="getTypeStyle">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$typestyle!=''">
                <core:emph typestyle="{$typestyle}">
                    <xsl:apply-templates/>
                </core:emph>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="para">
        <xsl:if test="contains(@role, 'Art-')">
            <xsl:comment>VimmitArtIndent</xsl:comment>
        </xsl:if>
        <xsl:variable name="firstF" select="emphasis[starts-with(text(), 'F')][following-sibling::text()[1][starts-with(normalize-space(),':')]][1]"/>
        <xsl:choose>
            <xsl:when test="$firstF">
                <xsl:apply-templates select="$firstF/preceding-sibling::* | $firstF/preceding-sibling::text() | $firstF/preceding-sibling::processing-instruction()"/>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:apply-templates select="$firstF | $firstF/following-sibling::* | $firstF/following-sibling::text() | $firstF/following-sibling::processing-instruction()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="*|text()|processing-instruction()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="(//processing-instruction('textpage'))[1]"/>
    
</xsl:transform>