const fs = require('fs'),
    saxon = require('./../saxon'),
    _ = require('lodash'),
    unzip = require('unzip'),
    exec = require('child_process').exec,
    util = require('util');

const fsReadFile = util.promisify(fs.readFile),
    fsReadDir = util.promisify(fs.readdir),
    fsWriteFile = util.promisify(fs.writeFile);

function createFilter(filter){
    return function(input){
        return (new RegExp(filter)).test(input);
    }
}

function normalizePath(path){
    return path;
    return path.replace(/ /g, '_').replace(/\'/g, '');
}

function filterInvalidFiles(input){
    return !createFilter('\.DS_Store$|.*\.json$')(input);
}

function unzipEpubFiles(path, collection, collectionPath){
    return fsReadDir(collectionPath)
        .then(files => {
            return Promise.all(
                    files
                    .filter( createFilter('\.epub$') )
                    .map( (epubFile, index) => {
                        
                        return new Promise(function(resolve, reject){

                            var exportPath = normalizePath([collectionPath, 'folder_' + epubFile.replace('.epub','')].join('/'));
                            fs
                            .createReadStream([collectionPath, epubFile].join('/'))
                                .pipe(unzip.Extract({ path: exportPath }))
                                .on('finish', resolve);
                            
                        });
                    

                    })
            );
        });
}

function unzipCollection(path, filter){
    return fsReadDir(path)
        .then(collections => {
            return Promise.all(
                collections
                    .filter( filterInvalidFiles )
                    .filter( createFilter(filter) )
                    .map( collection => {

                        return unzipEpubFiles(path, collection, [path, collection, 'temp'].join('/'));

                    })      
            );
        });
}

function unzipPackage(path, filter){
    return unzipCollection(path, filter);
}

function unzipPackages(paths, filter){
    return Promise.all(paths.map( path  => {
        return unzipPackage(path.replace('/in/', '/out/'), filter);
    }));
}

exports.unzipPackages = unzipPackages;