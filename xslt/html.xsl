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
    
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="html:p html:span"/>
    
    <xsl:template match="html:table">
        <table>  
            <xsl:copy-of select="@*[name()!='id']"/>
            <xsl:if test="@id">
                <xsl:attribute name="xml:id" select="@id"/>
            </xsl:if>
            <caption></caption>
            <xsl:apply-templates/>            
        </table>
    </xsl:template>
    
    <xsl:template match="html:table[contains(@class, 'No-Table-Style')]">
        <xsl:comment>No-Table-Style START</xsl:comment>
        <xsl:apply-templates select=".//html:td/*"/>
        <xsl:comment>No-Table-Style END</xsl:comment>
    </xsl:template>
    
    <xsl:template match="html:table[count(self::node()//html:col)=1][count(self::node()//html:tr)=1]">
        <xsl:comment>One-Cell-Table START</xsl:comment>
        <xsl:apply-templates select=".//html:td/*"/>
        <xsl:comment>One-Cell-Table END</xsl:comment>
    </xsl:template>
    
    <xsl:template match="html:colgroup|html:col|html:thead|html:tbody|html:tr|html:td">
        <xsl:element name="{name()}">  
            <xsl:copy-of select="@*[name()!='id']"/>
            <xsl:if test="@id">
                <xsl:attribute name="xml:id" select="@id"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="html:img">
        <mediaobject>
            <imageobject>
                <imagedata fileref="{@src}"/>
            </imageobject>
        </mediaobject>
    </xsl:template>
    
    <!--<xsl:template match="html:div[normalize-space()='']"/>-->
    <!--<xsl:template match="text()[normalize-space()='']"/>-->
    
    <xsl:template match="html:p/text()">
        <xsl:if test="string-length(.)>0">
            <emphasis>
                <xsl:value-of select="."/>
            </emphasis>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>