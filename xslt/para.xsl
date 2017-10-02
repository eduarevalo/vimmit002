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
                <xsl:value-of select="@class"/>
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
    
    <xsl:template match="html:p[contains(@class, 'Titre')] | html:span[contains(@class, 'Titre')]">
        <title>    
            <xsl:apply-templates/>            
        </title>
    </xsl:template>
    
    <xsl:template match="html:span">
        <emphasis>
            <xsl:if test="@class">
                <xsl:attribute name="role">
                    <xsl:value-of select="@class"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>            
        </emphasis>
    </xsl:template>
    
    <!--<xsl:template match="html:p/text()">
        <emphasis>
            <xsl:apply-templates/>
        </emphasis>
    </xsl:template>-->
    
</xsl:stylesheet>