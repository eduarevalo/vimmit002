<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:em="http://www.lexisnexis.com/namespace/sslrp/em"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Endmatter v018//EN//XML" doctype-system="endmatterxV018-0000.dtd"/>
    
    <xsl:import href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="nextPageRef"></xsl:param>
    
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        <em:table>
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=toclist'"/>
            <xsl:copy-of select="(//processing-instruction('textpage'))[1]"/>
            <xsl:variable name="firstTitle" select="(part/partintro/para[contains(@role, 'texte-space-after')])[1]"/>
            
            <xsl:apply-templates select="$firstTitle/preceding-sibling::para"/>
            <table typesize="small" colsep="0" frame="none" rowsep="0">
                <tgroup cols="1">
                    <colspec align="left" colname="col0" colnum="1" colwidth="162.00pt"/>
                    <tbody>
                        <xsl:apply-templates select="$firstTitle | $firstTitle/following-sibling::para | $firstTitle/following-sibling::title"/>
                    </tbody>
                </tgroup>
            </table>
        </em:table>
    </xsl:template>
    
    <xsl:template match="para">
        <core:comment type="other">
            <xsl:apply-imports/>
        </core:comment>
    </xsl:template>
    
    <xsl:template match="para[contains(@role, 'texte-space-after') or contains(@role, 'texte-pointill')]">
        <row>
            <entry colname="col0">
                <xsl:variable name="date">
                    <xsl:call-template name="extractDate">
                        <xsl:with-param name="text" select="normalize-space()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$date != ''">
                        <xsl:value-of select="normalize-space(substring-before(., $date))"/>
                        <core:leaders blank-leader="dot" blank-use="fill"/>
                        <xsl:value-of select="$date"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>
            </entry>
        </row>
    </xsl:template>
    
    <xsl:template match="partintro/title[position()>1]" priority="100">
        <row>
            <entry colname="col0" align="center">
                <core:emph typestyle="bf">
                    <xsl:value-of select="."/>
                </core:emph>
            </entry>
        </row>
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
        <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
    </xsl:template>
    
    <xsl:template match="processing-instruction('textpage')[1]"/>
    
    <xsl:template name="extractDate">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" regex="(\w*\s*[0-9]{{4}})$">
            <xsl:matching-substring>
                <xsl:copy>                    
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
</xsl:transform>