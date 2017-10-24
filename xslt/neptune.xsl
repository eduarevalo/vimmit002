<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:template match="emphasis">
        <xsl:variable name="typestyle">
            <xsl:call-template name="getTypeStyle">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$typestyle != ''">
                <core:emph>
                    <xsl:attribute name="typestyle" select="$typestyle"/>
                    <xsl:apply-templates/>
                </core:emph>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="para">
        <xsl:param name="labelToExtract"/>
        <xsl:variable name="nodes" select="*|text()|processing-instruction()"/>
        <xsl:variable name="validNodes" select="$nodes except $nodes[last()][self::processing-instruction()] except $nodes[1][self::processing-instruction()]"/>
        <xsl:call-template name="printFirstTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="$labelToExtract">
                <core:para>
                    <xsl:apply-templates select="normalize-space(substring-after($validNodes[1], $labelToExtract))"/>
                    <xsl:apply-templates select="$validNodes[position()>1]"/>
                </core:para>
            </xsl:when>
            <xsl:otherwise>
                <core:para>
                    <xsl:apply-templates select="$validNodes"/>
                </core:para>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="printLastTextPagePI">
            <xsl:with-param name="scope" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    
    <xsl:template name="getTypeStyle">
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="contains($node/@role, 'Italic') and contains($node/@role, 'Bold')">ib</xsl:when>
            <xsl:when test="contains($node/@role, 'Bold')">bf</xsl:when>
            <xsl:when test="contains($node/@role, 'Italic')">it</xsl:when>
            <xsl:when test="contains($node/@role, 'Underline')">un</xsl:when>
            <xsl:when test="contains($node/@role, 'Small-caps')">smcaps</xsl:when>
            <xsl:when test="contains($node/@role, 'Line-through')">strike</xsl:when>
            <xsl:when test="contains($node/@role, 'Super')">su</xsl:when>
            <xsl:when test="contains($node/@role, 'SUb')">sb</xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="para[preceding-sibling::comment()[1] = 'One-Cell-Table START']">
        <fm:boxed-text>
            <core:para>
                <xsl:apply-templates/>
            </core:para>
        </fm:boxed-text>
    </xsl:template>
    
    <xsl:template name="printLastTextPagePI">
        <xsl:param name="scope"/>
        <xsl:variable name="lastPI" select="($scope//(*|text()|processing-instruction()))[last()]"/>
        <xsl:if test="$lastPI/name() = 'textpage'">
            <xsl:apply-templates select="$lastPI"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="printFirstTextPagePI">
        <xsl:param name="scope"/>
        <xsl:variable name="firstPI" select="($scope//(*|text()|processing-instruction()))[1]"/>
        <xsl:if test="$firstPI/name() = 'textpage'">
            <xsl:apply-templates select="$firstPI"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="printLastPageNumber">
        <xsl:processing-instruction name="textpage" select="concat('page-num=&quot;', count(//processing-instruction())+1 ,'&quot; release-num=&quot;', '&quot;')"/>
    </xsl:template>
    
</xsl:transform>