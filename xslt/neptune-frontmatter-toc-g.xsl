<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:import href="neptune-frontmatter.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="tocNumber" select="'01a'"/>
    <xsl:param name="nextPageRef"></xsl:param>
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="concat('ch-num=ptoc', $tocNumber)"/>
            <xsl:copy-of select="(//processing-instruction('textpage'))[1]"/>
            <fm:pub-toc>
                <xsl:call-template name="toc"/>
            </fm:pub-toc>
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="toc">
        <fm:toc>
            <core:title>
                <xsl:apply-templates select="part/toc/title"/>
            </core:title>
            <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
            <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
            <xsl:variable name="comments" select="part/toc/title/following-sibling::*[contains(lower-case(@role), 'note-lecteur')]/(*|text()|processing-instruction())"/>
            <xsl:if test="$comments">
                <core:comment type="other" box="1" box-style="rule">
                    <core:para>
                        <xsl:apply-templates select="$comments"/>
                    </core:para>
                </core:comment>
            </xsl:if>
            <xsl:apply-templates select="part/toc/*[not(self::title)]"/>
        </fm:toc>
    </xsl:template>
    
    <xsl:template match="para[contains(@role, 'Align-center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
    <!--<xsl:template match="para[starts-with(normalize-space(.), 'ISBN')]">
        <fm:isbn>
            <xsl:value-of select="normalize-space()"/>
        </fm:isbn>
    </xsl:template>-->

    <!--<xsl:template match="para">
        <core:para>
            <xsl:apply-templates/>
        </core:para>
    </xsl:template>-->
    
    <xsl:template match="para[contains(@role, 'nom-fascicule')]">
        <xsl:variable name="typestyle1">
            <xsl:call-template name="getTypeStyle">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="typestyle">
            <xsl:choose>
                <xsl:when test="$typestyle1!=''">
                    <xsl:copy-of select="$typestyle1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="getTypeStyle">
                        <xsl:with-param name="node" select="emphasis"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:variable name="pageNumber">
                    <xsl:call-template name="extractPageNumber">
                        <xsl:with-param name="text" select="normalize-space()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$typestyle!=''">
                        <core:emph typestyle="{$typestyle}">
                            <xsl:value-of select="substring-before(normalize-space(), $pageNumber)"/>
                        </core:emph>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-before(normalize-space(), $pageNumber)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:value-of select="$pageNumber"/>
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="tocentry">
        <xsl:variable name="level">
            <xsl:choose>
                <xsl:when test="emphasis[contains(@role,'nom-fascicule')]">unclassified</xsl:when>
                <xsl:when test="emphasis[contains(@role,'fascicule')]">ch</xsl:when>
                <xsl:when test="contains(@role, '-I-')">ch-pt</xsl:when>
                <xsl:when test="contains(@role, '-A-')">ch-ptsub1</xsl:when>
                <xsl:when test="contains(@role, '-1-')">ch-ptsub2</xsl:when>
                <xsl:when test="contains(@role, '-a-')">ch-ptsub3</xsl:when>
                <xsl:when test="contains(@role, '-i-')">ch-ptsub4</xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="nextLevelIdentifier">
            <xsl:choose>
                <xsl:when test="contains(@role, '-I-')">-A-</xsl:when>
                <xsl:when test="contains(@role, '-A-')">-1-</xsl:when>
                <xsl:when test="contains(@role, '-1-')">-a-</xsl:when>
                <xsl:when test="contains(@role, '-a-')">-i-</xsl:when>
                <xsl:when test="contains(@role, '-i-')">-i-</xsl:when>
            </xsl:choose>    
        </xsl:variable>
        
        <xsl:variable name="currentLevelIdentifier">
            <xsl:choose>
                <xsl:when test="contains(@role, '-I-')">-I-</xsl:when>
                <xsl:when test="contains(@role, '-A-')">-A-</xsl:when>
                <xsl:when test="contains(@role, '-1-')">-1-</xsl:when>
                <xsl:when test="contains(@role, '-a-')">-a-</xsl:when>
                <xsl:when test="contains(@role, '-i-')">-i-</xsl:when>
            </xsl:choose>    
        </xsl:variable>
        
        <xsl:variable name="thisTocEntry" select="."/>
        
        <fm:toc-entry lev="{$level}">
            
            <xsl:variable name="label">
                <xsl:call-template name="extractLabel">
                    <xsl:with-param name="text" select="."/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="$label!='' or contains(@role, '-I-')">
                    
                    <core:entry-num>
                        <xsl:value-of select="$label"/>
                    </core:entry-num>
                    
                    <core:entry-title>
                        <xsl:variable name="typestyle">
                            <xsl:call-template name="getTypeStyle">
                                <xsl:with-param name="node" select="emphasis"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="emphasis[contains(.,$label)]">
                                <xsl:choose>
                                    <xsl:when test="$typestyle!=''">
                                        <core:emph typestyle="{$typestyle}">
                                            <xsl:apply-templates select="*|text()">
                                                <xsl:with-param name="labelToExtract" select="$label"/>
                                            </xsl:apply-templates>
                                        </core:emph>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="*|text()">
                                            <xsl:with-param name="labelToExtract" select="$label"/>
                                        </xsl:apply-templates>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="emphasis">
                                <xsl:choose>
                                    <xsl:when test="$typestyle!=''">
                                        <core:emph typestyle="{$typestyle}">
                                            <xsl:value-of select="substring-after(text()[1], $label)"/>
                                            <xsl:apply-templates select="* | text()[not(contains(., $label))]"/>
                                        </core:emph>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring-after(text()[1], $label)"/>
                                        <xsl:apply-templates select="* | text()[not(contains(., $label))]"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="$typestyle!=''">
                                        <core:emph typestyle="{$typestyle}">
                                            <xsl:value-of select="substring-after(., $label)"/>
                                        </core:emph>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring-after(., $label)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </core:entry-title>
                    <xsl:if test="following-sibling::*[1][name() = 'tocentry'][contains(@role, $nextLevelIdentifier)]">
                        <xsl:variable name="limit" select="following-sibling::*[contains(@role, $currentLevelIdentifier)][1]"/>
                        <xsl:variable name="nextLevels" select="following-sibling::tocentry[contains(@role, $nextLevelIdentifier)] except $limit except $limit/following-sibling::*"/>
                        <xsl:apply-templates select="$nextLevels"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <core:entry-title>
                        <xsl:choose>
                            <xsl:when test="emphasis">
                                <xsl:for-each select="emphasis">
                                    <xsl:choose>
                                        <xsl:when test="position() = last()">
                                            <xsl:variable name="pageNumber">
                                                <xsl:call-template name="extractPageNumber">
                                                    <xsl:with-param name="text" select="text()"/>
                                                </xsl:call-template>
                                            </xsl:variable>
                                            
                                            <xsl:variable name="typestyle">
                                                <xsl:call-template name="getTypeStyle">
                                                    <xsl:with-param name="node" select="."/>
                                                </xsl:call-template>
                                            </xsl:variable>
                                            <xsl:choose>
                                                <xsl:when test="$typestyle!=''">
                                                    <core:emph typestyle="{$typestyle}">
                                                        <xsl:value-of select="substring-before(text(), $pageNumber)"/>
                                                    </core:emph>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="substring-before(text(), $pageNumber)"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            
                                            <core:leaders blank-leader="dot" blank-use="fill"/>
                                            <xsl:value-of select="$pageNumber"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates select="."/>
                                            <core:nl/>
                                        </xsl:otherwise>
                                    </xsl:choose>    
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                        </core:entry-title>
                </xsl:otherwise>
            </xsl:choose>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="tocdiv">
        <xsl:copy-of select="title/preceding-sibling::processing-instruction()"/>
        <xsl:if test="title">
            <xsl:variable name="level">
                <xsl:choose>
                    <xsl:when test="parent::toc">pub-pt</xsl:when>
                    <xsl:when test="parent::tocdiv/parent::toc">pub-ptsub1</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <fm:toc-entry lev="{$level}">
                <core:entry-title>
                    <xsl:variable name="typestyle">
                        <xsl:call-template name="getTypeStyle">
                            <xsl:with-param name="node" select="title"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="title[contains(@role, 'Align-center')]">
                            <xsl:choose>
                                <xsl:when test="$typestyle!=''">
                                    <fm:center>
                                        <core:emph typestyle="{$typestyle}">
                                            <xsl:apply-templates select="title[1]"/>
                                        </core:emph>
                                    </fm:center>        
                                </xsl:when>
                                <xsl:otherwise>
                                    <fm:center>
                                        <xsl:apply-templates select="title[1]"/>
                                    </fm:center>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$typestyle!=''">
                                    <core:emph typestyle="{$typestyle}">
                                        <xsl:apply-templates select="title[1]"/>
                                    </core:emph>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="title[1]"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </core:entry-title>
            </fm:toc-entry>
        </xsl:if>
        <xsl:apply-templates select="tocentry[contains(@role,'-I-') or emphasis[contains(@role,'fascicule')]]|tocdiv|para"/>
    </xsl:template>
    
    <xsl:template match="(//processing-instruction('textpage'))[1]"/>
    
    
</xsl:transform>