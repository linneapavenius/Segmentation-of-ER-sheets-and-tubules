#@ File (label = "Input file", style = "file") input
#@ File (label = "PSF file", style = "file") PSFfile
#@ File (label = "Output directory", style = "directory") outputdir
#@ String (label = "File suffix", value = ".tif") suffix

bars = newArray("*", "**", "***", "****", "*****", "******", "*******", "********", "*********");
index = 0;

open(input);
path = getInfo("image.directory");
filename = File.nameWithoutExtension;

//remember original hyperstack
id = getImageID();
 
// number of timepoints
getDimensions(xDim, yDim, nChannel, zDim, nTime);

// bara under debug!!
//nTime = 3;

print("Timepoints: " + nTime); 

// Split timepoints, denoise and subtract background
ErodeSteps = 2;
DilateSteps = 3;

for (tp = 1; tp <= nTime; tp++) {
    // select the frame
    selectImage(id);
    close("\\Others");
    Stack.setPosition(1, 1, tp);
    // extract one frame
    print("Update:" + "Extracting timepoint: " + tp);
    run("Reduce Dimensionality...", "channels slices keep");
	// denoise
    print("\\Update:" + "Extracting timepoint: " + tp + " denoise");
	run("32-bit");
	run("ROF Denoise", "theta=250");
	rename("denoised");
	run("Duplicate...", "duplicate");
	rename("mask");
	//subtract background by masking	    
    print("\\Update:" + "Extracting timepoint: " + tp + " denoise" + " subtracting background");
    setAutoThreshold("Default dark");
	run("Make Binary", "method=MinError calculate black create");
	setOption("BlackBackground", true);
	for (nn = 1; nn<=ErodeSteps; nn++) {
		run("Erode", "stack");
	}
	for (nn = 1; nn<=DilateSteps; nn++) {
		run("Dilate", "stack");
	}
	imageCalculator("AND create 32-bit stack", "denoised", "mask");
    
    //save intermediate result    
    tempFile = outputdir + File.separator + filename + tp;    
    saveAs("tiff", tempFile);
    close();

	//DECONVOLUTION
	inputImage = tempFile + suffix;
	image = " -image file " + inputImage;
	psf = " -psf file " + PSFfile;
	algorithm = " -algorithm RL 25";
	outputImage = filename + "DCV"+ tp;
	output = " -out stack noshow " + outputImage;
	homepath   = " -path " + outputdir;
	monitor = " -verbose yes ";
	resources = " -fft FFTW2";
	resultFile = outputdir + File.separator + outputImage + ".tif";
	
	print("Deconvolving: " + inputImage);
	print(" ");
	
	//overwrite existing file by delete -- needed for the while loop
	if (File.exists(resultFile)) {
		File.delete(resultFile);
	}
	run("DeconvolutionLab2 Run", image + psf + algorithm + resources + monitor + output + homepath);
	while(!File.exists(resultFile)) {
    	wait(1000);
    	print("\\Update:" + bars[(index++)%9]);
	}
 	wait(1000);
	print("\\Update:" + "Timepoint: " + tp + " of " + nTime + " finished!");
	run("Collect Garbage");
	File.delete(inputImage);
    wait(1000);

}
 
// close all open images
close("*");

// recombine the images into a hyperstack
resultFile = outputdir + File.separator + filename + "DCVstack.tif"
//overwrite existing file by delete -- needed for the while loop
if (File.exists(resultFile)) {
	File.delete(resultFile);
}
File.openSequence(outputdir);
print("order=xyczt(default) channels=1 slices=" + zDim + " frames=" + nTime +" display=Color");

run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + zDim + " frames=" + nTime +" display=Color");
saveAs("tiff", resultFile);
