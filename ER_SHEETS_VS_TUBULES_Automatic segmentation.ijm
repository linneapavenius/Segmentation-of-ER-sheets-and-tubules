

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".czi") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	open();
path = getInfo("image.directory");
filename = File.nameWithoutExtension;


run("Duplicate...", "duplicate");
saveAs("Tiff", path + filename + " Original duplicate");
close("\\Others");
selectImage(filename + " Original duplicate.tif");
run("Duplicate...", "duplicate channels=3");
rename("Original duplicate-1.tif");
selectImage("Original duplicate-1.tif");
run("Make Binary", "method=MinError background=Dark calculate black create");
run("Erode", "stack");
run("Erode", "stack");
run("Erode", "stack");
run("Erode", "stack");
run("Erode", "stack");
run("Erode", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
run("Dilate", "stack");

selectImage(filename + " Original duplicate.tif");
rename("Original duplicate.tif");
run("Duplicate...", "duplicate channels=3");
rename("Original duplicate-2.tif");
selectImage("Original duplicate-2.tif");
imageCalculator("AND create stack", "MASK_Original duplicate-1.tif","Original duplicate-2.tif");
selectImage("Result of MASK_Original duplicate-1.tif");
saveAs("Tiff", path + filename + " Result of MASK_sheets"); 
selectImage("MASK_Original duplicate-1.tif");
saveAs("Tiff", path + filename + " MASK_sheets.tif");

/*Remove background from the ER-channel*/

selectImage("Original duplicate.tif");
run("Duplicate...", "duplicate channels=3");
rename("Original duplicate-3.tif");
selectImage("Original duplicate-3.tif");
run("Make Binary", "method=MinError background=Dark calculate black create");
run("Erode", "stack");
run("Erode", "stack");
run("Dilate", "stack");
run("Dilate", "stack");

/* create tubeles by subtracting sheets from the total ER*/

imageCalculator("Subtract create stack", "MASK_Original duplicate-3.tif",filename + " MASK_sheets.tif");
/* selectImage("Result of MASK_Original duplicate-3.tif");*/
run("Make Binary", "method=MinError background=Dark calculate black create");
saveAs("Tiff", path + filename + " MASK_tubules.tif");

selectImage("Original duplicate.tif");
run("Duplicate...", "duplicate channels=3");
rename("Original duplicate-4.tif");
selectImage("Original duplicate-4.tif");
imageCalculator("AND create stack", filename + " MASK_tubules.tif","Original duplicate-4.tif");
/* selectImage("Result of MASK_tubules.tif");*/
saveAs("Tiff", path + filename + " Result of MASK_tubules.tif");


close("Original duplicate-1");
close("Original duplicate-2");
close("Original duplicate-3");
close("Original duplicate-4");

/*Merge new channels*/

selectImage("Original duplicate.tif");
run("Duplicate...", "duplicate channels=1");
run("Subtract Background...", "rolling=20 stack");
run("Red");
selectImage("Original duplicate.tif");
run("Duplicate...", "duplicate channels=2");
run("Subtract Background...", "rolling=20 stack");
run("Cyan");


selectImage(filename + " Result of MASK_sheets.tif");
setOption("ScaleConversions", true);
run("16-bit");
run("Save");
run("Magenta");
rename("Result of MASK_sheets.tif");

selectImage(filename + " Result of MASK_tubules.tif");
setOption("ScaleConversions", true);
run("16-bit");
run("Save");
run("Green");
rename("Result of MASK_tubules.tif");

run("Merge Channels...", "c1=[Original duplicate-5.tif] c2=[Original duplicate-6.tif] c3=[Result of MASK_sheets.tif] c4=[Result of MASK_tubules.tif] create keep");
saveAs("Tiff", path + filename + " Merged.tif");
rename("Merged.tif");

close("\\Others");

selectImage("Merged.tif");
Stack.setActiveChannels("0011");
run("Z Project...", "projection=[Average Intensity] all");
run("AVI... ", "compression=JPEG frame=3 save=[/Users/linnea/Library/CloudStorage/OneDrive-KarolinskaInstitutet/20231203 Files for michela/20230620 MBS MR SplitfastCoral ER staygold/AVG_Merged.avi]");
saveAs("Tiff", path + filename + " AVG_Merged_ER.tif");

selectImage("Merged.tif");
Stack.setActiveChannels("1111");
run("Z Project...", "projection=[Average Intensity] all");
run("AVI... ", "compression=JPEG frame=3 save=[/Users/linnea/Library/CloudStorage/OneDrive-KarolinskaInstitutet/20231203 Files for michela/20230620 MBS MR SplitfastCoral ER staygold/AVG_Merged.avi]");
saveAs("Tiff", path + filename + " AVG_Merged.tif");
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
}

