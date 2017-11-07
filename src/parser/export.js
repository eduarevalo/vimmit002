const fs = require('fs'),
    tmp = require('tmp'),
    exec = require('child_process').exec,
    util = require('util');

const runJsxCommand = '"/Applications/Adobe\ ExtendScript\ Toolkit\ CC/ExtendScript\ Toolkit.app/Contents/MacOS/ExtendScript\ Toolkit" -run ';

const fsReadFile = util.promisify(fs.readFile),
    fsReadDir = util.promisify(fs.readdir);

function createFilter(filter){
    return function(input){
        return (new RegExp(filter)).test(input);
    }
}

function filterInvalidFiles(input){
    return !createFilter('\.DS_Store$|.*\.json$')(input);
}

function exportCollection(path, filter){
    var collectionsWithBatchFiles = fsReadDir(path)
            .then(collections => {
                return Promise.all(
                    collections
                        .filter( filterInvalidFiles )
                        .filter( createFilter(filter) )
                        .map( collection => {

                            var collectionPath = [path, collection, 'indd'].join('/');
                            return fsReadDir(collectionPath)
                                .then(files => {
                                        return files
                                            .filter( file => !/Instructions/.test(file) )
                                            .filter( createFilter('\.indd$') )
                                            .map( inddFile => {
                                                return {
                                                    indd: [collectionPath, inddFile].join('/'),
                                                    html: [collectionPath, inddFile].join('/').replace('.indd', '.html').replace('/indd/', '/html/'),
                                                    epub: [collectionPath, inddFile].join('/').replace('.indd', '.epub').replace('/indd/', '/temp/')
                                                };
                                            });
                                    });
                            
                        })      
                );
            });
        
    return collectionsWithBatchFiles
        .then( collections => {

            var allCollections = [].concat.apply([], collections);
            return runScript(allCollections);
            
        });

}

function exportPackage(path, filter){
    return exportCollection(path, filter);
}

function exportPackages(paths, filter){
    return Promise.all(paths.map( path  => {
        return exportPackage(path.replace('/in/', '/out/'), filter);
    }));
}

function runScript(batchFiles) {

    return fsReadFile('./export-files.jsx', 'utf8')
        .then(function (jsxScript) {

            return new Promise( (resolve, reject) => {

                tmp.file({postfix: '.jsx' }, function(err, path, fd, cleanupCallback) {
                    if (err) throw err;
                
                    console.log('Jsx Script: ', path, ' with ' + batchFiles.length + ' files');
            
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
                        }, batchFiles.length * 1000 * 10);
            
                    });
            
                });

            });

        });

};

exports.exportPackages = exportPackages;