<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes" doctype-system="frontmatterV015-0000.dtd" doctype-public="-//LEXISNEXIS//DTD Front Matter v015//EN//XML"/>
            
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="collectionTitle" select="'DROIT DE L’ENVIRONNEMENT'"/>
    
    <xsl:variable name="mediaobject" select="part/info/cover/mediaobject[1] "/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="1">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=fmvol001titre'"/>
            <fm:body>
                <xsl:call-template name="title"/>
                <xsl:call-template name="copyright"/>
                <xsl:call-template name="printLastPageNumber"/>
            </fm:body>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="title" >
        <xsl:variable name="firstPageMark" select="processing-instruction()[1]"/>
        <xsl:variable name="jurisClasseur" select="part/info/cover/para[contains(normalize-space(), 'JurisClasseur')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="collection" select="part/info/cover/para[contains(normalize-space(), 'collection droit')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="lastUpdate" select="part/info/cover/para[contains(normalize-space(), 'mise ')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="directors" select="part/info/cover/para[contains(normalize-space(), 'Directeurs')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="conseillers" select="part/info/cover/para[contains(normalize-space(), 'Conseillers')] intersect $firstPageMark/preceding-sibling::para"/>
        <xsl:variable name="title" select="part/info/cover/para[contains(normalize-space(), $collectionTitle)]"/>       
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
                        <xsl:apply-templates select="$directors/*"/>
                    </core:role>
                    <xsl:for-each select="$directors[1]/following-sibling::para[contains(normalize-space(), 'Prof')] intersect $conseillers/preceding-sibling::para">
                        <core:person>
                            <core:name.text>
                                <xsl:apply-templates select="*"/>
                            </core:name.text>
                        </core:person>
                    </xsl:for-each>
                </fm:byline>
            </xsl:if>
            <xsl:if test="$conseillers">
                <fm:byline>
                    <core:role>
                        <xsl:apply-templates select="$conseillers/*"/>
                    </core:role>
                    <xsl:for-each select="$conseillers[1]/following-sibling::para[contains(normalize-space(), 'Prof')] intersect $mediaobject/preceding-sibling::para">
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
                <fm:publisher-logo name="other"><!--LexisNexis Logo--></fm:publisher-logo>
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

    <xsl:template match="para">
        <core:para>
            <xsl:apply-templates/>
        </core:para>
    </xsl:template>
    
    <xsl:template match="title[parent::partintro or parent::toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="l-running-hd">TODO</core:title-alt>
        <core:title-alt use4="r-running-hd">TODO</core:title-alt>
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
    
</xsl:transform>