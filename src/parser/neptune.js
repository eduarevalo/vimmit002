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
    xmllint = require('./xmllint'),
    diff = require('./diff3');

const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);
    

function fascicleFilter(input){
    return /-F[0-9]+.*.xml$/.test(input);
}

function wrapInHtml(content){
    return `<html>
    <head>
        <style>
            ins {background-color: green;}
            del {background-color: red;}
        </style>
    </head>
    <body> ${content} </body>
    </html>`;
    
}
var htmlWrapper = '';

function transformCollection(collectionFolder, filter){
    
        console.log('transformCollection()', collectionFolder);
    
        var neptunePath = collectionFolder + '/neptune';
        
        return fxMkDir(neptunePath)
            .then( () => {
            

            var frontMatterTitle= fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /Page de titre/.test(file);
                            })
                            .map( file => {
        
                                var found = file.match(/([0-9]*)_JCQ_/);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-frontmatter-title.xsl',
                                            params: {
                                                pubNum: pubNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-fmvol001.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                    docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                };
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });
        
            var frontMatterPreface = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /Préface/.test(file);
                            })
                            .map( file => {
        
                                var found = file.match(/([0-9]*)_JCQ_/);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-frontmatter-preface.xsl',
                                            params: {
                                                pubNum: pubNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-fmvol001pre.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                    docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                };
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });
            
            var frontMatterForeword = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /Avant-propos/.test(file);
                            })
                            .map( file => {
        
                                var found = file.match(/([0-9]*)_JCQ_/);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-frontmatter-foreword.xsl',
                                            params: {
                                                pubNum: pubNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-fmvol001ap.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                    docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                };
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });
            
            var frontMatterFeature = fsReadDir(collectionFolder + '/xml')
                    .then( files => {
                        
                        return Promise.all(
                            
                            files
                                .filter(function(file){
                                    return filter.test(file);
                                })
                                .filter(function(file){
                                    return /biographiques/.test(file);
                                })
                                .map( file => {
            
                                    var found = file.match(/([0-9]*)_JCQ_/);
                                    if(found){

                                        var pubNum = found[1].padStart(5, "0");
                                        var xmlPath = collectionFolder + '/xml/' + file;
                                        return saxon
                                            .exec({
                                                xmlPath: xmlPath, 
                                                xslPath: __dirname + '/../../xslt/neptune-frontmatter-feature.xsl',
                                                params: {
                                                    pubNum: pubNum
                                                }
                                            })
                                            .then( response => response.stdout )
                                            .then( content => {
            
                                                    var newFileName = pubNum + '-fmvol001bio.xml';
                                                    var xmlFilePath = neptunePath + '/' + newFileName;
                                                    return { 
                                                        content: content, 
                                                        filePath: xmlFilePath, 
                                                        xmlPath: xmlPath, 
                                                        dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                        docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                    };
                                                
                                            });
                                    }else{
                                        return Promise.resolve();
                                    }
                                    
                                })
                        );
            
                    });         
                
            var frontMatterToc = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /TDMG/.test(file);
                            })
                            .map( file => {
        
                                var found = file.match(/([0-9]*)_JCQ_/);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-frontmatter-toc-g.xsl',
                                            params: {
                                                pubNum: pubNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-ptoc01a.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                    docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                };
                                                
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });         
        
            var detailedToc = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /TDM[I|V|X]+/.test(file);
                            })
                            .map( file => {
                                
        
                            var found = file.match(/([0-9]+)_JCQ_[0-9]+-TDM([I|V|X]+)_/);
                                if(found){
                                    
                                    var tocValues = {'I': "1", 'II': "2", 'III':"3", 'IV':"4", 'V':"5", "VI": "6", "VII": "7", "VIII": "8", "IX":9, "X":10};
                                    var pubNum = found[1].padStart(5, "0"),
                                        volNum = tocValues[found[2]],
                                        tocNumber = volNum.padStart(2, "0");
                                        var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-frontmatter-toc.xsl',
                                            params: {
                                                pubNum: pubNum,
                                                tocNumber: tocNumber,
                                                volNum: volNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-ptoc' + tocNumber + '.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;

                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/frontmatterV015-0000.dtd',
                                                    docType: '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">'
                                                };
                                                
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });

            var fascicles = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(fascicleFilter)
                            .map( file => {
                                
                                var found = file.match(/([0-9]*)_JCQ_[0-9]*-F([0-9]*)_[^.]*\.inline\.html\.db\.xml$/);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0"),
                                        chapterNum = found[2].padStart(4, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
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
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/treatiseV021-0000.dtd',
                                                    docType: '<!DOCTYPE tr:ch PUBLIC "-//LEXISNEXIS//DTD Treatise-pub v021//EN//XML" "treatiseV021-0000.dtd">'
                                                };
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
    
                });
            
            var legisIndex = fsReadDir(collectionFolder + '/xml')
                .then( files => {
                    
                    return Promise.all(
                        
                        files
                            .filter(function(file){
                                return filter.test(file);
                            })
                            .filter(function(file){
                                return /Index de la /.test(file);
                            })
                            .map( file => {
    
                            var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index de la /);
                                if(found){
                                    
                                    var pubNum = found[1].padStart(5, "0");
                                    var xmlPath = collectionFolder + '/xml/' + file;
                                    return saxon
                                        .exec({
                                            xmlPath: xmlPath, 
                                            xslPath: __dirname + '/../../xslt/neptune-tos.xsl',
                                            params: {
                                                pubNum: pubNum
                                            }
                                        })
                                        .then( response => response.stdout )
                                        .then( content => {
        
                                                var newFileName = pubNum + '-tos001.xml';
                                                var xmlFilePath = neptunePath + '/' + newFileName;
                                                return { 
                                                    content: content, 
                                                    filePath: xmlFilePath, 
                                                    xmlPath: xmlPath, 
                                                    dtdPath: './../../neptune/endmatterxV018-0000.dtd',
                                                    docType: '<!DOCTYPE em:table PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">'
                                                };
                                            
                                        });
                                }else{
                                    return Promise.resolve();
                                }
                                
                            })
                    );
        
                });

            var index = fsReadDir(collectionFolder + '/xml')
            .then( files => {
                
                return Promise.all(
                    
                    files
                        .filter(function(file){
                            return filter.test(file);
                        })
                        .filter(function(file){
                            return /Index a/.test(file);
                        })
                        .map( file => {
    
                        var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index a/);
                            if(found){
                                
                                var pubNum = found[1].padStart(5, "0");
                                var xmlPath = collectionFolder + '/xml/' + file;
                                return saxon
                                    .exec({
                                        xmlPath: xmlPath, 
                                        xslPath: __dirname + '/../../xslt/neptune-index.xsl',
                                        params: {
                                            pubNum: pubNum
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '-index.xml';
                                            var xmlFilePath = neptunePath + '/' + newFileName;
                                            return { 
                                                content: content, 
                                                filePath: xmlFilePath, 
                                                xmlPath: xmlPath, 
                                                dtdPath: './../../neptune/endmatterxV018-0000.dtd',
                                                docType: '<!DOCTYPE em:index PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">'
                                            };
                                            
                                        
                                    });
                            }else{
                                return Promise.resolve();
                            }
                            
                        })
                );
    
            });

            var toclist = fsReadDir(collectionFolder + '/xml')
            .then( files => {
                
                return Promise.all(
                    
                    files
                        .filter(function(file){
                            return filter.test(file);
                        })
                        .filter(function(file){
                            return /publication/.test(file);
                        })
                        .map( file => {
    
                        var found = file.match(/([0-9]+)_JCQ_[0-9]+-/);
                            if(found){
                                
                                var pubNum = found[1].padStart(5, "0");
                                
                                var xmlPath = collectionFolder + '/xml/' + file;
                                return saxon
                                    .exec({
                                        xmlPath: xmlPath, 
                                        xslPath: __dirname + '/../../xslt/neptune-endmatter-toclist.xsl',
                                        params: {
                                            pubNum: pubNum
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '-toclist.xml';
                                            var xmlFilePath = neptunePath + '/' + newFileName;

                                            return { 
                                                content: content, 
                                                filePath: xmlFilePath, 
                                                xmlPath: xmlPath, 
                                                dtdPath: './../../neptune/endmatterxV018-0000.dtd',
                                                docType: '<!DOCTYPE em:table PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">'
                                            };
                                        
                                    });
                            }else{
                                return Promise.resolve();
                            }
                            
                        })
                );
    
            });

            return Promise.all([frontMatterTitle, frontMatterPreface, frontMatterForeword, frontMatterFeature, frontMatterToc, fascicles, detailedToc, legisIndex, index, toclist])
                .then( fileTypes => {
                    var files = [];
                    fileTypes.forEach(function(fileType){
                        fileType.forEach( function(file){
                            files.push(file);
                        });
                    })

                    var sorted = _.sortBy(files, function(file){
                        var fileName = _.last(file.xmlPath.split('/'));
                        var match = fileName.match(/^[0-9]+_JCQ_([0-9]+)-/);
                        if(match){
                            return match[1];
                        }
                        return fileName;
                    });

                    var volnum = "1";
                    
                    return _.reduce(sorted, function(promise, file, index){
                        return promise.then(function(){

                            var volNumMatch = file.filePath.match(/\-ptoc([0-9]+)\.xml$/);
                            if(volNumMatch){
                                volnum = parseInt(volNumMatch[1]);
                            }
                            var xppContent;

                            if(sorted[index+1]){
                                var match = sorted[index+1].content.match(/page-num=\"([A-ZÉ\-0-9]+)"\srelease-num="/);
                                if(match && match[1]){
                                    xppContent = file.content.replace(/<\?xpp nextpageref=""\?>/, "<?xpp XppPI nextpageref=\"" + match[1] + "\"?>");
                                }else{
                                    xppContent = file.content.replace(/<\?xpp nextpageref=""\?>/, "<?xpp XppPI nextpageref=\"NOT_FOUND\"?>");
                                }
                            }else{
                                xppContent = file.content.replace(/<\?xpp nextpageref=""\?>/, "");
                            }

                            xppContent = xppContent.replace(/volnum=""/g, `volnum="${volnum}"`);

                            var htmlPath = file.xmlPath.replace('/xml/', '/html/').replace('.inline.html.db.xml', '.html'),
                                tempXml = file.filePath.replace('/neptune/','/temp/');
                            
                            return fsWriteFile(tempXml, xppContent)
                                .then(() => {

                                    var diffPromise = Promise.all([exportHtmlText(htmlPath), exportXmlText(tempXml)])
                                        .then( (promises) => {
                                            var htmlContent = promises[0].replace(/\r\n/g,'').replace(/\u00AD/g,''),
                                                xmlContent = promises[1].replace(/\r\n/g,'');
                                            var diffPath = htmlPath.replace('/html/', '/neptune/').replace('.html', '-diff.html');
                                            var diffContent = diff.exec(htmlContent, xmlContent);
                                            var diffCount = diffContent.match(/<ins|<del/g);
                                            if(diffCount){
                                                console.log(htmlPath, "Integrity Errors:", diffCount.length);
                                            }
                                            return fsWriteFile(diffPath, wrapInHtml(diffContent)); 
                                        }).then( () => {
                                            return neptuneLast(tempXml)
                                                .then( (lastContent) => {
                                                    return fsWriteFile(file.filePath, lastContent);
                                                });
                                        });

                                    return diffPromise.then(() => {
                                        return xmllint.exec({
                                            xmlPath: file.filePath,
                                            dtdPath: file.dtdPath
                                        })
                                        .then( () => { 
                                            console.log(file.filePath);
                                         })
                                        .catch( output => {
                                            console.log(file.filePath + " with " + output.stderr.split("\n") + "errors");
                                        });
                                    }).then(() =>{
                                        return fsReadFile(file.filePath, 'utf8').
                                            then( (data) => {
                                                var content = data.replace('<?xml version="1.0" encoding="UTF-8"?>', '<?xml version="1.0" encoding="UTF-8"?>' + file.docType);
                                                return fsWriteFile(file.filePath, content);
                                            });
                                    });

                                });
                            
                            
                        });
                    }, Promise.resolve());

                });
    
        });
    
    }
    

function transformPackages(paths, collectionFilter, filter){
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
                                        return transformCollection(collectionPath, filter) 
                                    });
                                }, Promise.resolve() 
                        );

                });
        })
    );
}

function exportHtmlText(filePath){
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: __dirname + '/../../xslt/extract-html-final-text.xsl'
        })
        .then( response => response.stdout );
}

function exportXmlText(filePath){
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: __dirname + '/../../xslt/extract-neptune-text.xsl'/*,
            options: {
                catalog: "/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/neptune/catalog.xml"
            }*/
        })
        .then( response => response.stdout );
}function exportXmlText(filePath){
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: __dirname + '/../../xslt/extract-neptune-text.xsl'/*,
            options: {
                catalog: "/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/neptune/catalog.xml"
            }*/
        })
        .then( response => response.stdout );
}

function neptuneLast(filePath){
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: __dirname + '/../../xslt/neptune-last.xsl'/*,
            options: {
                catalog: "/Users/eas/Documents/dev/projects/lexis-nexis/vimmit002/neptune/catalog.xml"
            }*/
        })
        .then( response => response.stdout );
}

exports.transformPackages = transformPackages;