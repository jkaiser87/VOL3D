// Cell Count Analysis tools

macro "Unused Tool-1 - " {}  // leave empty slot

macro "Setup Folder to process Action Tool - icon:folder.png" {
  
  var defaultPath = call("ij.Prefs.get", "input.x",0); //retrieve last input
  
  Dialog.create("Setup");
  Dialog.addMessage("Choose folder 'Slices' from M2 CropSlide pipeline");
  Dialog.addDirectory("\n", defaultPath)
  Dialog.addMessage("------------------------");
  Dialog.addCheckbox("Get coordinates? (default false)", false);
  Dialog.show;
  
  var input = Dialog.getString();
  if (!endsWith(input, File.separator)) {
      input += File.separator;
	}
  var docoords = Dialog.getCheckbox();
	call("ij.Prefs.set", "input.x", input);
	call("ij.Prefs.set", "docoords.x",docoords );
	
	print("Pipeline to trace injection volume in cortical slices.\n! Input folder: \n"+input);
	
} 

macro "Preprocess Slices Action Tool - icon:imageproc.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//VOL3D_SetupSlices.ijm");
}

macro "Draw Volume for All Action Tool - icon:shape.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//VOL3D_channeldep.ijm");
}

macro "Flip image [F]"{
	run("Flip Horizontally");
    print ("--- Selection flipped.");
}