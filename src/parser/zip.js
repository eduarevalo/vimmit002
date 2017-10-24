const fs = require('fs'),
    unzip = require('unzip'),
    inlineCss = require('inline-css'),
    util = require('util'),
    fsReadFile = util.promisify(fs.readFile),
    fsReadDir = util.promisify(fs.readdir),
    fsWriteFile = util.promisify(fs.writeFile);

const pathToEpub = '/Users/eas/Documents/dev/projects/lexis-nexis/conversion/6018_JCQ_10-F03_MJ9.epub',
    pathToExport = '/Users/eas/Documents/dev/projects/lexis-nexis/conversion/export';

const inlineCssParser = function(html){
    var replaces = {
        // HTML TAGS FIXES
        '<(img|col|meta|hr) ([a-z]*="[^"]*" ?)*>': function(match){ return match.substring(0, match.length - 1) + '/>'; },
        '<br\s*>': '<br/>',
        'style=\"([^\"]*)\"': function(matched, content){ 
            var found = content.match(/-webkit-transform: translate\([0-9|\.]*px,([0-9|\.]*)px\)/);
            if(found){
                return `style="${content}" top-transform="${parseInt(found[1])}"`; 
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

const createInlineCSSFile = function(path, fileIn, fileOut){
    return new Promise(function(resolve, reject){
        fsReadFile(path + '/' + fileIn, 'utf8')
            .then(function (htmlData) {
                inlineCss(htmlData, { url: 'file:///' + path })
                    .then(inlineCss => {
            
                        fsWriteFile(path + fileOut, inlineCssParser(inlineCss), 'utf8')
                            .then(resolve);
                    })
            });
    });
}

const injectXhtmlFiles = function(path){
    return function(){
        return fsReadDir(path + '/OEBPS')
            .then( files => {
                return Promise.all(
                    files
                        .filter( file => /\.xhtml$/.test(file) )
                        .map( file => createInlineCSSFile(path + '/OEBPS/',  file, 'xInline.' + file) )
                );
            });
    };
};

    fs
    .createReadStream(pathToEpub)
    .pipe(unzip.Extract({ path: pathToExport }))
    .on('finish', injectXhtmlFiles(pathToExport));