const util = require('util');
const execChildProcess = util.promisify(require('child_process').exec);

let pdfBoxJarPath = '';

function setDefaults(options){
    if(options.pdfBoxJarPath){
        pdfBoxJarPath = options.pdfBoxJarPath;
    }
}

function prepareCommand(commandName, options){
    var command = ['java -jar'];
    command.push(util.format('"%s"', pdfBoxJarPath));
    command.push(commandName);
    for(var key in options.params){
        command.push(`-${key} ${options.params[key]}`);
    }
    if(options.input)     command.push(util.format('"%s"', options.input));
    if(options.output)     command.push(util.format('"%s"', options.output));
    
    return command.join(' ');
}

async function extractText(options) {
    let cmd = prepareCommand('ExtractText', options);
    return execChildProcess(cmd, {maxBuffer: options.maxBuffer || 1024 * 10000});
}

exports.extractText = extractText;
exports.setDefaults = setDefaults;