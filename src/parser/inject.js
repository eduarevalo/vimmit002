const fs = require('fs'),
    tmp = require('tmp'),
    saxon = require('./../saxon'),
    _ = require('lodash'),
    exec = require('child_process').exec,
    inlineCss = require('inline-css'),
    util = require('util'),
    htmlparser = require("htmlparser2"),
    Entities = require('html-entities').XmlEntities,
    entities = new Entities();

const runJsxCommand = '"/Applications/Adobe\ ExtendScript\ Toolkit\ CC/ExtendScript\ Toolkit.app/Contents/MacOS/ExtendScript\ Toolkit" -run ';

const fsReadFile = util.promisify(fs.readFile),
    fsReadDir = util.promisify(fs.readdir),
    fsWriteFile = util.promisify(fs.writeFile);

function createFilter(filter){
    return function(input){
        return (new RegExp(filter)).test(input);
    }
}

function encodeXmlEntities(input){
    return entities.encode(input);
    return input.replace(/\&/g, '&amp;')
        .replace(/\</g, '&lt;')
        .replace(/\>/g, '&gt;')
        .replace(/\"/g, '&quot;')
        .replace(/\'/g, '&apos;');
}

function decodeXmlEntities(input){
    return input.replace(/&amp;/g, '&')
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, "\"")
        .replace(/&apos;/g, "'");
}

function normalizePath(path){
    return path;
    return path.replace(' ', '_', '\'', '');
}

function encodeXmlVimmitEntities(input){
    return input
        .replace(/&amp;/g, '--vimmit-trap--amp;')
        .replace(/&lt;/g, '--vimmit-trap--lt;')
        .replace(/&gt;/g, '--vimmit-trap--gt;')
        .replace(/&quot;/g, '--vimmit-trap--quot;')
        .replace(/&apos;/g, '--vimmit-trap--apos;');
}

function decodeXmlVimmitEntities(input){
    return input.replace(/--vimmit-trap--amp;/g, '&amp;')
        .replace(/--vimmit-trap--lt;/g, '&lt;')
        .replace(/--vimmit-trap--gt;/g, '&gt;')
        .replace(/--vimmit-trap--quot;/g, '&quot;')
        .replace(/--vimmit-trap--apos;/g,'&apos;');
}

function hexEncodeChar(input, i){
    var hex = input.charCodeAt(i).toString(16);
    return("000"+hex).slice(-4);
}

//.replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\x2029|\x2e/g, '')
var charsToOmit = ['0020', '0009', '00ad', '002d', '000a', '00a0', '2029', '002e'];

/*function validateStrings(stringA, stringB, iterators){
    var charA = stringA.charAt(iterators.A),
        charB = stringB.charAt(iterators.B);
    if(charA === charB){
        iterators.A++;
        iterators.B++;
        return true;
    }
    console.log(iterators.A, iterators.B, iterators.page, 'HTML:', stringA.substr(iterators.A, 10), 'Pages:', stringB.substr(iterators.B, 10), 'Page:', iterators.page, iterators.fileName);
    return false;
}*/
function validateStrings(stringB, iterators){
    var charA = iterators.text.charAt(0),
        charB = stringB.charAt(iterators.B),
        charAHex,
        charBHex
        result = false;

    if(charA === charB){
        iterators.out += encodeXmlEntities(charA);
        iterators.text = iterators.text.substr(1);
        iterators.B++;
        result = true;
    }else{
        charAHex = hexEncodeChar(iterators.text, 0);
        if(charsToOmit.indexOf(charAHex) >= 0){
            iterators.out += encodeXmlEntities(charA);
            iterators.text = iterators.text.substr(1);
            result = true;
        }
        /*charBHex = hexEncodeChar(stringB, iterators.B);
        if(charsToOmit.indexOf(charBHex) >= 0){
            iterators.B++;
            result = true;
        }*/
    }
    if(!result){
        console.log(iterators.B, iterators.page, 'HTML:', iterators.text.substr(0, 10), 'Pages:', stringB.substr(iterators.B, 10), charAHex, charBHex, 'Page:', iterators.page, iterators.fileName);
        //process.exit();
    }
    return result;
}

function inlineHtmlParser(html){
    var replaces = {
        // HTML TAGS FIXES
        //'<meta charset="utf-8">': '<meta charset="utf-8"/>',
        '<(img|col|meta|hr) ([a-z]*="[^"]*" ?)*>': function(match){ return match.substring(0, match.length - 1) + '/>'; },
        '<br\s*>': '<br/>',
        
        // STYLES REPLACE
        '-epub-hyphens: (auto|none);': '',
        'border-collapse: [^;]*;': '',
        'border-color: ([^;]*);': '',
        'border-style: [^;]*;': '',
        'border-width: ([0-9]*)(px|);': '',
        'background-color: ([^;]*);': function(match, p1, p2){ return `BgColor-${p1}`; },
        'color: ([^;]*);': '',
        "font-family: [^;]*;": '',
        'font-size: ([0-9]*)(px|%);': '',
        'font-style: (normal|italic|oblique);': function(match, p1){ 
            if(p1 === 'normal'){
                return '';
            }
            return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); 
        },
        'font-variant: ([^;]*);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
        'font-weight: (bold|normal);': function(match, p1){ 
            if(p1 === 'normal'){
                return '';
            }
            return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); 
        },
        'line-height: ([0-9]*)(\.[0-9]*)?;': function(match, p1, p2){ return `LineHeight-${p1}${p2}`; },
        'margin: ([0-9]*)(px|);': '',
        'margin-bottom: -?([0-9]*)(px|auto|);': '',
        'margin-left: -?([0-9]*)(px|auto|);': '',
        'margin-right: -?([0-9]*)(px|auto|);': '',
        'margin-top: -?([0-9]*)(px|auto|);': '',
        'orphans: ([0-9]*);': '',
        'padding: ([0-9]*);': '',
        'page-break-after: auto;': '',
        'page-break-after: avoid;': 'AvoidPageBreakAfter',
        'page-break-before: auto;': '',
        'page-break-before: avoid;': 'AvoidPageBreakBefore',
        'text-align: (justify|center|right|left);': function(match, p1){ return `Align-${p1}`; },
        'text-align-last: (justify|center|right|left);': function(match, p1){ return `AlignLast-${p1}`; },
        'text-decoration: none;': '',
        'text-indent: -?([0-9]*)(px|);': '',
        'text-decoration: ([^;]*);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
        'text-transform: none;': '',
        'text-transform: uppercase;': 'Upper',
        'widows: ([0-9]*);': '',
        'vertical-align: (super|sub);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
        'display: inline-block;':'',
        'height: ([0-9]*)(px|);': function(match, p1){ return `Height-${p1}`; },
        'position: relative;':'',
        'width: ([0-9]*)(px|);': function(match, p1){ return `Width-${p1}`; },
        
        // AFTER FIXES
        /*'style="([^"]*)"': function(match, p1){ 
            var values = p1.replace(/\s\s+/g, ' ').trim().split(' ');
            if(values.indexOf('Italic')>=0 && values.indexOf('Bold')>=0){
                removeStyle(values, 'Italic');
                removeStyle(values, 'Bold');
                values.push('ib');
            }else if(values.indexOf('Super')>=0){
                removeStyle(values, 'Super');
                values.push('su');    
            }else if(values.indexOf('Sub')>=0){
                removeStyle(values, 'Sub');
                values.push('sb');    
            }else if(values.indexOf('Bold')>=0){
                removeStyle(values, 'Bold');
                values.push('bf');
            }else if(values.indexOf('Italic')>=0){
                removeStyle(values, 'Italic');
                values.push('it');
            }else if(values.indexOf('Underline')>=0){
                removeStyle(values, 'Underline');
                values.push('un');
            }else if(values.indexOf('Small-caps')>=0){
                removeStyle(values, 'Small-caps');
                values.push('smcaps');
            }else if(values.indexOf('Line-through')>=0){
                removeStyle(values, 'Line-through');
                values.push('strike');
            }
            
            removeStyle(values, 'Normal');
            //console.log(values);
            if(values.length > 0){
                return `style="${values.join(' ')}"`;
            }
            return '';
        },*/
        'CharOverride-([0-9]*)': ''
    };
    var output = html;
    for(var key in replaces){
        output = output.replace(new RegExp(key, 'gi'), replaces[key]);
    }
    return output;
}

