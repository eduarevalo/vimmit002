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
    exec = require('child_process').exec;

const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);
    

function fascicleFilter(input){
    return /-F[0-9]+.*.xml$/.test(input);
    //6018_JCQ_09-F02_MJ8.indd.inline.html.db.xml
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
    
                                var found = file.match(/([0-9]*)_JCQ_[0-9]*-F([0-9]*)_[^.]*\.inline\.html\.db\.xml$/);
                                if(found){
                                    console.log(found);
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
        
            var frontMatter = fsReadDir(collectionFolder + '/xml')
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
                            console.log(file);
    
                            var found = file.match(/([0-9]*)_JCQ_/);
                            if(found){
                                console.log(found);
                                var pubNum = found[1].padStart(5, "0");
    
                                return saxon
                                    .exec({
                                        xmlPath: collectionFolder + '/xml/' + file, 
                                        xslPath: __dirname + '/../../xslt/neptune-frontmatter.xsl',
                                        params: {
                                            pubNum: pubNum, 
                                            prefaceFile: collectionFolder + '/xml/' + files.find( file => /Préface/.test(file)),
                                            forewordFile: collectionFolder + '/xml/' + files.find( file => /Avant-propos/.test(file)),
                                            featureFile: collectionFolder + '/xml/' + files.find( file => /Notices_biographiques/.test(file)),
                                            tocFile: collectionFolder + '/xml/' + files.find( file => /TDMG/.test(file))
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '_fmvol001.xml';
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
                            console.log(file);
    
                        var found = file.match(/([0-9]+)_JCQ_[0-9]+-TDM([I|V|X]+)_/);
                            if(found){
                                console.log(found);
                                var tocValues = {'I': "1", 'II': "2", 'III':"3", 'IV':"4", 'V':"5", "VI": "6", "VII": "7", "VIII": "8", "IX":9, "X":10};
                                var pubNum = found[1].padStart(5, "0"),
                                    tocNumber = tocValues[found[2]].padStart(2, "0");
                                
                                return saxon
                                    .exec({
                                        xmlPath: collectionFolder + '/xml/' + file, 
                                        xslPath: __dirname + '/../../xslt/neptune-toc.xsl',
                                        params: {
                                            pubNum: pubNum,
                                            tocNumber: tocNumber
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '-ptoc' + tocNumber + '.xml';
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
                            console.log(file);
    
                        var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index de la /);
                            if(found){
                                console.log(found);
                                var pubNum = found[1].padStart(5, "0");
                                
                                return saxon
                                    .exec({
                                        xmlPath: collectionFolder + '/xml/' + file, 
                                        xslPath: __dirname + '/../../xslt/neptune-tos.xsl',
                                        params: {
                                            pubNum: pubNum
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '-tos001.xml';
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
                            console.log(file);
    
                        var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index a/);
                            if(found){
                                console.log(found);
                                var pubNum = found[1].padStart(5, "0");
                                
                                return saxon
                                    .exec({
                                        xmlPath: collectionFolder + '/xml/' + file, 
                                        xslPath: __dirname + '/../../xslt/neptune-index.xsl',
                                        params: {
                                            pubNum: pubNum
                                        }
                                    })
                                    .then( response => response.stdout )
                                    .then( content => {
    
                                            var newFileName = pubNum + '-index.xml';
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

            return Promise.all([fascicles, frontMatter, detailedToc, legisIndex, index]);
    
        });
    
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

exports.transformPackages = transformPackages;