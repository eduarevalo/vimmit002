const parseRTF = require('rtf-parser');
const fs = require('fs'),
    path = require('path'),
    mkdirp = require('mkdirp');

var printXml = function(element, file){
    var tagProps = getTagProperties(element),
        docProps = file ? getDocumentProperties(file) : {},
        content;
    if(element.content){
        if(!element.content.length){
            return '';
        }
        content = element.content.reduce(function(result, child){
            return result + (child ? printXml(child) : '');
        }, '');
    }else{
        if(element.value){
            content = element.value;
            //console.log(element);
        }
    }
    
    return content 
        ? tagProps.tag
        ? file
        ? `<${tagProps.tag} file="${file}" document-type="${docProps.documentType}" order="${docProps.order}">${content}</${tagProps.tag}>`
        : `<${tagProps.tag}>${escapeXml(content)}</${tagProps.tag}>`
        : escapeXml(content)
        : '';
};

var escapeXml = function(content){
    return content.replace(/[<>&'"]/g, function (c) {
        switch (c) {
            case '<': return '&lt;';
            case '>': return '&gt;';
            case '&': return '&amp;';
            case '\'': return '&apos;';
            case '"': return '&quot;';
        }
    });
};

var getDocumentProperties = function(file){
    var match = /.*JCQ_(.*)-.*/.exec(file) || {};
    var order = match[1] || 999;
    if(/.*-Instructions.*/.test(file)){
        return { documentType: 'Instructions', order: order};
    }else if(/.*-Page de titre.*/.test(file)){
        return { documentType: 'TitlePage', order: order};
    }else if(/.*-Préface.*/.test(file)){
        return { documentType: 'Preface', order: order};
    }else if(/.*-Avant-propos.*/.test(file)){
        return { documentType: 'Foreword', order: order};
    }else if(/.*-Notices biographiques.*/.test(file)){
        return { documentType: 'BiographicalNotices', order: order};
    }else if(/.*-TDMG.*/.test(file)){
        return { documentType: 'Toc', order: order};
    }else if(/.*-TDMI.*/.test(file)){
        return { documentType: 'DetailedToc', order: order};
    }else if(/.*-TDMII.*/.test(file)){
        return { documentType: 'DetailedToc', order: order};
    }else if(/.*-F[0-9]*.*/.test(file)){
        return { documentType: 'Fascicle', order: order};
    }else if(/.*-Index de.*/){
        return { documentType: 'Index', order: order};
    }else if(/.*-Index analytique.*/){
        return { documentType: 'AnalyticalIndex', order: order};
    }else if(/.*État.*/){
        return { documentType: 'PublishingState', order: order};
    }else{
        return { documentType: '?', order: order};
    }
}

var getTagProperties = function(element){
    if(!element){
        return '';
    }
    switch(element.constructor.name){
        case 'RTFDocument':
            return {tag:'document'};
        case 'RTFParagraph':
            return {tag:'paragraph'};
        case 'RTFSpan':
            return {};
        default:
            return element.constructor.name;
    }
};

var folder = './../in/JCQ_ENV/Fichiers RTF_Version courante';
var outFolder = './../out/JCQ_ENV/XML';

fs.readdir(folder, (err, files) => {
    files.forEach(file => {
        var fileName = path.basename(file, '.rtf');
        mkdirp(outFolder, function(){
            console.log(folder + "/" + file);
            parseRTF.stream(fs.createReadStream(folder + "/" + file), (err, doc) => {
                console.log(folder + "/" + file);
                if(err){
                    console.log(err);
                }else{
                    var content = printXml(doc, file);
                    fs.writeFile(outFolder + "/" + fileName + '.xml', content);
                }
            });
        });
    });
})


