%% Volume tracing from Fiji to CCFv3 using AP_histology
% Julia Kaiser, April 2024

% this script processes injection volumes traced in
% FIJI and plots them into CCFv3 3D space using AP_histology written by petersaj

% https://github.com/petersaj/AP_histology

% ----- add D:\MATLAB to your path
% ----- make sure that there is only 1 animal in folder
% should contain subfolder VOL/ and *.tif slices in main folder (open)

clearvars; clc;
% adapt these settings:
channelsToProcess = {'C1'}; % Define which channels to process (should have csv files in subfolder starting with)
channelColors={'red'}; %colors to plot the channels by
ChannelNames = {'S1'}; %Add Names to the channels (eg Cre, TdT, ...) to label in plot

%This allows you to additionally copy the *.mat file into an additional folder.
%This can help with the follow-up steps of combining several animals into 1
%figure.
% Keep empty if you want to skip!
%addfolder="Z:\Research\Sahni Lab\_Julia\_DOCS\_PAPERS\2024_CBNskill\data\Fig7\VOL3D\M1S1";

%% only change here if you need to, probs not

rerun_histology = 0;  % Set to 1 if you want to force rerun AP_histology
overlap_vol = 0; % Set to 1 if you want to calculate the brain volume for this brain (this will be done later for ALL brains anyway in step 2, so only put 1 if you are not planning on running step 2)
% uncomment this next line (delete the %) if you dont want to plot any ABA structures:
% structure_names = {'Somatomotor areas', 'Somatosensory areas', 'Visual areas', 'Auditory areas'}; %structures to plot into the brain (light grey)

%%
%----- NO CHANGES HERE
parentFolder = pwd;
cd(parentFolder);

subfolderName = 'OUT';

% Full path to the new subfolder
outputFolderPath = fullfile(parentFolder, subfolderName);

% Check if the subfolder already exists
if ~exist(outputFolderPath, 'dir')
    % The subfolder does not exist, so create it
    mkdir(outputFolderPath);
end

figPath = fullfile(outputFolderPath, 'FIG');
if ~exist(figPath, 'dir')
    % The subfolder does not exist, so create it
    mkdir(figPath);
end


csvsavePath = fullfile(outputFolderPath, 'CSV');
if ~exist(csvsavePath, 'dir')
    % The subfolder does not exist, so create it
    mkdir(csvsavePath);
end

% Calculate %ap for min and max
z_min = 8; % Min limit from X-axis
z_max = 1320; % Max limit from X-axis
y_min = 58;
y_max = 1093;

midline = 575;

%%
% run through the following pipeline
% DO NOT DOWNSAMPLE
% DO NOT PROCESS IMAGES (rotate/flip/...)

% Check if the 'histology_ccf.mat' file exists in the specified output folder
histology_file = fullfile(outputFolderPath, 'atlas2histology_tform.mat');

if rerun_histology == 1 || ~isfile(histology_file)
    AP_histology
    disp('Go through all steps in AP_histology window, then continue by pressing any key inside the terminal. \n To stop, press Ctrl + C');
    pause;
else
    disp('histology_ccf.mat already exists. Skipping AP_histology.');
end

%% data processing to convert volumes and plot

% --- GATHER COORDINATES INTO STRUCT
% Get a list of all CSV files in the folder
folderPath = fullfile(parentFolder,'VOL/CSV'); %filepath to csv files

[parentFolderPath, parentFolderName, ~] = fileparts(parentFolder);
%[~, parentFolderName, ~] = fileparts(parentFolderPath);
disp(['-------- Processing ',parentFolderName]); %second folder up to Slices

% Get a list of all TIFF files in the folder
tifFiles = dir(fullfile(parentFolder, '*.tif'));

% Initialize a structure to store points, dynamically creating fields for each channel
points = struct;

% Loop through each TIFF file
for i = 1:length(tifFiles)
    baseFileName = tifFiles(i).name;
    [~, name, ~] = fileparts(baseFileName);

    % Process each specified channel
    for j = 1:length(channelsToProcess)
        channel = channelsToProcess{j};
        if ~isfield(points, channel)
            points.(channel) = struct('name', {}, 'X', {}, 'Y', {});
        end
        csvPath = fullfile(folderPath, strcat(channel, '_', name, '.csv'));

        points.(channel)(i).name = name;
        points.(channel)(i).X = [];
        points.(channel)(i).Y = [];
        % Check if the CSV file exists
        if exist(csvPath, 'file')
            dataTable = readtable(csvPath);
            points.(channel)(i).X = dataTable.X;
            points.(channel)(i).Y = dataTable.Y;
        end
    end
