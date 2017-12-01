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
  
    <xsl:variable name="firstTitle" select="(./html:html/html:body//html:p[normalize-space()!=''][contains(lower-case(@class), 'titre')])[1]"/>
    <xsl:variable name="directors" select="$firstTitle/following-sibling::html:p[contains(upper-case(normalize-space(.)), 'DIRECTEURS DE COLLECTION') or contains(upper-case(normalize-space(.)), 'DIRECTEUR DE COLLECTION')][1]"/>
    <xsl:variable name="conseillers" select="$directors/following-sibling::html:p[contains(upper-case(normalize-space(.)), 'CONSEILLERS')][1]"/>
    <xsl:variable name="authors" select="$conseillers/following-sibling::html:p[contains(upper-case(normalize-space(.)), 'AUTEURS')][1]"/>
  
    <xsl:template match="/">
        <part version="5.1">   
            <xsl:processing-instruction name="leftHeader" select="(//html:br[@left-header][@left-header!='undefined'])[1]/@left-header"/>
            <xsl:processing-instruction name="rightHeader" select="(//html:br[@right-header][@right-header!='undefined'])[1]/@right-header"/>
            <info>
                <title><xsl:apply-templates select="./html:html/html:head/html:title" /></title>
            </info>
            <partintro>
                <xsl:apply-templates select="$firstTitle"/>
                <sect1>
                    <xsl:apply-templates select="$directors"/>
                    <xsl:apply-templates select="$directors/following-sibling::html:* except $conseillers except $conseillers/following-sibling::html:*"/>
                </sect1>
                <sect1>
                    <xsl:apply-templates select="$conseillers"/>
                    <xsl:apply-templates select="$conseillers/following-sibling::html:* except $authors except $authors/following-sibling::html:*"/>
                </sect1>
                <sect1>
                    <xsl:apply-templates select="$authors"/>
                    <xsl:apply-templates select="$authors/following-sibling::html:*"/>
                </sect1>
            </partintro>
        </part>
    </xsl:template>
    
</xsl:stylesheet>