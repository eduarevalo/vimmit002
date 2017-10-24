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
    
    <xsl:template match="html:p">
        <para>   
            <xsl:attribute name="role">
                <xsl:value-of select="concat(@class, ' ', @style)"/>
            </xsl:attribute>
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
    
    <xsl:template match="html:p[contains(@class, 'Titre')] | html:span[contains(@class, 'Titre')]">
        <title>    
            <xsl:apply-templates/>            
        </title>
    </xsl:template>
    
    <xsl:template match="html:span">
        <xsl:variable name="role">
            <xsl:value-of select="normalize-space(concat(@class, ' ', @style))"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($role) > 0">
                <xsl:variable name="reference" select="normalize-space()"/>
                <xsl:variable name="referencedNode" select="./following::html:p[contains(@class, 'Notes')][starts-with(self::node(), $reference)][1]"/>
                <xsl:choose>
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
        <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', @page-num ,'&quot; release-num=&quot;', @release-num ,'&quot;')"/>
    </xsl:template>
    
</xsl:stylesheet>