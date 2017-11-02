<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core"
    xpath-default-namespace="http://docbook.org/ns/docbook">
    
    <xsl:template match="emphasis">
        <xsl:param name="labelToExtract"/>
        <xsl:variable name="typestyle">
            <xsl:call-template name="getTypeStyle">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="nodes" select="text()|processing-instruction()"/>
        <xsl:variable name="righTrimmed" select="normalize-space($nodes[last()])"/>
        <xsl:choose>
            <xsl:when test="$typestyle != ''">
                <core:emph>
                    <xsl:attribute name="typestyle" select="$typestyle"/>
                    <xsl:choose>
                        <xsl:when test="$labelToExtract != ''">
                            <xsl:value-of select="substring-after(., $labelToExtract)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="$nodes">
                                <xsl:choose>
                                    <xsl:when test="position()=last()"><xsl:value-of select="concat(substring-before(., $righTrimmed), $righTrimmed)"/></xsl:when>
                                    <xsl:otherwise><xsl:apply-templates select="."/></xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </core:emph>
                <xsl:value-of select="substring-after($nodes[last()], $righTrimmed)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$labelToExtract">
                        <xsl:value-of select="substring-after(., $labelToExtract)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="text()|processing-instruction()"/>
                    </xsl:otherwise>
                </xsl:choose>
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
    
    <xsl:template match="*">
        <xsl:apply-templates select="*|text()|processing-instruction()"/>
    </xsl:template>
    
    <xsl:template match="processing-instruction()">
        <xsl:copy-of select="."></xsl:copy-of>
    </xsl:template>
    
    <xsl:template match="para[markup]">
        <xsl:apply-templates select=".//processing-instruction()"/>
    </xsl:template>
    
    <xsl:template match="table">
        <table>
            <tgroup cols="{count(colgroup/col)}">
                <xsl:apply-templates/>
            </tgroup>
        </table>
    </xsl:template>
    
    <xsl:template match="col">
        <colspec colname="col{position()}" colnum="{position()}" colsep="0"/>
    </xsl:template>
    
    <xsl:template match="thead">
        <thead>
            <xsl:apply-templates/>
        </thead>
    </xsl:template>
    
    <xsl:template match="thead/tr/td">
        <row rowsep="1">
            <entry colname="col{position()}" namest="col{position()}" nameend="col{position()}" align="center">
                <xsl:apply-templates/>
            </entry>
        </row>
    </xsl:template>
    
    <xsl:template match="tbody">
        <tbody>
            <xsl:apply-templates/>
        </tbody>
    </xsl:template>
    
    <xsl:template match="tbody/tr/td">
        <row rowsep="1">
            <entry colname="col{position()}">
                <xsl:apply-templates/>
            </entry>
        </row>
    </xsl:template>
    
    <xsl:template name="extractLabel">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" 
            regex="^\(?([0-9]*[a-z]*[A-Z]*){{1,2}}[\.|\)]">
            <xsl:matching-substring>
                <xsl:copy>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template name="extractPageNumber">
        <xsl:param name="text"/>
        <xsl:analyze-string select="normalize-space($text)" 
            regex="([0-9]+ / [0-9]+)$">
            <xsl:matching-substring>
                <xsl:copy>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:copy>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:template name="extractVolnum">
        <xsl:param name="text"/>
        <xsl:variable name="volnum">
            <xsl:analyze-string select="normalize-space($text)" 
                regex="(I|V|X)+\.">
                <xsl:matching-substring>
                    <xsl:copy>                    
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:copy>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$volnum='I.'">1</xsl:when>
            <xsl:when test="$volnum='II.'">2</xsl:when>
            <xsl:when test="$volnum='III.'">3</xsl:when>
            <xsl:when test="$volnum='IV.'">4</xsl:when>
            <xsl:when test="$volnum='V.'">5</xsl:when>
            <xsl:when test="$volnum='VI.'">6</xsl:when>
            <xsl:when test="$volnum='VII.'">7</xsl:when>
            <xsl:when test="$volnum='VIII.'">8</xsl:when>
            <xsl:when test="$volnum='IX.'">9</xsl:when>
            <xsl:when test="$volnum='X.'">10</xsl:when>
        </xsl:choose>
    </xsl:template>
    
</xsl:transform>