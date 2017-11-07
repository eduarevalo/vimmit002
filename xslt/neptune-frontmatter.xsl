<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:output indent="yes" doctype-public="-//LEXISNEXIS//DTD Front Matter v015//EN//XML" doctype-system="frontmatterV015-0000.dtd"/>
    
    <xsl:import href="neptune.xsl"/>
    
    <xsl:template match="para[preceding-sibling::comment()[1] = 'One-Cell-Table START']">
        <fm:boxed-text>
            <core:para>
                <xsl:apply-templates/>
            </core:para>
        </fm:boxed-text>
    </xsl:template>
    
    <xsl:template match="para[contains(@role,'text-align: center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
</xsl:transform>