end

disp('Files read into dataTable');

savemat=fullfile(outputFolderPath,[parentFolderName,'_variables.mat']);
save(savemat,'points', 'ChannelNames');

%% --- CONVERT POINTS TO CCF
% Load histology/CCF alignment
ccf_slice_fn = fullfile(outputFolderPath,'histology_ccf.mat');
load(ccf_slice_fn);
ccf_alignment_fn = fullfile(outputFolderPath,'atlas2histology_tform.mat');
load(ccf_alignment_fn);

ccf_points = struct;

for j = 1:length(channelsToProcess)
    channel = channelsToProcess{j};
    dataSets = points.(channel); %subset to this specific channel
    ccf_points.(channel) = cell(length(dataSets), 1);

    for i = 1:length(dataSets)
        histology_points = [dataSets(i).X, dataSets(i).Y];

        if ~isempty(histology_points)
            % Transform histology to atlas slice
            tform = affine2d;
            tform.T = atlas2histology_tform{i}; % Adjust index i according to your data
            tform = invert(tform);

            % Transform and round to nearest index
            [histology_points_atlas_x,histology_points_atlas_y] = ...
                transformPointsForward(tform, ...
                histology_points(:,1), ...
                histology_points(:,2));

            histology_points_atlas_x = round(histology_points_atlas_x);
            histology_points_atlas_y = round(histology_points_atlas_y);

            [M, N] = size(histology_ccf(i).av_slices);
            outOfRangeY = histology_points_atlas_y < 1 | histology_points_atlas_y > M;
            outOfRangeX = histology_points_atlas_x < 1 | histology_points_atlas_x > N;

            if any(outOfRangeY)
                fprintf('Y indices out of range: Min = %d, Max = %d, Valid Range = [1, %d]\n', min(histology_points_atlas_y(outOfRangeY)), max(histology_points_atlas_y(outOfRangeY)), M);
            end

            if any(outOfRangeX)
                fprintf('X indices out of range: Min = %d, Max = %d, Valid Range = [1, %d]\n', min(histology_points_atlas_x(outOfRangeX)), max(histology_points_atlas_x(outOfRangeX)), N);
            end


            probe_points_atlas_idx = sub2ind(size(histology_ccf(i).av_slices), histology_points_atlas_y,histology_points_atlas_x);

            % Get CCF coordinates for histology coordinates (CCF in AP,DV,ML)
            ccf_points.(channel){i} = ...
                [histology_ccf(i).plane_ap(probe_points_atlas_idx), ...
                histology_ccf(i).plane_dv(probe_points_atlas_idx), ...
                histology_ccf(i).plane_ml(probe_points_atlas_idx)];

        end
    end
end

disp('Coordinates transferred into CCF space');
save(savemat,'ccf_points','-append');

% Outputs
% ccf_points = cell array with CCF coordinates corresponding to histology_points (note: in native CCF order [AP/DV/ML])

%% plot

figure('Color','w');
ccf_3d_axes = axes;

plot_brain_outline;
% Plot pre-defined ABA structures if parameter set above
legends = cell(1, 1);
patch_handles = zeros(1, 1);

if exist('structure_names','var')
    num_structures = length(structure_names);
    grey_values = linspace(0.2, 0.8, num_structures);  % Create a gradient from light grey to dark grey

    % Initialize cell arrays for legend handling
    legends = cell(num_structures, 1);
    patch_handles = zeros(num_structures, 1);


    % Plot the structures with distinct grey tones and black edges
    struct_vol = struct;

    for i = 1:num_structures
        structure_name = structure_names{i};
        structure_index = find(strcmpi(st.safe_name, structure_name), 1);

        if isempty(structure_index)
            warning(['Structure not found: ', structure_name]);
            continue;
        end

        target_path = st.structure_id_path{structure_index}; % Get the specific path component outside of cellfun
        plot_ccf_idx = find(cellfun(@(x) contains(x, target_path), st.structure_id_path)); % Use the predefined path
        plot_ccf_volume = ismember(reduced_av, plot_ccf_idx);
        structure_3d = isosurface(permute(plot_ccf_volume, [3, 1, 2]), 0);

        if ~isempty(structure_3d.vertices)
            struct_vol(i).name = {structure_name};
            struct_vol(i).struct = structure_3d;
            h = patch(ccf_3d_axes, 'Vertices', structure_3d.vertices * slice_spacing, 'Faces', structure_3d.faces, ...
                'FaceColor', repmat(grey_values(i), 1, 3), 'EdgeColor', 'none', 'FaceAlpha', 0.1);
            patch_handles(i) = h;
            legends{i} = st.safe_name{structure_index};
        else
            warning(['No visible structure for plotting: ', st.safe_name{structure_index}]);
        end
    end

