const fs = require('fs'),
util = require('util'),
crypto = require('crypto'),
docbook = require('./docbook'),
_ = require('lodash'),
async = require('async'),
saxon = require('./../saxon'),
pdfbox = require('./../pdfbox'),
jing = require('./../jing'),
fx = require('mkdir-recursive'),
tmp = require('tmp'),
htmlparser = require("htmlparser2"),
inlineCss = require('inline-css'),
exec = require('child_process').exec,
runJsxCommand = '"/Applications/Adobe\ ExtendScript\ Toolkit\ CC/ExtendScript\ Toolkit.app/Contents/MacOS/ExtendScript\ Toolkit" -run ';

var jsxScript = '';

const fxMkDir = util.promisify(fx.mkdir),
fsReadFile = util.promisify(fs.readFile),
fsWriteFile = util.promisify(fs.writeFile),
fsReadDir = util.promisify(fs.readdir);
 
saxon.setDefaults({ saxonJarPath : __dirname + '/../../bin/saxon/saxon9he.jar' });
jing.setDefaults({ jingJarPath : __dirname + '/../../bin/jing-20091111/bin/jing.jar' });
pdfbox.setDefaults({ pdfBoxJarPath : __dirname + '/../../bin/pdfbox/pdfbox-app-2.0.7.jar' });

function hexEncodeChar(input, i){
var hex = input.charCodeAt(i).toString(16);
return("000"+hex).slice(-4);
}

function htmlFilter(input){
return /.html$/.test(input) && !/.inline.html$/.test(input) && !/.pages.html$/.test(input);
}

function fascicleFilter(input){
return /-F[0-9]*.*.xml$/.test(input);
//6018_JCQ_09-F02_MJ8.indd.inline.html.db.xml
}

function htmlInlineFilter(input){
return /.inline.html$/.test(input);
}

function folderFilter(input){
return /_Version courante$/.test(input);
}

