const util = require('util');
const execChildProcess = util.promisify(require('child_process').exec);

async function exec(options) {
    let cmd = "";
    if(options.schematronPath){
        cmd = ["xmllint", 
        util.format('-schematron "%s"', options.schematronPath),
        util.format('"%s"', options.xmlPath)].join(" ");
    }else{
        cmd = ["xmllint", 
            util.format('-dtdvalid "%s"', options.dtdPath),
            util.format('"%s"', options.xmlPath)].join(" ");
    }
    return execChildProcess(cmd, {maxBuffer: options.maxBuffer || 1024 * 10000});
}

exports.exec = exec;
