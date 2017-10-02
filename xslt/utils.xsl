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
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:include href="para.xsl"/>
    <xsl:include href="html.xsl"/>
  
    <xsl:template match="/">
        <toc version="5.1">    
            <title>
                <xsl:value-of select=".//html:p[contains(@class, 'Gros-titre')]" />
            </title>
            <xsl:variable name="firstPart" select=".//html:p[@class='Partie'][1]"/>
            <xsl:apply-templates select="$firstPart/preceding-sibling::html:p[contains(@class, 'nom-fascicule')]"/>
            <xsl:call-template name="parts"/>
        </toc>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'nom-fascicule') or contains(., 'TDMI')]">
        <tocentry>
            <xsl:apply-templates/>
        </tocentry>
    </xsl:template>
    
    <xsl:template name="parts">
        <xsl:variable name="parts" select=".//html:p[@class='Partie']"/>
        <xsl:for-each select="$parts">
            <xsl:variable name="i" select="position()" />
            <xsl:call-template name="part">
                <xsl:with-param name="current-p" select="$parts[$i]"/>
                <xsl:with-param name="next-p" select="$parts[$i + 1]"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="part">
        <xsl:param name="current-p"/>
        <xsl:param name="next-p"/>
        <tocdiv>
            <title>
                <xsl:apply-templates/>
            </title>
            <xsl:variable name="firstTitle" select="$current-p/following-sibling::html:p[contains(@class, '--Titre')][1]"/>
            <xsl:apply-templates select="$current-p/following-sibling::html:p[self::node()/following-sibling::html:p[self::node() = $firstTitle]]"/>
            <xsl:call-template name="titles">
                <xsl:with-param name="current-p" select="$current-p"/>
                <xsl:with-param name="next-p" select="$next-p"/>
            </xsl:call-template>
            <xsl:call-template name="fascicles">
                <xsl:with-param name="current-t" select="$current-p"/>
                <xsl:with-param name="next-t" select="$next-p"/>
            </xsl:call-template>
        </tocdiv>
    </xsl:template>
    
    <xsl:template name="titles">
        <xsl:param name="current-p"/>
        <xsl:param name="next-p"/>
        <xsl:variable name="titles" select="$current-p/following-sibling::html:p[self::node()/following-sibling::html:p[self::node() = $next-p]][contains(@class,'--Titre')]"/>
        <xsl:for-each select="$titles">
            <xsl:variable name="i" select="position()" />
            <xsl:call-template name="title">
                <xsl:with-param name="current-t" select="$titles[$i]"/>
                <xsl:with-param name="next-t" select="$titles[$i + 1]"/>
                <xsl:with-param name="next-p" select="$next-p"/>
            </xsl:call-template>    
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:param name="current-t"/>
        <xsl:param name="next-t"/>
        <xsl:param name="next-p"/>
        <tocdiv>
            <title>
                <xsl:apply-templates/>
            </title>
            <xsl:call-template name="fascicles">
                <xsl:with-param name="current-t" select="$current-t"/>
                <xsl:with-param name="next-t" select="$next-t"/>
                <xsl:with-param name="next-p" select="$next-p"/>
            </xsl:call-template>
        </tocdiv> 
    </xsl:template>
    
    <xsl:template name="fascicles">
        <xsl:param name="current-t"/>
        <xsl:param name="next-t"/>
        <xsl:param name="next-p" as="node()"/>
        <xsl:variable name="fascicles" select="$current-t/following-sibling::html:p[not(self::node()/following-sibling::html:p) or self::node()/following-sibling::html:p[(self::node() = $next-t and $next-t) or (self::node() = $next-p and $next-p and not($next-t)) or (not($next-p) and not($next-t))]][contains(@class, 'nom-fascicule')]"/>
        <xsl:for-each select="$fascicles">
            <xsl:variable name="i" select="position()" />
            <xsl:call-template name="fascicle">
                <xsl:with-param name="current-f" select="$fascicles[$i]"/>
                <xsl:with-param name="next-f" select="$fascicles[$i + 1]"/>
            </xsl:call-template>    
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="fascicle">
        <xsl:param name="current-f"/>
        <xsl:param name="next-f"/>
        <tocentry>
            <!--<xsl:variable name="text" select="$current-f/preceding-sibling::html:p[2][contains(@class, 'nom-fascicule')]"/>
            <xsl:if test="$text">
                <emphasis role="{$text/@class}">
                    <xsl:value-of select="$text"/>
                </emphasis>
            </xsl:if>
            <xsl:variable name="name" select="$current-f/preceding-sibling::html:p[1][contains(@class,'texte-fascicule')]"/>
            <xsl:if test="$name">
                <emphasis role="{$name/@class}">
                    <xsl:value-of select="$name"/>
                </emphasis>
            </xsl:if>-->
            <emphasis role="{@class}">
                <xsl:value-of select="."/>
            </emphasis>
        </tocentry> 
    </xsl:template>
    
</xsl:stylesheet>