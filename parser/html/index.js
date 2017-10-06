
const fs = require('fs'),
    util = require('util'),
    crypto = require('crypto'),
    docbook = require('./docbook'),
    _ = require('lodash'),
    async = require('async'),
    saxon = require('./../saxon'),
    jing = require('./../jing'),
    fx = require('mkdir-recursive'),
    tmp = require('tmp'),
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

function htmlFilter(input){
    return /.html$/.test(input) && !/.inline.html$/.test(input);
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
        'style="([^"]*)"': function(match, p1){ 
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
        },
        'CharOverride-([0-9]*)': ''
    };
    var output = html;
    for(var key in replaces){
        output = output.replace(new RegExp(key, 'gi'), replaces[key]);
    }
    return output;
}

var conversionQueue = async.queue(function(task, callback) {
    processCollection(task.htmlPath, task.xmlPath, callback);
}, 1);

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

function preparePackages(paths){

    var batchFiles = {};
    return Promise.all(paths.map( path  => {
            
        var outPath = path.replace('/in/', '/out/');
        
        return fxMkDir(outPath)
        .then(function() {
            console.log(outPath);

            return fsReadDir(path)
            .then(collections => {
                
                return Promise.all(
                    collections
                    .filter( collection => collection != '.DS_Store' )
                    .map( collection => {
                        var collectionPath = path + '/' + collection;
                    
                        return fsReadDir(collectionPath)
                            .then( renditions => {

                                return Promise.all(
                                    renditions
                                        .filter( rendition => rendition != '.DS_Store') 
                                        .map( rendition => {
                                            var renditionPath = collectionPath + '/' + rendition;

                                            var copyFiles = function(fileType){
                                            
                                                var inddOutPath = outPath + '/' + collection + '/' + fileType + '/';
                                                return fxMkDir(inddOutPath)
                                                    .then(() => {
                                                        return fsReadDir(renditionPath)
                                                            .then(files => {
                                                                
                                                                return Promise.all(files
                                                                    .map(file => {
                                                                        var inddFilePath = renditionPath + '/' + file;
                                                                        if((new RegExp(fileType + '$')).test(inddFilePath)){
                                                                            var inddFinalPath = inddOutPath + '/' + file;
                                                                            return copyFile(inddFilePath, inddFinalPath);
                                                                        }
                                                                        return Promise.resolve();
                                                                    }));
                                                            });
                                                    });
                                                
                                            };

                                            if(/INDD/.test(rendition) || /InDesign/.test(rendition)){
                                                return copyFiles('indd')
                                                    .then(() => {
                                                        var xmlOutPath = outPath + '/' + collection + '/xml';
                                                        console.log(xmlOutPath);
                                                        return fxMkDir(xmlOutPath)
                                                            .then( () => {
                                                                var htmlOutPath = outPath + '/' + collection + '/html';
                                                                return fxMkDir(htmlOutPath)
                                                                    .then( () => {
                                                                        return fsReadDir(renditionPath)
                                                                            .then( files => {
                                                                                return Promise.all(files
                                                                                    .map(file => {
                                                                                        if(/.indd$/.test(file)){
                                                                                            var inddFilePath = renditionPath + '/' + file;
                                                                                            var htmlFilePath = htmlOutPath + '/' + file + '.html';
                                                                                            batchFiles[inddFilePath] = htmlFilePath;
                                                                                        }
                                                                                        return Promise.resolve();
                                                                                    }));
                                                                            });
                                                                    });
                                                            });
                                                        
                                                    });
                                            
                                            }else if(/PDF/.test(rendition)){
                                                return copyFiles('pdf');
                                            }else{
                                                return Promise.resolve();
                                            }
                                        })
                                );
                                
                            });
                    }));
                
            });

        });
    }))
    .then( () => {
        return indd2Html(batchFiles);
    });
}

(function main(){
    
    var args = {};
    process.argv.forEach((val, index) => {
        var parts = val.split('=');
        args[parts[0]] = parts[1] || true;
    });

    var basePath = "/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/data/in/Package_";
    
    var packages = (args.packages.split(',') || [1,2,3,4]).map( id => {
        return basePath + id;
    });

    var filter = new RegExp(args.filter || '\.html$');
    
    var preparePromise = args.prepare
        ? fsReadFile('./export-single-html.jsx', 'utf8')
            .then(function (data) {
                jsxScript = data;
                return preparePackages(packages)
            })
        : Promise.resolve();
    
    preparePromise
        .then(() => {
            
            return args.convert
                ? convertPackages(packages, filter)
                : Promise.resolve();
                    
        })
        .then(function(){
            console.log('FINISHED');
        });
    
})();