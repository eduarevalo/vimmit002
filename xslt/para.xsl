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
    
    <xsl:template match="html:p[contains(@class,'N1') or contains(@class,'N2') or contains(@class,'N3') or contains(@class,'N4')]">
        <xsl:apply-templates/>            
    </xsl:template>
    
    <xsl:template match="html:span[contains(@class, 'locuspara')]">
        <emphasis role="label" xreflabel="{.}">
            <xsl:apply-templates/>
            <xsl:variable name="punctuation" select="(following-sibling::*|following-sibling::text())[1][self::text()]"/>
            <xsl:value-of select="$punctuation"/>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="text()[preceding-sibling::*[1][contains(@class, 'locuspara')]]"/>
    
    <xsl:template match="html:p">
        <xsl:variable name="indent" select="starts-with(., '&#9;')"/>
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
            <xsl:apply-templates/>            
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[@class='Markup']">
        <para>
            <markup>
                <xsl:apply-templates/>      
            </markup>      
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'Notes')]">
        <para>
            <xsl:attribute name="role">
                <xsl:value-of select="concat(@class, ' ', @style)"/>
            </xsl:attribute>
            <footnote xml:id="{generate-id()}">
                <para>
                    <xsl:apply-templates/>    
                </para>
            </footnote>      
        </para>
    </xsl:template>
    
    <xsl:template match="html:p[contains(lower-case(@class), 'titre')] | html:span[contains(lower-case(@class), 'titre')]">
        <title role="{@style}">    
            <xsl:apply-templates/>            
        </title>
    </xsl:template>
    
    <xsl:template match="html:span">
        <xsl:variable name="role">
            <xsl:value-of select="normalize-space(concat(@class, ' ', @style))"/>
        </xsl:variable>
        <xsl:variable name="label">
            <xsl:call-template name="extractLabel">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($role) > 0">
                <xsl:variable name="reference" select="normalize-space()"/>
                <xsl:variable name="referencedNode" select="./following::html:p[contains(@class, 'Notes')][starts-with(self::node(), $reference)][1]"/>
                <xsl:choose>
                    <xsl:when test="$label!='' and parent::html:p[contains(@class,'Texte')] and following-sibling::html:span[2][contains(.,'–')]">
                        <emphasis role="label" xreflabel="{$label}">
                            <xsl:apply-templates/>
                        </emphasis>
                    </xsl:when>
                    <xsl:when test="contains($role, 'Super') and text() castable as xs:decimal and ./parent::html:p[not(contains(@class, 'Notes'))] and $reference and $referencedNode">
                        <emphasis role="footnoteref">
                            <footnoteref linkend='{generate-id($referencedNode)}'/>
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
            <xsl:choose>
                <xsl:when test="@page-num ">
                    <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', @page-num ,'&quot; release-num=&quot;', @release-num ,'&quot;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', @extracted-page ,'&quot; release-num=&quot;', @release-num ,'&quot;')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="extractLabel">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" 
            regex="^\(?([0-9]*[a-z]*[A-Z]*){{1,2}}[\.|\)]">
            <xsl:matching-substring>
                <xsl:copy>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
</xsl:stylesheet>