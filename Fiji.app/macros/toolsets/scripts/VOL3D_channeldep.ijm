macro "Mark CSN Action Tool - icon:neuron.png"{

var input = call("ij.Prefs.get", "input.x",0);
//input = input + "Slices" + File.separator; 

 Dialog.create("Setup");
 Dialog.addMessage("Select the Channel to process \nC1 (red), C2 (green), C3 (blue), C4 (farred)");
 items = newArray("C1", "C2", "C3","C4");
 Dialog.addRadioButtonGroup("", items, 1, 4, "C1");
 Dialog.show;
 var channelc = Dialog.getRadioButton();
 var channelno = parseFloat(replace(channelc, "C","")); //extracts number of channel for later

print("Tracing of injection volume \n--- Processing folder "+input+"\nProcessing Channel "+channelc);

//list = getFileList(input);
suffix = ".tif";



//opens all tools
run("Channels Tool...");
run("Brightness/Contrast...");
run("ROI Manager...");


// Process each subfolder under the input directory
    var animalFolders = getFileList(input);
    
    for (var i = 0; i < animalFolders.length; i++) {
        var subFolderPath = input + animalFolders[i];
        var savepath = subFolderPath + "VOL" + File.separator;
		var zipPath =  savepath + "ZIP";
 		var csvPath =  savepath + "CSV";
                
        if (File.isDirectory(subFolderPath)) {
            print("Processing folder: " + subFolderPath);
            createDirectories(subFolderPath);
            processFolder(subFolderPath);
        }
    }

  
run("Close All");

showMessage("Done", "All Slices processed for Channel "+channelc+".\nIf you want to process another channel, go to Setup, select that channel, and redo Volume\n(you can skip the Slice setup in that case).");

}

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, list[i]);
	}
}

function processFile(input, file) {
if(File.exists(zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"))) {		
	print(" !! "+file+ " previously processed, skipping. \n --- Delete this file to re-do: "+zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"));
} else {
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}
run("Clear Results");

print(" -- Processing file "+file);
open(input+file);  
run("Hide Overlay");
run("Brightness/Contrast...");
run("ROI Manager...");

roiManager("Show All");
    
Stack.setDisplayMode("color");
Stack.setChannel(channelno);
run("Grays");

run("Set Measurements...", "centroid limit display redirect=None decimal=3");
print(" -- Duplicating channel "+channelc);
run("Duplicate...", "duplicate channels="+channelno);

//do we want thresholding here?
/*
print("-- Thresholding at "+thresh);
setAutoThreshold("Default dark");
setThreshold(thresh, 255, "raw"); //should be 8bit
run("Convert to Mask");
//run("Invert");
*/

//remove scale and any ROIs
run("Set Scale...", "distance=0 known=0 unit=pixel");
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

setTool("polygon");
waitForUser("Action required", "Trace the injection volume within cortex (if available)\nShould be 1 single area.\nRight click to close the contour.");
type = selectionType();

if (type ==-1) {
	print("No selection for this image, skipping to next.");
	run("Close All");
	continue;
} else if (type==2) {
	  roiManager("Add");
	  //saving as zip
	 
	  roiManager("save", zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip")); //at the moment i dont want to save it as seperate channels, just one
	  print("-- saved as "+zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"));	
	  
	  //saving as csv
	  	  
	  roiManager("select", 0);
	  getSelectionCoordinates(xpoints, ypoints);
	  run("Clear Results");
	  for (f=0; f<xpoints.length; f++) {
	  	setResult("Label", f, file);
         setResult("X", f, xpoints[f]);
         setResult("Y", f, ypoints[f]);
	  }
	  updateResults();
	  saveAs("Measurements", csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv")); 
	  print("-- saved as "+csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv"));	
	  
		run("Clear Results");
		run("Close All");
	  
} else {
      print("Wrong selection. Redo if possible.").
      break;
}


}
}

/// functions

function createDirectories(subFolderPath) {
    var subfolders = newArray("VOL", "VOL" + File.separator + "CSV","VOL" + File.separator + "ZIP");
	for (ff = 0; ff < subfolders.length; ff++) {
			subsub = subFolderPath + File.separator + subfolders[ff];
			File.makeDirectory(subsub);
 			if (!File.exists(subsub))
 			 exit("Unable to create directory "+subsub);
		}
}