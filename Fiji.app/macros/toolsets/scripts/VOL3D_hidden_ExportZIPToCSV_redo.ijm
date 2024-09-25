macro "Re-export ZIP as CSV - icon:neuron.png" {
    var input = call("ij.Prefs.get", "input.x", 0);
    input += "Slices" + File.separator; 

    // Create a new blank image of specified size (e.g., 1024x1024 pixels)
    newImage("Blank", "8-bit Black", 5000, 5000, 1);
    //remove scale otherwise particle analysis returns in inches
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
    print("Re-exporting all ZIP files as CSV in the folder " + input);

    var animalFolders = getFileList(input);

    // Opens the ROI Manager
    run("ROI Manager...");

    // Process each subfolder under the input directory
    for (var i = 0; i < animalFolders.length; i++) {
        var subFolderPath = input + animalFolders[i] + File.separator;
                
        if (File.isDirectory(subFolderPath)) {
            print("Processing folder: " + subFolderPath);
            processFolder(subFolderPath);
        }
    }

    run("Close All");
    showMessage("Done", "All ZIP files have been re-exported as CSV.");
}

function processFolder(input) {
    var zipFiles = getFileList(input + "VOL" + File.separator + "ZIP");

    for (var i = 0; i < zipFiles.length; i++) {
        if (endsWith(zipFiles[i], ".zip")) {
            processZipFile(input, zipFiles[i]);
        }
    }
}

function processZipFile(input, zipFile) {
    var savepath = input + "VOL" + File.separator;
    var zipPath = savepath + "ZIP" + File.separator + zipFile;
    var csvPath = savepath + "CSV" + File.separator + replace(zipFile, ".zip", ".csv");

ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

    if (File.exists(zipPath)) {
        print(zipFile + " exists, re-exporting as CSV.");
        roiManager("Open", zipPath);
        roiManager("select", 0);
        getSelectionCoordinates(xpoints, ypoints);
        run("Clear Results");
        for (var f = 0; f < xpoints.length; f++) {
            setResult("Label", f, replace(zipFile, ".zip", ""));
            setResult("X", f, xpoints[f]);
            setResult("Y", f, ypoints[f]);
        }
        updateResults();
        saveAs("Measurements", csvPath);
        
        run("Clear Results");
    } else {
        print("No ZIP file found for " + zipFile + ", skipped.");
    }
    
	}
    
}
