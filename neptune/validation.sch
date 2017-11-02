<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <sch:ns prefix="tr" uri="http://www.lexisnexis.com/namespace/sslrp/tr"/>
    <sch:ns prefix="core" uri="http://www.lexisnexis.com/namespace/sslrp/core"/>
    <sch:ns prefix="fn" uri="http://www.lexisnexis.com/namespace/sslrp/fn"/>
    
    <sch:pattern>
        
        <sch:rule context="core:title">
            <sch:assert test="normalize-space()!=''">//core:title should be no EMPTY.</sch:assert>
        </sch:rule>
        
        <sch:rule context="core:title-alt[@use4='r-running-hd' or @use4='l-running-hd']">
            <sch:assert test="normalize-space()!=''">//core:title-alt[r-running-hd | l-running-hd] should be captured.</sch:assert>
        </sch:rule>
        
        <sch:rule context="fn:endnote-id">
            <sch:let name="ref" value="@er"/>
            <sch:assert test=".//ancestor::tr:secmain[descendant::fn:endnote[@er=$ref]]">//fn:endnote-id should contain its corresponding endnote</sch:assert>
        </sch:rule>
        
        <sch:rule context="fn:endnote">
            <sch:let name="ref" value="@er"/>
            <sch:assert test=".//ancestor::tr:secmain[descendant::fn:endnote-id[@er=$ref]]">//fn:endnote should contain its corresponding endnote-id</sch:assert>
        </sch:rule>
        
    </sch:pattern>
    
</sch:schema>