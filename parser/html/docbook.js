const saxon = require('./../saxon');

function exec(filePath){
    var xslPath = __dirname + '/../../xslt/part.xsl';
    if(/.*-Instructions.*/.test(filePath)){
        //xslPath = __dirname + '/../../xslt/instructions.xsl'
    }else if(/.*-Page de titre.*/.test(filePath)){
        xslPath = __dirname + '/../../xslt/cover.xsl';
    }else if(/.*-TDM.*/.test(filePath)){
        xslPath = __dirname + '/../../xslt/toc.xsl';    
    }else if(/.*-F[0-9]*_.*/.test(filePath)){
        xslPath = __dirname + '/../../xslt/fascicle.xsl';
    }
    return saxon
        .exec({
            xmlPath: filePath, 
            xslPath: xslPath
        });
}

function validate(filePath){
    var xslPath = __dirname + '/../../xslt/part.xsl';
    return saxon
        .exec({
            xmlPath: filePath, 
            xsdPath: xslPath
        });
}

exports.exec = exec;

exports.validate = validate;