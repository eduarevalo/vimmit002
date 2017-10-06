<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://docbook.org/xml/5.1/rng/docbook.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
<?xml-model href="http://docbook.org/xml/5.1/rng/docbook.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docbook.org/ns/docbook"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs db html"
    version="2.0">
   
    <xsl:include href="para.xsl"/>
    <xsl:include href="html.xsl"/>
    
    <xsl:template match="/">
        <part version="5.1">    
            <info>
                <title>
                    <xsl:apply-templates select="./html:html/html:head/html:title" />
                </title>
            </info>
            
            <xsl:call-template name="mainContent">
                <xsl:with-param name="mainContainer" select="./html:html/html:body/html:div[normalize-space()!=''][1]"/>
            </xsl:call-template>
            
            <xsl:call-template name="others">
                <xsl:with-param name="othersSet" select="./html:html/html:body/html:div[normalize-space()!=''][position()>1]"/>
            </xsl:call-template>
            
        </part>
    </xsl:template>
    
    <xsl:template name="mainContent">
        <xsl:param name="mainContainer"></xsl:param>
        
        <xsl:variable name="lastUpdateDate" select="$mainContainer/html:*[contains(@class,'Date-de-mise---jour')]"/>
        <xsl:variable name="keyPointsStart" select="$mainContainer/html:*[@class='Titres_Titre-de-section'][1]"/>
        <xsl:variable name="tocStart" select="$mainContainer/html:*[contains(@class, 'Titres_TdM')]"/>
        <xsl:variable name="indexStart" select="$mainContainer/html:*[contains(@class, 'Titres_Titre-index')]"/>
        <xsl:variable name="bodyStart" select="$mainContainer/html:*[@class='Titres_Titre-de-section-Markup'][1]"/> 
        <xsl:variable name="bibliographyStart" select="$mainContainer/html:*[@class='Titres_Titre-de-section'][2]"/>
        
        <chapter>
            
            <xsl:call-template name="title">
                <xsl:with-param name="titleSet" select="$keyPointsStart/preceding-sibling::html:*"/>
            </xsl:call-template>
            
            <xsl:call-template name="epigraph">
                <xsl:with-param name="epigraphSet" select="$lastUpdateDate/following-sibling::html:* intersect $keyPointsStart/preceding-sibling::html:*"/>
            </xsl:call-template>
            
            <xsl:call-template name="keyPoints">
                <xsl:with-param name="keyPointsEntry" select="$keyPointsStart"/>
                <xsl:with-param name="keyPointsSet" select="$keyPointsStart/following-sibling::html:p[contains(@class, '---Points')] intersect $tocStart/preceding-sibling::html:p"/>
            </xsl:call-template>
            
            <xsl:call-template name="toc">
                <xsl:with-param name="tocEntry" select="$tocStart"/>
                <xsl:with-param name="tocSet" select="$tocStart/following-sibling::html:*[contains(@class, 'TM-')] intersect $indexStart/preceding-sibling::html:*"/>
            </xsl:call-template>
            
            <xsl:call-template name="index">
                <xsl:with-param name="indexEntry" select="$indexStart"/>
                <xsl:with-param name="indexSet" select="$indexStart/following-sibling::html:*[starts-with(@class, 'N')] intersect $bodyStart/preceding-sibling::html:*"/>
                <xsl:with-param name="startOfNextSection" select="$bodyStart"/>
            </xsl:call-template>
            
            <xsl:call-template name="body">
                <xsl:with-param name="bodySet" select="$bodyStart union ($bodyStart/following-sibling::html:* except $bibliographyStart/following-sibling::html:* except $bibliographyStart)"/>
            </xsl:call-template>
            
            <xsl:call-template name="bibliography">
                <xsl:with-param name="bibliographyEntry" select="$bibliographyStart"/>
                <xsl:with-param name="bibliographySet" select="$bibliographyStart/following-sibling::html:*"/>
            </xsl:call-template>
            
        </chapter>
    </xsl:template>
    
    <xsl:template name="others">
        <xsl:param name="othersSet"/>
        <xsl:variable name="headerSet" select="$othersSet/html:*[contains(@class, 'Ent-te')]"></xsl:variable>
        <xsl:variable name="appendixSet" select="$othersSet/html:* except $headerSet"></xsl:variable>
        <xsl:if test="$headerSet">
            <colophon>
                <xsl:apply-templates select="$headerSet"/>
            </colophon>
        </xsl:if>
        <xsl:if test="$appendixSet">
            <appendix>
                <xsl:apply-templates select="$appendixSet"/>
            </appendix>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="appendix">
        <xsl:param name="appendixSet"/>
        <xsl:if test="$appendixSet">
            <appendix>
                <xsl:apply-templates select="$appendixSet/*"/>
            </appendix>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:param name="titleSet"/>
        <titleabbrev>
            <xsl:value-of select="$titleSet[@class='Fascicule'][1]"/>
        </titleabbrev>
        <title>
            <xsl:value-of select="$titleSet[contains(@class, 'Titre-du-fascicule')][1]"/>
        </title>
        <info>
            <xsl:for-each select="$titleSet[contains(@class, 'Auteur---Nom')]">
                <author>
                    <personname>
                        <xsl:apply-templates/>
                    </personname>
                    <xsl:variable name="affiliation" select="following-sibling::html:p[1][contains(@class, 'Auteur---description')]"/>
                    <xsl:if test="$affiliation">
                        <affiliation>
                            <jobtitle>
                                <xsl:value-of select="$affiliation"/>
                            </jobtitle>
                        </affiliation>
                    </xsl:if>
                </author>
            </xsl:for-each>
            
            <xsl:variable name="acknowledgments" select="$titleSet[contains(@class, 'Note-de-remerciements')]"/>
            <xsl:if test="$acknowledgments">
                <abstract>
                    <xsl:apply-templates select="$acknowledgments"/>
                </abstract>
            </xsl:if>
            
            <date>
                <xsl:value-of select="$titleSet[contains(@class,'Date-de-mise---jour')][1]"/>
            </date>
        </info>
    </xsl:template>
    
    <xsl:template name="epigraph">
        <xsl:param name="epigraphSet"/>
        <xsl:if test="$epigraphSet">
            <epigraph>
            <xsl:apply-templates select="$epigraphSet"/>
            </epigraph>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="keyPoints">
        <xsl:param name="keyPointsEntry"/>
        <xsl:param name="keyPointsSet"/>
        <sect1>
           <title>
               <xsl:value-of select="$keyPointsEntry"/>
           </title>
           <xsl:apply-templates select="$keyPointsSet"/>
       </sect1>
    </xsl:template>
    
    <xsl:template name="toc">
        <xsl:param name="tocEntry"/>
        <xsl:param name="tocSet"/>
        <sect1>
            <title>
                <xsl:value-of select="$tocEntry"/>
            </title>
            <toc>
                <xsl:for-each select="$tocSet[contains(@class, 'TM-I-')]">
                    <xsl:variable name="tocLevel1" select="."/>
                    <xsl:variable name="tocLevel2Set" select="$tocLevel1/following-sibling::html:p[contains(@class, 'TM-A-')][self::node()/preceding-sibling::html:p[contains(@class, 'TM-I-')][1] = $tocLevel1]"/>
                    <xsl:choose>
                        <xsl:when test="$tocLevel2Set">
                            <tocdiv>
                                <title>
                                    <xsl:apply-templates/>
                                </title>
                                <xsl:for-each select="$tocLevel2Set">
                                    <xsl:variable name="tocLevel2" select="."/>
                                    <xsl:variable name="tocLevel3Set" select="$tocLevel2/following-sibling::html:p[contains(@class, 'TM-1-')][self::node()/preceding-sibling::html:p[contains(@class, 'TM-A-')][1] = $tocLevel2]"/>
                                    <xsl:choose>
                                        <xsl:when test="$tocLevel3Set">
                                            <tocdiv>
                                                <title>
                                                    <xsl:apply-templates/>
                                                </title>
                                                <xsl:for-each select="$tocLevel3Set">
                                                    <xsl:variable name="tocLevel3" select="."/>
                                                    <xsl:variable name="tocLevel4Set" select="$tocLevel3/following-sibling::html:p[contains(@class, 'TM-a-')][self::node()/preceding-sibling::html:p[contains(@class, 'TM-1-')][1] = $tocLevel3]"/>
                                                    <xsl:choose>
                                                        <xsl:when test="$tocLevel4Set">
                                                            <tocdiv>
                                                                <title>
                                                                    <xsl:apply-templates/>
                                                                </title>
                                                                <xsl:for-each select="$tocLevel4Set">
                                                                    <xsl:variable name="tocLevel4" select="."/>
                                                                    <xsl:variable name="tocLevel5Set" select="$tocLevel4/following-sibling::html:p[contains(@class, 'TM--i-')][self::node()/preceding-sibling::html:p[contains(@class, 'TM-a-')][1] = $tocLevel4]"/>
                                                                    <xsl:choose>
                                                                        <xsl:when test="$tocLevel5Set">
                                                                            <tocdiv>
                                                                                <title>
                                                                                    <xsl:apply-templates/>
                                                                                </title>
                                                                                <xsl:for-each select="$tocLevel5Set">
                                                                                    <tocentry>
                                                                                        <xsl:apply-templates/>
                                                                                    </tocentry>      
                                                                                </xsl:for-each>
                                                                            </tocdiv>   
                                                                        </xsl:when>
                                                                        <xsl:otherwise>
                                                                            <tocentry>
                                                                                <xsl:apply-templates/>
                                                                            </tocentry> 
                                                                        </xsl:otherwise>
                                                                    </xsl:choose> 
                                                                </xsl:for-each>
                                                            </tocdiv>   
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <tocentry>
                                                                <xsl:apply-templates/>
                                                            </tocentry> 
                                                        </xsl:otherwise>
                                                    </xsl:choose> 
                                                </xsl:for-each>
                                            </tocdiv>   
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <tocentry>
                                                <xsl:apply-templates/>
                                            </tocentry> 
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                            </tocdiv>
                        </xsl:when>
                        <xsl:otherwise>
                            <tocentry>
                                <xsl:apply-templates/>
                            </tocentry>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </toc>
        </sect1>
    </xsl:template>
    
    <xsl:template name="index">
        <xsl:param name="indexEntry"/>
        <xsl:param name="indexSet"/>
        <xsl:param name="startOfNextSection"></xsl:param>
        <sect1>
            <title>
                <xsl:value-of select="$indexEntry"/>
            </title>
            <index>
                <xsl:variable name="index1Set" select="$indexSet[starts-with(@class,'N1')]"/>
                <xsl:for-each select="$index1Set">
                    <xsl:variable name="i" select="position()"/>
                    <xsl:variable name="innnerIndexSet" select="($index1Set[$i]/following-sibling::html:p[starts-with(@class,'N2') or starts-with(@class,'N3') or starts-with(@class,'N4')] except $index1Set[$i+1]/following-sibling::html:p) intersect $indexSet"/>
                    <indexentry>
                        <primaryie>
                            <xsl:value-of select="$index1Set[$i]"/>
                        </primaryie>
                        <xsl:if test="$innnerIndexSet and not($innnerIndexSet[starts-with(@class,'N2')])">
                            <secondaryie role="----conversion-warning----"></secondaryie>
                        </xsl:if>
                        <xsl:for-each select="$innnerIndexSet">
                            <xsl:choose>
                                <xsl:when test="starts-with(@class,'N2')">
                                    <secondaryie>
                                        <xsl:value-of select="."/>
                                    </secondaryie>
                                </xsl:when>
                                <xsl:otherwise>
                                    <tertiaryie role="{@class}">
                                        <xsl:value-of select="."/>
                                    </tertiaryie>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </indexentry>    
                </xsl:for-each>
            </index>
            <xsl:apply-templates select="$indexSet[last()]/following-sibling::html:* intersect $startOfNextSection/preceding-sibling::html:*"/>
        </sect1>
    </xsl:template>
    
    <xsl:template name="body">
        <xsl:param name="bodySet"/>
        <xsl:variable name="bodyEntries" select="$bodySet[@class='Titres_Titre-de-section-Markup']"/>
        <xsl:for-each select="$bodyEntries">
            <xsl:variable name="i" select="position()"/>
            <xsl:choose>
                <xsl:when test="$i=last()">
                    <xsl:call-template name="section1">
                        <xsl:with-param name="section1Entry" select="$bodyEntries[$i]"/>
                        <xsl:with-param name="section1Set" select="$bodyEntries[$i]/following-sibling::html:* intersect $bodySet"/>
                    </xsl:call-template>
                </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="section1">
                            <xsl:with-param name="section1Entry" select="$bodyEntries[$i]"/>
                            <xsl:with-param name="section1Set" select="$bodyEntries[$i]/following-sibling::html:* intersect $bodyEntries[$i+1]/preceding-sibling::html:*"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="bibliography">
        <xsl:param name="bibliographyEntry"/>
        <xsl:param name="bibliographySet"/>
        <xsl:if test="$bibliographyEntry">
            <sect1>
                <title>
                    <xsl:value-of select="$bibliographyEntry"/>
                </title>
                <xsl:apply-templates select="$bibliographySet"/>
            </sect1>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="section1">
        <xsl:param name="section1Entry"/>
        <xsl:param name="section1Set"/>
        <xsl:variable name="section2Set" select="$section1Set[contains(@class, 'Titres_A--Titre') or contains(@class, 'Titres_Titre-de-section')]"/>
        <sect1>
            <title>
                <xsl:value-of select="$section1Entry"/>
            </title>
            <xsl:apply-templates select="$section1Set except $section2Set[1] except $section2Set[1]/following-sibling::html:*"/>
            <xsl:for-each select="$section2Set">
                <xsl:variable name="i" select="position()"/>
                <xsl:choose>
                    <xsl:when test="$i=last()">
                        <xsl:call-template name="section2">
                            <xsl:with-param name="section2Entry" select="."/>
                            <xsl:with-param name="section2Set" select="$section2Set[$i]/following-sibling::html:* intersect $section1Set"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="section2">
                            <xsl:with-param name="section2Entry" select="."/>
                            <xsl:with-param name="section2Set" select="$section2Set[$i]/following-sibling::html:* intersect $section2Set[$i+1]/preceding-sibling::html:*"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </sect1>
    </xsl:template>
    
    <xsl:template name="section2">
        <xsl:param name="section2Entry"/>
        <xsl:param name="section2Set"/>
        <xsl:variable name="section3Set" select="$section2Set[contains(@class, 'Titres_1--Titre')]"/>
        <sect2>
            <title>
                <xsl:value-of select="$section2Entry"/>
            </title>
            <xsl:apply-templates select="$section2Set except $section3Set[1] except $section3Set[1]/following-sibling::html:*"/>
            <xsl:for-each select="$section3Set">
                <xsl:variable name="i" select="position()"/>
                <xsl:choose>
                    <xsl:when test="$i=last()">
                        <xsl:call-template name="section3">
                            <xsl:with-param name="section3Entry" select="$section3Set[$i]"/>
                            <xsl:with-param name="section3Set" select="$section3Set[$i]/following-sibling::html:* intersect $section2Set"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="section3">
                            <xsl:with-param name="section3Entry" select="$section3Set[$i]"/>
                            <xsl:with-param name="section3Set" select="$section3Set[$i]/following-sibling::html:* intersect $section3Set[$i+1]/preceding-sibling::html:*"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </sect2>
    </xsl:template>
    
    <xsl:template name="section3">
        <xsl:param name="section3Entry"/>
        <xsl:param name="section3Set"/>
        <xsl:variable name="section4Set" select="$section3Set[contains(lower-case(@class), 'titres_a--titre')]"/>
        <sect3>
            <title>
                <xsl:value-of select="$section3Entry"/>
            </title>
            <xsl:apply-templates select="$section3Set except $section4Set[1] except $section4Set[1]/following-sibling::html:*"/>
            <xsl:for-each select="$section4Set">
                <xsl:variable name="i" select="position()"/>
                <xsl:choose>
                    <xsl:when test="$i=last()">
                        <xsl:call-template name="section4">
                            <xsl:with-param name="section4Entry" select="$section4Set[$i]"/>
                            <xsl:with-param name="section4Set" select="$section4Set[$i]/following-sibling::html:* intersect $section3Set"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="section4">
                            <xsl:with-param name="section4Entry" select="$section4Set[$i]"/>
                            <xsl:with-param name="section4Set" select="$section4Set[$i]/following-sibling::html:* intersect $section4Set[$i+1]/preceding-sibling::html:*"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </sect3>
    </xsl:template>
    
    <xsl:template name="section4">
        <xsl:param name="section4Entry"/>
        <xsl:param name="section4Set"/>
        <xsl:variable name="section5Set" select="$section4Set[contains(lower-case(@class), 'titres_-i--titre')]"/>
        <sect4>
            <title>
                <xsl:value-of select="$section4Entry"/>
            </title>
            <xsl:apply-templates select="$section4Set except $section5Set[1] except $section5Set[1]/following-sibling::html:*"/>
            <xsl:for-each select="$section5Set">
                <xsl:variable name="i" select="position()"/>
                <xsl:choose>
                    <xsl:when test="$i=last()">
                        <xsl:call-template name="section5">
                            <xsl:with-param name="section5Entry" select="$section5Set[$i]"/>
                            <xsl:with-param name="section5Set" select="$section5Set[$i]/following-sibling::html:* intersect $section4Set"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="section5">
                            <xsl:with-param name="section5Entry" select="$section5Set[$i]"/>
                            <xsl:with-param name="section5Set" select="$section5Set[$i]/following-sibling::html:* intersect $section5Set[$i+1]/preceding-sibling::html:*"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </sect4>
    </xsl:template>
    
    <xsl:template name="section5">
        <xsl:param name="section5Entry"/>
        <xsl:param name="section5Set"/>
        <sect5>
            <title>
                <xsl:value-of select="$section5Entry"/>
            </title>
            <xsl:apply-templates select="$section5Set"/>
        </sect5>
    </xsl:template>
    
</xsl:stylesheet>