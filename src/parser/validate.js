const fs = require('fs'),
    util = require('util'),
    fx = require('mkdir-recursive'),
    exec = require('child_process').exec,
    _ = require('lodash'),
    chalk = require('chalk'),
    saxon = require('./../saxon'),
    xmllint = require('./xmllint'),
    diff = require('./diff3'),
    moment = require('moment'),
    validatedData = require('./validatedData.json');
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

const templatePath = './template/validation-report.hbs',
    tempPaths = ['./template/temp.html','./../../data/out/validation-report-' + moment().format('YYYYMMDDHHmm') + '.html'];

var results = {};

/*
 *  Global functions
 *
 *  This function should be called after reading the file
 */
function renderToString(source, data) {
  const handlebars = require('handlebars');
  const handlebarsIntl = require('handlebars-intl');
  handlebarsIntl.registerWith(handlebars);
  handlebarsHelpers = require('handlebars-helpers');
  handlebarsHelpers.math({
    handlebars: handlebars
  });
  handlebars.registerHelper('currency', function(options) {
      return '';
    //return "$ " +(""+options.toFixed(2)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  });
    handlebars.registerHelper('lastPath', function(options) {
        return _.last(options.split('/'));
    });
    handlebars.registerHelper('firstExtensionPart', function(options) {
        return _.first(options.split('.'));
    });
    handlebars.registerHelper('doneClass', function(options) {
        return options ? " strikeout " : "";
    });
    handlebars.registerHelper('acceptedClass', function(options) {
        return options ? " accepted " : "";
    });
  var template = handlebars.compile(source, { noEscape: true });
  
  var outputString = template({data: data}, {
    data: {
      locales: 'fr-CA'
    }
  });
  return outputString;
}

/*
 * This calculates taxes, and subtotal per data line
 */
function calculateData(data){
    
    for(var i=0; i<data.length; i++){
        data[i].path = data[i].path.split('/../../')[1];
        data[i].collectionCount = Object.keys(data[i].json).length;
    }

    var tasks = [
        { description: 'Indd -> Interchange: End to end tool', done: true },
        { description: 'Indd -> Interchange: Report tool', done: true },
        { description: 'Indd -> Interchange: Left-Right Headers & Release-Number', done: true },
        { description: 'Indd -> Interchange: Page numbers', done: true },
        { description: 'Indd -> Interchange: Page numbers tests', done: false },
        { description: 'Indd -> Interchange: Treatise / Fascicles Parsing Package 1', done: true },
        { description: 'Indd -> Interchange: Treatise / Fascicles Parsing Package 2', done: true },
        { description: 'Indd -> Interchange: Treatise / Fascicles Parsing Package 3', done: false },
        { description: 'Indd -> Interchange: Treatise / Fascicles Parsing Package 4', done: false },
        { description: 'Indd -> Interchange: FrontMatter Parsing Package 1', done: true },
        { description: 'Indd -> Interchange: FrontMatter Parsing Package 2', done: true },
        { description: 'Indd -> Interchange: FrontMatter Parsing Package 3', done: false },
        { description: 'Indd -> Interchange: FrontMatter Parsing Package 4', done: false },
        { description: 'Indd -> Interchange: Detailed TOC Parsing Package 1', done: true },
        { description: 'Indd -> Interchange: Detailed TOC Parsing Package 2', done: true },
        { description: 'Indd -> Interchange: Detailed TOC Parsing Package 3', done: false },
        { description: 'Indd -> Interchange: Detailed TOC Parsing Package 4', done: false },
        { description: 'Indd -> Interchange: Table of Statutes Parsing Package 1', done: true },
        { description: 'Indd -> Interchange: Table of Statutes Parsing Package 2', done: true },
        { description: 'Indd -> Interchange: Table of Statutes Parsing Package 3', done: true },
        { description: 'Indd -> Interchange: Table of Statutes Parsing Package 4', done: true },
        { description: 'Indd -> Interchange: Index Parsing Package 1', done: true },
        { description: 'Indd -> Interchange: Index Parsing Package 2', done: true },
        { description: 'Indd -> Interchange: Index Parsing Package 3', done: true },
        { description: 'Indd -> Interchange: Index Parsing Package 4', done: true },
        { description: 'Indd -> Interchange: Parsing Blockquotes', done: false },
        { description: 'Interchange -> Neptune: Treatise / Fascicles', done: true },
        { description: 'Interchange -> Neptune: Treatise / Fascicles DTD Validation', done: true },
        { description: 'Interchange -> Neptune: Treatise / Fascicles tests', done: true },
        { description: 'Interchange -> Neptune: FrontMatter', done: false },
        { description: 'Interchange -> Neptune: FrontMatter -> TOC levels', done: false },
        { description: 'Interchange -> Neptune: FrontMatter DTD Validation', done: false },
        { description: 'Interchange -> Neptune: FrontMatter tests', done: false },
        { description: 'Interchange -> Neptune: Detailed TOC', done: false },
        { description: 'Interchange -> Neptune: Detailed TOC DTD Validatiom', done: false },
        { description: 'Interchange -> Neptune: Detailed TOC tests', done: false },
        { description: 'Interchange -> Neptune: Table of Statutes', done: false },
        { description: 'Interchange -> Neptune: Table of Statutes DTD Validation', done: false },
        { description: 'Interchange -> Neptune: Table of Statutes tests', done: false },
        { description: 'Interchange -> Neptune: Index', done: false },
        { description: 'Interchange -> Neptune: Index DTD Validation', done: false },
        { description: 'Interchange -> Neptune: Index tests', done: false },
        { description: 'Interchange -> Neptune: Input/Output comparison report', done: false }
    ];

    var validations = [
        { document: '5996_JCQ_08-F02_MJ13.indd', description: 'Invalid TOC Level : "1.	Travail subordonné " tagged as TM-A-', fix: 'Replace index level to TM-1-', accepted: false },
        { document: '6018-F0*.indd', description: 'Footnote/First page - Position of Note de remerciements - Invalid Page Numbers', fix: 'Move the note to the last content of the page', accepted: false }
    ];

    return { packages: data, tasks, validations };
}

function createReport(){
    
    //var results = calculateData(results);

    // read the file and use the callback to render
    fs.readFile(templatePath, function(err, data){

      if (!err) {
          
        // make the buffer into a string
        var source = data.toString();
        // call the render function
        var preparedFile = renderToString(source, results);

        return Promise.all(tempPaths.map(function(tempPath){
            return fs.writeFile(tempPath, preparedFile, function(err) {
                if(err) {
                  return console.log(err);
                }
                console.log(`${tempPath} was saved!`);
              });
        }));
        

      } else {
            console.log(err);
      }
    });
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
            xslPath: __dirname + '/../../xslt/extract-neptune-text.xsl'
        })
        .then( response => response.stdout );
}

