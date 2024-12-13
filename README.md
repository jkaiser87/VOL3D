# Volume tracking from slices into CCFv3 ABA space
Toolbox to track volumes (such as injection volume or stroke volume etc...) and translate the location into CCFv3 ABA Space using FIJI and MATLAB. 
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
        
        **Example filenames:**
        
            `EXP1-A2_s001.tif`
            `EXP1-A3_s002_Ch01.tif`
            `EXP2-B5_s005_Ch02.tif`
        
    

<h3>FIJI.app</h3>
    
        **Download FIJI** from the official <a href="https://fiji.sc/">website</a>.
        Download the necessary **Fiji folder** from this repository and paste it into your `FIJI.app` folder.
    

<h3>MATLAB</h3>
  
        This pipeline is built on **AP_histology**, developed by Andy Peters, which provides tools to align histology images to the Allen Brain Atlas. We recommend following their detailed documentation for setup and use. Special thanks to the AP_histology team for making this invaluable resource available to the community.
        **AP_histology:** Follow the installation instructions on the <a href="https://github.com/petersaj/AP_histology">AP_histology GitHub page</a>.
        **MATLAB Toolboxes and Add-ons:**
        
            Install the **Curve Fitting Toolbox**.
            Install the **natsortfile add-on** (Natural-Order Filename Sort Version 3.4.5 by Stephen23).
        
        Download the **MATLAB folder** from this toolbox and place it in your Windows user folder under `Documents/MATLAB/` (in addition to the AP-histology required files).
   Make sure the MATLAB folder is added to your path (main menu > add to path > check all files and folders are listed, otherwise MATLAB won't find the scripts)
    
 
   <h2>Running the Pipeline</h2>
<h3>1. FIJI Part</h3>

<b>1.1. Pre-processing of images 
*(Optional, creates folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal)</b>

    <b>Open FIJI:</b> Launch FIJI and navigate to the toolbox by selecting `>>` `1_PrepareSlicesAsTif`.
     <b>Select the appropriate folder:</b> Choose the folder that contains either whole-slide overview TIF files or single-slice separate-channel TIF files. If the correct filename convention is followed, the folder can contain multiple animals' data within the same folder.
    <b>If you are working with whole-slide imaging:</b> 
    <b>If you need to make adjustments to the histogram</b>: ![image](https://github.com/user-attachments/assets/c781c3c7-77ef-432e-8b27-0ca4efac2c04) Split the channels. Then, if needed, make any adjustments to the split channel images (such as reducing background noise) in Photoshop. ![image](https://github.com/user-attachments/assets/1c4609b5-9eee-4bf0-b8ea-09ae165468b6) Crop the whole-slide images by drawing rectangles around each slice you want to export. At the end, the script will save each slice as a separate file in the subfolder "Slices/ANIMALNAME".
        ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) <b>If you are working with separate-channel images:</b> This script will allow you to provide a folder of split-channel images. You will be prompted to select which channels to include and to specify the color for each channel in the final multichannel TIF file.
        ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) <b>If you are working with multi-channel images and want to exclude images:</b> This script also allows to remove channels from the image that you do not want and re-arrange the colors.


<p><b>OUTPUT:</b> The result will be a folder with one multichannel TIF file per section (i.e., per slice). 
        If multiple animals provided, there will be subfolders in the folder "Slices" according to the animal name.</p>

