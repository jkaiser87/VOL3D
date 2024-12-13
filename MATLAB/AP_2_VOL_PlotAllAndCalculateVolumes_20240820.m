%% Volume Tracing from FIJI to CCFv3 Using AP_histology
% Author: Julia Kaiser, August 2024

% Description:
% This script processes brain volumes traced in FIJI and aligns them with the Allen Brain Atlas (CCFv3) using AP_histology. 
% It visualizes all traced volumes in 3D, calculates overlaps, and compares volumes to selected Allen Brain Atlas structures.

% Features:
% 1. Plots multiple brain volumes into a 3D model, with options for flipping and color grouping.
% 2. Calculates overlap between volumes and selected ABA structures.
% 3. Supports flexible groupings and customizable colors.
% 
% Inputs:
% - ExperimentName: Name of the experiment.
% - groups: Group identifiers based on filenames.
% - groupColors: Colors for each group (RGB values or names).
% - flipside: Set to 'L' or 'R' to flip brain model, or leave empty for no flipping.
% - resolution: Voxel size (10 for high resolution, 100 for faster runs).
% - structure_acronyms: ABA structure acronyms for overlap calculations.
% 
% Outputs:
% - 3D plots of traced volumes.
% - CSV files with overlap percentages (volume-to-volume and volume-to-ABA structures).

% Main Functions:
% - create_volumes_data: Creates 3D volume data.
% - plot_volumes_with_brain: Plots the volumes in a brain model.
% - calculate_volume_overlap: Calculates overlap between volumes.
% - calculate_overlap_with_brain_structures: Computes overlap with ABA structures.

clearvars; clc;

ExperimentName = 'EXP';
colorMapType = 'group';  % Set to 'channel' to (re)color by channel, or 'group' [as defined in Script 1]
colorMap = containers.Map(... % Define the colors and which group they correspond to (by order)
    {'TdT', 'GFP'}, ...  % Group or channel names
    {'#DB2B39', '#337054',});  % Corresponding colors (465487=blue, DB2B39=red, 7C8289=gray, 337054=green)
flipside = 'L'; %can be L or R or empty for no flipping
alpha = 0.1;
resolution = 100; % voxelsize. 10 for high resolution, 100 for fast runs

%% folder setup, Create volumes data 
% and calculates min and max for each volume on all axes
% always needs to be run

forceRun = false; % Set this to true to force re-creating the volumes file even if the file exists

baseDir = pwd;
disp(['Processing folder ', baseDir]);
outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); disp(['OUT folder created']); end
savename = fullfile(outDir, [ExperimentName, '_3D_VolumeCalc.mat']);
disp(['Creating volumes structure for further processing... ']);

% Check if the file exists
if exist(savename, 'file') && ~forceRun
    % Load the existing volumes data
    load(savename, 'volumes');
    disp(['Loaded existing volumes data from ', savename]);
else
    % Run the function to create volumes data
   volumes = create_volumes_data(baseDir, outDir, ExperimentName, resolution, flipside, [], colorMap, colorMapType);
   disp(['Created new volumes data and saved as ', savename]);
end

%% Plot volumes with brain
% run this section to plot all 3D volumes in brains

plot_volumes_with_brain(volumes, outDir, ExperimentName, alpha, 'group', 2); 

%colorType [second last parameter] can be group or channel to choose what to color volumes by
%plotMode [last parameter]: 0 all volumes in 1 brain, 1 split by group, 2 split all individual animals

% %it is also possible to run this and following steps on a subset of data (eg Ctrl channels):
% subvolumes = volumes(ismember({volumes.channel}, {'Ctrl'}));
% plot_volumes_with_brain(subvolumes, outDir, [ExperimentName,'-Ctrl'], 0.2, 'group',0); 

%% Calculate overlap between volumes (or subvolumes)

calculate_volume_overlap(volumes, outDir, ExperimentName, alpha, false);
%output: CSV file *_3D_Overlap_Results_AllPairs

%% Calculate overlap with brain structures
structure_acronyms = {'MOs','MOp','SSp','SSs', 'AUD','VIS','AI','ACA'}; %need to match ABA nomenclature
calculate_overlap_with_brain_structures(volumes, structure_acronyms, outDir, ExperimentName, alpha, false);
%output: CSV file *_3D_Overlap_Results_VolumestoBrainStructures

disp('Analysis done.');
%% ADDITIONAL CODE THAT ALLOWS MORE FLEXIBILITY BUT IS NOT NECESSARY ALL THE TIME

% plot_ABA_structures(structure_acronyms,0); %open MATLAB figure and run this code to add ABA structs onto file
% savename = fullfile(outDir, ['ABA_3DPlot_AllStruct']);
% savefig(gcf, savename);
% print([savename, '.png'], '-dpng');
% view([-40, 30]); %angled view
% savename = fullfile(outDir, ['ABA_3DPlot_AllStruct-Angled']);
% savefig(gcf, savename);
% print([savename, '.png'], '-dpng');

% If you are combining experiments and need to rename groups based on
% Experiment name + channel or something, overwrite group by concatenating
% whichever 2 columns you want:

% for i = 1:numel(volumes)
%     %Concatenate 'group' and 'channel' with a '-' in between
%     volumes(i).group = [volumes(i).group '-' volumes(i).channel];
% end

%if you want to re-assign group colors afterwards, you can do it using this
%bit:
% 
% % change colors to add colors to the new groups (has to use _ not -)
% colorMap = struct('Npy_Cre', '#FFBF1F', ...
%                   'Cartpt_Cre', '#BA0763', ...
%                   'Npy_Ctrl', '#FFDF8F', ...
%                   'Cartpt_Ctrl', '#BA779A', ...
%                   'M1S1_S1', '#DB2B39', ...
%                   'M1S1_M1', '#295C0D');
% 
% % Assign colors to volumes based on the 'group' field
% for v = 1:length(volumes)
%     groupName = strrep(volumes(v).group, '-', '_'); % Replace '-' with '_' to match struct field names
%     if isfield(colorMap, groupName)
%         volumes(v).groupColor = getRGBColor(colorMap.(groupName));
%     else
%         warning('Group "%s" not found in color map. Assigning default color.', volumes(v).group);
%         volumes(v).groupColor = [0, 0, 0]; % Default color (black) if group not found
%     end
% end

%if you want to change colors after creating the figure, open the figure
%and run this with original RGB triplet and the one to change to, and save again (change filename as necessary):
% changeColorInFigure('red',[0.86, 0.17, 0.22]);
% changeColorInFigure('green',[0.20, 0.44, 0.33]);
% savename = fullfile(outDir, [ExperimentName, '_3DPlot_AllCombined']);
% savefig(gcf, savename);
% print([savename, '.png'], '-dpng');
% print('-dpng', '-r300', fullfile(outDir, [ExperimentName, '_3DPlot_AllCombined_HR.png']));