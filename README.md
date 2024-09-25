<h1>Volume tracking from slices into CCFv3 ABA space</h1>

Toolbox to track volumes (such as injection volume or stroke volume etc...) and translate the location into CCFv3 ABA Space using FIJI and MATLAB. 
This pipeline is fully based on the amazing AP_histology (https://github.com/petersaj/AP_histology) for alignment of sections to brain regions and calculation of coordinates into CCFv3 space. 
It provides an easy-to-follow workflow for processing single-slice TIF files of coronal brain sections and integrating the data into a 3D model for analysis.

<h2>Requirements and Setup</h2>

<h3>Data Format</h3>

<ul>
        <li>Folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal.</li>
        <li><strong>Important: Naming of the Files</strong></li>
        <ul>
            <li>The pipeline <strong>relies heavily on filenames</strong> for correct processing and sorting. The correct syntax for the filenames is as follows:</li>
            <pre><code>EXP1-A2_filename_s001.tif</code></pre>
            <li>
                where:
                <ul>
                    <li>The part before the first underscore (e.g., <code>EXP1-A2</code>) is <strong>used to identify the animal</strong>. This can include both the experiment and animal name, separated by a hyphen <code>-</code> if necessary.</li>
                    <li><code>_s001</code> is the slice number (slice numbers must be padded to avoid incorrect sorting, e.g., <code>_s001</code>, <code>_s002</code>).</li>
                    <li><strong>Optional:</strong> <code>_Ch01</code> represents the channel (e.g., <code>_Ch01</code>, <code>_DAPI</code>), if using separate-channel images.</li>
                </ul>
            </li>
            <li><strong>Ensure that filenames always start with the animal name</strong> (or a combination of experiment and animal name). Anything before the first underscore will be treated as the animal identifier. This is critical for correct organization and grouping of data.</li>
        </ul>
        <li><strong>Example filenames:</strong></li>
        <ul>
            <li><code>EXP1-A2_s001.tif</code></li>
            <li><code>EXP1-A3_s002_Ch01.tif</code></li>
            <li><code>EXP2-B5_s005_Ch02.tif</code></li>
        </ul>
    </ul>

<h3>FIJI.app</h3>
    <ul>
        <li><strong>Download FIJI</strong> from the official <a href="https://fiji.sc/">website</a>.</li>
        <li>Download the necessary <strong>Fiji folder</strong> from this repository and paste it into your <code>FIJI.app</code> folder.</li>
    </ul>

<h3>MATLAB</h3>
  <ul>
    <li><strong>AP_histology:</strong> Follow the installation instructions on the <a href="https://github.com/petersaj/AP_histology">AP_histology GitHub page</a>.</li>
        <li><strong>Credit:</strong> This pipeline relies on AP_histology, developed by Andy Peters and others, which provides tools to align histology images to the Allen Brain Atlas. We recommend following their detailed documentation for setup and use. Special thanks to the AP_histology team for making this invaluable resource available to the community.</li>
        <li><strong>MATLAB Toolboxes:</strong></li>
        <ul>
            <li>Install the <strong>Curve Fitting Toolbox</strong>.</li>
            <li>Install the <strong>natsortfile add-on</strong> (Natural-Order Filename Sort Version 3.4.5 by Stephen23).</li>
        </ul>
        <li>Download the <strong>MATLAB folder</strong> from this toolbox and place it for example in your user folder under <code>Documents/MATLAB/</code> (in addition to the AP-histology required files).</li>
   <li>Make sure the MATLAB folder is added to your path (main menu > add to path > check all files and folders are listed, otherwise MATLAB won't find the scripts)</li>
    </ul>
 
   <h2>Running the Pipeline</h2>
<h3>1. FIJI Part</h3>

<b>1.1. Pre-processing of images (optional)</b>
<ul>
    <li><b>Open FIJI:</b> Launch FIJI and navigate to the toolbox by selecting <code>>></code> <code>1_PrepareSlicesAsTif</code>.</li>
    <li><b>Select the appropriate folder:</b> Choose the folder that contains either whole-slide overview TIF files or single-slice separate-channel TIF files. If the correct filename convention is followed, the folder can contain multiple animals' data within the same folder.</li>
</ul>

<p><b>If you are working with whole-slide imaging:</b> First, split the channels in FIJI. Then, if needed, make any adjustments to the image (such as reducing background noise) in Photoshop. Finally, crop the whole-slide images by drawing rectangles around each slice you want to export, and save each slice as a separate file.</p>

<p><b>If you are working with separate-channel images:</b> Use the last icon in the toolset to merge the channels. You will be prompted to select which channels to include and to specify the color for each channel in the final multichannel TIF file.</p>

<p><b>OUTPUT:</b> The result will be a folder with one multichannel TIF file per section (i.e., per slice).</p>

<b>1.2. Volume Tracing</b>
<ul>
    <li>Navigate to the toolbox (<code>>></code> <code>2_VOL3D_VolCoords</code>).</li>
    <li>Set the folder to a folder containing sections (multichannel) of 1 or more animals.</li>
    <li>Preprocess slices: Rotate and flip slices as necessary.</li>
    <li>Draw Volume: FIJI will automatically isolate the channel.</li>
    <ul>
        <li>If no signal is detected, click "Continue" to proceed to the next slice.</li>
        <li>If signal is present, use the pre-selected free selection tool to outline the region of interest (there should only be 1 volume present).</li>
    </ul>
    <li>You can process several channels, one after another.</li>
</ul>

<h3>2. MATLAB Part</h3>

<b>2.1. Processing Animal by Animal</b>

<p><b>Step 1:</b> Navigate to the folder, make sure the folder you select contains only the single TIF files for one brain.</p>
<p><b>Step 2:</b> Open the code file: <code>AP_1_VOL_SingleAnimal_addGroup_20240729.m</code> from this repository.</p>

<p>Customize the following settings in the code:</p>

<ul>
    <li><b>Define channels to process:</b> Set the channels and colors for your analysis, and give your volume a label (e.g., group or fluorophore). This will be used to color-code your plots later.</li>
</ul>

<pre><code>
channelsToProcess = {'C1','C2'}; % List the channels you want to process (make sure corresponding CSV files exist in a subfolder)
channelColors = {'red','green'}; % Set the colors for plotting each channel
ChannelNames = {'TdTomato','GFP'}; % Give descriptive names for each channel (e.g., Cre/Ctrl, TdT/GFP, Stroke/Injection, etc.)
</code></pre>

<p><b>Optional:</b> If you're planning to combine results from multiple animals later, you can choose to copy the final output into an additional (existing!) folder. This saves you from manually copying files later.</p>

<pre><code>
% If you want to copy the output to a specific folder, set it here
addfolder = "C:\......\VOL3D\EXP\";  % You can skip this by adding a % before the line if not needed. Folder needs to already exist, and it needs the full folder address
</code></pre>

<p>There are some additional options you can customize:</p>

<ul>
    <li><b>Rerun AP-histology:</b> By default, AP-histology runs automatically the first time. Set this to 1 if you want to rerun it for any reason later.</li>
    <li><b>Calculate brain volume:</b> By default, brain volume is calculated for all brains in step 2, but you can choose to do it now for this brain by setting this to 1.</li>
    <li><b>Plot ABA structures:</b> You can plot specific brain structures by defining their names (these should match ABA nomenclature). If you don’t want to plot structures, just comment out the line by adding a %.</li>
</ul>

<pre><code>
rerun_histology = 0;  % Set to 1 if you want to force rerun AP_histology
overlap_vol = 0;      % Set to 1 if you want to calculate brain volume now
% Uncomment the line below if you want to skip plotting ABA structures:
% structure_names = {'Somatomotor areas', 'Somatosensory areas', 'Visual areas', 'Auditory areas'}; % Structures to plot in the brain (light grey)
</code></pre>

<p><b>Final Step:</b> Press "Run" or run the script section by section. This will generate a 3D plot and create CSV files for further analysis.</p>


<h4>2.2. Processing Multiple Animals</h4>
<p>To combine data from multiple animals into a single 3D model, follow these steps using the second MATLAB script: <code>AP_2_VOL_PlotAllAnimalsInFolder_20240502.m</code>.</p>

<ul>
    <li><b>Step 1:</b> Navigate to the folder where the <code>addfolder</code> from the previous script was saved. Alternatively, copy and paste any <code>*_variables.mat</code> file from each animal you want to include into a new folder, and navigate to that folder.</li>
</ul>

<p><b>Step 2:</b> Adapt the following settings at the beginning of the script:</p>

<pre><code>
ExperimentName = 'EXPABC';    % Name of the experiment
groups = {'Cre', 'Ctrl'};     % Group names based on filenames (ensure unique names for each group)
groupColors = {[0.9882, 0.6706, 0.3922], [244/255, 91/255, 105/255], 'blue'};  % Colors for plotting (RGB triplet or standard color names)
flipside = 'L';               % Can be 'L' or 'R' to flip, or leave empty for no flipping
alpha = 0.1;                  % Transparency for the 3D plot
resolution = 100;             % Voxel size (e.g., use 10 for high resolution, 100 for faster runs)
structure_acronyms = {'MO', 'MOs', 'MOp', 'SS', 'SSp', 'SSs', 'AUD', 'VIS', 'AI', 'ACA'};  % List of ABA structures to plot
</code></pre>

<ul>
    <li><b>Step 3:</b> Run the script.</li>
</ul>

<p><b>Output:</b> The script will generate the following:</p>
<ul>
    <li>A 3D plot of volumes, either by group, by animal, or combined into one plot.</li>
    <li>A CSV file with the percentage overlap between all volumes (all volumes compared to each other).</li>
    <li>A CSV file with the percentage overlap between the volumes and the selected ABA structures.</li>
</ul>
