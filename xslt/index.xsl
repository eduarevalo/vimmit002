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
    
    <xsl:import href="para.xsl"/>
    <xsl:import href="html.xsl"/>
  
    <xsl:template match="/">
        <part version="5.1">
            <xsl:processing-instruction name="leftHeader" select="(//html:br[@left-header][@left-header!='undefined'])[1]/@left-header"/>
            <xsl:processing-instruction name="rightHeader" select="(//html:br[@right-header][@right-header!='undefined'])[1]/@right-header"/>
            <info>
                <title><xsl:apply-templates select="./html:html/html:head/html:title" /></title>
            </info>
            <partintro>
                <xsl:apply-templates select="./html:html/html:body/*"/>
            </partintro>
        </part>
    </xsl:template>
    
    <xsl:template match="p[contains(@class, 'Index')]" priority="150">
        <index role="{@class} {@style}">
            <xsl:apply-templates/>
        </index>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class,'N1') or contains(@class,'N2') or contains(@class,'N3') or contains(@class,'N4')]">
        <index role="{@class} {@style}">
            <xsl:apply-templates/>
        </index>            
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class,'Voir-aussi')]">
        <index role="Index_N1 {@class} {@style}">
            <xsl:apply-templates/>
        </index>            
    </xsl:template>
    
    <xsl:template match="html:p[normalize-space()='INDEX ANALYTIQUE']">
        <xsl:apply-templates select=".//html:br"/>
        <title>
            <xsl:value-of select="."/>
        </title>
    </xsl:template>
    
</xsl:stylesheet>