function filterInvalidFiles(input){
    return !createFilter('\.DS_Store$|.*\.json$')(input);
}

function inlineCssParser(html){
    var replaces = {
        // HTML TAGS FIXES
        '<(img|col|meta|hr) ([a-z]*="[^"]*" ?)*>': function(match){ return match.substring(0, match.length - 1) + '/>'; },
        '<br\s*>': '<br/>',
        'style=\"([^\"]*)\"': function(matched, content){ 
            var found = content.match(/-webkit-transform: translate\([0-9|\.]*px,([0-9|\.]*)px\)/);
            if(found){
                var position = parseInt(found[1]), lastPosition;
                if( position >= 649){
                    lastPosition = 3;
                }else if( position < 30){
                    lastPosition = 1;
                }else{
                    lastPosition = 2;
                }
                return `style="${content}" top-transform="${lastPosition}" original="${position}"`; 
            }
            return `style="${content}"`; 
        }
    };
    var output = html;
    for(var key in replaces){
        output = output.replace(new RegExp(key, 'gi'), replaces[key]);
    }
    
    return output;
}

function createInlineCSSFile(path, fileIn, fileOut){
    return fsReadFile(path + fileIn, 'utf8')
        .then(function (htmlData) {
            return inlineCss(htmlData, { url: 'file:///' + path })
                .then(inlineCss => {
                    return fsWriteFile(path + fileOut, inlineCssParser(inlineCss), 'utf8')
                        .then(() => {
                            return path + fileOut;
                        });
                })
        });
}

