<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:em="http://www.lexisnexis.com/namespace/sslrp/em"
    xmlns:in="http://www.lexisnexis.com/namespace/sslrp/in"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <!--<xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Endmatter v018//EN//XML" doctype-system="endmatterxV018-0000.dtd"/>-->
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="nextPageRef"></xsl:param>
   
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:template match="/">
        
        <em:index volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=index'"/>
            <xsl:copy-of select="(//processing-instruction('textpage'))[1]"/>
            
            <xsl:apply-templates select="part/partintro/title"/>
            <xsl:apply-templates select="part/partintro/para[starts-with(normalize-space(),'Note explicative')][1]"/>
            <in:body>
                <xsl:for-each select="part/partintro/para[contains(@role,'Index_S-parateur') or contains(@role,'Lettre')]">
                    <xsl:variable name="this" select="."/>
                    <xsl:variable name="i" select="position()"/>
                    <in:alpha-breaker>
                        <xsl:apply-templates select="$this"/>
                        <xsl:choose>
                            <xsl:when test="$i!=last()">
                                <xsl:variable name="set" select="$this/following-sibling::index[contains(@role, 'N1')][preceding-sibling::para[1] = $this]"/>
                                <xsl:call-template name="level1">
                                    <xsl:with-param name="entry" select="$this"/>
                                    <xsl:with-param name="set" select="$set"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="set" select="$this/following-sibling::index[contains(@role, 'N1')]"/>
                                <xsl:call-template name="level1">
                                    <xsl:with-param name="entry" select="$this"/>
                                    <xsl:with-param name="set" select="$set"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </in:alpha-breaker>
                </xsl:for-each>
            </in:body>
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
        </em:index>
        
    </xsl:template>
    
    <xsl:template name="level1">
        <xsl:param name="entry"/>
        <xsl:param name="set"/>
        <xsl:for-each select="$set">
            <xsl:variable name="this" select="."/>
            <xsl:if test="not(count(*)=0)">
                <xsl:copy-of select="$this/processing-instruction()"/>
            </xsl:if>
            <xsl:variable name="set2" select="$this/following-sibling::index[contains(@role, 'N2')][preceding-sibling::index[contains(@role, 'N1')][1] = $this]"/>
            <xsl:variable name="typestyle">
                <xsl:call-template name="getTypeStyle">
                    <xsl:with-param name="node" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <in:lev1>
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
                <xsl:call-template name="level2">
                    <xsl:with-param name="entry" select="."/>
                    <xsl:with-param name="set" select="$set2"/>
                </xsl:call-template>
            </in:lev1>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="level2">
        <xsl:param name="entry"/>
        <xsl:param name="set"/>
        <xsl:for-each select="$set">
            <xsl:variable name="this" select="."/>
            <xsl:if test="not(count(*)=0)">
                <xsl:copy-of select="$this/processing-instruction()"/>
            </xsl:if>
            <xsl:variable name="limit" select="($this/following-sibling::index[not(contains(@role, 'N3')) and not(contains(@role, 'N4')) and not(contains(@role, 'N5'))])[1]"/>
            <xsl:variable name="set3" select="$this/following-sibling::index[contains(@role, 'N3')] intersect $limit/preceding-sibling::index"/>
            <xsl:variable name="typestyle">
                <xsl:call-template name="getTypeStyle">
                    <xsl:with-param name="node" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <in:lev2>
                <xsl:choose>
                    <xsl:when test="$typestyle!=''">
                        
                        <xsl:variable name="firstF" select="emphasis[starts-with(normalize-space(), 'F')][1]"/>
                        <xsl:choose>
                            <xsl:when test="$firstF">
                                <core:emph typestyle="{$typestyle}">
                                    <xsl:apply-templates select="$firstF/preceding-sibling::* | $firstF/preceding-sibling::text()"/>
                                    <in:locator>
                                        <xsl:apply-templates select="$firstF | $firstF/following-sibling::* | $firstF/following-sibling::text()"/>    
                                    </in:locator>
                                </core:emph>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="firstF" select="emphasis[starts-with(normalize-space(), 'F')][1]"/>
                        <xsl:choose>
                            <xsl:when test="$firstF">
                                <xsl:apply-templates select="$firstF/preceding-sibling::* | $firstF/preceding-sibling::text()"/>
                                <in:locator>
                                    <xsl:apply-templates select="$firstF | $firstF/following-sibling::* | $firstF/following-sibling::text()"/>    
                                </in:locator>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="level3">
                    <xsl:with-param name="entry" select="."/>
                    <xsl:with-param name="set" select="$set3"/>
                </xsl:call-template>
            </in:lev2>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="level3">
        <xsl:param name="entry"/>
        <xsl:param name="set"/>
        <xsl:for-each select="$set">
            <xsl:variable name="this" select="."/>
            <xsl:if test="not(count(*)=0)">
                <xsl:copy-of select="$this/processing-instruction()"/>
            </xsl:if>
            <xsl:variable name="set4" select="$this/following-sibling::index[contains(@role, 'N4')][preceding-sibling::index[contains(@role, 'N3')][1] = $this]"/>
            <xsl:variable name="typestyle">
                <xsl:call-template name="getTypeStyle">
                    <xsl:with-param name="node" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <in:lev3>
                <xsl:choose>
                    <xsl:when test="$typestyle!=''">
                        <core:emph typestyle="{$typestyle}">
                            <xsl:apply-templates/>
                        </core:emph>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="firstF" select="emphasis[starts-with(normalize-space(), 'F')][1]"/>
                        <xsl:choose>
                            <xsl:when test="$firstF">
                                <xsl:apply-templates select="$firstF/preceding-sibling::* | $firstF/preceding-sibling::text()"/>
                                <in:locator>
                                    <xsl:apply-templates select="$firstF | $firstF/following-sibling::* | $firstF/following-sibling::text()"/>    
                                </in:locator>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="level4">
                    <xsl:with-param name="entry" select="."/>
                    <xsl:with-param name="set" select="$set4"/>
                </xsl:call-template>
            </in:lev3>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="level4">
        <xsl:param name="entry"/>
        <xsl:param name="set"/>
        <xsl:for-each select="$set">
            <xsl:variable name="this" select="."/>
            <xsl:if test="not(count(*)=0)">
                <xsl:copy-of select="$this/processing-instruction()"/>
            </xsl:if>
            <xsl:variable name="set4" select="$this/following-sibling::index[contains(@role, 'N5')][preceding-sibling::index[contains(@role, 'N3')][1] = $this]"/>
            <xsl:variable name="typestyle">
                <xsl:call-template name="getTypeStyle">
                    <xsl:with-param name="node" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <in:lev4>
                <xsl:choose>
                    <xsl:when test="$typestyle!=''">
                        <core:emph typestyle="{$typestyle}">
                            <xsl:apply-templates/>
                        </core:emph>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="firstF" select="emphasis[starts-with(normalize-space(), 'F')][1]"/>
                        <xsl:choose>
                            <xsl:when test="$firstF">
                                <xsl:apply-templates select="$firstF/preceding-sibling::* | $firstF/preceding-sibling::text()"/>
                                <in:locator>
                                    <xsl:apply-templates select="$firstF | $firstF/following-sibling::* | $firstF/following-sibling::text()"/>    
                                </in:locator>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                <!--<xsl:call-template name="level3">
                    <xsl:with-param name="entry" select="."/>
                    <xsl:with-param name="set" select="$set2"/>
                </xsl:call-template>-->
            </in:lev4>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:value-of select="."/>
        </core:title>
        <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
        <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
    </xsl:template>
    
    <xsl:template match="para[starts-with(normalize-space(),'Note explicative')]">
        <core:legend>
            <xsl:apply-templates/>
        </core:legend>    
    </xsl:template>
    
    <xsl:template match="para[contains(@role,'Index_S-parateur') or contains(@role, 'Lettre')]">
        <in:alpha-letter>
            <xsl:value-of select="."/>
        </in:alpha-letter>
    </xsl:template>
    
    <xsl:template match="(//processing-instruction('textpage'))[1]"/>
    
</xsl:transform>