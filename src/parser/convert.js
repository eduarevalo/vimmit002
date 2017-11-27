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
    filterManualFixes = require('./manualFiles').filterManualFixes;


const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);
    
saxon.setDefaults({ saxonJarPath : __dirname + '/../../bin/saxon/saxon9he.jar' });
jing.setDefaults({ jingJarPath : __dirname + '/../../bin/jing-20091111/bin/jing.jar' });
pdfbox.setDefaults({ pdfBoxJarPath : __dirname + '/../../bin/pdfbox/pdfbox-app-2.0.7.jar' });

function processCollection(collectionFolder, filter){
    
    console.log('processCollection()', collectionFolder);

    var collectionPaths = [],
        emphasis = [];

    var outPath = collectionFolder + '/xml';

    return fsReadDir(collectionFolder + '/html')
        .then( files => {
            
            var htmlFiles = files
                .filter( filterManualFixes )
                .filter( file => /\.inline\.html$/.test(file) )
                .filter( file => filter.test(file) );
            
            var docBook = htmlFiles      
                .map(file => {
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
                        
                        })
                        .catch(() => {
                            return Promise.resolve();
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
                        .then( () => {
                            return results;
                        } );

                });
            

        });    
}

function convertPackages(paths, collectionFilter, filter){
    return Promise.all(paths
        .map( path => path.replace('/in/', '/out/') )
        .map( path => {
                
            return fsReadDir(path)
                .then(collections => {

                    var collectionsResults = {};

                    return collections
                        .filter( collection => collectionFilter.test(collection) )
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
                                .then(() => {
                                    return results;
                                }); 
                        });

                });
        })
    );
}   

exports.convertPackages = convertPackages;