function injectXhtmlFiles(path, resolve){
    return fsReadDir(path + '/OEBPS')
        .then( files => {
            return Promise.all(
                files
                    .filter( file => /\.xhtml$/.test(file) )
                    .filter( file => !/^xInline\./.test(file) )
                    .filter( file => file != 'toc.xhtml' )
                    .map( file => {
                        return createInlineCSSFile(path + '/OEBPS/', file, 'xInline.' + file) 
                    })
            );
        });
};

function injectEpubFiles(path, collection, collectionPath, filter){
    return fsReadDir(collectionPath)
        .then(files => {

            return _.reduce(
                
                files
                    .filter( file => filter.test(file) )
                    .filter( file => !/Instructions/.test(file))
                    .filter( createFilter('^folder_') ), 

                ( promise, epubFolder ) => {
                    return promise.then(() => {
                        var epubFolderPath = collectionPath + '/' + epubFolder;
                        return processFile(path, collection, epubFolderPath);
                    });
                }, 
                Promise.resolve()
            );

    });
}

function processFile(path, collection, epubFolderPath){
    return injectXhtmlFiles(epubFolderPath)
    .then( () => {
        return saxon
            .exec({
                xmlPath: __dirname + '/../../xslt/empty.xml', 
                xslPath: __dirname + '/../../xslt/pages.xsl',
                params: {
                    "exportFolder": epubFolderPath + '/OEBPS'
                }
            })
            .then( response => response.stdout )
            .then( (content) => { 
                return { content, epubFolderPath };
            });
    }).then( (conversion) => {
        var fileName = _.last(conversion.epubFolderPath.split('/')).replace('folder_', '');
        return new Promise(function(resolve, reject){

            var htmlFilePath = [path, collection, 'html/'].join('/') + fileName + '.html';
            
            injectInlineHtml([path, collection, 'html/'].join('/'), fileName + '.html')
                .then( htmlData => {
                    
                    injectPages(conversion.content, htmlData, htmlFilePath, fileName, resolve);
                    
                });
            

        }).then( injectProcess => {
            var outFilePath = [path, collection, 'html', fileName + '.inline.html'].join('/');
            var error = injectProcess.error ? 'Error: ' + injectProcess.error + ' - ' + injectProcess.text : '';
            console.log('File:', _.last(outFilePath.split('/')), 'Pages:', injectProcess.pageCount, error);
            return fsWriteFile(outFilePath, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + injectProcess.content, 'utf8');
        });

    });
}

