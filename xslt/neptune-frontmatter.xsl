<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:tr="http://www.lexisnexis.com/namespace/sslrp/tr"
    xmlns:fn="http://www.lexisnexis.com/namespace/sslrp/fn"
    xmlns:fm="http://www.lexisnexis.com/namespace/sslrp/fm"
    xmlns:core="http://www.lexisnexis.com/namespace/sslrp/core">
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:include href="neptune.xsl"/>
    
    <xsl:param name="pubNum" select="'--PUB-NUM--'"/>
    <xsl:param name="collectionTitle" select="'DROIT DE L’ENVIRONNEMENT'"/>
    <xsl:param name="prefaceFile" select="'/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/data/out/Package_1/Droit de l''environnement/xml/6018_JCQ_03-Préface_MJ9.inline.html.db.xml'"/>
    <xsl:param name="forewordFile" select="'/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/data/out/Package_1/Droit de l''environnement/xml/6018_JCQ_04-Avant-propos_MJ9.inline.html.db.xml'"/>
    <xsl:param name="featureFile" select="'/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/data/out/Package_1/Droit de l''environnement/xml/6018_JCQ_05-Notices biographiques_MJ9.inline.html.db.xml'"/>
    <xsl:param name="tocFile" select="'/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/data/out/Package_1/Droit de l''environnement/xml/6018_JCQ_06-TDMG_MJ9.inline.html.db.xml'"/>
    
    <xsl:variable name="mediaobject" select="db:part/db:info/db:cover/db:mediaobject[1] "/>
    
    <xsl:template match="/">
        
        <fm:vol-fm pub-num="{$pubNum}" volnum="1">
            <xsl:comment select="concat('pub-num=', $pubNum)"/>
            <xsl:comment select="'ch-num=fmvol--1'"/>
            <fm:body>
                <xsl:call-template name="title"/>
                <xsl:call-template name="copyright"/>
                <xsl:call-template name="preface"/>
                <xsl:call-template name="foreword"/>
                <xsl:call-template name="feature"/>
                <xsl:call-template name="toc"/>
            </fm:body>
        </fm:vol-fm>
        
    </xsl:template>
    
    <xsl:template name="title">
        <xsl:variable name="jurisClasseur" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), 'JurisClasseur')] intersect $mediaobject/preceding-sibling::db:para"/>
        <xsl:variable name="collection" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), 'collection droit')] intersect $mediaobject/preceding-sibling::db:para"/>
        <xsl:variable name="lastUpdate" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), 'mise ')] intersect $mediaobject/preceding-sibling::db:para"/>
        <xsl:variable name="directors" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), 'Directeurs')] intersect $mediaobject/preceding-sibling::db:para"/>
        <xsl:variable name="conseillers" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), 'Conseillers')] intersect $mediaobject/preceding-sibling::db:para"/>
        <xsl:variable name="title" select="db:part/db:info/db:cover/db:para[contains(normalize-space(), $collectionTitle)]"/>       
        <fm:title-pg>
            <fm:pub-series>
                <xsl:apply-templates select="$jurisClasseur"/>
                <core:nl/>
                <xsl:apply-templates select="$collection"/>
            </fm:pub-series>
            <fm:pub-title>
                <xsl:apply-templates select="$title"/>
            </fm:pub-title>
            <xsl:if test="$directors">
                <fm:byline>
                    <core:role>
                        <xsl:apply-templates select="$directors/*"/>
                    </core:role>
                    <xsl:for-each select="$directors[1]/following-sibling::db:para[contains(normalize-space(), 'Prof')] intersect $conseillers/preceding-sibling::db:para">
                        <core:person>
                            <core:name.text>
                                <xsl:apply-templates select="*"/>
                            </core:name.text>
                        </core:person>
                    </xsl:for-each>
                </fm:byline>
            </xsl:if>
            <xsl:if test="$conseillers">
                <fm:byline>
                    <core:role>
                        <xsl:apply-templates select="$conseillers/*"/>
                    </core:role>
                    <xsl:for-each select="$conseillers[1]/following-sibling::db:para[contains(normalize-space(), 'Prof')] intersect $mediaobject/preceding-sibling::db:para">
                        <core:person>
                            <core:name.text>
                                <xsl:apply-templates select="*"/>
                            </core:name.text>
                        </core:person>
                    </xsl:for-each>
                </fm:byline>
            </xsl:if>
            <fm:issued-date>
                <xsl:value-of select="$lastUpdate"/>
            </fm:issued-date>
            <fm:publisher-id>
                <fm:publisher-logo name="other"><!--LexisNexis Logo--></fm:publisher-logo>
            </fm:publisher-id>
        </fm:title-pg>
    </xsl:template>
    
    <xsl:template name="copyright">
        <xsl:variable name="copyright" select="$mediaobject/following-sibling::db:para[contains(normalize-space(), '© LexisNexis')]"/>
        <xsl:variable name="nextCopyright" select="$copyright/following-sibling::db:para[1]"/>
        <fm:copyright-pg use4template="CAN">
            <fm:copyright-info>
                <fm:copyright-info.content>
                    <core:para>
                        <xsl:for-each select="$mediaobject/following-sibling::db:para intersect $copyright/preceding-sibling::db:para">
                            <xsl:apply-templates/>
                            <xsl:if test="position()!=last()">
                                <core:nl/>
                            </xsl:if>
                        </xsl:for-each>
                    </core:para>
                    <fm:copyright-year-and-holder>
                        <xsl:value-of select="$copyright"/>
                        <core:nl/>
                        <xsl:value-of select="$nextCopyright"/>
                    </fm:copyright-year-and-holder>
                    <xsl:apply-templates select="$nextCopyright/following-sibling::db:para"/>
                </fm:copyright-info.content>
            </fm:copyright-info>
            <xsl:apply-templates select="$nextCopyright/following-sibling::db:para"/>
        </fm:copyright-pg>
    </xsl:template>
    
    <xsl:template name="preface">
        <xsl:variable name="prefaceContent" select="document($prefaceFile)"/>
        <fm:preface>
            <xsl:apply-templates select="$prefaceContent/db:part/db:partintro"/>
            <xsl:comment>TODO: Example Start</xsl:comment>
            <fm:signed>
                <fm:signed-line><fm:right><core:emph typestyle="bf">Stéphane
                    Beaulac</core:emph><core:nl/>Codirecteur de collection – Droit
                    public<core:nl/><core:emph typestyle="it">JurisClasseur
                        Québec</core:emph><core:nl/><core:nl/>Professeur titulaire et
                    spécialiste de droit public national et comparé<core:nl/>Faculté de droit,
                    Université de Montréal</fm:right></fm:signed-line>
                <fm:signed-line><fm:right><core:emph typestyle="bf">Jean-François
                    Gaudreault-DesBiens</core:emph><core:nl/>Codirecteur de collection –
                    Droit public<core:nl/><core:emph typestyle="it">JurisClasseur
                        Québec</core:emph><core:nl/><core:nl/>Professeur titulaire et
                    doyen<core:nl/>Faculté de droit, Université de
                    Montréal</fm:right></fm:signed-line>
            </fm:signed>
            <xsl:comment>TODO: Example End</xsl:comment>
        </fm:preface>
    </xsl:template>
    
    <xsl:template name="foreword">
        <xsl:variable name="forewordContent" select="document($forewordFile)"/>
        <fm:foreword>
            <xsl:apply-templates select="$forewordContent/db:part/db:partintro"/>
            <xsl:comment>TODO: Example Start</xsl:comment>
            <fm:signed>
                <fm:signed-line><fm:right><core:emph typestyle="bf">Paule
                    Halley</core:emph><core:nl/>Conseillère éditoriale<core:nl/><core:emph
                        typestyle="it">JurisClasseur Québec – Droit de
                        l’environnement</core:emph><core:nl/><core:nl/>Avocate et professeure
                    titulaire, Faculté de droit, Université Laval<core:nl/>Titulaire de la
                    Chaire de recherche du Canada en droit de
                    l’environnement</fm:right></fm:signed-line>
                <fm:signed-line><fm:right><core:emph typestyle="bf">Hugo
                    Tremblay</core:emph><core:nl/>Conseillère éditoriale<core:nl/><core:emph
                        typestyle="it">JurisClasseur Québec – Droit de
                        l’environnement</core:emph><core:nl/><core:nl/>Avocat et professeur
                    adjoint, Faculté de droit, Université de
                    Montréal</fm:right></fm:signed-line>
            </fm:signed>
            <xsl:comment>TODO: Example End</xsl:comment>
        </fm:foreword>
    </xsl:template>
    
    <xsl:template name="feature">
        <xsl:variable name="featureContent" select="document($featureFile)"/>
        <fm:feature>
            <xsl:apply-templates select="$featureContent/db:part/db:partintro"/>
        </fm:feature>
    </xsl:template>
    
    <xsl:template name="toc">
        <xsl:variable name="tocContent" select="document($tocFile)"/>
        <fm:toc>
            <xsl:apply-templates select="$tocContent/db:part/db:toc/*"/>
        </fm:toc>
    </xsl:template>
    
    <xsl:template match="db:para[contains(@role, 'Align-center')]">
        <fm:center>
            <xsl:apply-templates/>
        </fm:center>
    </xsl:template>
    
    <xsl:template match="db:para[starts-with(normalize-space(.), 'ISBN')]">
        <fm:isbn>
            <xsl:value-of select="normalize-space()"/>
        </fm:isbn>
    </xsl:template>

    <xsl:template match="db:para">
        <core:para>
            <xsl:apply-templates/>
        </core:para>
    </xsl:template>
    
    <xsl:template match="db:title[parent::db:partintro or parent::db:toc]">
        <core:title>
            <xsl:apply-templates/>
        </core:title>
        <core:title-alt use4="l-running-hd">TODO</core:title-alt>
        <core:title-alt use4="r-running-hd">TODO</core:title-alt>
    </xsl:template>
    
    <xsl:template match="db:tocentry">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates select="db:emphasis"/>
                <core:leaders blank-leader="dot" blank-use="fill"/>
                <xsl:apply-templates select="db:emphasis/following-sibling::text()"/>
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
    <xsl:template match="db:tocdiv">
        <fm:toc-entry lev="unclassified">
            <core:entry-title>
                <xsl:apply-templates />
            </core:entry-title>
        </fm:toc-entry>
    </xsl:template>
    
</xsl:transform>