function removeStyle(array, style){
for(var index = array.indexOf(style); index >=0; index = array.indexOf(style)){
    array.splice(index, 1);
}
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

var indd2Html = function(batchFiles) {

return new Promise( (resolve, reject) => {

    tmp.file({postfix: '.jsx' }, function(err, path, fd, cleanupCallback) {
        if (err) throw err;
    
        console.log('Jsx Script: ', path, ' with ' + _.size(batchFiles) + ' files');

        var jsxScriptCode = jsxScript.replace('{$batchFiles}', JSON.stringify(batchFiles));
        
        fs.writeFile(path, jsxScriptCode, function(err) {
            if(err) throw err;
            exec(runJsxCommand + path, (error, stdout, stderr) => {
                if (error !== null) {
                    reject(error);
                }
            });
        
            setTimeout(function(){
                resolve();
                cleanupCallback();
            }, _.size(batchFiles) * 1000);

        });

    });

});

};

function processCollection(collectionFolder, filter){

console.log('processCollection()', collectionFolder);

var collectionPaths = [],
    emphasis = [];

var outPath = collectionFolder + '/xml';

var inlineHtmls = fsReadDir(collectionFolder + '/html')
    .then( files => {

        return Promise.all(
            
            files
                .filter(function(file){
                    return filter.test(file);
                })
                .filter(htmlFilter)
                .map(file => {
                
            var filePath = collectionFolder + '/html/' + file;
            
            return new Promise(function(resolve, reject){
                
                fsReadFile(filePath, 'utf8')
                    .then(function (htmlData) {
                        
                        inlineCss(htmlData, { url: 'file:///' + collectionFolder + '/html/' })
                            .then(function(html) {
                                
                                var fileInline = file.replace('.html', '.inline.html');
                                var fileInlinePath = collectionFolder + '/html/' + fileInline;
                  
                                fsWriteFile(fileInlinePath, inlineHtmlParser(html), 'utf8')
                                    .then(() => {
                                        resolve(fileInline);
                                    });
                            }, function(){
                                reject(filePath);
                            });

                    });
            });
        }));

    });

return inlineHtmls
    .then( files => {
        
        var htmlFiles = files.filter(htmlInlineFilter);
        
        var docBook = htmlFiles.map(file => {
            return docbook.exec(collectionFolder + '/html/' + file)
                .then( response => response.stdout )
                .then( content => {
                    var xmlFilePath = outPath + '/' + file + '.db.xml';
                    return fsWriteFile(xmlFilePath, content)
                        .then(() => xmlFilePath);
                })
                .then( xmlFilePath => {

                    return saxon
                        .exec({
                            xmlPath: xmlFilePath, 
                            xslPath: __dirname + '/../../xslt/export-paths.xsl'
                        })
                        .then( response => response.stdout )
                        .then( content => {
                            var lines = content.split(/\r|\n/);
                            for(var i=0;i<lines.length;i++){
                                if(lines[i] && collectionPaths.indexOf(lines[i]) === -1){
                                    collectionPaths.push(lines[i]);
                                }
                            }
                            return xmlFilePath;
                        });
                })
                .then( xmlFilePath => {

                    return saxon
                        .exec({
                            xmlPath: xmlFilePath, 
                            xslPath: __dirname + '/../../xslt/export-emphasis.xsl'
                        })
                        .then( response => response.stdout )
                        .then( content => {
                            var lines = content.split(/\r|\n/);
                            for(var i=0;i<lines.length;i++){
                                if(lines[i] && emphasis.indexOf(lines[i]) === -1){
                                    emphasis.push(lines[i]);
                                }
                            }
                            return xmlFilePath;
                        });
                })
                .then( xmlFilePath => ({ file, xmlFilePath, type: 'docbook' }) )
                .then( docBookFile => {
                    return jing.exec({
                        xmlPath: docBookFile.xmlFilePath, 
                        rngPath: __dirname + '/../../docbook/docbook.rng'
                    })
                    .then( response => response.stdout )
                    .then( validation => { 
                        docBookFile.valid = true;
                        return docBookFile;
                    }, (error) => {
                        docBookFile.valid = false;
                        docBookFile.error = error.stdout;
                        return docBookFile;
                    });
                })
                .then( docBookFile => {
                    return saxon
                        .exec({
                            xmlPath: docBookFile.xmlFilePath, 
                            xslPath: __dirname + '/../../xslt/extract-docbook-text.xsl'
                        })
                        .then( response => response.stdout )
                        .then( content => {
                            docBookFile.length = content.length;
                            docBookFile.content = content;
                            docBookFile.md5 = crypto.createHash('md5').update(content).digest("hex");
                            return docBookFile;
                        });
                
                });
                
        });

        var textMd5 = htmlFiles.map(file => {
            var filePath = collectionFolder + '/html/' + file;
            return saxon
                .exec({
                    xmlPath: filePath, 
                    xslPath: __dirname + '/../../xslt/extract-html-text.xsl'
                })
                .then( response => response.stdout )
                .then( content => {
                    var htmlFileObj = { file, filePath, type: 'text-md5' };
                    htmlFileObj.length = content.length;
                    htmlFileObj.content = content;
                    htmlFileObj.md5 = crypto.createHash('md5').update(content).digest("hex");
                    return htmlFileObj;
                });
                
        });

        return Promise.all([...docBook, ...textMd5])
            .then( tasks => {

                var docbookTasks = tasks
                    .filter( task => task.type === 'docbook' )
                    .reduce( (hash, elem) => {
                            hash[elem.file] = elem;
                            return hash;
                        }, {});

                var textMd5Tasks = tasks
                    .filter( task => task.type === 'text-md5' )
                    .reduce( (hash, elem) => {
                        hash[elem.file] = elem;
                        return hash;
                    }, {});

                var results = {};
                var txtResults = []
                var number = 0,
                    integrityFiles = 0
                    dbValidFiles = 0;

                for(var file in docbookTasks){
                    var integrityValidation = docbookTasks[file].md5 === textMd5Tasks[file].md5;
                    var firstError = '';
                    if(!integrityValidation){
                        for(var i=0; i<textMd5Tasks[file].content.length; i++){
                            if(textMd5Tasks[file].content.charAt(i) != docbookTasks[file].content.charAt(i)){
                                var min = i - 10 < 0 ? i : i - 5;
                                var maxChars = 40;
                                firstError = ` error:` + textMd5Tasks[file].content.substr(min, maxChars) + '/' + docbookTasks[file].content.substr(min, maxChars);
                                break;
                            }
                        }
                    }else{
                        integrityFiles++;
                    }
                    var coverage = (docbookTasks[file].length / textMd5Tasks[file].length).toFixed(7) * 100;
                    results[file] = { 
                        integrity: integrityValidation,
                        coverage: coverage,
                        firstHtmlDifference: firstError
                    };
                    _.assign(results[file], { 
                        docbook: _.omit(docbookTasks[file], ['content', 'error']), 
                        html: _.omit(textMd5Tasks[file], ['content', 'error'])
                    });
                    if(docbookTasks[file].valid){
                        dbValidFiles++;
                    }
                    var data = [++number, file, 
                        'Valid:', integrityValidation,
                        'DocBook:', docbookTasks[file].valid,
                        'Coverage', coverage,
                        firstError
                    ];
                    console.log(...data);
                    txtResults.push(data.join(' '));
                };

                var lastLine = ['MD5 invalid', (number - integrityFiles),
                    'DocBook invalid', (number - dbValidFiles),
                    'Files count', number
                ];
                console.log(...lastLine);
                txtResults.push(lastLine.join(' '));

                return fsWriteFile(collectionFolder + '/results.json', JSON.stringify(results), 'utf8')
                    .then(() => {
                        return fsWriteFile(collectionFolder + '/results.txt', txtResults.join("\r\n"), 'utf8')
                            .then(() => {
                                fsWriteFile(collectionFolder + '/paths.txt', collectionPaths.join("\r\n"), 'utf8');
                            })
                            .then(() => {
                                fsWriteFile(collectionFolder + '/emphasis.txt', emphasis.join("\r\n"), 'utf8');
                            });
                    })
                    .then( () => results );

            });
        

    });    
}

function readDir(path){
fs.readdir(path, (err, files) => {
    files.forEach( file => {
        var filePath = path + '/' + file;
        
        fs.readdir(filePath, (err, files2) => {
            if(files2){
                files2.forEach( file2 => {
                    var collectionPath = filePath + '/' + file2;
                    if(folderFilter(collectionPath)){
                        q.push({collectionPath}, function(err) {
                            console.log('q.push()' + collectionPath);
                        });
                    }
                });
            }
        });
    });
});
}

function copyFile(src, dest) {
return new Promise((resolve, reject) => {
    let readStream = fs.createReadStream(src);
    readStream.once('error', reject);
    readStream.once('end', resolve);
    readStream.pipe(fs.createWriteStream(dest));
});
}

function convertPackages(paths, filter){
return Promise.all(paths
    .map( path => path.replace('/in/', '/out/') )
    .map( path => {
            
        return fsReadDir(path)
            .then(collections => {

                var collectionsResults = {};

                return collections
                    .filter( collection => !_.includes(['.DS_Store', 'results.json', 'results.txt', 'paths.txt', 'emphasis.txt'], collection) )
                    .reduce( (promise, collection) => {
                            var collectionPath = path + '/' + collection;
                            return promise
                                .then(() => {
                                    return processCollection(collectionPath, filter) 
                                })
                                .then( results => { 
                                    collectionsResults[collectionPath] = results;
                                    return Promise.resolve(collectionsResults);
                                });
                            }, Promise.resolve() )
                    .then( results => {
                        return fsWriteFile(path + '/results.json', JSON.stringify(results), 'utf8')
                            .then(() => results); 
                    });

            });
    })
);
}            

function transformPackages(paths, filter){
return Promise.all(paths
    .map( path => path.replace('/in/', '/out/') )
    .map( path => {
            
        return fsReadDir(path)
            .then(collections => {

                var collectionsResults = {};

                return collections
                    .filter( collection => !_.includes(['.DS_Store', 'results.json', 'results.txt', 'paths.txt', 'emphasis.txt'], collection) )
                    .reduce( (promise, collection) => {
                            var collectionPath = path + '/' + collection;
                            return promise
                                .then(() => {
                                    return transformCollection(collectionPath, filter) 
                                });
                            }, Promise.resolve() 
                    );

            });
    })
);
}

function transformCollection(collectionFolder, filter){

console.log('transformCollection()', collectionFolder);

var neptunePath = collectionFolder + '/neptune';

return fxMkDir(neptunePath)
    .then( () => {
        

    var fascicles = fsReadDir(collectionFolder + '/xml')
        .then( files => {
            
            return Promise.all(
                
                files
                    .filter(function(file){
                        return filter.test(file);
                    })
                    .filter(fascicleFilter)
                    .map( file => {

                        var found = file.match(/([0-9]*)_JCQ_[0-9]*-F([0-9]*)_[^.]*\.indd\.inline\.html\.db\.xml$/);
                        if(found){
                            
                            var pubNum = found[1].padStart(5, "0"),
                                chapterNum = found[2].padStart(4, "0");

                            return saxon
                                .exec({
                                    xmlPath: collectionFolder + '/xml/' + file, 
                                    xslPath: __dirname + '/../../xslt/neptune-fascicle.xsl',
                                    params: {
                                        pubNum: pubNum,
                                        chNum: chapterNum
                                    }
                                })
                                .then( response => response.stdout )
                                .then( content => {

                                        var newFileName = pubNum + '-ch' + chapterNum + '.xml';
                                        var xmlFilePath = neptunePath + '/' + newFileName;
                                        return fsWriteFile(xmlFilePath, content)
                                            .then(() => xmlFilePath);
                                    
                                });
                        }else{
                            return Promise.resolve();
                        }
                        
                    })
            );

        });

    return fascicles;

});

}



(function main(){

    var htmlOutPath = "/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/parser/html/../../data/out/Package_1/Droit de l'environnement/html/";
    var file = "6018_JCQ_10-F03_MJ9.pdf.pages.html";
    ///Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/parser/html/../../data/out/Package_1/Droit de l'environnement/html/6018_JCQ_10-F03_MJ9.indd.inline.html
    
    var charsToOmit = ['0020', '0009', '00ad', '002d', '000a', '00a0'];

    console.log(htmlOutPath + '/' + file);
    return fsReadFile(htmlOutPath + '/' + file, 'utf8')
        .then(function (htmlData) {
            
            return new Promise(function(resolve, reject){
                var injectPageNumbers = function(fileName, pages, resolve){
console.log(htmlOutPath + '/' + fileName);
                    return fsReadFile(htmlOutPath + '/' + fileName, 'utf8')
                     .then(function (htmlData) {
                        
                        var page = 0,
                            iterator = 0,
                            onBody = false,
                            insertPageNumber = false;

                        var parser = new htmlparser.Parser({
                            onopentag: function(name, attribs){
                                if(name === "body"){
                                    onBody = true;
                                }
                            },
                            ontext: function(text){
                                var cleanText = text;//.replace(/\u00AD/g,'').replace(/\t/g, '').replace(/\r?\n/g, '');
                                console.log(cleanText);
                                if(onBody && cleanText.length > 0){

                                    for(var textIterator=0; textIterator < cleanText.length && iterator < pages[page].text.length; textIterator++){
                                        if(cleanText.charAt(textIterator) === pages[page].text.charAt(iterator)){
                                            iterator++;
                                        }else{
                                            var textChar = hexEncodeChar(cleanText, textIterator),
                                                pageTextChar = hexEncodeChar(pages[page].text, iterator);
                                            if(charsToOmit.indexOf(textChar) >= 0){
                                                // Chars to omit
                                            }else if(charsToOmit.indexOf(pageTextChar) >= 0){
                                                iterator++;
                                                textIterator--;
                                            }else{
                                                console.log(pages[page].text.length, textIterator, iterator, textChar, pageTextChar, cleanText, pages[page].text);
                                                process.exit();
                                            }
                                        }
                                    }

                                    console.log(iterator, '/', pages[page].text.length, ' in page ', page);

                                    if(pages[page].text.length === iterator){
                                        insertPageNumber = true;
                                        page++;
                                        iterator = 0;
                                        console.log('Page');
                                    }
                                }
                                
                            },
                            onclosetag: function(name){
                                if(name === "body"){
                                    onBody = false;
                                }
                            },
                            onend: function(){
                                resolve(true);
                            }
                        }, { decodeEntities: true });
                        parser.write(htmlData);
                        parser.end();

                    });
                };

                var pages = [],
                    lastNodeName,
                    lastText,
                    lastP,
                    pubNum = '6018',
                    pubNumRegExp = new RegExp('\(6018\)'),
                    leftHeader = "I. Aspects généraux",
                    rightHeader = "Fasc. 1 – Droit international de l’environnement";

                var parser = new htmlparser.Parser({
                    onopentag: function(name, attribs){
                        lastNodeName = name;
                        if(name === "div" && attribs.style === "page-break-before:always; page-break-after:always"){
                            pages.push({ number: pages.length+1, text: '', headers: []});
                        }else if(name === "p"){
                            lastText = '';
                        }
                    },
                    ontext: function(text){
                        lastText += text;
                    },
                    onclosetag: function(tagname){
                        if(tagname === "p" && lastText.length > 0 && pages[pages.length - 1]){
                                
                            if( pubNumRegExp.test(lastText) 
                                || lastText.replace(/(\r?\n|\r)/gm, '') === leftHeader 
                                || lastText.replace(/(\r?\n|\r)/gm, '') === rightHeader){
                                pages[pages.length - 1].headers.push(lastText);
                            }else{
                                pages[pages.length - 1].text += lastText;
                            }

                            lastText = '';
                        }
                    },
                    onend: function(){
                        var inlineHtmlFile = file.replace('.pdf.pages', '.indd.inline');
                        injectPageNumbers(inlineHtmlFile, pages, resolve);
                    }
                }, { decodeEntities: true });
                parser.write(htmlData);
                parser.end();
            });
        });
    


})();