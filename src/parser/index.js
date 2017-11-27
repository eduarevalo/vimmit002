
const prepare = require('./prepare'),
    exportAdobe = require('./export'),
    inject = require('./inject'),
    convert = require('./convert'),
    neptune = require('./neptune'),
    validate = require('./validate'),
    report = require('./report'),
    unzip = require('./unzip'),
    chalk = require('chalk');

var systemError = console.error;

console.error = function(){
    var args = Object.values(arguments).map( arg => chalk.red(arg) );
    systemError.apply(null, args);
};

console.error = function(){
    var args = Object.values(arguments).map( arg => chalk.red(arg) );
    systemError.apply(null, args);
};

(function main(){
    
    var args = {};
    process.argv.forEach((val, index) => {
        var parts = val.split('=');
        args[parts[0]] = parts[1] || true;
    });

    var basePath = __dirname + "/../../data/in/Package_";
    
    var packages = (args.packages || '1,2,3,4').split(',').map( id => {
        return basePath + id;
    });

    var filter = new RegExp(args.filter || '.*'),
        collectionFilter = new RegExp(args.collectionFilter || '.*');
    
    var preparePromise = function(){
        return args.prepare
            ? prepare.preparePackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };
    
    var exportAdobePromise = function(){
        return args.export
            ? exportAdobe.exportPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var unzipPromise =  function(){
        return args.unzip
            ? unzip.unzipPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var injectPromise =  function(){
        return args.inject
            ? inject.injectPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var convertPromise =  function(){
        return args.convert
            ? convert.convertPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var neptunePromise =  function(){
        return args.neptune
            ? neptune.transformPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var validatePromise =  function(){
        return args.validate
            ? validate.validatePackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    var reportPromise =  function(){
        return args.report
            ? report.reportPackages(packages, collectionFilter, filter)
            : Promise.resolve('Omitted');
    };

    
    var processExecution = [preparePromise, exportAdobePromise, unzipPromise, injectPromise, convertPromise, neptunePromise, validatePromise, reportPromise]
        .reduce( (promise, newPromise) => {
            
            return promise.then((operationResult) => {
                    if(operationResult !== 'Omitted'){
                        console.info('======================================================================');
                    }
                    return newPromise();
                });
            }, Promise.resolve()
        );

    console.time('Total time');
    processExecution.then(() => { console.timeEnd('Total time'); })
    
})();