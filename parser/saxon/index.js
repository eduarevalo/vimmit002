const util = require('util');
const execChildProcess = util.promisify(require('child_process').exec);

let saxonJarPath = '';

function setDefaults(options){
    if(options.saxonJarPath){
        saxonJarPath = options.saxonJarPath;
    }
}

function prepareCommand(options){
    var command = ['java -jar'];
    command.push(util.format('"%s"', saxonJarPath));
    command.push(util.format('"-s:%s"', options.xmlPath));
    if(options.xslPath)     command.push(util.format('"-xsl:%s"', options.xslPath));
    if(options.xsdPath)     command.push(util.format('"-xsd:%s"', options.xsdPath));
    for(var key in options.params){
        command.push(`${key}=${options.params[key]}`);
    }
    return command.join(' ');
}

async function exec(options) {
    let cmd = prepareCommand(options);
    return execChildProcess(cmd, {maxBuffer: options.maxBuffer || 1024 * 10000});
}

exports.exec = exec;
exports.setDefaults = setDefaults;