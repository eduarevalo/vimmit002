const fs = require('fs'),
    util = require('util'),
    fx = require('mkdir-recursive');

const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);

const folderMapping = { 
    'INDD': 'indd',
    'InDesign': 'indd',
    'PDF': 'pdf'
};

function makeDir(folderPath){
    return fs.existsSync(folderPath)
        ? Promise.resolve()
        : fxMkDir(folderPath);
}
function copyFile(src, dest) {
    return new Promise((resolve, reject) => {
        let readStream = fs.createReadStream(src);
        readStream.once('error', reject);
        readStream.once('end', resolve);
        readStream.pipe(fs.createWriteStream(dest));
    });
}

function prepareFolders(path, folders){
    return folders.reduce( (promise, folder) => {
        return makeDir(path + '/' + folder);
    }, Promise.resolve);
}

function createFilter(filter){
    return function(input){
        return (new RegExp(filter)).test(input);
    }
}

function filterInvalidFiles(input){
    return !createFilter('\.DS_Store$|.*\.json$')(input);
}

function copySourceFiles(path, collectionPath, folderMapping){

    var renditionFolderMapping = function(folderName){
        return Object.keys(folderMapping).find( folderKey => (new RegExp(folderKey)).test(folderName) );
    }

    return fsReadDir(path)
        .then( renditions => { 
            return Promise.all(
                renditions
                    .filter( renditionFolderMapping )
                    .map( rendition => {
                        var fileType = folderMapping[renditionFolderMapping(rendition)];
                        var renditionPath = [path, rendition].join('/');
                        return fsReadDir(renditionPath)
                            .then(files => {
                                
                                return Promise.all(files
                                    .map(file => {

                                        var inddFilePath = renditionPath + '/' + file;

                                        return (new RegExp(fileType + '$')).test(inddFilePath)
                                            ? copyFile(inddFilePath, [collectionPath, fileType, file].join('/'))
                                            : Promise.resolve();
                                    }));
                            });
                    })
            );
        });
}

function prepareCollection(path, filter){
    return fsReadDir(path)
            .then(collections => {
                return Promise.all(
                    collections
                        .filter( filterInvalidFiles )
                        .filter( createFilter(filter) )
                        .map( collection => {

                            var collectionPath = [path.replace('/in/', '/out/'), collection].join('/');
                            return makeDir(collectionPath)
                                .then( () => prepareFolders(collectionPath, ['xml', 'html', 'temp', 'pdf', 'indd', 'neptune', 'report']) )
                                .then( () => copySourceFiles([path, collection].join('/'), collectionPath, folderMapping) );
                        })      
                );
            });
}

function preparePackage(path, filter){
    return prepareCollection(path, filter);
}

function preparePackages(paths, filter){
    return Promise.all(paths.map( path  => {
        return preparePackage(path, filter);
    }));
}

function runScript(){
    return fsReadFile('./export-single-html.jsx', 'utf8')
        .then(function (data) {
            jsxScript = data;
            return preparePackages(packages, filter)
        });
}

exports.preparePackages = preparePackages;