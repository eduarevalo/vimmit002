const util = require('util');
const execChildProcess = util.promisify(require('child_process').exec);

let jingJarPath = '';

function setDefaults(options){
    if(options.jingJarPath){
        jingJarPath = options.jingJarPath;
    }
}

function prepareCommand(options){
    return util.format('java -jar "%s" "%s" "%s"', jingJarPath, options.rngPath, options.xmlPath);
}

async function exec(options) {
    let cmd = prepareCommand(options);
    return execChildProcess(cmd, {maxBuffer: options.maxBuffer || 1024 * 5000});
}

exports.exec = exec;
exports.setDefaults = setDefaults;