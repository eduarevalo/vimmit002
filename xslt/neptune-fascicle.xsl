<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="chNum" select="'--CH-NUM--'"/>
    
    <xsl:template match="/">
        
        <tr:ch volnum="2015">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="concat('ch-num=', $chNum)"/>
            <xsl:call-template name="title"/>
            <xsl:call-template name="keyPoints"/>
            <xsl:call-template name="toc"/>
            <xsl:call-template name="index"/>
        </tr:ch>
        
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:variable name="design">
            <xsl:value-of select="/db:part/db:chapter/db:titleabbrev"/>
        </xsl:variable>
        <core:desig value="{substring-after($design, 'FASCICULE ')}"><xsl:value-of select="$design"/></core:desig>
        <core:title>
            <xsl:value-of select="/db:part/db:chapter/db:title"/>
        </core:title>
        <core:title-alt use4="l-running-hd">
            TODO: Extract from layout
            <!--<core:emph typestyle="smcaps">Fasc. 1 – Droit international de l’environnement</core:emph>-->
        </core:title-alt>
        <core:title-alt use4="r-running-hd">
            TODO: Extract from layout
            <!--<core:emph typestyle="smcaps">I. Aspects généraux</core:emph>-->
        </core:title-alt>
        <core:byline>
            <xsl:for-each select="/db:part/db:chapter/db:info/db:author">
                <core:person>
                    <core:name.text>
                        <core:emph typestyle="it">
                            <xsl:value-of select="db:personname"/>
                        </core:emph>
                    </core:name.text>
                    <core:name.detail>
                        <core:role>
                            <xsl:value-of select="db:affiliation/db:jobtitle"/>
                        </core:role>
                    </core:name.detail>
                </core:person>
            </xsl:for-each>
        </core:byline>
        <core:comment-prelim type="currentness">
            <core:para>
                <xsl:value-of select="/db:part/db:chapter/db:info/db:date"/>
            </core:para>
        </core:comment-prelim>
    </xsl:template>
    
    <xsl:template name="keyPoints">
        <xsl:variable name="keyPoints" select="/db:part/db:chapter/db:sect1[db:title/text() = 'POINTS-CLÉS']"/>
        <xsl:if test="$keyPoints">
            <tr:ch-pt-dummy volnum="1">
                <tr:secmain volnum="1">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$keyPoints/db:title"/>
                    </core:title>
                    <core:list>
                        <xsl:for-each select="$keyPoints/db:para">
                            <xsl:variable name="firstNode" select="(*|text())[1]"/>
                            <xsl:variable name="label">
                                <xsl:call-template name="extractLabel">
                                    <xsl:with-param name="text" select="$firstNode"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <core:listitem>
                                <core:enum>
                                    <xsl:value-of select="$label"/>
                                </core:enum>
                                <xsl:apply-templates select=".">
                                    <xsl:with-param name="labelToExtract" select="$label"/>
                                </xsl:apply-templates>  
                            </core:listitem>
                        </xsl:for-each>
                    </core:list>
                </tr:secmain>
            </tr:ch-pt-dummy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="toc">
        <xsl:variable name="tocNode" select="/db:part/db:chapter/db:sect1[db:title/text() = 'TABLE DES MATIÈRES']"/>
        <xsl:if test="$tocNode">
            <tr:ch-pt-dummy volnum="1">
                <tr:secmain volnum="1">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$tocNode/db:title"/>
                    </core:title>
                    <core:toc>
                        <xsl:apply-templates select="$tocNode/db:toc"/>
                    </core:toc>
                </tr:secmain>
            </tr:ch-pt-dummy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="index">
        <xsl:variable name="indexNode" select="/db:part/db:chapter/db:sect1[db:title/text() = 'INDEX ANALYTIQUE']"/>
        <xsl:if test="$indexNode">
            <tr:ch-pt-dummy volnum="1">
                <tr:secmain volnum="1">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$indexNode/db:title"/>
                    </core:title>
                    <core:list>
                        <xsl:for-each select="$indexNode/db:index">
                            <xsl:apply-templates/>
                        </xsl:for-each>
                    </core:list>
                </tr:secmain>
            </tr:ch-pt-dummy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="db:indexentry">
        <core:listitem>
            <core:para>
                <xsl:apply-templates select="db:primaryie"/>
            </core:para>
            <xsl:variable name="nodes" select="db:secondaryie|db:tertiaryie"/>
            <xsl:if test="$nodes">
                <core:list>
                    <xsl:for-each select="$nodes">
                        <core:listitem>
                            <core:para>
                                <xsl:apply-templates/>
                            </core:para>
                        </core:listitem>
                    </xsl:for-each>
                </core:list>
            </xsl:if>
        </core:listitem>
    </xsl:template>
    
    <xsl:template match="db:para">
        <xsl:param name="labelToExtract"></xsl:param>
        <xsl:variable name="nodes" select="*|text()"/>
        <xsl:choose>
            <xsl:when test="$labelToExtract">
                <core:para>
                    <xsl:apply-templates select="normalize-space(substring-after($nodes[1], $labelToExtract))"/>
                    <xsl:apply-templates select="$nodes[position()>1]"/>
                </core:para>
            </xsl:when>
            <xsl:otherwise>
                <core:para>
                    <xsl:apply-templates/>
                </core:para>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="db:emphasis">
        <xsl:variable name="typestyle">
            <xsl:call-template name="getTypeStyle">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <core:emph>
            <xsl:if test="$typestyle">
                <xsl:attribute name="typestyle" select="$typestyle"/>
            </xsl:if>
            <xsl:apply-templates/>
        </core:emph>
    </xsl:template>
    
    <xsl:template match="db:tocentry">
        <xsl:variable name="nodes" select="*|text()"/>
        <xsl:variable name="firstNode" select="$nodes[1]"/>
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="$firstNode"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ancestorsCount" select="count(./ancestor::*)"/>
        <xsl:variable name="tocLevel">
            <xsl:choose>
                <xsl:when test="$ancestorsCount = 4">ch-pt</xsl:when>
                <xsl:when test="$ancestorsCount = 5">ch-ptsub1</xsl:when>
                <xsl:when test="$ancestorsCount = 6">ch-ptsub2</xsl:when>
                <xsl:otherwise><xsl:value-of select="concat('undefined--', $ancestorsCount)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <core:toc-entry lev="{$tocLevel}">
            <core:entry-num>
                <xsl:value-of select="$label"/>
            </core:entry-num>
            <core:entry-title>
                <xsl:choose>
                    <xsl:when test="$label != ''">
                        <xsl:apply-templates select="normalize-space(substring-after($nodes[1], $label))"/>
                        <xsl:apply-templates select="$nodes[position()>1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:apply-templates select="db:tocdiv"/>
        </core:toc-entry>
    </xsl:template>
    
    <xsl:template match="db:tocdiv">
        <xsl:variable name="nodes" select="db:title/(*|text())"/>
        <xsl:variable name="firstNode" select="$nodes[1]"/>
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="$firstNode"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ancestorsCount" select="count(./ancestor::*)"/>
        <xsl:variable name="tocLevel">
            <xsl:choose>
                <xsl:when test="$ancestorsCount = 4">ch-pt</xsl:when>
                <xsl:when test="$ancestorsCount = 5">ch-ptsub1</xsl:when>
                <xsl:when test="$ancestorsCount = 6">ch-ptsub2</xsl:when>
                <xsl:otherwise><xsl:value-of select="concat('undefined--', $ancestorsCount)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <core:toc-entry lev="{$tocLevel}">
            <core:entry-num>
                <xsl:value-of select="$label"/>
            </core:entry-num>
            <core:entry-title>
                <xsl:choose>
                    <xsl:when test="$label != ''">
                        <xsl:apply-templates select="normalize-space(substring-after($nodes[1], $label))"/>
                        <xsl:apply-templates select="$nodes[position()>1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes"/>    
                    </xsl:otherwise>
                </xsl:choose>
                </core:entry-title>
            <xsl:apply-templates select="db:tocentry|db:tocdiv"/>
        </core:toc-entry>
    </xsl:template>
    
    <xsl:template name="extractLabel">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" 
            regex="^([0-9]*[a-z]*[A-Z]*){{1,2}}\.">
            <xsl:matching-substring>
                <xsl:copy>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template name="getTypeStyle">
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="contains($node/@role, 'Italic') and contains($node/@role, 'Bold')">ib</xsl:when>
            <xsl:when test="contains($node/@role, 'Bold')">bf</xsl:when>
            <xsl:when test="contains($node/@role, 'Italic')">it</xsl:when>
            <xsl:when test="contains($node/@role, 'Underline')">un</xsl:when>
            <xsl:when test="contains($node/@role, 'Small-caps')">smcaps</xsl:when>
            <xsl:when test="contains($node/@role, 'Line-through')">strike</xsl:when>
            <xsl:when test="contains($node/@role, 'Super')">su</xsl:when>
            <xsl:when test="contains($node/@role, 'SUb')">sb</xsl:when>
        </xsl:choose>
    </xsl:template>
    
</xsl:transform>