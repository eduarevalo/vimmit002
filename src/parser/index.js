
const prepare = require('./prepare'),
    exportAdobe = require('./export'),
    inject = require('./inject'),
    convert = require('./convert'),
    neptune = require('./neptune'),
    report = require('./report'),
    unzip = require('./unzip');

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
    
    var preparePromise = args.prepare
        ? prepare.preparePackages(packages, collectionFilter, filter)
        : Promise.resolve();
    
    var exportAdobePromise = args.export
        ? exportAdobe.exportPackages(packages, collectionFilter, filter)
        : Promise.resolve();

    var unzipPromise = args.unzip
        ? unzip.unzipPackages(packages, collectionFilter, filter)
        : Promise.resolve();

    var injectPromise = args.inject
        ? inject.injectPackages(packages, collectionFilter, filter)
        : Promise.resolve();

    var convertPromise = args.convert
        ? convert.convertPackages(packages, collectionFilter, filter)
        : Promise.resolve();

    var neptunePromise = args.neptune
        ? neptune.transformPackages(packages, collectionFilter, filter)
        : Promise.resolve();

    var reportPromise = args.report
        ? report.reportPackages(packages, collectionFilter, filter)
        : Promise.resolve();
    
    
})();