

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
rename("Original duplicate.tif");

// SNR increase, median filter based method

run("32-bit");
run("ROF Denoise", "theta=250");
saveAs("Tiff", path + filename + " denoised");
rename("Denoised.tif");
selectImage("Denoised.tif");
setAutoThreshold("Default dark");

//SBR: removing background through thresholding

run("Make Binary", "method=MinError calculate black create");
setOption("BlackBackground", true);
run("Erode", "stack");
run("Erode", "stack");
run("Erode", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
run("Dilate", "stack");
saveAs("Tiff", path + filename + " threshhold MASK");
rename("Denoised MASK.tif");

imageCalculator("AND create 32-bit stack", "Denoised.tif","Denoised MASK.tif");
saveAs("Tiff", path + filename + " denoised final");
close("\\Others");
close("*");

//DECONVOLUTION

//Change image file and psf file for every new image!!!


	image = " -image file /Users/linnea/Desktop/Deconvolution/b-ERRed denoised final.tif";
	psf = " -psf file /Users/linnea/Desktop/Deconvolution/PSF RW best 647.tif";
	algorithm = " -algorithm RL 25.00";
	parameters = "25";
	output = " -out stack ST1";
	monitor = " -monitor yes";
	stats = " -stats show + save";
	resources = " - fft FFTW2";
	run("DeconvolutionLab2 Launch", image + psf + algorithm + parameters + output + monitor + stats + resources);
	//click ok when process is done not before
	wait(600000);
	waitForUser;

	selectImage("ST1");
	saveAs("Tiff", path + filename + " denoised and deconvoluted");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=8 frames=33 display=Grayscale");
	run("Save");
