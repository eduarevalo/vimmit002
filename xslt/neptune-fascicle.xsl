<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="chNum" select="'--CH-NUM--'"/>
    <xsl:param name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:param name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:variable name="keyPoints" select="/db:part/db:chapter/db:sect1[db:title/text() = 'POINTS-CLÉS']"/>
    <xsl:variable name="tocNode" select="/db:part/db:chapter/db:sect1[db:title/text() = 'TABLE DES MATIÈRES']"/>
    <xsl:variable name="indexNode" select="/db:part/db:chapter/db:sect1[db:title/text() = 'INDEX ANALYTIQUE']"/>
    <xsl:variable name="chapterNodes" select="/db:part/db:chapter/db:sect1 except $keyPoints except $tocNode except $indexNode"/>
    
    <xsl:template match="/">
        
        <tr:ch volnum="2015">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="concat('ch-num=', $chNum)"/>
            <xsl:call-template name="title"/>
            <xsl:call-template name="keyPoints"/>
            <xsl:call-template name="toc"/>
            <xsl:call-template name="index"/>
            <xsl:call-template name="chapters"/>
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
            <core:emph typestyle="smcaps"><xsl:value-of select="$leftHeader"/></core:emph>
        </core:title-alt>
        <core:title-alt use4="r-running-hd">
            <core:emph typestyle="smcaps"><xsl:value-of select="$rightHeader"/></core:emph>
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
    
    <xsl:template name="chapters">
        <xsl:if test="$chapterNodes">
            <xsl:for-each select="$chapterNodes">
                <xsl:variable name="firstNode" select="./db:title[1]"/>
                <xsl:variable name="label">
                    <xsl:call-template name="extractLabel">
                        <xsl:with-param name="text" select="$firstNode"/>
                    </xsl:call-template>
                </xsl:variable>
                <tr:ch-pt volnum="1">
                    
                    <core:desig value="{substring-before($label, '.')}">
                        <xsl:value-of select="$label"/>
                    </core:desig>
                    <core:title>
                        <xsl:value-of select="substring-after($firstNode, $label)"/>
                    </core:title>
                    <!--<tr:secmain-dummy volnum="1">
                        <core:blockquote>
                            <core:blockquote-para>Défendre et améliorer l’environnement pour les générations
                                présentes et à venir est devenu pour l’humanité un objectif primordial, une
                                tâche dont il faudra coordonner et harmoniser la réalisation avec celle des
                                objectifs fondamentaux déjà fixés de paix et de développement économique et
                                social dans le monde entier.</core:blockquote-para>
                            <core:credit>
                                <core:credit-origin><core:emph typestyle="it">Déclaration sur
                                    l’environnement</core:emph>, Stockholm, 1972,
                                    préambule.</core:credit-origin>
                            </core:credit>
                        </core:blockquote>
                    </tr:secmain-dummy>-->
                    <tr:secmain volnum="1">
                        <xsl:apply-templates select="./db:* except $firstNode | ./processing-instruction()"/>
                    </tr:secmain>
                </tr:ch-pt>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="db:indexentry">
        <xsl:variable name="primary" select="db:primaryie"/>
        <core:listitem>
            <core:para>
                <xsl:apply-templates select="$primary"/>
            </core:para>
            <xsl:apply-templates select="$primary/following-sibling::processing-instruction()[1][self::processing-instruction()/preceding-sibling::db:primaryie[1] = $primary]"/>
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
        <xsl:param name="labelToExtract"/>
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:variable name="validNodes" select="$nodes except $nodes[last()][self::processing-instruction()] except $nodes[1][self::processing-instruction()]"/>
        <xsl:call-template name="printFirstTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="$labelToExtract">
                <core:para>
                    <xsl:apply-templates select="normalize-space(substring-after($validNodes[1], $labelToExtract))"/>
                    <xsl:apply-templates select="$validNodes[position()>1]"/>
                </core:para>
            </xsl:when>
            <xsl:otherwise>
                <core:para>
                    <xsl:apply-templates select="$validNodes"/>
                </core:para>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="printLastTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="db:emphasis[@role='footnoteref']">
        <fn:endnote-id er="{normalize-space()}" />
    </xsl:template>
    
    <xsl:template match="db:para[db:footnote]">
        <xsl:call-template name="printFirstTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
        <fn:endnotes>
            <xsl:apply-templates select="*|text()|processing-instruction()"/>
        </fn:endnotes>
        <xsl:call-template name="printLastTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="db:para[db:markup]">
        <xsl:call-template name="printLastTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="db:para[parent::db:footnote]">
        <xsl:param name="labelToExtract"/>
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:variable name="lastPI" select="$nodes[last()]/name()"/>
        <xsl:call-template name="printFirstTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="$labelToExtract">
                <fn:para>
                    <xsl:apply-templates select="normalize-space(substring-after($nodes[1], $labelToExtract))"/>
                    <xsl:apply-templates select="$nodes[position()>1][$lastPI='' or position()&lt;last()]"/>
                </fn:para>
            </xsl:when>
            <xsl:otherwise>
                <fn:para>
                    <xsl:apply-templates select="$nodes[$lastPI='' or position()&lt;last()]"/>
                </fn:para>
            </xsl:otherwise>
        </xsl:choose>
        <!--<xsl:if test="$lastPI = 'textpage'">
            <xsl:apply-templates select="$nodes[last()]"/>
        </xsl:if>-->
    </xsl:template>
    
    <xsl:template match="db:footnote">
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="./db:para[1]"/>
            </xsl:call-template>
        </xsl:variable>
        <fn:endnote er="{substring-before($label, '.')}">
            <xsl:apply-templates>
                <xsl:with-param name="labelToExtract" select="$label"/>
            </xsl:apply-templates>
        </fn:endnote>
    </xsl:template>
    
    <xsl:template match="db:tocentry">
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:variable name="lastPI" select="$nodes[last()]/name()"/>
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
                        <xsl:apply-templates select="$nodes[position()>1][$lastPI='' or position()&lt;last()]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes[$lastPI='' or position()&lt;last()]"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:apply-templates select="db:tocdiv"/>
        </core:toc-entry>
        <xsl:if test="$lastPI = 'textpage'">
            <xsl:apply-templates select="$nodes[last()]"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="db:tocdiv">
        <xsl:variable name="nodes" select="db:title/(*|text()|processing-instruction())"/>
        <xsl:variable name="lastPI" select="$nodes[last()]/name()"/>
        <xsl:variable name="firstNode" select="db:title/(*|text())[1]"/>
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
                        <xsl:apply-templates select="$nodes[position()>1][$lastPI='' or position()&lt;last()]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes[$lastPI='' or position()&lt;last()]"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:if test="$lastPI = 'textpage'">
                <xsl:apply-templates select="$nodes[last()]"/>
            </xsl:if>
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
    
    <xsl:template match="processing-instruction()">
        <xsl:copy-of select="."></xsl:copy-of>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:apply-templates select="*|text()|processing-instruction()"/>
    </xsl:template>
    
    <xsl:template name="printLastTextPagePI">
        <xsl:param name="scope"/>
        <xsl:variable name="lastPI" select="($scope//(*|text()|processing-instruction()))[last()]"/>
        <xsl:if test="$lastPI/name() = 'textpage'">
            <xsl:apply-templates select="$lastPI"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="printFirstTextPagePI">
        <xsl:param name="scope"/>
        <xsl:variable name="firstPI" select="($scope//(*|text()|processing-instruction()))[1]"/>
        <xsl:if test="$firstPI/name() = 'textpage'">
            <xsl:apply-templates select="$firstPI"/>
        </xsl:if>
    </xsl:template>
    
</xsl:transform>