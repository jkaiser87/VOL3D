# Volume tracking from slices into CCFv3 ABA space
Toolbox to track volumes (such as injections, stroke area, region of interest etc...) and translate the location into CCFv3 ABA Space using FIJI and MATLAB. 
This pipeline is fully based on the amazing AP_histology (https://github.com/petersaj/AP_histology) for alignment of sections to brain regions and calculation of coordinates into CCFv3 space. 
It provides an easy-to-follow workflow for processing single-slice TIF files of coronal brain sections and integrating the data into a 3D model for analysis.

![image](https://github.com/user-attachments/assets/5fa86b22-43e4-4fb3-bc98-8fa4d4731fc2)

## Requirements and Setup

### Data Format
- **Requirement**: Folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal (additional pipeline provided that can help with cropping slide images and merging split-channel images).
- **Important: Naming of the Files.** The pipeline **relies heavily on filenames** for correct processing and sorting. The correct syntax for the filenames is `EXP1-A2_filename_s001.tif` where:
  - The part **before the first underscore** (e.g., `EXP1-A2`) is used to **identify the animal** (and should be unique). This can include both the experiment and animal name, separated by a hyphen `-` if necessary.
  - `_s001` is the slice number (slice numbers must be padded to avoid incorrect sorting, e.g., `_s001`, `_s002`).
  - **Optional:** `_Ch01` represents the channel (e.g., `_Ch01`, `_DAPI`), if using separate-channel images.

**Ensure that filenames always start with the animal name** (or a combination of experiment and animal name, ***unique!***). Anything before the first underscore will be treated as the animal identifier. This is critical for correct organization and grouping of data.

**Example filenames that work for the pipeline:**
```
EXP1-A2_10x-Cortex_RFP-GFP-NeuN_s001.tif
EXP1-A3_retroAAV-GFP_DAPI_fNissl_10x_s002_Ch01.tif
EXP1-A3_retroAAV-GFP_DAPI_fNissl_10x_s002_Ch02.tif
EXP2-B5_thistext-really-doesnt-matter-as-long-as-the-rest_fits_s005_DAPI.tif
EXP2-B5_thistext-really-doesnt-matter-as-long-as-the-rest_fits_s005_Alexa488.tif
```        

### FIJI.app
- **Download FIJI** from the official <a href="https://fiji.sc/">website</a>.
- Download the necessary **Fiji folder** from this repository and paste it into your `FIJI.app` folder. Make sure that it lands in the right subfolder (Fiji.app/macro/toolsets)
    
    
### MATLAB (tested on 2023a)

This pipeline builds on AP_histology, a powerful toolkit for aligning histological images to the Allen Brain Atlas. We recommend following their excellent documentation for installation and usage. Special thanks to the AP_histology team for making this invaluable resource freely available to the community.

#### AP_histology

[AP_histology](https://github.com/petersaj/AP_histology): Follow the installation instructions on the original AP_histology GitHub repository.

OR

[devAP_histology](https://github.com/jkaiser87/devAP_histology) (forked for developmental atlas support): Supports both adult and developmental mouse brain atlases.

- **MATLAB Toolboxes and Add-ons:**
  - Install the **Curve Fitting Toolbox**.
  - Install the **natsortfile add-on** (Natural-Order Filename Sort Version 3.4.5 by Stephen23).
- Download the **MATLAB folder** from this toolbox and place it in your Windows user folder under `Documents/MATLAB/` (in addition to the AP-histology required files). Make sure the MATLAB folder is added to your path (main menu > add to path > check all files and folders are listed, otherwise MATLAB won't find the scripts)

## Running the Pipeline
### FIJI - get coordinates of volume in 2D slices
#### 1. OPTIONAL: Pre-processing of images
Run this part to create a folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal. Skip to Step 2 if your files are already sorted into 1 folder.
- Open FIJI and navigate to the toolbox by selecting `>>` `1_PrepareSlicesAsTif`.
- ![folder](https://github.com/user-attachments/assets/48cd6811-b670-4e04-af52-b52ba09f3ff7)
Select the appropriate folder: Choose the folder that contains either whole-slide overview TIF files or single-slice separate-channel TIF files. If the correct filename convention is followed, the folder can contain multiple animals' data within the same folder.
- **If you are working with whole-slide imaging:**
  - ![image](https://github.com/user-attachments/assets/c781c3c7-77ef-432e-8b27-0ca4efac2c04) Split the channels.
  - Then, if needed, make any adjustments to the split channel images (such as reducing background noise) in Photoshop.
  - ![image](https://github.com/user-attachments/assets/1c4609b5-9eee-4bf0-b8ea-09ae165468b6) Crop the whole-slide images by drawing rectangles around each slice you want to export.
  - At the end, the script will save each slice as a separate file in the subfolder "Slices/ANIMALNAME".
- **If you are working with separate-channel images:** ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) This script will allow you to provide a folder of split-channel images. You will be prompted to select which channels to include and to specify the color for each channel in the final multichannel TIF file.
  - **If you are working with multi-channel images and want to exclude images:** ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) This script also allows to remove channels from the image that you do not want and re-arrange the colors.

**OUTPUT:** The result will be a folder with one multichannel TIF file per section (i.e., per slice).  
If multiple animals provided, there will be subfolders in the folder "Slices" according to the animal name.

#### 2. Volume Tracing (VOL3D)
- Navigate to the toolbox (`>>` `2_VOL3D_VolCoords`).
- ![image](https://github.com/user-attachments/assets/7f85864d-4866-470c-bfa6-9bd9f3986a01) Set the folder to a folder containing sections (multichannel) of 1 or more animals (this can be the folder "Slices" created in the previous step or directly a folder containing TIF files of 1 animal. Make sure that no other tif files are in this or a subfolder).
- ![image](https://github.com/user-attachments/assets/2d716049-19c7-4aeb-a8cf-f3071fd66221)
Preprocess slices: Rotate and flip slices as necessary
  - Rotate the slices by drawing a line at the midline (from top to bottom)
  - Injection volumes should be on the same side, so if necessary, flip the section using Ctrl + F.
- ![shape](https://github.com/user-attachments/assets/63b517f2-2c0e-4299-ae90-5ed4a129c229) Draw Volume: Select channel to be analysed (C1, C2, C3 or C4) - FIJI will automatically isolate the channel and show you a black/white version of the selected channel for each section.
  - If there is no signal that you want to outline, click "Continue" to proceed to the next slice.
  - If there is signal present, use the pre-selected free selection tool to outline the region of interest (there should only be 1 volume for each slice!).
  - Continue through all slices, the pipeline will tell you when all are processed.
- ![shape](https://github.com/user-attachments/assets/63b517f2-2c0e-4299-ae90-5ed4a129c229) **You can process additional channels**. Re-run this last step and select another channel.
- This pipeline currently only works for 1 volume per channel, it can not be used to create several volumes from the same channel. 

- **Output:** Running this pipeline will create a subfolder called "VOL" in each animal folder (or in the main folder), which contains CSV and ZIP folders of the coordinates tracked through the pipeline.

### MATLAB - transform coordinates into CCFv3 space

#### 1. Animal-specific transformation
- Open MATLAB
- Navigate to the folder of 1 animal. This is the folder containing the TIF files, and should also contain a subfolder called "VOL" that was created through the FIJI pipeline
- Open the code file: `VOL3D_Step1_Animal_GUI.m` from this repository.
- Run the script (if asked, "add to path")
- a GUI will pop up:

<img width="1397" height="727" alt="image" src="https://github.com/user-attachments/assets/0ee8171d-4c2e-468c-9c6e-10d61f91d568" />

- Check that all tif files are found and listed on the left
- Choose channel(s) and assign an optional channel name (to label the volume, eg with GFP or Cre or stroke etc) and assign a group to the animal.
- Select the appropriate Atlas Type (e.g. adult or developmental) to enable AP_histology.
- Run AP_histology (alignment to CCF). After running through all steps (up to manual alignment), close the GUI and re-start CELL3D to refresh.
- Run "Create 3D VOlume in CCF" -> This will display the volume within CCF space in a plot on the right.
- You can also choose to mirror the volume onto left/right hemisphere, choose what to color by etc.


<img width="1400" height="727" alt="image" src="https://github.com/user-attachments/assets/d241d764-3b43-43b3-a183-53f894f9d29a" />


To prepare for step 2 (summarizing several animals in one brain), use the button "save to additional folder" and choose a folder where the *_volumes.mat file will be stored. Add all additional animals after processing them to this same folder.

#### 2. Plotting Multiple Animals into 1 
To combine data from multiple animals into a single 3D model, follow these steps using the second MATLAB script: `VOL3D_Step2_PlotAllAndCalculateVolumes.m`.

- Open MATLAB
- Navigate to the folder in which the *_volumes.mat files were saved in step 1.
- Open `VOL3D_Step2_GUI.m` in MATLAB.
- Run the script (if asked, "add to path")
- a GUI will pop up:

<img width="1403" height="731" alt="image" src="https://github.com/user-attachments/assets/8eb6491e-a967-43e7-a23a-c7190d09d5a0" />




```
ExperimentName = 'EXP'; %set a prefix for the files saved in the script
colorMapType = 'channel';  % Set to 'channel' to (re)color by channel (set in Script 1), or 'group' if defined in Script 1
colorMap = containers.Map(... % Define the colors and which group they correspond to (by order)
    {'flexTdT', 'GFP'}, ...  % Group or channel names
    {'#DB2B39', '#337054',});  % Corresponding colors (465487=blue, DB2B39=red, 7C8289=gray, 337054=green)
flipside = 'L'; %if L/R: volumes will all be flipped onto L/R hemisphere 
alpha = 0.1; %transparency for volumes in brain plots
resolution = 100; % voxelsize for volume estimation (um). 10 for high resolution, 100 for fast runs (Atlas original is 10)
```

- **Run the script by section and adapt as necessary**
  - **folder setup, Create volumes data**: This always needs to be run to load the volumes into a suitable format for the following steps.
    - Will load a previously created file if run the second time. If you want to re-run, set forceRun = true or manually delete `OUT/*_3D_VolumeCalc.mat` (useful when you add more animals, or change the color etc in the main files);
    - **Output**: This script also creates a CSV file with the min & max coordinate in each [x,y,z] direction as well as the estimated volume size by calculating how many voxel are inside the volume (voxel size depend on resolution). Can be found in `OUT/*_MinMax-Axes.csv`.
  - **Plot volumes with brain**: Run this section to create 3D reconstructions of volumes within a CCFv3 brain.
    - `plot_volumes_with_brain(volumes, outDir, ExperimentName, alpha, colorType, plotMode)` function parameters:
      - *volumes* - structure created in previous step
      - *outDir, ExperimentName, alpha* - (defined in setup)
      - *colorType* - can be 'group' or 'channel'. 
      - *plotMode* - can be 0 (plots all available volumes into 1 brain), 1 (split each group into several brains), 2 (split animals into individual brains)
    - This can also be done on a subset of the data:
    ```
    subvolumes = volumes(ismember({volumes.channel}, {'GFP'}));
    plot_volumes_with_brain(subvolumes, outDir, [ExperimentName,'-GFP'], alpha, 'group',0); 
    ```
    - **Output**: This script saves a *.png and *.m figure file of each plot
      - plotMode 0 - `OUT/*_3DPlot_SinglePanel.png/.m`.  (also creates an angled view)
      ![image](https://github.com/user-attachments/assets/68d54f91-2e1d-440c-a348-00b0dc26a0d9)
      - plotMode 1 - `OUT/*_3DPlot_SplitPanel.png/.m`
      ![image](https://github.com/user-attachments/assets/397932e1-af18-49af-8338-ea8b033ee166)
      - plotMode 2 - `OUT/*_3DPlot_IndividualPanel.png/.m`
      ![image](https://github.com/user-attachments/assets/d061e2bd-8a56-43cc-86e4-bdd6c9168ea8)

  - **Calculate overlap between volumes (or subvolumes)**: Run this section, if you want to calculate the estimated overlap between volumes.
    - This script calculates the overlap between each volume with all other volumes and creates a CSV file in `OUT/*_3D_Overlap_Results_AllPairs.csv` with % of overlap between Vol1 compared to Vol2 (ovelap_percentage)
  - **Calculate overlap with brain structures:** Run this section to calculate overlap with Allen brain atlas structures
    - Define ABA structures using acronyms (use `Documents\MATLAB\AP_histology\allenAtlas\structure_tree_safe_2017.csv` provided here or in AP_histology to find acronyms for any given structure)
    - Run `calculate_overlap_with_brain_structures` 
```
structure_acronyms = {'MOs','MOp','SSp','SSs', 'AUD','VIS','AI','ACA'}; %need to match ABA nomenclature
calculate_overlap_with_brain_structures(volumes, structure_acronyms, outDir, ExperimentName, alpha, false);
```

   - **Output** : creates a CSV file (`OUT/*_3D_Overlap_Results_VolumestoBrainStructures.csv`) with % of overlap of each volume to given ABA structure (overlap_fraction_original)

### Summary Output
The script will generate the following:
  - A 3D plot of volumes, either by group, by animal, or combined into one plot.
  - A CSV file with the percentage overlap between all volumes (all volumes compared to each other).
  - A CSV file with the percentage overlap between the volumes and the selected ABA structures.

