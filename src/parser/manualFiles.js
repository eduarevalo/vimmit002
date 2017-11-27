var filterManualFixes = function(file){
    return !/^6020_JCQ_15-F08/.test(file) 
        && !/^6020_JCQ_19-F11/.test(file)
        
        && !/^6025_JCQ_24-F18/.test(file)
        && !/^6025_JCQ_14-F08/.test(file)
        && !/^6025_JCQ_16-F10/.test(file)
        && !/^6025_JCQ_21-F15/.test(file)
        && !/^6025_JCQ_24-F18/.test(file)
        
        && !/^6024_JCQ_32-F24/.test(file)

        && !/^6017_JCQ_30-F19/.test(file)
        
        && !/^6021_JCQ_15-F06/.test(file)
        
        && !/^6019_JCQ_22-F14/.test(file)
        && !/^6019_JCQ_35-F23/.test(file)
        
        && !/^6023_JCQ_15-F07/.test(file)
        && !/^6023_JCQ_19-F10/.test(file)
        
        && !/^5994_JCQ_23-F15/.test(file)

        && !/^5983_JCQ_52-F42/.test(file)

        && !/^6011_JCQ_24-F16/.test(file);
}

exports.filterManualFixes = filterManualFixes;