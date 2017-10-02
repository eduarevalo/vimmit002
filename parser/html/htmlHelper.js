const fs = require('fs');

var replaceIt = '٠١٢٣٤٥٦٧٨٩', 
    replaceWith = '0123456789';

function cleanSpecialChars(filePath){
    var newFilePath = filePath + '.clean.html';
    return new Promise(function(resolve, reject) {
        fs.readFile(filePath, 'utf8', function (err,data) {
            if (err) {
                reject(err);
                return;
            }
            
            var result = data;
            for(var i=0; replaceIt[i]; i++){
                result = result.replace(new RegExp(replaceIt[i]), replaceWith[i]);      
            }
            fs.writeFile(newFilePath, result, 'utf8', function (err) {
                if (err) {
                    reject(err);
                    return;
                }
                resolve(newFilePath);    
            });
        });
    });
      
}

exports.cleanSpecialChars = cleanSpecialChars;