//@target indesign

//Save the current application setting.
var currentAppSettings = {
    checkLinksAtOpen: app.linkingPreferences.checkLinksAtOpen,
    scriptPreferences: app.scriptPreferences.userInteractionLevel
};

//Set the value to false to prevent the dialog from showing.
app.linkingPreferences.checkLinksAtOpen = false;
app.scriptPreferences.userInteractionLevel = UserInteractionLevels.NEVER_INTERACT;  
app.findGrepPreferences.appliedLanguage = 'Arabic';
app.changeTextPreferences.changeTo = 'language: [No Language]';

var folder = new Folder("/Users/eas/Documents/dev/projects/lexis-nexis/conversion/data/in/JCQ_RICT/Fichiers INDD_Version courante");
//var folder = new Folder("/Users/eas/Documents/dev/projects/lexis-nexis/conversion/data/in/CWK_FMST/Fichiers InDesign_Version courante");
//var folder = new Folder("/Users/eas/Documents/dev/projects/lexis-nexis/conversion/data/in/CWK_DLMT/Fichiers InDesign_Version courante");

var aChildren = folder.getFiles("*.indd");
for (var i = 0; i < aChildren.length; i++) {
    var file = aChildren[i];
    
    var document = app.open(file);

    var outFilePath = file.absoluteURI.replace('/in/', '/out/html/');
    var outFile = new File(outFilePath + '.html');

    var outFolder = outFile.parent;

    if(!outFolder.exists){
        outFolder.create();
    }

    app.activeDocument.htmlExportPreferences.viewDocumentAfterExport = false;
    app.activeDocument.htmlExportPreferences.preserveLayoutAppearence = true;
    
    //document.changeText();

    app.activeDocument.exportFile(ExportFormat.HTML, outFile, false);
    document.close(SaveOptions.NO);
}

//Set the value back to its original value.
app.linkingPreferences.checkLinksAtOpen = currentAppSettings.checkLinksAtOpen;
app.scriptPreferences.userInteractionLevel = currentAppSettings.scriptPreferences;  