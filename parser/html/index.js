
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
    return /.html$/.test(input);
}

function folderFilter(input){
    return /_Version courante$/.test(input);
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

function processCollection(collectionFolder){
    
    console.log('processCollection()', collectionFolder);

    var outPath = collectionFolder + '/xml';

    return fsReadDir(collectionFolder + '/html')
        .then( files => {
            
            var htmlFiles = files.filter(htmlFilter);
            
            var docBook = htmlFiles.map(file => {
                return docbook.exec(collectionFolder + '/html/' + file)
                    .then( response => response.stdout )
                    .then( content => {
                        var xmlFilePath = outPath + '/' + file + '.db.xml';
                        return fsWriteFile(xmlFilePath, content)
                            .then(() => xmlFilePath);
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
                            return fsWriteFile(collectionFolder + '/results.txt', txtResults.join("\r\n"), 'utf8');
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
    
function convertPackages(paths){
    return Promise.all(paths
        .map( path => path.replace('/in/', '/out/') )
        .map( path => {
                
            return fsReadDir(path)
                .then(collections => {

                    var collectionsResults = {};

                    return collections
                        .filter( collection => !_.includes(['.DS_Store', 'results.json', 'results.txt'], collection) )
                        .reduce( (promise, collection) => {
                                var collectionPath = path + '/' + collection;
                                return promise
                                    .then(() => {
                                        return processCollection(collectionPath) 
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
                ? convertPackages(packages)
                : Promise.resolve();
                    
        })
        .then(function(){
            console.log('FINISHED');
        });
    
})();