function neptuneLast(filePath){
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: __dirname + '/../../xslt/neptune-last.xsl'
        })
        .then( response => response.stdout );
}

function validateFile(collectionFolder, xmlFileName, htmlFiles){
    
    results[xmlFileName] = validatedData[xmlFileName] || {};

    var filePath =  collectionFolder + '/temp/' + xmlFileName;
    var fileName, dtd, docType;
    var matchFascicle = xmlFileName.match(/0([0-9]{4})\-ch0+([0-9\.]+).xml$/);
    if(matchFascicle){

        var collection = matchFascicle[1],
            fascicle = matchFascicle[2],
            exp = collection + '_JCQ_[0-9]+\\-F0*' + fascicle +'.*\\.html$',
            regExp = new RegExp(exp);
            
        fileName = htmlFiles.find(function(file){
            return regExp.test(file);
        });
        dtd = './../../neptune/treatiseV021-0000.dtd';
        docType = '<!DOCTYPE tr:ch PUBLIC "-//LEXISNEXIS//DTD Treatise-pub v021//EN//XML" "treatiseV021-0000.dtd">';

    }else{

        var matchPageTitre = xmlFileName.match(/0([0-9]{4})\-fmvol001.*\.xml$/);
        if(matchPageTitre){
            var collection = matchPageTitre[1];
            
            if(xmlFileName.match(/0([0-9]{4})\-fmvol001.xml$/)){
                exp = collection + '_JCQ_[0-9]+.Page de titre.*\\.html$';
            }else if(xmlFileName.match(/0([0-9]{4})\-fmvol001ap.xml$/)){
                exp = collection + '_JCQ_[0-9]+\\-Avant-propos.*\\.html$';
            }else if(xmlFileName.match(/0([0-9]{4})\-fmvol001bio.xml$/)){
                exp = collection + '_JCQ_[0-9]+\\-Notices biographiques.*\\.html$';
            }else if(xmlFileName.match(/0([0-9]{4})\-fmvol001pre.xml$/)){
                exp = collection + '_JCQ_[0-9]+\\-Pr.*\\.html$';
            }

            var regExp = new RegExp(exp);

            fileName = htmlFiles.find(function(file){
                return regExp.test(file);
            });
            dtd = './../../neptune/frontmatterV015-0000.dtd';
            docType = '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">';

        }else{

            var matchPageToc = xmlFileName.match(/0([0-9]{4})\-ptoc(0[0-9]+).*\.xml$/);
            if(matchPageToc){

                var romans = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

                var collection = matchPageToc[1],
                    detailedIndex = romans[parseInt(matchPageToc[2])];
                
                if(xmlFileName.match(/0([0-9]{4})\-ptoc01a\.xml$/)){
                    exp = collection + '_JCQ_[0-9]+\\-TDMG.*\\.html$';
                }else if(xmlFileName.match(/0([0-9]{4})\-ptoc.*\.xml$/)){
                    exp = collection + '_JCQ_[0-9]+\\-TDM'+detailedIndex+'.*\\.html$';
                }
    
                var regExp = new RegExp(exp);
    
                fileName = htmlFiles.find(function(file){
                    return regExp.test(file);
                });

                dtd = './../../neptune/frontmatterV015-0000.dtd';
                docType = '<!DOCTYPE fm:vol-fm PUBLIC "-//LEXISNEXIS//DTD Front Matter v015//EN//XML" "frontmatterV015-0000.dtd">';
                
            }else{

                var matchPageEndMatter = xmlFileName.match(/0([0-9]{4})\-.*\.xml$/);

                if(matchPageEndMatter){
                    var collection = matchPageEndMatter[1];
                    
                    if(xmlFileName.match(/0([0-9]{4})\-tos001\.xml$/)){
                        exp = collection + '_JCQ_[0-9]+\\-Index de la.*\\.html$';
                        docType = '<!DOCTYPE em:table PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">';
                    }else if(xmlFileName.match(/0([0-9]{4})\-index\.xml$/)){
                        exp = collection + '_JCQ_[0-9]+\\-Index a.*\\.html$';
                        docType = '<!DOCTYPE em:index PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">';
                    }else if(xmlFileName.match(/0([0-9]{4})\-toclist\.xml$/)){
                        exp = collection + '_JCQ_[0-9]+\\-État de la';
                        docType = '<!DOCTYPE em:table PUBLIC "-//LEXISNEXIS//DTD Endmatter v018//EN//XML" "endmatterxV018-0000.dtd">';
                    }

                    var regExp = new RegExp(exp);

                    fileName = htmlFiles.find(function(file){
                        return regExp.test(file);
                    });
        
                    dtd = './../../neptune/endmatterxV018-0000.dtd';
                }
            }


        }

    }
    var htmlPath = collectionFolder + '/html/' + fileName;
    if(!fileName){
        console.error(filePath, 'source file not found');
    }else{

        results[xmlFileName]['package'] = collectionFolder.match(/Package_([0-9])/)[1];
        results[xmlFileName]['sourceFile'] = fileName;

        var xmlFilePath = filePath.replace('/temp/', '/neptune/');
        
        /*var schematronPromise = xmllint.exec({
                xmlPath: filePath,
                schematronPath: './../../neptune/validation.sch'
            })
            .then( (result) => { 
                console.log('{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{',xmlFilePath + result);
                results[xmlFileName]['schematronValid'] = true;
            })
            .catch( output => {
                console.error('+++++++++++++++++++++++++++++++'+xmlFilePath + " with errors", output);
                results[xmlFileName]['schematronValid'] = false;
            });*/

        var pageJumpsPromise = fsReadFile(htmlPath, 'utf8')
            .then( (data) => {
                var pagesMatch = data.match(/Page suivante/gmi);
                results[xmlFileName]['pageNumbersJumps'] = pagesMatch
                        ? pagesMatch.length 
                        : 0;
                return Promise.resolve();
            });

        var diffPromise = Promise.all([exportHtmlText(htmlPath), exportXmlText(filePath)])
            .then( (promises) => {
                var htmlContent = promises[0].replace(/[\r\n]/g,'').replace(/\u00AD/g,''),
                    xmlContent = promises[1].replace(/[\r\n]/g,'');

                var diffPath = htmlPath.replace('/html/', '/neptune/').replace('.html', '-diff.html');
                var diffContent = diff.exec(htmlContent, xmlContent);
                var diffCount = diffContent.match(/<ins|<del/g);
                if(diffCount){
                    console.error(htmlPath, "Integrity Errors:", diffCount.length);
                    results[xmlFileName]['integrityValid'] = false;
                    results[xmlFileName]['integrityErrors'] = diffCount.length;
                }else{
                    results[xmlFileName]['integrityValid'] = true;
                    results[xmlFileName]['integrityErrors'] = 0;
                }
                
                return Promise.all([fsWriteFile(diffPath, wrapInHtml(diffContent)), pageJumpsPromise]);

            }).then( () => {
                
                return neptuneLast(filePath)
                    .then( (lastContent) => {
                        lastContent = lastContent
                            .replace(/<\?textpage page-num=".*[02468]" release\-num=".*"\?>/g, '');

                        var pageNumbers = {};
                        var matches = lastContent.match(/<\?textpage page\-num="[A-Z0-9É\-]+\-([0-9]+)" release\-num="[^"]*"\?>/g);
                        try{
                            if(matches){
                                results[xmlFileName]['pageNumbersCount'] = matches.length;
                                var lineNumbers = matches.map(textPageNumber => {
                                    return parseInt(textPageNumber.match(/\-([0-9]+)"/g)[0].replace('"','').replace("-",''));
                                });
                                pageNumbers = lineNumbers.reduce(function(control, line, index){
                                    if(_.last(control.seqs) == line){
                                        control.duplicate.push(line);
                                    }
                                    if(2 + _.last(control.seqs) != line){
                                        control.start = true;
                                    }else{
                                        if(!control.start){
                                            control.seqs.pop();
                                        }
                                        control.start = false;
                                    }
                                    control.seqs.push(line);
                                    return control;
                                }, { start: true, seqs: [], duplicate: [] });
                            }
                            results[xmlFileName]['pageNumbersValid'] = pageNumbers.duplicate.length === 0 && ( ((results[xmlFileName]['pageNumbersJumps']+1)*2 === pageNumbers.seqs.length) || (pageNumbers.seqs.length === 1 && results[xmlFileName]['pageNumbersJumps'] === 0));
                            results[xmlFileName]['pageNumbersSequences'] = pageNumbers.seqs.join();
                            results[xmlFileName]['pageNumbersDuplicate'] = pageNumbers.duplicate.join();
                        }catch(error){
                            results[xmlFileName]['pageNumbersValid'] = false;
                        }

                        lastContent = lastContent
                            .replace('é́','é')
                            .replace('<core:title>Index analytique</core:title>','<core:title>INDEX ANALYTIQUE</core:title>')
                            .replace(/(&#x2003;&#x2003;)(<\?textpage page-num=".*" release\-num=".*"\?>)/g, function(match, p1, p2){
                                return p2+p1;
                            });

                        lastContent = lastContent.replace(/\<core\:emph typestyle\=\"upper\"\>([^<]*)\<\/core\:emph\>/g, function(match, p1){ return p1.toUpperCase();});
                        
                        lastContent = lastContent.replace(/([\s\t	]+)(<core:leaders)/g, function(match, p1, p2){ 
                            return p2;
                        });

                        lastContent = lastContent.replace(/(<core:entry-title>)(\s+)/g, function(match, p1, p2){ 
                            return p1;
                        });

                        lastContent = lastContent.replace(/(<fn:endnote er="[0-9]*">)(<\?textpage page-num=".*" release-num=".*"\?>)/gmi, function(match, p1, p2){ 
                            return p2 + p1;
                        });
                        
                        lastContent = lastContent.replace(/(<core:title runin=".+">)[\t\s	]+(<core:emph)/gm, function(match, p1, p2){
                            return p1 + p2;
                        });

                        lastContent = lastContent.replace(/(<core:title>)(\s+)/g, function(match, p1, p2){ 
                            return p1;
                        });
                        lastContent = lastContent.replace(/(<core:title>)<\?.*\?>(\s+)/g, function(match, p1, p2){ 
                            return p1;
                        });

                        lastContent = lastContent.replace(/(<core:entry-title>)([\s\t	]+)(<core:emph)/g, function(match, p1, p2, p3){ 
                            return p1 + p3;
                        });

                        // Empty emphasis
                        lastContent = lastContent.replace(/(<core:emph typestyle="[a-z]*">)\s+(<\/)/g, function(match, p1, p2){ 
                            return p1 + p2;
                        });
                        lastContent = lastContent.replace(/<core:emph typestyle="[a-z]*"\/>/g, '');

                        // Leading spaces in emphasis
                        lastContent = lastContent.replace(/(<core:emph typestyle="[a-z]*">)(\s+)/g, function(match, p1, p2){ 
                            return p2 + p1;
                        });

                        // Trailing spaces in emphasis
                        lastContent = lastContent.replace(/(\s+)(<\/core:emph>)/g, function(match, p1, p2){ 
                            return p2 + p1;
                        });

                        // Leading spaces in paragraphs
                        lastContent = lastContent.replace(/(<(?:fn|core):para[\sa-z1-9\=\"]*>)(\s+)/g, function(match, p1, p2){ 
                            return p1;
                        });
                    
                        return fsWriteFile(xmlFilePath, lastContent);
                    });
            });

        return diffPromise
            .then(() => {
                return xmllint.exec({
                    xmlPath: xmlFilePath,
                    dtdPath: dtd
                })
                .then( () => { 
                    console.log(xmlFilePath);
                    results[xmlFileName]['dtdValid'] = true;
                })
                .catch( output => {
                    console.error(xmlFilePath + " with errors");
                    results[xmlFileName]['dtdValid'] = false;
                });
            }).then(() =>{
                return fsReadFile(xmlFilePath, 'utf8').
                    then( (data) => {
                        var content = data.replace('<?xml version="1.0" encoding="UTF-8"?>', '<?xml version="1.0" encoding="UTF-8"?>' + docType);
                        return fsWriteFile(xmlFilePath, content);
                    });
            });
    }
        
}

function validateCollection(collectionFolder, filter){
    
    console.info('validateCollection()', collectionFolder);

    return fsReadDir(collectionFolder + '/html')
        .then( htmlFiles => {

            var filteredFiles = htmlFiles
                .filter( file => /\.html$/.test(file))
                .filter( file => !/inline\.html$/.test(file));
            
            return fsReadDir(collectionFolder + '/temp')
                .then( files => {
                    
                    var xmlFiles = files
                        .filter(function(file){
                            return filter.test(file);
                        })
                        .filter( file => /.xml$/.test(file));
                    
                    return Promise.all(xmlFiles.map( file => {
                        return validateFile(collectionFolder, file, filteredFiles);
                    }));

                });
        });
    
}

function validatePackages(paths, collectionFilter, filter){

    return Promise.all(paths
        .map( path => path.replace('/in/', '/out/') )
        .map( path => {
            return fsReadDir(path)
                .then(collections => {
                    

                    return collections
                        .filter( collection => collectionFilter.test(collection) )
                        .filter( collection => !_.includes(['.DS_Store', 'results.json', 'results.txt', 'paths.txt', 'emphasis.txt'], collection) )
                        .reduce( (promise, collection) => {
                                var collectionPath = path + '/' + collection;
                                return promise
                                    .then(() => {
                                        return validateCollection(collectionPath, filter) 
                                    });
                                }, Promise.resolve() 
                        );

                });
        })
    ).then( () => {
        return createReport();
    });
}

exports.validatePackages = validatePackages;