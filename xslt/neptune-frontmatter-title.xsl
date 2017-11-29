<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
           
    <xsl:import href="neptune-frontmatter.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="collectionTitle" select="'BIENS ET PUBLICITÉ'"/>
    <xsl:param name="nextPageRef"></xsl:param>
    
    <xsl:variable name="container" select="part/info/cover | part/partintro"/>
    <xsl:variable name="mediaobject" select="$container/mediaobject[1] "/>
    <xsl:variable name="rightHeader" select="//processing-instruction('rightHeader')"/>
    <xsl:variable name="leftHeader" select="//processing-instruction('leftHeader')"/>
    
    <xsl:variable name="releaseNum">
        <xsl:call-template name="extractReleaseNum"/>
    </xsl:variable>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=fmvol001'"/>
            <xsl:processing-instruction name="textpage">
                <xsl:value-of select="concat('page-num=&quot;i&quot; release-num=&quot;', $releaseNum,'&quot;')"/>
            </xsl:processing-instruction>
            <fm:body>
                <xsl:call-template name="title"/>
                <xsl:call-template name="copyright"/>
            </fm:body>
            <xsl:processing-instruction name="xpp">
                <xsl:value-of select="concat('nextpageref=&quot;', $nextPageRef, '&quot;')"/>
            </xsl:processing-instruction>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="title" >
        
        
        
        <xsl:variable name="firstPageMark" select="//mediaobject[1]"/>
        <xsl:variable name="jurisClasseur" select="$container/para[contains(normalize-space(), 'JurisClasseur')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="collection" select="$container/para[contains(normalize-space(), 'collection droit')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="lastUpdate" select="$container/para[contains(normalize-space(), 'mise ')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="directors" select="$container/para[contains(normalize-space(), 'Directeur')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="conseillers" select="$container/para[contains(normalize-space(), 'Conseiller')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="title" select="$container/para[contains(normalize-space(), $collectionTitle)]"/>       
        <fm:title-pg>
            <fm:pub-series>
                <xsl:apply-templates select="$jurisClasseur"/>
                <core:nl/>
                <xsl:apply-templates select="$collection"/>
            </fm:pub-series>
            <fm:pub-title>
                <xsl:apply-templates select="$title"/>
            </fm:pub-title>
            <xsl:if test="$directors">
                <fm:byline>
                    <core:role>
                        <xsl:apply-templates select="$directors/* | $directors/text()"/>
                    </core:role>
                    <xsl:choose>
                        <xsl:when test="$conseillers">
                            <xsl:for-each select="$directors[1]/following-sibling::para[contains(normalize-space(), 'Prof')] intersect $conseillers/preceding-sibling::para">
                                <core:person>
                                    <core:name.text>
                                        <xsl:apply-templates select="*"/>
                                    </core:name.text>
                                </core:person>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="$directors[1]/following-sibling::para[contains(normalize-space(), 'Prof')] intersect $lastUpdate/preceding-sibling::para">
                                <core:person>
                                    <core:name.text>
                                        <xsl:apply-templates select="*"/>
                                    </core:name.text>
                                </core:person>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </fm:byline>
            </xsl:if>
            <xsl:if test="$conseillers">
                <fm:byline>
                    <core:role>
                        <xsl:apply-templates select="$conseillers/* | $conseillers/text()"/>
                    </core:role>
                    <xsl:for-each select="$conseillers[1]/following-sibling::para[contains(normalize-space(), 'Prof') or contains(normalize-space(), 'Me')] intersect $mediaobject/preceding-sibling::para">
                        <core:person>
                            <core:name.text>
                                <xsl:apply-templates select="*"/>
                            </core:name.text>
                        </core:person>
                    </xsl:for-each>
                </fm:byline>
            </xsl:if>
            <fm:issued-date>
                <xsl:value-of select="$lastUpdate"/>
            </fm:issued-date>
            <fm:publisher-id>
                <fm:publisher-logo name="other">
                    <xsl:comment>LexisNexis Logo</xsl:comment>
                </fm:publisher-logo>
            </fm:publisher-id>
            
        </fm:title-pg>
    </xsl:template>
    
    <xsl:template name="copyright">
        <xsl:variable name="copyright" select="$mediaobject/following-sibling::para[contains(normalize-space(), '© LexisNexis')]"/>
        <xsl:variable name="nextCopyright" select="$copyright/following-sibling::para[1]"/>
        <xsl:variable name="nextBoxedText" select="($nextCopyright/following-sibling::para[preceding-sibling::comment()[1] = 'One-Cell-Table START'])[1]"/>
        <fm:copyright-pg use4template="CAN">
            <fm:copyright-info>
                <fm:copyright-info.content>
                    <core:para>
                        <xsl:for-each select="$mediaobject/following-sibling::para intersect $copyright/preceding-sibling::para">
                            <xsl:apply-templates/>
                            <xsl:if test="position()!=last()">
                                <core:nl/>
                            </xsl:if>
                        </xsl:for-each>
                    </core:para>
                    <fm:copyright-year-and-holder>
                        <xsl:value-of select="$copyright"/>
                        <core:nl/>
                        <xsl:value-of select="$nextCopyright"/>
                    </fm:copyright-year-and-holder>
                    <xsl:apply-templates select="$nextCopyright/following-sibling::para except $nextBoxedText except $nextBoxedText/following-sibling::para"/>
                </fm:copyright-info.content>
            </fm:copyright-info>
            <xsl:apply-templates select="$nextBoxedText"/>
            <xsl:apply-templates select="$nextBoxedText/following-sibling::para"/>
        </fm:copyright-pg>
    </xsl:template>
 
    <xsl:template match="para[contains(@role, 'Align-center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
    <xsl:template match="para[starts-with(normalize-space(.), 'ISBN')]">
        <fm:isbn>
            <xsl:value-of select="normalize-space()"/>
        </fm:isbn>
    </xsl:template>
    
    <xsl:template match="para[contains(@role,'text-align: center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
    <xsl:template match="para">
        <xsl:variable name="indent" select="contains(@role, 'VimmitIndent')"/>
        <core:para>
            <xsl:if test="$indent">
                <xsl:attribute name="indent">1st-line</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </core:para>
    </xsl:template>
    
    <xsl:template match="emphasis[parent::para[contains(@role, 'VimmitIndent')]]">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="r-running-hd"><xsl:value-of select="$rightHeader"/></core:title-alt>
        <core:title-alt use4="l-running-hd"><xsl:value-of select="$leftHeader"/></core:title-alt>
    </xsl:template>
    
    <xsl:template match="tocentry">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates select="emphasis"/>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:apply-templates select="emphasis/following-sibling::text()"/>
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="tocdiv">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates />
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template name="extractReleaseNum">
        <xsl:variable name="updateDate" select="//para[contains(., 'mise à jour')]"/>
        <xsl:variable name="releaseNum" select="normalize-space(substring-after($updateDate, '—'))"/>
        <xsl:value-of select="concat( upper-case(substring($releaseNum,1,1)), substring($releaseNum, 2))"/>
    </xsl:template>
    
    <xsl:template match="processing-instruction()"/>
    
</xsl:transform>