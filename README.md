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
    
### MATLAB
- This pipeline is built on **AP_histology**, developed by Andy Peters, which provides tools to align histology images to the Allen Brain Atlas. We recommend following their detailed documentation for setup and use. Special thanks to the AP_histology team for making this invaluable resource available to the community.
- **AP_histology:** Follow the installation instructions on the <a href="https://github.com/petersaj/AP_histology">AP_histology GitHub page</a>
- **MATLAB Toolboxes and Add-ons:**
  - Install the **Curve Fitting Toolbox**.
  - Install the **natsortfile add-on** (Natural-Order Filename Sort Version 3.4.5 by Stephen23).
- Download the **MATLAB folder** from this toolbox and place it in your Windows user folder under `Documents/MATLAB/` (in addition to the AP-histology required files). Make sure the MATLAB folder is added to your path (main menu > add to path > check all files and folders are listed, otherwise MATLAB won't find the scripts)

## Running the Pipeline
### FIJI - get coordinates of volume in 2D slices
#### 1. Pre-processing of images 
(Optional, creates folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal)
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

### MATLAB - transform coordinates into CCFv3 space
#### 1. Animal-specific transformation
- Open MATLAB
- Navigate to the folder, make sure the folder you select contains only the single TIF files for one brain.
- Open the code file: `AP_1_VOL_SingleAnimal_addGroup_20240729.m` from this repository.
- Adjust the following settings in the code:
  - **Define channels to process:** Set the channels and colors for your analysis, and give your volume a label (e.g., group or fluorophore). This will be used to color-code your plots later.
    
```
channelColors = {'red','green'}; % Set the colors for plotting each channel
ChannelNames = {'TdTomato','GFP'}; % Give descriptive names for each channel (e.g., Cre/Ctrl, TdT/GFP, Stroke/Injection, etc.)
```
**Optional:** If you're planning to combine results from multiple animals later, you can choose to copy the final output into an additional (existing!) folder. The script will then save the necessary files into this folder. Make sure this folder already exists:
`addfolder="C:\......\VOL3D\EXP\";  % You can skip this by adding a % before the line if not needed. Folder needs to already exist, and it needs the full folder address`

- There are some additional options you can customize:
  - **Rerun AP-histology:** By default, AP-histology runs automatically the first time, and once defined will be skipped. Set this to 1 if you want to rerun it (eg if you want to re-define the atlas mapping).
  - **Calculate brain volume:**By default, brain volume is calculated for all brains in step 2, but you can choose to do it now for this brain by setting this to 1.
  - **Plot ABA structures:**You can plot specific brain structures by defining their names (these should match ABA nomenclature). If you don’t want to plot structures, just comment out the line by adding a %.


`
rerun_histology = 0;  % Set to 1 if you want to force rerun AP_histology
overlap_vol = 0;      % Set to 1 if you want to calculate brain volume now
% Uncomment the line below if you want to skip plotting ABA structures:
% structure_names = {'Somatomotor areas', 'Somatosensory areas', 'Visual areas', 'Auditory areas'}; % Structures to plot in the brain (light grey)
`

<p>**Final Step:**Press "Run" or run the script section by section. This will generate a 3D plot and create CSV files for further analysis.


<h4>2.2. Processing Multiple Animals</h4>
<p>To combine data from multiple animals into a single 3D model, follow these steps using the second MATLAB script: `AP_2_VOL_PlotAllAnimalsInFolder_20240502.m`.


    **Step 1:**Navigate to the folder where the `addfolder` from the previous script was saved. Alternatively, copy and paste any `*_variables.mat` file from each animal you want to include into a new folder, and navigate to that folder.


<p>**Step 2:**Adapt the following settings at the beginning of the script:

`
ExperimentName = 'EXPABC';    % Name of the experiment
groups = {'Cre', 'Ctrl'};     % Group names based on filenames (ensure unique names for each group)
groupColors = {[0.9882, 0.6706, 0.3922], [244/255, 91/255, 105/255], 'blue'};  % Colors for plotting (RGB triplet or standard color names)
flipside = 'L';               % Can be 'L' or 'R' to flip, or leave empty for no flipping
alpha = 0.1;                  % Transparency for the 3D plot
resolution = 100;             % Voxel size (e.g., use 10 for high resolution, 100 for faster runs)
structure_acronyms = {'MO', 'MOs', 'MOp', 'SS', 'SSp', 'SSs', 'AUD', 'VIS', 'AI', 'ACA'};  % List of ABA structures to plot
`


    **Step 3:**Run the script.


<p>**Output:**The script will generate the following:

    A 3D plot of volumes, either by group, by animal, or combined into one plot.
    A CSV file with the percentage overlap between all volumes (all volumes compared to each other).
    A CSV file with the percentage overlap between the volumes and the selected ABA structures.

