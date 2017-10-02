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

var batchFiles = {$batchFiles};

for (var key in batchFiles) { 
    
    var inddFile = new File(key);
    var htmlFile = new File(batchFiles[key]);

    var document = app.open(inddFile);

    app.activeDocument.htmlExportPreferences.viewDocumentAfterExport = false;
    app.activeDocument.htmlExportPreferences.preserveLayoutAppearence = true;

    //document.changeText();

    app.activeDocument.exportFile(ExportFormat.HTML, htmlFile, false);
    document.close(SaveOptions.NO);
}

//Set the value back to its original value.
app.linkingPreferences.checkLinksAtOpen = currentAppSettings.checkLinksAtOpen;
app.scriptPreferences.userInteractionLevel = currentAppSettings.scriptPreferences;  