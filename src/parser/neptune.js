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
    chalk = require('chalk'),
    filterManualFixes = require('./manualFiles').filterManualFixes;

var systemError = console.error;

console.error = function(){
    var args = Object.values(arguments).map( arg => chalk.red(arg) );
    systemError.apply(null, args);
};

const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);

var titles = {
    '06018': 'DROIT DE L’ENVIRONNEMENT',
    '05985': 'BIENS ET PUBLICITÉ',
    '06020': 'BANCAIRE',
    '06025': 'DE LA CONCURRENCE'
}

function transformFile(file, path, filter){

    var xsl, params, newFileName, xmlFilePath;

    if(/Page de titre/.test(file)){
        
        xsl = '/../../xslt/neptune-frontmatter-title.xsl';
        var found = file.match(/([0-9]*)_JCQ_/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum,
                collectionTitle: titles[pubNum]
            };
        }
        newFileName = pubNum + '-fmvol001.xml';

    }else if(/Pr.*face/.test(file)){

        xsl = '/../../xslt/neptune-frontmatter-preface.xsl';
        var found = file.match(/([0-9]*)_JCQ_/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-fmvol001pre.xml';

    }else if(/Avant-propos/.test(file)){

        xsl = '/../../xslt/neptune-frontmatter-foreword.xsl';
        var found = file.match(/([0-9]*)_JCQ_/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-fmvol001ap.xml';

    }else if(/biographiques/.test(file)){
        
        xsl = '/../../xslt/neptune-frontmatter-feature.xsl';
        var found = file.match(/([0-9]*)_JCQ_/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-fmvol001bio.xml';

    }else if(/TDMG/.test(file)){
        
        xsl = '/../../xslt/neptune-frontmatter-toc-g.xsl';
        var found = file.match(/([0-9]*)_JCQ_/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-ptoc01a.xml';

    }else if(/TDM[I|V|X]+/.test(file)){
        
        xsl = '/../../xslt/neptune-frontmatter-toc.xsl';
        var found = file.match(/([0-9]+)_JCQ_[0-9]+-TDM([I|V|X]+)/);
        if(found){
            var tocValues = {'I': "1", 'II': "2", 'III':"3", 'IV':"4", 'V':"5", "VI": "6", "VII": "7", "VIII": "8", "IX":9, "X":10};
            var pubNum = found[1].padStart(5, "0"),
                volNum = tocValues[found[2]],
                tocNumber = volNum.padStart(2, "0");
            params = {
                pubNum: pubNum,
                tocNumber: tocNumber,
                volNum: volNum
            };
        }
        newFileName = pubNum + '-ptoc' + tocNumber + '.xml';

    }else if(/-F[0-9\.]+.*.xml$/.test(file)){

        xsl = '/../../xslt/neptune-fascicle.xsl';
        var found = file.match(/([0-9]*)_JCQ_[0-9]*-F([0-9\.]*)[^.]*\.inline\.html\.db\.xml$/);
        if(found){
            var pubNum = found[1].padStart(5, "0"),
                chapterNum = found[2].padStart(4, "0");
            params = {
                pubNum: pubNum,
                chNum: chapterNum
            };
        }
        newFileName = pubNum + '-ch' + chapterNum + '.xml';

    }else if(/Index de la /.test(file)){

        xsl = '/../../xslt/neptune-tos.xsl';
        var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index de la /);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-tos001.xml';

    }else if(/Index a/.test(file)){

        xsl = '/../../xslt/neptune-index.xsl';
        var found = file.match(/([0-9]+)_JCQ_[0-9]+-Index a/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-index.xml';

    }else if(/publication/.test(file)){

        xsl = '/../../xslt/neptune-endmatter-toclist.xsl';
        var found = file.match(/([0-9]+)_JCQ_[0-9]+-/);
        if(found){
            var pubNum = found[1].padStart(5, "0");
            params = {
                pubNum: pubNum
            };
        }
        newFileName = pubNum + '-toclist.xml';
    }else{
        console.error(`${file} parser not found.`)
        return Promise.resolve(false);
    }

    return saxon
        .exec({
            xmlPath: path + '/' + file, 
            xslPath: __dirname + xsl,
            params: params
        })
        .then( response => response.stdout )
        .then( content => {

                return { 
                    content: content, 
                    filePath: path.replace('/xml','/neptune') + '/' + newFileName, 
                    xmlPath: path + '/' + file
                };
            
        });
}

function transformCollection(collectionFolder, filter){
    
    console.info('transformCollection()', collectionFolder);

    var neptunePath = collectionFolder + '/neptune';
    
    return fxMkDir(neptunePath)
            .then( () => {
            
                return fsReadDir(collectionFolder + '/xml')
                    .then( files => {
                        return Promise.all(
                            files
                                .filter( file => /\.xml$/.test(file) )
                                .filter( file => !/Instructions/.test(file) )
                                .filter( file => !/Introduction/.test(file) )
                                .filter(function(file){
                                    return filter.test(file);
                                })
                                .filter(filterManualFixes)
                                .map( file => transformFile(file, collectionFolder + '/xml', filter))

                        ).then( files => {
                            
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
        
                                    xppContent = xppContent.replace(/(<fn:endnote-id er=")([0-9])"\/>[\r\n]*<core:emph typestyle="su">([0-9])<\/core:emph>/gim,function(match, p1, p2, p3){ return p1+p2+p3+"\"/>";});
                                    xppContent = xppContent.replace(/(<fn:endnote-id er=")([0-9])"\/>[\r\n]*<fn:endnote-id er="([0-9])("\/>)/gim, function(match, p1, p2, p3, p4){ return p1+p2+p3+p4;});

                                    xppContent = xppContent.replace(/(<[a-z])/g,function(match, p1){ return "\r\n"+p1; });

                                    xppContent = xppContent.replace(/<core:emph typestyle="smcaps-su">([^<]*)<\/core:emph>/gim,function(match, p1, p2, p3){ 
                                        return '<core:emph typestyle="smcaps"><core:emph typestyle="su">' + p1 + '</core:emph></core:emph>';
                                    });

                                    while(/<core:emph typestyle="bf">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="bf">([^<]*)<\/core:emph>/.test(xppContent)){
                                        xppContent = xppContent.replace(/<core:emph typestyle="bf">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="bf">([^<]*)<\/core:emph>/gm, function(match, p1, p2, p3){ 
                                            return "<core:emph typestyle=\"bf\">" + p1 + p2 + p3 + "</core:emph>";
                                        });
                                    }
        
                                    while(/<core:emph typestyle="it">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="it">([^<]*)<\/core:emph>/.test(xppContent)){
                                        xppContent = xppContent.replace(/<core:emph typestyle="it">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="it">([^<]*)<\/core:emph>/gm, function(match, p1, p2, p3){ 
                                            return "<core:emph typestyle=\"it\">" + p1 + p2 + p3 + "</core:emph>";
                                        });
                                    }
        
                                    while(/<core:emph typestyle="su">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="su">([^<]*)<\/core:emph>/.test(xppContent)){
                                        xppContent = xppContent.replace(/<core:emph typestyle="su">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="su">([^<]*)<\/core:emph>/gm, function(match, p1, p2, p3){ 
                                            return "<core:emph typestyle=\"su\">" + p1 + p2 + p3 + "</core:emph>";
                                        });
                                    }
        
                                    while(/<core:emph typestyle="sb">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="sb">([^<]*)<\/core:emph>/.test(xppContent)){
                                        xppContent = xppContent.replace(/<core:emph typestyle="sb">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="sb">([^<]*)<\/core:emph>/gm, function(match, p1, p2, p3){ 
                                            return "<core:emph typestyle=\"sb\">" + p1 + p2 + p3 + "</core:emph>";
                                        });
                                    }
        
                                    while(/<core:emph typestyle="ib">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="ib">([^<]*)<\/core:emph>/.test(xppContent)){
                                        xppContent = xppContent.replace(/<core:emph typestyle="ib">([^<]*)<\/core:emph>(\s*)<core:emph typestyle="ib">([^<]*)<\/core:emph>/gm, function(match, p1, p2, p3){ 
                                            return "<core:emph typestyle=\"ib\">" + p1 + p2 + p3 + "</core:emph>";
                                        });
                                    }
        
                                    xppContent = xppContent.replace(/volnum=""/g, `volnum="${volnum}"`);
        
                                    var htmlPath = file.xmlPath.replace('/xml/', '/html/').replace('.inline.html.db.xml', '.html'),
                                        tempXml = file.filePath.replace('/neptune/','/temp/');
                                    
                                    return fsWriteFile(tempXml, xppContent)
                                        .then(() => {
        
                                            console.log(tempXml);
        
                                        });
                                    
                                    
                                });
                            }, Promise.resolve());
        
                        });

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

exports.transformPackages = transformPackages;