<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:se="http://www.lexisnexis.com/namespace/sslrp/se"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <!--<xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Treatise-pub v021//EN//XML" doctype-system="treatiseV021-0000.dtd"></xsl:output>-->
    
    <xsl:import href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="chNum" select="'--CH-NUM--'"/>
    <xsl:param name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:param name="leftHeader" select="//processing-instruction('leftHeader')"/>
    <xsl:param name="nextPageRef"/>
    
    <xsl:variable name="keyPoints" select="/part/chapter/sect1[title/text() = 'POINTS-CLÉS']"/>
    <xsl:variable name="tocNode" select="/part/chapter/sect1[title/text() = 'TABLE DES MATIÈRES']"/>
    <xsl:variable name="indexNode" select="/part/chapter/sect1[title/text() = 'INDEX ANALYTIQUE']"/>
    <xsl:variable name="chapterNodes" select="/part/chapter/sect1 except $keyPoints except $tocNode except $indexNode"/>
    
    <xsl:template match="/">
        
        <tr:ch volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="concat('ch-num=ch', $chNum)"/>
            <xsl:call-template name="title"/>
            <xsl:call-template name="keyPoints"/>
            <xsl:call-template name="toc"/>
            <xsl:call-template name="index"/>
            <xsl:apply-templates select="$chapterNodes"/>
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
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
        
        <xsl:for-each select="/part/chapter/info/author">
            <core:byline>
                <core:person>
                    <xsl:variable name="typestyle">
                        <xsl:call-template name="getTypeStyle">
                            <xsl:with-param name="node" select="personname"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <core:name.text>
                        <xsl:choose>
                            <xsl:when test="$typestyle!=''">
                                <core:emph typestyle="{$typestyle}">
                                    <xsl:apply-templates select="personname"/>
                                </core:emph>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="personname"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </core:name.text>
                    <core:name.detail>
                        <core:role>
                            <xsl:value-of select="affiliation/jobtitle"/>
                        </core:role>
                    </core:name.detail>
                </core:person>
            </core:byline>
        </xsl:for-each>
        
        <xsl:if test="/part/chapter/info/abstract">
            <xsl:for-each select="/part/chapter/info/abstract/para">
                <xsl:variable name="footNoteId" select="(*[not(preceding-sibling::text())])[1][contains(@role,'Super')]"/>
                <xsl:choose>
                    <xsl:when test="text()[1][starts-with(normalize-space(), '*')]">
                        <fn:footnote fr="*">
                            <fn:para>
                                <xsl:value-of select="substring-after(text()[1], '*')"/>
                                <xsl:apply-templates select="(* | text() | processing-instruction()) except text()[1]"/>
                            </fn:para>
                            <xsl:variable name="nextPara" select="./parent::abstract/following-sibling::abstract[1]/para[contains(@role,'VimmitIndent')]"/> 
                            <xsl:if test="$nextPara">
                                <xsl:apply-templates select="$nextPara"/>
                            </xsl:if>
                        </fn:footnote>
                    </xsl:when>
                    <xsl:when test="$footNoteId">
                        <fn:footnote fr="{$footNoteId}">
                            <fn:para>
                                <xsl:apply-templates select="(* | text() | processing-instruction()) except $footNoteId"/>
                            </fn:para>
                            <xsl:variable name="nextPara" select="./parent::abstract/following-sibling::abstract[1]/para[contains(@role,'VimmitIndent')]"/> 
                            <xsl:if test="$nextPara">
                                <xsl:apply-templates select="$nextPara"/>
                            </xsl:if>
                        </fn:footnote>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
        <core:comment-prelim type="currentness">
            <core:para>
                <xsl:value-of select="/part/chapter/info/date"/>
            </core:para>
        </core:comment-prelim>
        <xsl:call-template name="epigraph"/>
    </xsl:template>
    
    <xsl:template match="emphasis[contains(@role, 'Super')][parent::personname]">
        <fn:footnote-id fr="{.}"/>
    </xsl:template>
    
    <xsl:template match="personname[not(child::emphasis)][ends-with(.,'*')]/text()">
        <xsl:value-of select="substring-before(.,'*')"/>
        <fn:footnote-id fr="*"/>
    </xsl:template>
    
    <xsl:template name="keyPoints">
        <xsl:if test="$keyPoints">
            <tr:ch-pt-dummy volnum="">
                <tr:secmain volnum="">
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
            <tr:ch-pt-dummy volnum="">
                <tr:secmain volnum="">
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
            <xsl:apply-templates select="$indexNode/(preceding-sibling::processing-instruction() | preceding-sibling::*)[position()=last()][self::processing-instruction()]"/>
            <tr:ch-pt-dummy volnum="">
                <tr:secmain volnum="">
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
    
    <xsl:template name="epigraph">
        <xsl:if test="/part/chapter/epigraph">
            <xsl:variable name="epigraphText">
                <xsl:call-template name="extractEpigraphText">
                    <xsl:with-param name="text" select="/part/chapter/epigraph/para"/>
                </xsl:call-template>
            </xsl:variable>
            <se:epigraph>
                <core:para>
                    <xsl:value-of select="$epigraphText"/>
                </core:para>
                <core:credit>
                    <core:credit-name>
                        <xsl:for-each select="/part/chapter/epigraph/para/* | /part/chapter/epigraph/para/text()">
                            <xsl:choose>
                                <xsl:when test="self::text()">
                                    <xsl:value-of select="substring-after(., $epigraphText)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select=".">
                                        <xsl:with-param name="labelToExtract" select="$epigraphText"/>
                                    </xsl:apply-templates>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </core:credit-name>
                </core:credit>
            </se:epigraph>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sect1|sect2|sect3|sect4|sect5">
        <xsl:variable name="runin" select="para[emphasis[@role='label' and @xreflabel] or contains(@role, 'Texte---apr-s-notes') or (contains(@role, 'Conseil-pratique') and ./preceding-sibling::para[1][footnote])]"/>
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
        <xsl:variable name="firstNode" select="title[1]"/>
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="$firstNode"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:element name="{$chapterNodeName}">
            <xsl:attribute name="volnum" select="''"/>
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
            <xsl:if test="not(self::sect1) or $runin or (self::sect1 and sect2)">
                <xsl:choose>
                    <xsl:when test="$desig != ''">
                        <core:desig value="{$desig}">
                            <xsl:value-of select="$label"/>
                        </core:desig>
                    </xsl:when>
                    <xsl:when test="not(self::sect1) or $runin">
                        <core:no-desig/>
                    </xsl:when>
                </xsl:choose>
                <core:title>
                    <xsl:value-of select="substring-after($firstNode, $label)"/>
                </core:title>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="sect2">
                    <xsl:variable name="sect2Nodes" select="$runin[not(preceding-sibling::sect2)]"/>
                    <xsl:if test="$sect2Nodes">
                        <tr:ch-ptsub1-dummy volnum="">
                            <xsl:apply-templates select="$sect2Nodes"/>
                        </tr:ch-ptsub1-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect2"/>
                </xsl:when>
                <xsl:when test="sect3">
                    <xsl:variable name="sect3Nodes" select="$runin[not(preceding-sibling::sect3)]"/>
                    <xsl:if test="$sect3Nodes">
                        <tr:ch-ptsub2-dummy volnum="">
                            <xsl:apply-templates select="$sect3Nodes"/>
                        </tr:ch-ptsub2-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect3"/>
                </xsl:when>
                <xsl:when test="sect4">
                    <xsl:variable name="sect4Nodes" select="$runin[not(preceding-sibling::sect4)]"/>
                    <xsl:if test="$sect4Nodes">
                        <tr:ch-ptsub3-dummy volnum="">
                            <xsl:apply-templates select="$sect4Nodes"/>
                        </tr:ch-ptsub3-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect4"/>
                </xsl:when>
                <xsl:when test="sect5">
                    <xsl:variable name="sect5Nodes" select="para[emphasis[@role='label' and @xreflabel] or contains(@role, 'Texte---apr-s-notes') or (contains(@role, 'Conseil-pratique') and ./preceding-sibling::para[1][footnote])][not(preceding-sibling::sect5)]"/>
                    <xsl:if test="$sect5Nodes">
                        <tr:ch-ptsub4-dummy volnum="">
                            <xsl:apply-templates select="$sect5Nodes"/>
                        </tr:ch-ptsub4-dummy>
                    </xsl:if>
                    <xsl:apply-templates select="sect5"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$runin">
                            <xsl:variable name="dummy" select="$runin[1]/preceding-sibling::para"/>
                            <xsl:if test="$dummy">
                                <tr:secmain-dummy volnum="1">
                                    <xsl:apply-templates select="$dummy"/>
                                </tr:secmain-dummy>
                            </xsl:if>
                            <xsl:apply-templates select="$runin"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="secmain">
                              <tr:secmain volnum="">
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
                            </xsl:variable>
                            <xsl:call-template name="lastParagrapSuivanthReplace">
                                <xsl:with-param name="secmain" select="$secmain"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="para[emphasis[@role='label'and @xreflabel] or contains(@role, 'Texte---apr-s-notes') or (contains(@role, 'Conseil-pratique') and ./preceding-sibling::para[1][footnote])]">
        <xsl:variable name="thisPara" select="."/>
        <xsl:variable name="emphasisLabel" select="$thisPara/emphasis[@role='label']"/>
        <xsl:variable name="label" select="$emphasisLabel/@xreflabel"/>
        <xsl:variable name="title" select="($emphasisLabel/following-sibling::emphasis[(following-sibling::*|following-sibling::text())[1][contains(.,'–')]])[1]"/>
        <xsl:variable name="titleSet" select="($title | $title/preceding-sibling::* | $title/preceding-sibling::text()) except $emphasisLabel"/>
        <xsl:apply-templates select="($emphasisLabel/* | $emphasisLabel/processing-instruction())[1][self::processing-instruction()][1]"/>
        <xsl:variable name="firstPunctuation" select="$titleSet[1][replace(.,' ','')='.' or replace(.,' ','')=')']"/>
        <xsl:variable name="secmain">
            <tr:secmain volnum="">
                <xsl:choose>
                    <xsl:when test="$emphasisLabel!=''">
                        <core:desig value="{$label}">
                            <xsl:value-of select="$emphasisLabel"/>
                            <xsl:value-of select="$firstPunctuation"/>
                        </core:desig>
                        <core:title runin="1">
                            <xsl:apply-templates select="$titleSet except $firstPunctuation"/>
                        </core:title>
                        <core:para runin="1">
                            <xsl:apply-templates select="$thisPara/(*|text()|processing-instruction()) except $emphasisLabel except $titleSet"/>
                        </core:para>
                    </xsl:when>
                    <xsl:otherwise>
                        <core:no-desig/>
                        <core:title runin="1">
                            <xsl:apply-templates />
                        </core:title>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:variable name="nextXrefLabel" select="(following-sibling::para[emphasis[@role='label' and @xreflabel] or contains(@role, 'Texte---apr-s-notes') or (contains(@role, 'Conseil-pratique') and ./preceding-sibling::para[1][footnote])])[1]"/>
                <xsl:choose>
                    <xsl:when test="$nextXrefLabel">
                        <xsl:variable name="nextNodes" select="$nextXrefLabel/(preceding-sibling::*|preceding-sibling::processing-instruction()) intersect (following-sibling::*|following-sibling::processing-instruction())"/>
                        <xsl:apply-templates select="$nextNodes"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="nextNodes" select="following-sibling::* except following-sibling::sect1 except following-sibling::sect2 except following-sibling::sect3 except following-sibling::sect4 except following-sibling::sect5"/>
                        <xsl:apply-templates select="$nextNodes"/>
                    </xsl:otherwise>
                </xsl:choose>
            </tr:secmain>
        </xsl:variable>
        <xsl:call-template name="lastParagrapSuivanthReplace">
            <xsl:with-param name="secmain" select="$secmain"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="indexentry">
        <xsl:variable name="primary" select="primaryie"/>
        <core:listitem>
            <core:para>
                <xsl:apply-templates select="$primary"/>
            </core:para>
            <!--<xsl:apply-templates select="$primary/following-sibling::processing-instruction()[1][self::processing-instruction()/preceding-sibling::primaryie[1] = $primary]"/>-->
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
    
    <xsl:template match="para[contains(@role,'Texte--num-ration')][preceding-sibling::para[1][not(contains(@role,'Texte--num-ration'))]]">
        <xsl:variable name="thisPara" select="."/>
        <core:list>
            <xsl:variable name="label">
                <xsl:call-template name="extractListItemLabel">
                    <xsl:with-param name="text" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <core:listitem>
                <core:enum>
                    <xsl:value-of select="concat(substring-before(.,$label), $label)"/>
                </core:enum>
                <core:para>
                    <xsl:apply-templates>
                        <xsl:with-param name="labelToExtract" select="concat(substring-before(.,$label), $label)"/>
                    </xsl:apply-templates>
                </core:para>
                <xsl:if test="./following-sibling::*[1][contains(@role,'Texte--num-ration2')]">
                    <core:list>
                        <xsl:variable name="limit" select="(./following-sibling::*[not(contains(@role,'Texte--num-ration2'))])[1]"/>
                        <xsl:choose>
                            <xsl:when test="$limit">
                                <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration2')] intersect $limit/preceding-sibling::para">
                                    <xsl:with-param name="controlledFlow" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration2')]">
                                    <xsl:with-param name="controlledFlow" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </core:list>
                </xsl:if>
            </core:listitem>
            <xsl:variable name="limit" select="(./following-sibling::*[not(contains(@role,'Texte--num-ration'))])[1]"/>
            <xsl:choose>
                <xsl:when test="$limit">
                    <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration') and not(contains(@role,'Texte--num-ration2'))] intersect $limit/preceding-sibling::para">
                        <xsl:with-param name="controlledFlow" select="true()"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration') and not(contains(@role,'Texte--num-ration2'))]">
                        <xsl:with-param name="controlledFlow" select="true()"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </core:list>
    </xsl:template>
    
    <!--<xsl:template match="para[contains(@role,'Texte - - num-ration2')][preceding-sibling::para[1][not(contains(@role,'Texte - - num-ration2'))]]" priority="15">
        <xsl:param name="controlledFlow" select="false()"/>
        <xsl:if test="$controlledFlow">
            <xsl:variable name="thisPara" select="."/>
            <core:list>
                <xsl:variable name="label">
                    <xsl:call-template name="extractListItemLabel">
                        <xsl:with-param name="text" select="."/>
                    </xsl:call-template>
                </xsl:variable>
                <core:listitem>
                    <core:enum>
                        <xsl:value-of select="concat(substring-before(.,$label), $label)"/>
                    </core:enum>
                    <core:para>
                        <xsl:apply-templates>
                            <xsl:with-param name="labelToExtract" select="concat(substring-before(.,$label), $label)"/>
                        </xsl:apply-templates>
                    </core:para>
                </core:listitem>
                <xsl:variable name="limit" select="(./following-sibling::*[not(contains(@role,'Texte- -num-ration2'))])[1]"/>
                <xsl:if test="$limit">
                    <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte- -num-ration2')] intersect $limit/preceding-sibling::para">
                        <xsl:with-param name="controlledFlow" select="true()"/>
                    </xsl:apply-templates>
                </xsl:if>
            </core:list>
        </xsl:if>
    </xsl:template>-->

    <xsl:template match="para[contains(@role,'Texte--num-ration')][preceding-sibling::para[1][contains(@role,'Texte--num-ration')]]">
        <xsl:param name="controlledFlow" select="false()"/>
        <xsl:if test="$controlledFlow">
            <xsl:variable name="label">
                <xsl:call-template name="extractListItemLabel">
                    <xsl:with-param name="text" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <core:listitem>
                <core:enum>
                    <xsl:value-of select="concat(substring-before(.,$label), $label)"/>
                </core:enum>
                <core:para>
                    <xsl:apply-templates>
                        <xsl:with-param name="labelToExtract" select="concat(substring-before(.,$label), $label)"/>
                    </xsl:apply-templates>
                </core:para>
                <xsl:if test="not(contains(@role, 'Texte--num-ration2')) and ./following-sibling::*[1][contains(@role, 'Texte--num-ration2')]">
                    <core:list>
                        <xsl:variable name="limit" select="(./following-sibling::*[not(contains(@role,'Texte--num-ration2'))])[1]"/>
                        <xsl:choose>
                            <xsl:when test="$limit">
                                <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration2')] intersect $limit/preceding-sibling::para">
                                    <xsl:with-param name="controlledFlow" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="./following-sibling::para[contains(@role,'Texte--num-ration2')]">
                                    <xsl:with-param name="controlledFlow" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </core:list>
                </xsl:if>
            </core:listitem>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="para[contains(@role,'Citation')][preceding-sibling::para[1][contains(@role,'Citation')]]"/>
    
    <xsl:template match="para[contains(@role,'Citation2')][preceding-sibling::para[1][not(contains(@role,'Citation2'))]]">
        <xsl:param name="controlledFlow" select="false()"/>
        <xsl:variable name="thisPara" select="."/>
        <xsl:if test="$controlledFlow">
            <core:blockquote>
                <core:blockquote-para>
                    <xsl:apply-templates/>
                </core:blockquote-para>
                <xsl:variable name="citation2Limit" select="($thisPara/following-sibling::para[not(contains(@role,'Citation2'))])[1]"/>
                <xsl:for-each select="$citation2Limit/preceding-sibling::para intersect ./following-sibling::para[contains(@role,'Citation2')]">
                    <core:blockquote-para>
                        <xsl:apply-templates/>
                    </core:blockquote-para>
                </xsl:for-each>
            </core:blockquote>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="para[markup] | para[starts-with(@role, 'Markup')]">
        <xsl:apply-templates select=".//processing-instruction()"/>
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
            <xsl:when test="contains(@role,'Citation2')"></xsl:when>
            <xsl:when test="contains(@role,'Citation')">
                <core:blockquote>
                    <core:blockquote-para>
                        <xsl:apply-templates select="$validNodes"/>
                        <xsl:if test="./following-sibling::para[1][contains(@role, 'Citation2')]">
                            <xsl:apply-templates select="./following-sibling::para[1][contains(@role, 'Citation2')]">
                                <xsl:with-param name="controlledFlow" select="true()"/>
                            </xsl:apply-templates>
                        </xsl:if>
                    </core:blockquote-para>
                    <xsl:variable name="limit" select="(following-sibling::*[not(contains(@role, 'Citation'))])[1]"/>
                    <xsl:for-each select="$limit/preceding-sibling::para[not(contains(@role, 'Citation2'))] intersect ./following-sibling::para[contains(@role,'Citation')]">
                        <core:blockquote-para>
                            <xsl:apply-templates/>
                            <xsl:if test="./following-sibling::para[1][contains(@role, 'Citation2')]">
                                <xsl:apply-templates select="./following-sibling::para[1][contains(@role, 'Citation2')]">
                                    <xsl:with-param name="controlledFlow" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:if>
                        </core:blockquote-para>
                    </xsl:for-each>
                </core:blockquote>
            </xsl:when>
            <xsl:when test="$labelToExtract">
                <core:para>
                    <xsl:apply-templates select="substring-after($validNodes[1], $labelToExtract)"/>
                    <xsl:apply-templates select="$validNodes[position()>1]"/>
                </core:para>
            </xsl:when>
            <xsl:when test="ancestor::abstract">
                <fn:para>
                    <xsl:apply-templates select="$validNodes"/>
                </fn:para>
            </xsl:when>
            <xsl:otherwise>
                <core:para>
                    <xsl:apply-templates select="$validNodes"/>
                </core:para>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="emphasis[@role='footnoteref']">
        <xsl:value-of select="substring-before(., normalize-space())"/>
        <fn:endnote-id er="{normalize-space()}" />
        <xsl:value-of select="substring-after(., normalize-space())"/>
    </xsl:template>
    
    <xsl:template match="para[footnote]">
        <xsl:param name="controlledFlow" select="false()"/>
        <xsl:variable name="hasPreviousFootnote" select="./preceding-sibling::para[1][footnote]"/>
        
        <xsl:choose>
            <xsl:when test="$hasPreviousFootnote">
                <xsl:if test="$controlledFlow">
                    <xsl:call-template name="printFirstTextPagePI">
                        <xsl:with-param name="scope" select="."/>
                    </xsl:call-template>
                    <xsl:apply-templates select="*|text()|processing-instruction()"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="printFirstTextPagePI">
                    <xsl:with-param name="scope" select="."/>
                </xsl:call-template>
                <fn:endnotes>
                    <xsl:apply-templates select="*|text()|processing-instruction()"/>
                    <xsl:variable name="limit" select="following-sibling::para[not(footnote)][1]"/>
                    <xsl:choose>
                        <xsl:when test="$limit">
                            <xsl:apply-templates select="./following-sibling::para[footnote] intersect $limit/preceding-sibling::para">
                                <xsl:with-param name="controlledFlow" select="true()"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="./following-sibling::para[footnote]">
                                <xsl:with-param name="controlledFlow" select="true()"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </fn:endnotes>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="para[parent::footnote]">
        <xsl:param name="labelToExtract"/>
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:choose>
            <xsl:when test="$nodes[1][name()='emphasis']">
                <xsl:call-template name="printFirstTextPagePI">
                    <xsl:with-param name="scope" select="$nodes[1]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="printFirstTextPagePI">
                    <xsl:with-param name="scope" select="."/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="$labelToExtract!=''">
                <fn:para>
                    <xsl:apply-templates select="$nodes except $nodes[1][self::processing-instruction()]">
                        <xsl:with-param name="labelToExtract" select="$labelToExtract"/>
                    </xsl:apply-templates>
                </fn:para>
            </xsl:when>
            <xsl:otherwise>
                <fn:para>
                    <xsl:apply-templates select="$nodes except $nodes[1][self::processing-instruction()]"/>
                </fn:para>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="footnote">
        <xsl:param name="controlledFlow" select="false()"/>
        <xsl:variable name="label">
            <xsl:call-template name="extractFootnoteLabel">
                <xsl:with-param name="text" select="./para[1]"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length(replace($label,'.','')) &lt; 3 and $label!=''">
                <fn:endnote er="{substring-before($label, '.')}">
                    <xsl:variable name="limit" select="(parent::para/following-sibling::para[footnote[matches(normalize-space(.),'^[0-9]{1,2}\.')] or not(footnote)])[1]"/>
                    <xsl:choose>
                        <xsl:when test="(./para[1]/text())[1] = substring-before($label, '.')">
                            <fn:para>
                                <xsl:apply-templates select="./para[1]/emphasis[1]">
                                    <xsl:with-param name="labelToExtract" select="'.'"/>
                                </xsl:apply-templates>
                                <xsl:apply-templates select="(./para[1]/* | ./para[1]/text()) except (./para[1]/emphasis)[1] except (./para[1]/text())[1]"/>
                            </fn:para>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates>
                                <xsl:with-param name="labelToExtract" select="$label"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$limit">
                            <xsl:apply-templates select="(parent::para/following-sibling::para[footnote] intersect $limit/preceding-sibling::para)/footnote">
                                <xsl:with-param name="controlledFlow" select="true()"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="parent::para/following-sibling::para[footnote]/footnote">
                                <xsl:with-param name="controlledFlow" select="true()"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </fn:endnote>
            </xsl:when>
            <xsl:when test="$controlledFlow">
                <xsl:apply-templates/>
            </xsl:when>
        </xsl:choose>
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
                        <xsl:apply-templates select="$nodes except $nodes[1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$nodes"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </core:entry-title>
            <xsl:apply-templates select="tocdiv"/>
        </core:toc-entry>
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
                            <xsl:when test="$firstPageNumberPI and not($firstPageNumberPI[parent::emphasis])">
                                <xsl:apply-templates select="substring-after($nodes[2], $label)"/>
                                <xsl:apply-templates select="$nodes[position()>2]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="substring-after($nodes[1], $label)"/>
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
    
    <xsl:template name="extractEpigraphText">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" 
            regex="(«.+»)">
            <xsl:matching-substring>
                <xsl:copy>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:param name="labelToExtract" select="''"/>
        <xsl:choose>
            <xsl:when test="$labelToExtract!='' and starts-with(., $labelToExtract)">
                <xsl:value-of select="substring-after(., $labelToExtract)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="para[not(contains(., 'Paragraphe suivant'))][contains(., 'Page suivant')]"/>
    
    <xsl:template match="para[contains(., 'Paragraphe suivant')]">
        <xsl:variable name="ParagrapheSuivantText">
            <xsl:choose>
                <xsl:when test="contains(., '[Paragraphe suivant')">
                    <xsl:value-of select="concat('[Paragraphe suivant', substring-after(.,'[Paragraphe suivant'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Paragraphe suivant', substring-after(.,'Paragraphe suivant'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <tr:secmain-dummy volnum="1">
            <core:comment type="other" box="1">
                <core:para>
                    <xsl:choose>
                        <xsl:when test="contains($ParagrapheSuivantText, '[Page suivant')">
                            <xsl:value-of select="substring-before($ParagrapheSuivantText,'[Page suivant')"/>
                        </xsl:when>
                        <xsl:when test="contains($ParagrapheSuivantText, 'Page suivant')">
                            <xsl:value-of select="substring-before($ParagrapheSuivantText,'Page suivant')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$ParagrapheSuivantText"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </core:para>
            </core:comment>
        </tr:secmain-dummy>
    </xsl:template>
    
    <xsl:template name="lastParagrapSuivanthReplace">
        <xsl:param name="secmain"/>
        <xsl:for-each select="$secmain/node()">
            <xsl:variable name="lastParagrapheSuivant" select="./*[not(contains(., 'Page suivante'))][last()][self::tr:secmain-dummy][contains(., 'Paragraphe suivant')]"/>
            <xsl:variable name="lastPI" select="($lastParagrapheSuivant/following-sibling::processing-instruction() | $lastParagrapheSuivant/following-sibling::*)[1]"/>
            <xsl:element name="{name()}">
                <xsl:copy-of select="(@* | node() | processing-instruction()) except $lastParagrapheSuivant except $lastPI"/>
            </xsl:element>
            <xsl:copy-of select="$lastParagrapheSuivant"/>
            <xsl:copy-of select="$lastPI"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="extractListItemLabel">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" regex="^([a-zA-Z0-9]*[-–\.\)•])">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
</xsl:transform>