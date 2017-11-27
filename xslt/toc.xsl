<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docbook.org/ns/docbook"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs db html"
    version="3.0">
    
    <xsl:include href="para.xsl"/>
    <xsl:include href="html.xsl"/>
    
    <xsl:variable name="mainContainer" select="./html:html/html:body/html:div[normalize-space()!=''][1]"/>
    
    <xsl:template match="/">
        <part version="5.1">
            <xsl:processing-instruction name="leftHeader" select="(//html:br[@left-header][@left-header!='undefined'])[1]/@left-header"/>
            <xsl:processing-instruction name="rightHeader" select="(//html:br[@right-header][@right-header!='undefined'])[1]/@right-header"/>
            <info>
                <title><xsl:apply-templates select="./html:html/html:head/html:title" /></title>
            </info>
            <toc>
                <xsl:variable name="parts" select=".//html:p[contains(@class,'Partie')]"/>
                <xsl:choose>
                    
                    <xsl:when test="$parts">
                        
                        <xsl:apply-templates select="$parts[1]/preceding-sibling::html:*"/>
                        <xsl:for-each select="$parts">
                            <xsl:variable name="i" select="position()" />
                            <xsl:call-template name="part">
                                <xsl:with-param name="part" select="."/>
                                <xsl:with-param name="partSet" select="$parts[$i]/following-sibling::html:p except $parts[$i+1]/following-sibling::html:p except $parts[$i+1]"/>
                            </xsl:call-template>
                        </xsl:for-each>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        
                        <xsl:variable name="firstTitle" select=".//html:p[contains(@class, '--Titre') ][1]"/>
                        
                        <xsl:choose>
                            <xsl:when test="$firstTitle">
                                <xsl:variable name="tocTitles" select="$firstTitle/preceding-sibling::html:*"/>
                                <xsl:apply-templates select="$tocTitles"/>
                                <xsl:call-template name="titles">
                                    <xsl:with-param name="baseSet" select="$tocTitles[last()]/following-sibling::html:p"/>
                                </xsl:call-template>  
                            </xsl:when>
                            <xsl:otherwise>
                                
                                <xsl:variable name="fascicles" select="$mainContainer//html:p[starts-with(@class,'no-fascicule') or starts-with(@class,'fascicule')]"/>
                                <xsl:apply-templates select="$fascicles[1]/preceding-sibling::html:*"/>
                                <xsl:for-each select="$fascicles">
                                    <xsl:variable name="i" select="position()" />
                                    <xsl:call-template name="fascicle">
                                        <xsl:with-param name="fascicle" select="$fascicles[$i]"/>
                                        <xsl:with-param name="fascicleSet" select="($fascicles[$i]/following-sibling::html:p except $fascicles[$i+1]/following-sibling::html:p except $fascicles[$i+1]) intersect $mainContainer//html:p[contains(@class, 'TM-')]"/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </toc>
        </part>
    </xsl:template>
    
    <xsl:template name="part">
        <xsl:param name="part"/>
        <xsl:param name="partSet"/>
        <tocdiv>
            <title role="{$part/@style}">
                <xsl:value-of select="$part"/>
            </title>
            <xsl:variable name="titles" select="$partSet[contains(@class,'--Titre') or contains(@class,'-titre')]"/>
            <xsl:choose>
                <xsl:when test="$titles">
                    <xsl:apply-templates select="$partSet except $titles[1]/following-sibling::* except $titles[1]"/>
                    <xsl:call-template name="titles">
                        <xsl:with-param name="baseSet" select="$partSet"/>
                    </xsl:call-template>        
                </xsl:when>
                <xsl:otherwise>
                    
                    <xsl:variable name="fascicles" select="$partSet[starts-with(@class,'no-fascicule') or starts-with(@class,'fascicule')]"/>
                    <xsl:choose>
                        <xsl:when test="$fascicles">
                            <xsl:apply-templates select="$fascicles[1]/preceding-sibling::html:* intersect $partSet"/>
                            <xsl:for-each select="$fascicles">
                                <xsl:variable name="i" select="position()" />
                                <xsl:call-template name="fascicle">
                                    <xsl:with-param name="fascicle" select="$fascicles[$i]"/>
                                    <xsl:with-param name="fascicleSet" select="($fascicles[$i]/following-sibling::html:p except $fascicles[$i+1]/following-sibling::html:p except $fascicles[$i+1]) intersect $mainContainer//html:p[contains(@class, 'TM-')]"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="fascicles2" select="$partSet[starts-with(@class,'nom-fascicule')]"/>
                            <xsl:for-each select="$fascicles2">
                                <xsl:variable name="i" select="position()" />
                                <xsl:call-template name="fascicle">
                                    <xsl:with-param name="fascicle" select="$fascicles2[$i]"/>
                                    <xsl:with-param name="fascicleSet" select="($fascicles2[$i]/following-sibling::html:p except $fascicles2[$i+1]/following-sibling::html:p except $fascicles[$i+1]) intersect $mainContainer//html:p[contains(@class, 'TM-')]"/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </xsl:otherwise>
            </xsl:choose>
            
        </tocdiv>
    </xsl:template>
    
    <xsl:template name="titles">
        <xsl:param name="baseSet"/>
        <xsl:variable name="titles" select="$baseSet[contains(@class,'--Titre') or contains(@class,'-titre')]"/>
        <xsl:for-each select="$titles">
            <xsl:variable name="i" select="position()" />
            <xsl:call-template name="title">
                <xsl:with-param name="title" select="."/>
                <xsl:with-param name="titleSet" select="($titles[$i]/following-sibling::html:p except $titles[$i+1]/following-sibling::html:p except $titles[$i+1]) intersect $baseSet"/>
            </xsl:call-template>    
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:param name="title"/>
        <xsl:param name="titleSet"/>
        <tocdiv>
            <xsl:apply-templates select="$title//html:br"/>
            <title role="{$title/@style}">
                <xsl:value-of select="$title"/>
            </title>
            <xsl:variable name="fascicles" select="$titleSet[starts-with(@class,'no-fascicule') or starts-with(@class,'fascicule')]"/>
            <xsl:for-each select="$fascicles">
                <xsl:variable name="i" select="position()" />
                <xsl:call-template name="fascicle">
                    <xsl:with-param name="fascicle" select="$fascicles[$i]"/>
                    <xsl:with-param name="fascicleSet" select="($fascicles[$i]/following-sibling::html:p except $fascicles[$i+1]/following-sibling::html:p except $fascicles[$i+1]) intersect $titleSet[contains(@class, 'TM-')]"/>
                </xsl:call-template>
            </xsl:for-each>
        </tocdiv> 
    </xsl:template>
    
    <xsl:template name="fascicle">
        <xsl:param name="fascicle"/>
        <xsl:param name="fascicleSet"/>
        <xsl:apply-templates select="$fascicle"/>
        <xsl:if test="$fascicleSet">
            <tocdiv>
                <xsl:apply-templates select="$fascicleSet"/>
            </tocdiv>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="html:p[starts-with(@class, 'no-fascicule') or starts-with(@class, 'fascicule')]">
        <xsl:apply-templates select=".//html:br"/>
        <tocentry>
            <emphasis role="{@class} {@style} {html:span/@style}">
                <xsl:value-of select="."/>
            </emphasis>
            <!--<xsl:variable name="text" select="following-sibling::html:p[1][starts-with(@class, 'nom-fascicule') or starts-with(@class, 'texte-fascicule')]"/>-->
            <xsl:variable name="text" select="following-sibling::html:p[1][not(contains(@class, '--Titre'))]"/>
            <xsl:if test="$text">
                <emphasis role="{$text/@class} {$text/@style} {html:span/@style}">
                    <xsl:value-of select="$text"/>
                </emphasis>
            </xsl:if>
            <xsl:variable name="name" select="following-sibling::html:p[2][starts-with(@class,'auteur') or starts-with(@class, 'nom-fascicule')]"/>
            <xsl:if test="$name">
                <emphasis role="{$name/@class} {$name/@style} {html:span/@style}">
                    <xsl:value-of select="$name"/>
                </emphasis>
            </xsl:if>
        </tocentry>
    </xsl:template>
    
    <xsl:template match="html:p[contains(., 'TDM')]">
        <xsl:apply-templates select=".//html:br"/>
        <tocentry>
            <emphasis role="{@class} {@style} {html:span/@style}">
                <xsl:value-of select="."/>
            </emphasis>
        </tocentry>
    </xsl:template>
    
    <xsl:template match="html:p[starts-with(@class, 'nom-fascicule')]">
        <xsl:apply-templates select=".//html:br"/>
        <tocentry>
            <emphasis role="{@class} {@style} {html:span/@style}">
                <xsl:value-of select="."/>
            </emphasis>
        </tocentry>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'Gros-titre') or contains(@class, 'Grand-titre')]" >
        <xsl:apply-templates select=".//html:br"/>
        <xsl:choose>
            <xsl:when test="position()=1">
                <title>
                    <xsl:value-of select="."/>
                </title>
            </xsl:when>
            <xsl:otherwise>
                <para role="{@class}">
                    
                    <xsl:value-of select="."/>
                </para>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="html:p[normalize-space()='TABLE DES MATIÈRES GÉNÉRALE' or normalize-space()='TABLE DES MATIÈRES DÉTAILLÉE']">
        <xsl:apply-templates select=".//html:br"/>
        <title>
            <xsl:value-of select="."/>
        </title>
    </xsl:template>
    
    <xsl:template match="html:p[contains(@class, 'TM-')]" >
        <xsl:apply-templates select=".//html:br"/>
        <tocentry role="{@class}">
            <xsl:apply-templates/>
        </tocentry>
    </xsl:template>
    
</xsl:stylesheet>