end

inj_vol = struct;

% PLOT VOLUMES
for j = 1:length(channelsToProcess)
    channel = channelsToProcess{j};
    dataSets = ccf_points.(channel); %subset to this specific channel
    ccf_points_cat = round(cell2mat(dataSets)); %z, x, y
    ccf_points_cat_ord = [ccf_points_cat(:,1),ccf_points_cat(:,3),ccf_points_cat(:,2)];
    %ccf_points_cat_ord = interpolatePoints(ccf_points_cat_ord, 50);  % Increase '50' as needed for more density
    [k1, vol] = boundary(ccf_points_cat_ord);
    smoothedVertices = laplacianSmooth(ccf_points_cat_ord, k1, 0.1, 5); % Apply the smoothing
    inj_vol(j).channels = {channel};
    inj_vol(j).channelColor = channelColors{j};
    inj_vol(j).animalName = parentFolderName;
    inj_vol(j).smoothedVertices = smoothedVertices;
    inj_vol(j).k1 = k1;
    inj_vol(j).ccf_points_cat_ord = ccf_points_cat_ord;
    if ~isempty(ChannelNames{j})
        inj_vol(j).ChannelName = ChannelNames{j};
    end
    h = patch('Vertices', smoothedVertices, 'Faces', k1, 'FaceColor', channelColors{j}, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    patch_handles(end+1) = h;
    legends{end+1} = ChannelNames{j};
end


% Create the legend
h = legend(patch_handles(patch_handles > 0), legends{patch_handles > 0}, 'Location', 'BestOutside');
hold on
view(90, 90);

% Set axis labels and adjust plot properties as needed
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

% Save the current figure
savename=fullfile(subfolderName,'FIG',[parentFolderName,'_3DPlot_Volume']);
savefig(gcf,savename);
% Save the current figure to a PNG file
print([savename,'.png'], '-dpng');
% For high-resolution, you can specify the resolution in DPI (dots per inch)
%print([savename,'_highres.png'], '-dpng', '-r300'); % 300 DPI

disp(['Figure saved as ',savename,'.png and .m']);

if exist('structure_names','var')
    save(savemat,'struct_vol','-append');
end

if exist('addfolder','var')
    %load(savemat);
    savename=fullfile(addfolder,[parentFolderName,'_variables.mat']);
    save(savename,'inj_vol','points','ccf_points', 'ChannelNames');
    if exist('structure_names','var')
        save(savemat,'struct_vol','-append');
    end

    disp('Data file additionally saved as:');
    disp(savename);
end



%% calculate brain structure overlaps

if overlap_vol==1
    % Prepare volumes structure for overlap calculation
    resolution = 100;
    flipside = 'R'; % can be L or R to flip to a specific side

    % Define brain structures you want to analyze
    structure_acronyms = {'MO', 'MOs','MOp','SS','SSp','SSs', 'AUD','VIS','AI','ACA'};
    outDir = fullfile(outputFolderPath,'FIG-ABA');  % Use the previously defined output directory

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    ExperimentName = extractBefore(parentFolderName, "-");

    if isempty(inj_vol)
        disp('Warning, no inj_vol provided, which should have been created in this script.');
    end

    volumes = create_volumes_data(pwd, outDir, ExperimentName, resolution, flipside, channelsToProcess, channelColors, ExperimentName, inj_vol);

    % Call the overlap calculation function
    structure_acronyms = {'MO', 'MOs','MOp','SS','SSp','SSs', 'AUD','VIS','AI','ACA'};
    calculate_overlap_with_brain_structures(volumes, structure_acronyms, outDir, parentFolderName, 0.1, 1);

end


%%

disp('Done.');