<b>1.2. Volume Tracing (VOL3D)</b>

    Navigate to the toolbox (`>>` `2_VOL3D_VolCoords`).
    ![image](https://github.com/user-attachments/assets/7f85864d-4866-470c-bfa6-9bd9f3986a01) Set the folder to a folder containing sections (multichannel) of 1 or more animals (this can be the folder "Slices" created in the previous step or directly a folder containing TIF files. Make sure that no other tif files are in this or a subfolder).
    ![image](https://github.com/user-attachments/assets/2d716049-19c7-4aeb-a8cf-f3071fd66221)
Preprocess slices: Rotate and flip slices as necessary
            - Rotate the slices by drawing a line at the midline (from top to bottom)
            - Injection volumes should be on the same side, so if necessary, flip the section using Ctrl + F.
    Draw Volume: FIJI will automatically isolate the channel.
    
        If no signal is detected, click "Continue" to proceed to the next slice.
        If signal is present, use the pre-selected free selection tool to outline the region of interest (there should only be 1 volume present).
    
    You can process several channels, one after another.


<h3>2. MATLAB Part</h3>

<b>2.1. Processing Animal by Animal</b>

<p><b>Step 1:</b> Navigate to the folder, make sure the folder you select contains only the single TIF files for one brain.</p>
<p><b>Step 2:</b> Open the code file: `AP_1_VOL_SingleAnimal_addGroup_20240729.m` from this repository.</p>

<p>Customize the following settings in the code:</p>


    <b>Define channels to process:</b> Set the channels and colors for your analysis, and give your volume a label (e.g., group or fluorophore). This will be used to color-code your plots later.


`
channelsToProcess = {'C1','C2'}; % List the channels you want to process (make sure corresponding CSV files exist in a subfolder)
channelColors = {'red','green'}; % Set the colors for plotting each channel
ChannelNames = {'TdTomato','GFP'}; % Give descriptive names for each channel (e.g., Cre/Ctrl, TdT/GFP, Stroke/Injection, etc.)
`

<p><b>Optional:</b> If you're planning to combine results from multiple animals later, you can choose to copy the final output into an additional (existing!) folder. This saves you from manually copying files later.</p>

`
% If you want to copy the output to a specific folder, set it here
addfolder = "C:\......\VOL3D\EXP\";  % You can skip this by adding a % before the line if not needed. Folder needs to already exist, and it needs the full folder address
`

<p>There are some additional options you can customize:</p>


    <b>Rerun AP-histology:</b> By default, AP-histology runs automatically the first time. Set this to 1 if you want to rerun it for any reason later.
    <b>Calculate brain volume:</b> By default, brain volume is calculated for all brains in step 2, but you can choose to do it now for this brain by setting this to 1.
    <b>Plot ABA structures:</b> You can plot specific brain structures by defining their names (these should match ABA nomenclature). If you don’t want to plot structures, just comment out the line by adding a %.


`
rerun_histology = 0;  % Set to 1 if you want to force rerun AP_histology
overlap_vol = 0;      % Set to 1 if you want to calculate brain volume now
% Uncomment the line below if you want to skip plotting ABA structures:
% structure_names = {'Somatomotor areas', 'Somatosensory areas', 'Visual areas', 'Auditory areas'}; % Structures to plot in the brain (light grey)
`

<p><b>Final Step:</b> Press "Run" or run the script section by section. This will generate a 3D plot and create CSV files for further analysis.</p>


<h4>2.2. Processing Multiple Animals</h4>
<p>To combine data from multiple animals into a single 3D model, follow these steps using the second MATLAB script: `AP_2_VOL_PlotAllAnimalsInFolder_20240502.m`.</p>


    <b>Step 1:</b> Navigate to the folder where the `addfolder` from the previous script was saved. Alternatively, copy and paste any `*_variables.mat` file from each animal you want to include into a new folder, and navigate to that folder.


<p><b>Step 2:</b> Adapt the following settings at the beginning of the script:</p>

`
ExperimentName = 'EXPABC';    % Name of the experiment
groups = {'Cre', 'Ctrl'};     % Group names based on filenames (ensure unique names for each group)
groupColors = {[0.9882, 0.6706, 0.3922], [244/255, 91/255, 105/255], 'blue'};  % Colors for plotting (RGB triplet or standard color names)
flipside = 'L';               % Can be 'L' or 'R' to flip, or leave empty for no flipping
alpha = 0.1;                  % Transparency for the 3D plot
resolution = 100;             % Voxel size (e.g., use 10 for high resolution, 100 for faster runs)
structure_acronyms = {'MO', 'MOs', 'MOp', 'SS', 'SSp', 'SSs', 'AUD', 'VIS', 'AI', 'ACA'};  % List of ABA structures to plot
`


    <b>Step 3:</b> Run the script.


<p><b>Output:</b> The script will generate the following:</p>

    A 3D plot of volumes, either by group, by animal, or combined into one plot.
    A CSV file with the percentage overlap between all volumes (all volumes compared to each other).
    A CSV file with the percentage overlap between the volumes and the selected ABA structures.

