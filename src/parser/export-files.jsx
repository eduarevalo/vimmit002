//@target indesign

//Save the current application setting.
var currentAppSettings = {
    checkLinksAtOpen: app.linkingPreferences.checkLinksAtOpen,
    scriptPreferences: app.scriptPreferences.userInteractionLevel
};

//Set the value to false to prevent the dialog from showing.
app.linkingPreferences.checkLinksAtOpen = false;
app.scriptPreferences.userInteractionLevel = UserInteractionLevels.NEVER_INTERACT;  

var batchFiles = {$batchFiles};

for (var it=0; it<batchFiles.length; it++) { 
    
    var inddFile = new File(batchFiles[it].indd);
    var htmlFile = new File(batchFiles[it].html);
    var epubFile = new File(batchFiles[it].epub);

    var document = app.open(inddFile);

    app.activeDocument.htmlExportPreferences.viewDocumentAfterExport = false;
    app.activeDocument.htmlExportPreferences.preserveLayoutAppearence = true;


    app.activeDocument.exportFile(ExportFormat.HTML, htmlFile, false);
    app.activeDocument.exportFile(ExportFormat.FIXED_LAYOUT_EPUB, epubFile, false);
    
    document.close(SaveOptions.NO);
}

//Set the value back to its original value.
app.linkingPreferences.checkLinksAtOpen = currentAppSettings.checkLinksAtOpen;
app.scriptPreferences.userInteractionLevel = currentAppSettings.scriptPreferences;  