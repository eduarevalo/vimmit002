const util = require('util');
const execChildProcess = util.promisify(require('child_process').exec);

async function exec(options) {
    let cmd = ["xmllint", 
        util.format('"%s"', options.xmlPath), 
        util.format('-dtdvalid "%s"', options.dtdPath)].join(" ");
    return execChildProcess(cmd, {maxBuffer: options.maxBuffer || 1024 * 10000});
}

exports.exec = exec;
