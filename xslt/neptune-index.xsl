<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:em="http://www.lexisnexis.com/namespace/sslrp/em"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    
    <xsl:variable name="mediaobject" select="db:part/db:info/db:cover/db:mediaobject[1] "/>
    
    <xsl:template match="/">
        
        <em:index volnum="1">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=tos001'"/>
            <xsl:apply-templates select="db:part/db:partintro"/>
        </em:index>
        
    </xsl:template>
    
</xsl:transform>