function compileTexts(pages, filename){
    var file = _.first(_.split(_.last(_.split(filename, '/')), '.'));
    var order = {
        /*'6018_JCQ_02-Page de titre et catalogage_MJ9' : { '1': [2,1,3,0] },
        '6018_JCQ_28-F06_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F07_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F08_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F10_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F13_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F14_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F15_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F18_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F20_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F22_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F24_MJ9': { '1': [0,2,1]},
        '6018_JCQ_28-F26_MJ9': { '1': [0,2,1]}*/
    };
    for(var key in pages){
        if(order[file] && order[file][key]){
            
            var texts = _.compact(pages[key].contents);   
            for(var it=0; it<order[file][key].length; it++){
                pages[key].text += texts[order[file][key][it]];
            }
            
        }else{
            pages[key].text = _.join(pages[key].contents, '');
        }
        delete pages[key].contents;
    }
}

function injectPageNumbers(htmlData, pages, fileName, resolve){
    
    var iterators = {
        A: 0,
        B: 0,
        text: undefined,
        fileName: fileName,
        html: htmlData,
        pages: pages,
        page: 1,
        out: ''
    };

    var onBody = false,
        onTable = false,
        onTHead = false,
        onMarkup = false,
        tHeadText = "",
        currentContent,
        hasMoreContents,
        error = false,
        errorText = '',
        insertFirst = true,
        canExcludeText = false,
        exclusions = 0,
        textAlreadyExcluded = false,
        insertNextPageBreak = true;

    var parser = new htmlparser.Parser({
        onopentag: function(name, attribs){
            onMarkup = false;
            if(name === "body"){
                onBody = true;
            }else if(name === "table"){
                onTable = true;
            }else if(name === "thead"){
                onTHead = true;
            }else if(name === "p" && attribs["class"] === "Markup"){
                onMarkup = true;
            }

            if(!textAlreadyExcluded && name === 'div'){
                if(!/Page de titre/.test(fileName)){
                    canExcludeText = true;
                }
            }

            iterators.out += `<${name}`;
            for(var key in attribs){
                iterators.out += ` ${key}="${encodeXmlEntities(attribs[key])}"`;
            }
            iterators.out += `>`;
        },
        ontext: function(text){

            if(onMarkup && text === "JBPD-20.4"){
                //return;
                console.log('error');
            }

            if(onTHead){
                tHeadText += text;
            }
            
            if(text.replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, '') == "" || error || _.get(currentContent, 'lastPage')){
                iterators.out += encodeXmlEntities(text);
                return;
            }

            //console.log('canExcludeText', canExcludeText, 'textAlreadyExcluded', textAlreadyExcluded, text);

            if(canExcludeText){
                if(/[0-9]{4}/.test(text) || (/[IVX]+\.\s/.test(text) || exclusions === 1) || /Suite: /.test(text) || /…/.test(text)){
                    textAlreadyExcluded = true;
                    exclusions++;
                    return;
                }else{
                    canExcludeText = false;
                }
            }

            var insertPageBreak = function(page){
                if(pages[page]){
                    //console.log("CHANGE", page);
                    var footer = pages[page].footer.trim(),
                        pageNo,
                        ofPages,
                        release;
                    var match = footer.match(/^\([0-9]*\)([A-ZÉ0-9\-]+)\s\/\s([0-9]*)(\D*\s[0-9]{4})?$/);
                    //var match = release.match(/^[\r\n ]*\([0-9]*\)[A-Z0-9]*\s\/\s[0-9]*\s*(\D*\s[0-9]{4})[\r\n ]*$/);
                    if(match){
                        pageNo = match[1];
                        ofPages = match[2];
                        release = match[3];
                    }
                    //console.log('----------------------------------->', pageNo, ofPages, release, pages[iterators.page].footer);
                    //if(page % 2 === 1){
                        if(pageNo && ofPages){
                            //console.log(`<?textpage page-num="${page}" release-num="Août 2017"?>`);
                            if(pages[page] && pages[page].header){
                                if(pages[page].header.right){
                                    iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" right-header="${pages[page].header.right}" extracted-page="${page}" release-num="${release}" footer="${footer}" />`;
                                }else if(pages[page].header.left){
                                    iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" left-header="${pages[page].header.left}" extracted-page="${page}" release-num="${release}" footer="${footer}" />`;
                                }else{
                                    iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" extracted-page="${page}" release-num="${release}" footer="${footer}" />`;
                                }
                            }else{
                                iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" extracted-page="${page}" release-num="${release}" footer="${footer}" />`;
                            }
                        }else{
                            iterators.out += `<br injected="true" extracted-page="${page}" release-num="${release}" footer="${footer}" />`;
                        }
                    //}
                }
                iterators.page = page;
                iterators.B = 0;
                insertNextPageBreak = false;
            }

            var evaluatePageChange = function(){
                if(pages[iterators.page] && currentContent.text.length === iterators.B){
                    insertNextPageBreak = true;
                }
            }

            if(onBody){

                if(insertFirst){
                    insertPageBreak(1);
                    insertFirst = false;
                }
                
                function pickCurrentContent(text){
                    if(iterators.B === 0){
                        while(pages[iterators.page] && pages[iterators.page].contents.length === 0){
                            insertPageBreak(iterators.page + 1);
                        }
                        if(pages[iterators.page]){
                            var availableContents = _.filter(pages[iterators.page].contents, { visited: false });
                            
                            hasMoreContents = _.size(availableContents) > 1;
                            if(_.size(availableContents) > 0){    
                                currentContent = _.find(availableContents, function(content){ 
                                    if(onTable){
                                        var thead = tHeadText.replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, '');
                                        if(_.startsWith(content.text, thead)){
                                            content.text = content.text.substr(_.size(thead));
                                        }
                                    }
                                    return _.startsWith(content.text, text.replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, '')); 
                                });
                                if(currentContent == undefined){
                                    errorText = text;
                                    currentContent = {error: true, page: iterators.page, text: text};
                                    return;
                                }
                                currentContent.visited = true;
                                return;
                            }
                        }
                        currentContent = {lastPage: true};
                    }
                }
                
                for(var it=0;  it<text.length; it++){
                    if(text.substr(it).replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, '') == "" || _.get(currentContent, 'error') || _.get(currentContent, 'lastPage')){
                        iterators.out += encodeXmlEntities(text.substr(it));
                        break;
                    }
                    var char = text.charAt(it);
                    if(char.replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, '') == ""){
                        iterators.out += encodeXmlEntities(char);
                    }else{
                        if(insertNextPageBreak){
                            insertPageBreak(iterators.page + 1);
                        }
                        pickCurrentContent(text.substr(it));
                        if(currentContent.error){
                            iterators.out += encodeXmlEntities(char);
                            error = true;
                        }else if(currentContent.lastPage){
                            iterators.out += encodeXmlEntities(char);
                            iterators.B++;
                        }else{
                            var charB = currentContent.text.charAt(iterators.B);
                            if(char === charB){
                                iterators.out += encodeXmlEntities(char);
                                iterators.B++;
                            }
                        }
                    }
                    if(!currentContent.lastPage){
                        if(!error && !hasMoreContents){
                            evaluatePageChange();
                        }
                        if(currentContent.text.length === iterators.B){
                            iterators.B = 0;
                        }
                    }
                }
                
            }else{
                iterators.out += encodeXmlEntities(text);
            }
            
        },
        onclosetag: function(name){
            if(name === "body"){
                onBody = false;
            }else if(name === "table"){
                onTable = false;
            }else if(name === "thead"){
                onTHead = false;
            }
            iterators.out += `</${name}>`;
        },
        onend: function(){
            var finalContent = iterators.out
                .replace(/(\<span\sclass\=\"\"\sstyle\=\"\s*Super\">)([0-9])\<\/span\>\<span\sclass\=\"\"\sstyle\=\"\s*Super\"\>([0-9])(\<\/span>)/g, function(match, p1, p2, p3, p4){ return p1 + p2 + p3 + p4; })
                .replace(/(\<span\sclass\=\"Footnote\-reference\s*\"\sstyle\=\"[^"]*Super[^"]*\"\>)([0-9])\<\/span\>\<span\sclass\=\"\"\sstyle\=\"[^"]*Super[^"]*\">([0-9])\</g, function(match, p1, p2, p3){ return p1 + p2 + p3 + '<'; })
                .replace(/(\<span\sclass\=\"Footnote\-reference\s*\"\sstyle\=\"[^"]*Super[^"]*\"\>)([0-9])\.(\<\/span\>)/g, function(match, p1, p2, p3){ return p1 + p2 + p3 + '.'; });

            resolve({ content: finalContent, pageCount: iterators.page, error: error, text: errorText});
        }
    }, { decodeEntities: true });
    parser.write(htmlData.replace(/&#173;/g, ''));
    parser.end();
};

function injectPages(content, htmlData, filePath, fileName, callback){
    var pages = {},
        lastNodeName,
        it = 0,
        lastP,
        rightHeaderExp = /(Fasc|Table|Notices|Index)/;

    var parser = new htmlparser.Parser({
        onopentag: function(name, attribs){
            lastNodeName = name;
            if(name === "page"){
                var found = attribs.filename.match(/-([0-9]*).xhtml$/);
                if(found){
                    lastP = found[1];
                    pages[lastP] = {contents: [], text: '',footer: '', header: {}};
                }
                it++;
            }
        },
        ontext: function(originalText){
            var text = decodeXmlEntities(decodeXmlVimmitEntities(originalText).replace(/\x20|\x09|\xad|\x2d|\x0a|\xa0|\u2029|\x2e/g, ''));
            if(text!=''){
                switch(lastNodeName){
                    case "content":
                        pages[lastP].contents.push({ text, visited: false});
                        break;

                    case "header":
                        if( rightHeaderExp.test(originalText) ){
                            pages[lastP].header.right = originalText.trim().replace(/\r\n/g, "");
                        }else{
                            pages[lastP].header.left = originalText.trim().replace(/\r\n/g, "");
                        }
                        break;
                    
                    case "footer":
                        pages[lastP].footer += originalText;
                    break;
                }
            }          
        },
        onend: function(){
            
            //compileTexts(pages, fileName);
            
            injectPageNumbers(htmlData, pages, filePath, callback);
        }
    }, { decodeEntities: true });
    parser.write(encodeXmlVimmitEntities(content));
    parser.end();
}

function injectInlineHtml(collectionPath, fileName){
    return fsReadFile(collectionPath + '/' + fileName, 'utf8')
        .then(function (htmlData) {

            return new Promise(function(resolve, reject){

                inlineCss(htmlData, { url: 'file:///' + collectionPath + '/' })
                    .then(function(html) {
                        
                        return resolve(inlineHtmlParser(html));

                    }, reject);

                });

        });
}

function injectCollection(path, collectionFilter, filter){
    return fsReadDir(path)
        .then(collections => {
            return Promise.all(
                collections
                    .filter( filterInvalidFiles )
                    .filter( collection => collectionFilter.test(collection) )
                    .map( collection => {

                        return injectEpubFiles(path, collection, [path, collection, 'temp'].join('/'), filter);

                    })      
            );
        });
}

function injectPackage(path, collectionFilter, filter){
    return injectCollection(path, collectionFilter, filter);
}

function injectPackages(paths, collectionFilter, filter){
    return Promise.all(paths.map( path  => {
        return injectPackage(path.replace('/in/', '/out/'), collectionFilter, filter);
    }));
}

exports.injectPackages = injectPackages;