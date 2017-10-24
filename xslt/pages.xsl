<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs html"
    version="2.0">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:param name="exportFolder">/var/folders/zw/t_ng0n_s4sq669j5_l74ks1h0000gn/T/6018_JCQ_25-F17_MJ7.epub_5459M9pgUUuAVtCx/OEBPS</xsl:param>
    
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="html:p html:span"/>
    
    <xsl:template match="/">
        <output>
            <xsl:for-each select="collection(concat($exportFolder, '?select=xInline*.xhtml'))">
            <xsl:variable name="fileName" select="tokenize(document-uri(.), '/')[last()]"/>
            <xsl:if test="$fileName != 'toc.xhtml'">
                <page fileName="{$fileName}">
                    <!--<xsl:for-each-group select="html:html/html:body/html:*" group-by="@top-transform, position()">
                        <xsl:sort select="@top-transform" data-type="number"/>
                        <xsl:variable name="top" select="current-grouping-key()"/>
                        <content top="{$top}" original="{@original}">
                            <xsl:apply-templates select="/html:html/html:body/html:*[@top-transform = $top]"/>
                        </content>
                    </xsl:for-each-group>
                    -->
                    <header>
                        <xsl:for-each select="html:html/html:body/html:*[@top-transform = '1']">
                            <xsl:apply-templates />
                        </xsl:for-each>
                    </header>
                
                    <!--<xsl:choose>
                        <xsl:when test="$fileName = 'xInline.6018_JCQ_13-F06_MJ6-31.xhtml'">
                            <content position="{@original}" fileName="{$fileName}">
                                <xsl:apply-templates select="html:html/html:body/html:*[@top-transform = '2'][@original = '57']"/>
                            </content>
                            <xsl:for-each select="html:html/html:body/html:*[@top-transform = '2'][@original != '57']">
                                <content position="{@original}" fileName="{$fileName}">
                                    <xsl:apply-templates />
                                </content>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>-->
                            <xsl:for-each select="html:html/html:body/html:*[@top-transform = '2']">
                                <xsl:sort select="@original" data-type="number"/>
                                <xsl:if test="normalize-space(.) != ''">
                                    <content position="{@original}" fileName="{$fileName}">
                                        <xsl:apply-templates />
                                    </content>
                                </xsl:if>
                            </xsl:for-each>
                        <!--</xsl:otherwise>
                    </xsl:choose>-->
                
                    <footer>
                        <xsl:for-each select="html:html/html:body/html:*[@top-transform = '3']">
                            <xsl:apply-templates />
                        </xsl:for-each>
                    </footer>                    
                </page>
            </xsl:if>
        </xsl:for-each>
        </output>
    </xsl:template>
    
</xsl:stylesheet>