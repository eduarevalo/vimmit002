<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Treatise-pub v021//EN//XML" doctype-system="treatiseV021-0000.dtd"></xsl:output>
    
    <xsl:import href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="chNum" select="'--CH-NUM--'"/>
    <xsl:param name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:param name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:variable name="keyPoints" select="/part/chapter/sect1[title/text() = 'POINTS-CLÉS']"/>
    <xsl:variable name="tocNode" select="/part/chapter/sect1[title/text() = 'TABLE DES MATIÈRES']"/>
    <xsl:variable name="indexNode" select="/part/chapter/sect1[title/text() = 'INDEX ANALYTIQUE']"/>
    <xsl:variable name="chapterNodes" select="/part/chapter/sect1 except $keyPoints except $tocNode except $indexNode"/>
    
    <xsl:variable name="volnum">
        <xsl:call-template name="extractVolnum">
            <xsl:with-param name="text" select="$leftHeader"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:template match="/">
        
        <tr:ch volnum="{$volnum}">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="concat('ch-num=', $chNum)"/>
            <xsl:call-template name="title"/>
            <xsl:call-template name="keyPoints"/>
            <xsl:call-template name="toc"/>
            <xsl:call-template name="index"/>
            <xsl:apply-templates select="$chapterNodes"/>
        </tr:ch>
        
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:variable name="design">
            <xsl:value-of select="/part/chapter/titleabbrev"/>
        </xsl:variable>
        <xsl:variable name="title" select="/part/chapter/title"/>
        <xsl:apply-templates select="$title/preceding-sibling::processing-instruction()"></xsl:apply-templates>
        <core:desig value="{substring-after($design, 'FASCICULE ')}"><xsl:value-of select="$design"/></core:desig>
        <core:title>
            <xsl:value-of select="$title"/>
        </core:title>
        <core:title-alt use4="r-running-hd">
            <xsl:value-of select="$rightHeader"/>
        </core:title-alt>
        <core:title-alt use4="l-running-hd">
            <xsl:value-of select="$leftHeader"/>
        </core:title-alt>
        <core:byline>
            <xsl:for-each select="/part/chapter/info/author">
                <core:person>
                    <core:name.text>
                        <core:emph typestyle="it">
                            <xsl:value-of select="personname"/>
                        </core:emph>
                    </core:name.text>
                    <core:name.detail>
                        <core:role>
                            <xsl:value-of select="affiliation/jobtitle"/>
                        </core:role>
                    </core:name.detail>
                </core:person>
            </xsl:for-each>
        </core:byline>
        <core:comment-prelim type="currentness">
            <core:para>
                <xsl:value-of select="/part/chapter/info/date"/>
            </core:para>
        </core:comment-prelim>
    </xsl:template>
    
    <xsl:template name="keyPoints">
        <xsl:if test="$keyPoints">
            <tr:ch-pt-dummy volnum="{$volnum}">
                <tr:secmain volnum="{$volnum}">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$keyPoints/title"/>
                    </core:title>
                    <core:list>
                        <xsl:for-each select="$keyPoints/para">
                            <xsl:variable name="firstNode" select="(*|text())[1]"/>
                            <xsl:variable name="label">
                                <xsl:call-template name="extractLabel">
                                    <xsl:with-param name="text" select="$firstNode"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:variable name="firstPageNumberPI" select="(*|text()|processing-instruction())[1][self::processing-instruction()]"/>
                            <xsl:apply-templates select="$firstPageNumberPI"/>
                            <core:listitem>
                                <core:enum>
                                    <xsl:value-of select="$label"/>
                                </core:enum>
                                <xsl:apply-templates select=".">
                                    <xsl:with-param name="labelToExtract" select="$label"/>
                                    <xsl:with-param name="printFirstTextPageNumber" select="false()"/>
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
            <tr:ch-pt-dummy volnum="{$volnum}">
                <tr:secmain volnum="{$volnum}">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$tocNode/title"/>
                    </core:title>
                    <core:toc>
                        <xsl:apply-templates select="$tocNode/toc"/>
                    </core:toc>
                    <core:para/>
                </tr:secmain>
            </tr:ch-pt-dummy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="index">
        <xsl:if test="$indexNode">
            <tr:ch-pt-dummy volnum="{$volnum}">
                <tr:secmain volnum="{$volnum}">
                    <core:no-desig/>
                    <core:title>
                        <xsl:value-of select="$indexNode/title"/>
                    </core:title>
                    <core:list>
                        <xsl:for-each select="$indexNode/index">
                            <xsl:apply-templates/>
                        </xsl:for-each>
                    </core:list>
                </tr:secmain>
            </tr:ch-pt-dummy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sect1|sect2|sect3|sect4|sect5">
        <xsl:variable name="runin" select="para[emphasis[@role='label'][@xreflabel]]"/>
        <xsl:variable name="chapterNodeName">
            <xsl:choose>
                <xsl:when test="name()='sect1' and not($runin)">tr:ch-pt-dummy</xsl:when>
                <xsl:when test="name()='sect1'">tr:ch-pt</xsl:when>
                <xsl:when test="name()='sect2'">tr:ch-ptsub1</xsl:when>
                <xsl:when test="name()='sect3'">tr:ch-ptsub2</xsl:when>
                <xsl:when test="name()='sect4'">tr:ch-ptsub3</xsl:when>
                <xsl:when test="name()='sect5'">tr:ch-ptsub4</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="previousPageNumber" select="(./(preceding-sibling::*|preceding-sibling::processing-instruction()))[last()][self::processing-instruction()]"/>
        <xsl:apply-templates select="$previousPageNumber"/>
        <xsl:variable name="firstNode" select="./title[1]"/>
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="$firstNode"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:element name="{$chapterNodeName}">
            <xsl:attribute name="volnum" select="$volnum"/>
            <xsl:variable name="desig">
                <xsl:choose>
                    <xsl:when test="contains($label, '.')">
                        <xsl:value-of select="substring-before($label, '.')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-before($label, ')')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="not(name()='sect1' and not($runin))">
                <xsl:choose>
                    <xsl:when test="$desig != ''">
                        <core:desig value="{$desig}">
                            <xsl:value-of select="$label"/>
                        </core:desig>
                    </xsl:when>
                    <xsl:otherwise>
                        <core:no-desig/>
                    </xsl:otherwise>
                </xsl:choose>
                <core:title>
                    <xsl:value-of select="substring-after($firstNode, $label)"/>
                </core:title>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="sect2">
                    <xsl:variable name="sect2Nodes" select="para[emphasis[@role='label'][@xreflabel]][not(preceding-sibling::sect2)]"/>
                    <xsl:if test="$sect2Nodes">
                        <tr:ch-ptsub1-dummy volnum="{$volnum}">
                            <xsl:apply-templates select="$sect2Nodes"/>
                        </tr:ch-ptsub1-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect2"/>
                </xsl:when>
                <xsl:when test="sect3">
                    <xsl:variable name="sect3Nodes" select="para[emphasis[@role='label'][@xreflabel]][not(preceding-sibling::sect3)]"/>
                    <xsl:if test="$sect3Nodes">
                        <tr:ch-ptsub2-dummy volnum="{$volnum}">
                            <xsl:apply-templates select="$sect3Nodes"/>
                        </tr:ch-ptsub2-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect3"/>
                </xsl:when>
                <xsl:when test="sect4">
                    <xsl:variable name="sect4Nodes" select="para[emphasis[@role='label'][@xreflabel]][not(preceding-sibling::sect4)]"/>
                    <xsl:if test="$sect4Nodes">
                        <tr:ch-ptsub3-dummy volnum="{$volnum}">
                            <xsl:apply-templates select="$sect4Nodes"/>
                        </tr:ch-ptsub3-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect4"/>
                </xsl:when>
                <xsl:when test="sect5">
                    <xsl:variable name="sect5Nodes" select="para[emphasis[@role='label'][@xreflabel]][not(preceding-sibling::sect5)]"/>
                    <xsl:if test="$sect5Nodes">
                        <tr:ch-ptsub4-dummy volnum="{$volnum}">
                            <xsl:apply-templates select="$sect5Nodes"/>
                        </tr:ch-ptsub4-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect5"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$runin">
                            <xsl:apply-templates select="$runin"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <tr:secmain volnum="{$volnum}">
                                <xsl:choose>
                                    <xsl:when test="$desig != ''">
                                        <core:desig value="{$desig}">
                                            <xsl:value-of select="$label"/>
                                        </core:desig>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <core:no-desig/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <core:title>
                                    <xsl:value-of select="substring-after($firstNode, $label)"/>
                                </core:title>
                                <xsl:apply-templates select="(*|processing-instruction()) except $firstNode"/>
                            </tr:secmain>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="para[emphasis[@role='label'][@xreflabel]]">
        <xsl:variable name="thisPara" select="."/>
        <xsl:variable name="emphasisLabel" select="emphasis[@role='label']"/>
        <xsl:variable name="label" select="$emphasisLabel/@xreflabel"/>
        <xsl:variable name="title" select="$emphasisLabel/following-sibling::emphasis[./following-sibling::text()[1][contains(.,'–')]]"/>
        <xsl:apply-templates select="($emphasisLabel/* | $emphasisLabel/processing-instruction())[1][self::processing-instruction()][1]"/>
        <tr:secmain volnum="{$volnum}">
            <core:desig value="{$label}">
                <xsl:value-of select="$emphasisLabel"/>
            </core:desig>
            <core:title runin="1">
                <xsl:apply-templates select="$title"/>
            </core:title>
            <core:para runin="1">
                <xsl:apply-templates select="./(*|text()|processing-instruction()) except $emphasisLabel except $title"/>
            </core:para>
            <xsl:variable name="nextXrefLabel" select="(following-sibling::para[emphasis[@role='label'][@xreflabel]])[1]"/>
            <xsl:choose>
                <xsl:when test="$nextXrefLabel">
                    <xsl:variable name="nextNodes" select="$nextXrefLabel/(preceding-sibling::*|preceding-sibling::processing-instruction()) intersect (following-sibling::*|preceding-sibling::processing-instruction())"/>
                    <xsl:apply-templates select="$nextNodes[not(footnote)]"/>
                    <xsl:if test="$nextNodes[footnote]">
                        <fn:endnotes>
                            <xsl:apply-templates select="$nextNodes[footnote]"/>
                        </fn:endnotes>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="nextNodes" select="following-sibling::* except following-sibling::sect1 except following-sibling::sect2 except following-sibling::sect3 except following-sibling::sect4 except following-sibling::sect5"/>
                    <xsl:apply-templates select="$nextNodes[not(footnote)]"/>
                    <xsl:if test="$nextNodes[footnote]">
                        <fn:endnotes>
                            <xsl:apply-templates select="$nextNodes[footnote]"/>
                        </fn:endnotes>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </tr:secmain>
    </xsl:template>
    
    <xsl:template match="indexentry">
        <xsl:variable name="primary" select="primaryie"/>
        <core:listitem>
            <core:para>
                <xsl:apply-templates select="$primary"/>
            </core:para>
            <xsl:apply-templates select="$primary/following-sibling::processing-instruction()[1][self::processing-instruction()/preceding-sibling::primaryie[1] = $primary]"/>
            <xsl:variable name="nodes" select="secondaryie"/>
            <xsl:if test="$nodes">
                <core:list>
                    <xsl:for-each select="$nodes">
                        <xsl:variable name="secondaryIndex" select="."/>
                        <core:listitem>
                            <core:para>
                                <xsl:apply-templates/>
                            </core:para>
                            <xsl:variable name="nodesTertiary" select="$secondaryIndex/following-sibling::tertiaryie[preceding-sibling::secondaryie[1] = $secondaryIndex]"/>
                            <xsl:if test="$nodesTertiary">
                                <core:list>
                                    <xsl:for-each select="$nodesTertiary">
                                        <core:listitem>
                                            <core:para>
                                                <xsl:apply-templates/>
                                            </core:para>
                                        </core:listitem>
                                    </xsl:for-each>
                                </core:list>
                            </xsl:if>
                        </core:listitem>
                    </xsl:for-each>
                </core:list>
            </xsl:if>
        </core:listitem>
    </xsl:template>
    
    <xsl:template match="para">
        <xsl:param name="labelToExtract"/>
        <xsl:param name="printFirstTextPageNumber" select="true()"/>
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:variable name="validNodes" select="$nodes except $nodes[last()][self::processing-instruction()] except $nodes[1][self::processing-instruction()]"/>
        <xsl:if test="$printFirstTextPageNumber">
            <xsl:call-template name="printFirstTextPagePI">
                <xsl:with-param name="scope" select="."/>
            </xsl:call-template>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$labelToExtract">
                <core:para>
                    <xsl:apply-templates select="substring-after($validNodes[1], $labelToExtract)"/>
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
    
    <xsl:template match="emphasis[@role='footnoteref']">
        <fn:endnote-id er="{normalize-space()}" />
    </xsl:template>
    
    <xsl:template match="para[footnote]">
        <xsl:call-template name="printFirstTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
        <xsl:apply-templates select="*|text()|processing-instruction()"/>
        <xsl:call-template name="printLastTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="para[parent::footnote]">
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
    
    <xsl:template match="footnote">
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="./para[1]"/>
            </xsl:call-template>
        </xsl:variable>
        <fn:endnote er="{substring-before($label, '.')}">
            <xsl:apply-templates>
                <xsl:with-param name="labelToExtract" select="$label"/>
            </xsl:apply-templates>
        </fn:endnote>
    </xsl:template>
    
    <xsl:template match="tocentry">
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
                <xsl:when test="$ancestorsCount = 7">ch-ptsub3</xsl:when>
                <xsl:when test="$ancestorsCount = 8">ch-ptsub4</xsl:when>
                <xsl:when test="$ancestorsCount = 9">ch-ptsub5</xsl:when>
                <xsl:when test="$ancestorsCount = 10">ch-ptsub6</xsl:when>
                <xsl:otherwise><xsl:value-of select="concat('undefined--', $ancestorsCount)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="$firstNode/processing-instruction()"/>
        <core:toc-entry lev="{$tocLevel}">
            <core:entry-num>
                <xsl:value-of select="$label"/>
            </core:entry-num>
            <core:entry-title>
                <xsl:choose>
                    <xsl:when test="$label != ''">
                        <xsl:apply-templates select="substring-after($nodes[1], $label)"/>
                        <xsl:apply-templates select="$nodes[position()>1][$lastPI='' or position()&lt;last()]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes[$lastPI='' or position()&lt;last()]"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:apply-templates select="tocdiv"/>
        </core:toc-entry>
        <xsl:if test="$lastPI = 'textpage'">
            <xsl:apply-templates select="$nodes[last()]"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tocdiv">
        <xsl:variable name="nodes" select="title/(*|text()|processing-instruction())"/>
        <xsl:variable name="firstNode" select="title/(*|text())[1]"/>
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
                <xsl:when test="$ancestorsCount = 7">ch-ptsub3</xsl:when>
                <xsl:when test="$ancestorsCount = 8">ch-ptsub4</xsl:when>
                <xsl:when test="$ancestorsCount = 9">ch-ptsub5</xsl:when>
                <xsl:when test="$ancestorsCount = 10">ch-ptsub6</xsl:when>
                <xsl:otherwise><xsl:value-of select="concat('undefined--', $ancestorsCount)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="firstPageNumberPI" select="(.//(text()|processing-instruction()))[1][self::processing-instruction()]"/>
        <xsl:apply-templates select="$firstPageNumberPI"/>
        <core:toc-entry lev="{$tocLevel}">
            <core:entry-num>
                <xsl:value-of select="$label"/>
            </core:entry-num>
            <core:entry-title>
                <xsl:choose>
                    <xsl:when test="$label != ''">
                        <xsl:choose>
                            <xsl:when test="$firstPageNumberPI">
                                <xsl:apply-templates select="normalize-space(substring-after($nodes[2], $label))"/>
                                <xsl:apply-templates select="$nodes[position()>2]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="normalize-space(substring-after($nodes[1], $label))"/>
                                <xsl:apply-templates select="$nodes[position()>1]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:apply-templates select="tocentry|tocdiv"/>
        </core:toc-entry>
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
    
    <xsl:template match="para[markup]">
        <xsl:apply-templates select=".//processing-instruction()"/>
    </xsl:template>
    
    <xsl:template match="para[mediaobject]">
        <xsl:variable name="path" select="mediaobject/imageobject/imagedata/@fileref"/>
        <xsl:choose>
            <xsl:when test="$path = '6018_JCQ_26-F18_MJ7-web-resources/image/Bassin.jpg'">
                <xsl:comment select="'GRAPHIC ch0018_001'"></xsl:comment>
            </xsl:when>
            <xsl:when test="$path = '6018_JCQ_26-F18_MJ7-web-resources/image/Carte.jpg'">
                <xsl:comment select="'GRAPHIC ch0018_002'"></xsl:comment>
            </xsl:when>
            <xsl:when test="$path = '6018_JCQ_26-F18_MJ7-web-resources/image/ENV_F18_Par53.png'">
                <xsl:comment select="'GRAPHIC ch0018_003'"></xsl:comment>
            </xsl:when>
            <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:transform>