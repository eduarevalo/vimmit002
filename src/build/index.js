const fs = require('fs');
const path = require('path');

/**
 * Explores recursively a directory and returns all the filepaths and folderpaths in the callback.
 * 
 * @see http://stackoverflow.com/a/5827895/4241030
 * @param {String} dir 
 * @param {Function} done 
 */
function filewalker(dir, done) {
    let results = [];

    fs.readdir(dir, function(err, list) {
        if (err) return done(err);

        var pending = list.length;

        if (!pending) return done(null, results);

        list.forEach(function(file){
            file = path.resolve(dir, file);

            fs.stat(file, function(err, stat){
                // If directory, execute a recursive call
                if (stat && stat.isDirectory()) {
                    // Add directory to array [comment if you need to remove the directories from the array]
                    results.push(file);

                    filewalker(file, function(err, res){
                        results = results.concat(res);
                        if (!--pending) done(null, results);
                    });
                } else {
                    results.push(file);

                    if (!--pending) done(null, results);
                }
            });
        });
    });
};

var basePath = __dirname + "/../../../lexis-nexis-data/";

filewalker(basePath, function(err, data){
    if(err){
        throw err;
    }
    
    var xmlFiles = data.filter( file => /\.xml$/.test(file) );
    
    xmlFiles.forEach( file => {
        fs.readFile(file, 'utf8', function(err, data ) {
            var out = data.replace(/[\r\n]/g, '');
            /*out = out.replace(/(<core:title runin="1">)\s*(<core:emph)/gm, function(match, p1, p2){
                return p1 + p2;
            });*/
            fs.writeFile(file, out, (err) => {
                if (err) throw err;
                console.log(`The file ${file} has been saved!`);
            });
         });
    });
});