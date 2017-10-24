const fs = require('fs'),
    tmp = require('tmp'),
    saxon = require('./../saxon'),
    _ = require('lodash'),
    unzip = require('unzip'),
    exec = require('child_process').exec,
    inlineCss = require('inline-css'),
    util = require('util'),
    htmlparser = require("htmlparser2");

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
    return input.replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

function hexEncodeChar(input, i){
    var hex = input.charCodeAt(i).toString(16);
    return("000"+hex).slice(-4);
}

var charsToOmit = ['0020', '0009', '00ad', '002d', '000a', '00a0', '2029'];

function validateStrings(stringA, stringB, iterators){
    var charA = stringA.charAt(iterators.A),
        charB = stringB.charAt(iterators.B),
        charAHex,
        charBHex
        result = false;

    if(charA === charB){
        iterators.out += encodeXmlEntities(charA);
        iterators.A++;
        iterators.B++;
        result = true;
    }else{
        charAHex = hexEncodeChar(stringA, iterators.A);
        if(charsToOmit.indexOf(charAHex) >= 0){
            iterators.out += encodeXmlEntities(charA);
            iterators.A++;
            result = true;
        }
        charBHex = hexEncodeChar(stringB, iterators.B);
        if(charsToOmit.indexOf(charBHex) >= 0){
            iterators.B++;
            result = true;
        }
    }
    if(!result){
        console.log(iterators.A, iterators.B, iterators.page, 'HTML:', stringA.substr(iterators.A, 10), 'Pages:', stringB.substr(iterators.B, 10), charAHex, charBHex, iterators.page, iterators.fileName);
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
        'color: ([^;]*)*;': '',
        "font-family: [^;]*;": '',
        'font-size: ([0-9]*)(px|%);': function(match, p1, p2){ return `FontSize-${p1}${p2}`; },
        'font-style: (normal|italic|oblique);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
        'font-variant: ([^;]*);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
        'font-weight: (bold|normal);': function(match, p1){ return p1.charAt(0).toUpperCase() + p1.slice(1).toLowerCase(); },
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
        'height: ([0-9]*)(px|);':'',
        'position: relative;':'',
        'width: ([0-9]*)(px|);':'',
        
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
                if( position > 650){
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
    return new Promise(function(resolve, reject){
        fsReadFile(path + fileIn, 'utf8')
            .then(function (htmlData) {
                inlineCss(htmlData, { url: 'file:///' + path })
                    .then(inlineCss => {
                        fsWriteFile(path + fileOut, inlineCssParser(inlineCss), 'utf8')
                            .then(() => {
                                resolve(path + fileOut);
                            });
                    })
            });
    });
}

function injectXhtmlFiles(path, resolve){
    return function(){
        fsReadDir(path + '/OEBPS')
            .then( files => {
                return Promise.all(
                    files
                        .filter( file => /\.xhtml$/.test(file) )
                        //.filter( file => /F01/.test(file) )
                        .filter( file => file != 'toc.xhtml' )
                        .map( file => {
                            return createInlineCSSFile(path + '/OEBPS/', file, 'xInline.' + file) 
                        })
                );
            }).then( () => {
                resolve(path);
            } );
    };
};

function exportEpubFiles(path, collection, collectionPath){
    return fsReadDir(collectionPath)
        .then(files => {
            return Promise.all(
                    files
                    .filter( createFilter('\.epub$') )
                    //.filter( (value, index) => /F18/.test(value) )
                    .map( epubFile => {
                        
                        return (new Promise(function(resolve, reject){
                            tmp.dir({ prefix: epubFile + "_" }, function(err, path) {
                                if (err) reject(err);
                                
                                fs
                                    .createReadStream([collectionPath, epubFile].join('/'))
                                        .pipe(unzip.Extract({ path: path }))
                                        .on('finish', injectXhtmlFiles(path, resolve) );
                                
                            });
                        })).then( (epubPath) => {

                            console.log(epubPath);
                            return saxon
                                .exec({
                                    xmlPath: __dirname + '/../../xslt/empty.xml', 
                                    xslPath: __dirname + '/../../xslt/pages.xsl',
                                    params: {
                                        "exportFolder": epubPath + '/OEBPS'
                                    }
                                })
                                .then( response => response.stdout )
                                .then( (content) => { 
                                    return { content, epubPath };
                                });
                        }).then( (conversion) => {
                            var fileName = _.last(conversion.epubPath.split('/')).split('.')[0];
                            
                            return new Promise(function(resolve, reject){

                                var htmlFilePath = [path, collection, 'html'].join('/') + fileName + '.html';
                                injectInlineHtml([path, collection, 'html'].join('/'), fileName + '.html')
                                    .then( htmlData => {
                                        return injectPages(conversion.content, htmlData, htmlFilePath, resolve);
                                    });
                                

                            }).then( content => {
                                var outFilePath = [path, collection, 'html', fileName + '.inline.html'].join('/');
                                console.log(outFilePath);
                                return fsWriteFile(outFilePath, content, 'utf8');
                            });

                        });

                    })
                );
    });
}

function injectPageNumbers(htmlData, pages, fileName, resolve){
    
    var iterators = {
        A: 0,
        B: 0,
        fileName: fileName,
        html: htmlData,
        pages: pages,
        page: 1,
        out: ''
    };

    var onBody = false,
        error = false;

    var parser = new htmlparser.Parser({
        onopentag: function(name, attribs){
            if(name === "body"){
                onBody = true;
            }
            iterators.out += `<${name}`;
            for(var key in attribs){
                iterators.out += ` ${key}="${attribs[key]}"`;
            }
            iterators.out += `>`;
        },
        ontext: function(text){
            if(error){
                iterators.out += encodeXmlEntities(text);
                return;
            }

            var evaluatePageChange = function(){
                if(pages[iterators.page] && pages[iterators.page].text.length === iterators.B){
                    var release = pages[iterators.page].footer,
                        pageNo,
                        ofPages;
                    var match = release.match(/^[\r\n ]*\([0-9]*\)([A-Z0-9])*\s\/\s([0-9]*)\s*(\D*\s[0-9]{4})[\r\n ]*$/);
                    //var match = release.match(/^[\r\n ]*\([0-9]*\)[A-Z0-9]*\s\/\s[0-9]*\s*(\D*\s[0-9]{4})[\r\n ]*$/);
                    if(match){
                        pageNo = match[1];
                        ofPages = match[2];
                        release = match[3];
                    }
                    if(pageNo && ofPages){
                        //console.log(`<?textpage page-num="${page}" release-num="Août 2017"?>`);
                        if(pages[iterators.page] && pages[iterators.page].header){
                            if(pages[iterators.page].header.right){
                                iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" right-header="${pages[iterators.page].header.right}" extracted-page="${iterators.page}" release-num="${release}" />`;
                            }else{
                                iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" left-header="${pages[iterators.page].header.left}" extracted-page="${iterators.page}" release-num="${release}" />`;
                            }
                        }else{
                            iterators.out += `<br injected="true" page-num="${pageNo}-${ofPages}" extracted-page="${iterators.page}" release-num="${release}" />`;
                        }
                    }
                    iterators.page++;
                    iterators.B = 0;
                }
            }

            if(onBody && text.length > 0){
                
                iterators.A = 0;
                while(!error && pages[iterators.page] && iterators.A < text.length && iterators.B < pages[iterators.page].text.length){
                    if(!validateStrings(text, pages[iterators.page].text, iterators)){
                        error = true;
                        iterators.out += encodeXmlEntities(text);
                    }
                    if(!error) evaluatePageChange();
                }

                if(!error) evaluatePageChange();
                
            }else{
                iterators.out += encodeXmlEntities(text);
            }
            
        },
        onclosetag: function(name){
            if(name === "body"){
                onBody = false;
            }
            iterators.out += `</${name}>`;
        },
        onend: function(){
            resolve(iterators.out);
        }
    }, { decodeEntities: true });
    parser.write(htmlData);
    parser.end();
};

function injectPages(content, htmlData, fileName, callback){
    var pages = {},
        lastNodeName,
        it = 0,
        lastP,
        footerRegExp = /^\([0-9]+\)[0-9A-Za-z]+\s\/\s[0-9]+[a-zA-Z]+\s*[0-9]*/,
        rightHeaderExp = /^[\r\n ]*Fasc\./;

    var parser = new htmlparser.Parser({
        onopentag: function(name, attribs){
            lastNodeName = name;
            if(name === "page"){
                var found = attribs.filename.match(/-([0-9]*).xhtml$/);
                if(found){
                    lastP = found[1];
                    pages[lastP] = {text: '', footer: '', header: {}};
                }
                it++;
            }
        },
        ontext: function(text){
            switch(lastNodeName){
                case "content":
                    pages[lastP].text += text;
                    break;

                case "header":
                    if( rightHeaderExp.test(text) ){
                        pages[lastP].header.right = text;

                    }else{
                        pages[lastP].header.left = text;
                    }
                    break;
                
                case "footer":
                    pages[lastP].footer += text;
                break;
            }          
        },
        onend: function(){
            injectPageNumbers(htmlData, pages, fileName, callback);
        }
    }, { decodeEntities: true });
    parser.write(content);
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

function injectCollection(path, filter){
    return fsReadDir(path)
        .then(collections => {
            return Promise.all(
                collections
                    .filter( filterInvalidFiles )
                    .filter( createFilter(filter) )
                    .map( collection => {

                        return exportEpubFiles(path, collection, [path, collection, 'temp'].join('/'));

                    })      
            );
        });
}

function injectPackage(path, filter){
    return injectCollection(path, filter);
}

function injectPackages(paths, filter){
    return Promise.all(paths.map( path  => {
        return injectPackage(path.replace('/in/', '/out/'), filter);
    }));
}

exports.injectPackages = injectPackages;