<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://docbook.org/xml/5.1/rng/docbook.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
<?xml-model href="http://docbook.org/xml/5.1/rng/docbook.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docbook.org/ns/docbook"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs db html"
    version="3.0">
    
    <xsl:template match="html:p[contains(@class,'N1') or contains(@class,'N2') or contains(@class,'N3') or contains(@class,'N4')]">
        <xsl:apply-templates/>            
    </xsl:template>
    
    <xsl:template match="html:span[contains(@class, 'locuspara')][not(preceding-sibling::html:span[contains(@class, 'locuspara')])]">
        <emphasis role="label" xreflabel="{.}">
            <xsl:apply-templates/>
            <xsl:variable name="punctuation" select="(following-sibling::*|following-sibling::text())[1][self::text()][starts-with(.,'.')]"/>
            <xsl:if test="$punctuation">
                <xsl:value-of select="'.'"/>
            </xsl:if>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::*[1][not(preceding-sibling::html:span[contains(@class, 'locuspara')])][contains(@class, 'locuspara')]][starts-with(.,'.')]">
        <xsl:value-of select="substring-after(.,'.')"/>
    </xsl:template>
    
    <xsl:template match="html:p">
        <xsl:variable name="indent" select="starts-with(., '&#9;')"/>
        <xsl:variable name="nodes" select="* | text()"/>
        <xsl:variable name="firstTextNode" select="($nodes[not(self::html:br or self::html:a)])[1][self::text() or self::html:span[not(contains(@class, 'locuspara'))]]"/>
        <para>
            <xsl:choose>
                <xsl:when test="$indent">
                    <xsl:attribute name="role">
                        <xsl:value-of select="concat('VimmitIndent ', @class, ' ', @style)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="role">
                        <xsl:value-of select="concat(@class, ' ', @style)"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:variable name="label">
                <xsl:call-template name="extractLabel">
                    <xsl:with-param name="text" select="$firstTextNode"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="$label!='' and contains(@class,'Texte') and ($nodes[not(self::html:br)][position()=3 or position()=4][starts-with(replace(normalize-space(.),' ',''),'–')] or $nodes[self::text()][normalize-space()!=''][2][starts-with(replace(normalize-space(.),' ',''),'–')] or $nodes[self::html:span][1][ends-with(replace(normalize-space(.),' ',''), '–')])">
                    <emphasis role="label" xreflabel="{$label}">
                        <xsl:apply-templates select="$firstTextNode"/>
                    </emphasis>
                    <xsl:apply-templates select="$nodes except $firstTextNode"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>       
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[@class='Markup' or starts-with(@class,'Markup') or starts-with(@class,'Titres_Markup')]">
        <para>
            <markup>
                <xsl:apply-templates/>      
            </markup>      
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'Notes2')]" priority="150"/>
    
    <xsl:template match="html:p[@class='Notes']/html:span[contains(@class, 'Footnote-reference')]">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'Notes')]">
        <para>
            <xsl:attribute name="role">
                <xsl:value-of select="concat(@class, ' ', @style)"/>
            </xsl:attribute>
            <xsl:variable name="limit" select="(following-sibling::*[not(contains(@class, 'Notes2'))])[1]"/>
            <footnote xml:id="{generate-id()}">
                <para>
                    <xsl:apply-templates/>    
                </para>
                <xsl:for-each select="(following-sibling::* | following-sibling::processing-instruction()) intersect ($limit/preceding-sibling::* | $limit/preceding-sibling::processing-instruction())">
                    <para>
                        <xsl:apply-templates/>
                    </para>
                </xsl:for-each>
            </footnote>      
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[contains(lower-case(@class), 'titre') and not(contains(@class, 'Texte---avant-titre'))] | html:span[contains(lower-case(@class), 'titre')]">
        <title role="{@style}">    
            <xsl:apply-templates/>            
        </title>
    </xsl:template>
    
    <xsl:template match="html:span[normalize-space()='.']">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="html:span">
        <xsl:variable name="role">
            <xsl:value-of select="normalize-space(concat(@class, ' ', @style))"/>
        </xsl:variable>
        <xsl:variable name="label">
            <xsl:if test="not(preceding-sibling::text()[normalize-space()!=''])">
                <xsl:call-template name="extractLabel">
                    <xsl:with-param name="text" select="."/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($role) > 0">
                <xsl:variable name="reference" select="normalize-space()"/>
                <xsl:variable name="notesStart" select="(./parent::html:p/following-sibling::html:p[contains(@class, 'Notes')])[1]"/>
                <xsl:variable name="notesLimit" select="$notesStart/following-sibling::html:p[not(contains(@class, 'Notes'))][1]"/>
                <xsl:variable name="notesSet" select="./parent::html:p/following-sibling::html:p[contains(@class, 'Notes')] except $notesLimit except $notesLimit/following-sibling::*"/>
                <xsl:variable name="referencedNode" select="$notesSet[starts-with(replace(normalize-space(.),' ',''), $reference)][1]"/>
                <xsl:choose>
                    <xsl:when test="contains($role, 'Super') and text() castable as xs:decimal and ./parent::html:p[not(contains(@class, 'Notes'))] and $reference and $referencedNode">
                        <emphasis role="footnoteref">
                            <footnoteref linkend='{generate-id($referencedNode)}'/>
                            <xsl:apply-templates/>
                        </emphasis>
                    </xsl:when>
                    <xsl:when test="$label!='' and parent::html:p[contains(@class,'Texte')] and (./following-sibling::html:span[2][contains(.,'–')] or ./following-sibling::text()[1][starts-with(replace(normalize-space(.),' ',''), '–')])  and not(./preceding-sibling::html:span[contains(@class, 'locuspara')])">
                        <emphasis role="label" xreflabel="{$label}">
                            <xsl:apply-templates/>
                        </emphasis>
                    </xsl:when>
                    <xsl:otherwise>
                        <emphasis role="{$role}">
                            <xsl:apply-templates/>
                        </emphasis>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="html:br[@injected]">
        <xsl:if test="not(@left-header)">
            <xsl:variable name="release">
                <xsl:if test="@release-num!='undefined'"><xsl:value-of select="@release-num"/></xsl:if>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="@page-num">
                    <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', @page-num ,'&quot; release-num=&quot;', $release ,'&quot;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', @extracted-page ,'&quot; release-num=&quot;', $release ,'&quot;')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="extractLabel">
        <xsl:param name="text"/>
        <xsl:variable name="firstTry">
            <xsl:analyze-string select="normalize-space($text)" regex="^([0-9]{{1,3}}\.?[0-9]?)\.?(?:\s+| |$)">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$firstTry!=''">
                <xsl:value-of select="$firstTry"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:analyze-string select="normalize-space($text)" regex="^([a-zA-Z]{{1,2}})\)(?:\s+| |$)">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>