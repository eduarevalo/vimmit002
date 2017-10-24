const fs = require('fs'),
    util = require('util'),
    fx = require('mkdir-recursive'),
    exec = require('child_process').exec,
    _ = require('lodash');

const fxMkDir = util.promisify(fx.mkdir),
    fsReadFile = util.promisify(fs.readFile),
    fsWriteFile = util.promisify(fs.writeFile),
    fsReadDir = util.promisify(fs.readdir);

const templatePath = './template/report.hbs',
    tempPath = './template/temp.html';
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
  var outputString = template(data, {
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

function createReport(results){
    
    var results = calculateData(results);

    // read the file and use the callback to render
    fs.readFile(templatePath, function(err, data){

      if (!err) {
          
        // make the buffer into a string
        var source = data.toString();
        // call the render function
        var preparedFile = renderToString(source, results);

        fs.writeFile(tempPath, preparedFile, function(err) {
          if(err) {
            return console.log(err);
          }
          console.log(`${tempPath} was saved!`);
        });

      } else {
            console.log(err);
      }
    });
}

function reportPackages(paths, filter){
    return Promise.all(paths
        .map( path => path.replace('/in/', '/out/') )
        .map( path => {
            var jsonPackagePath = [path, 'results.json'].join('/');
            return fsReadFile(jsonPackagePath, 'utf8')
                .then( (json) => { 
                    return {path, json: JSON.parse(json), jsonPackagePath};
                });
        })
    ).then(results => {
        return createReport(results);
    });
}

exports.reportPackages = reportPackages;