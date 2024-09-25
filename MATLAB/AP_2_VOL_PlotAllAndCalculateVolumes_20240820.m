%% Volume tracing from Fiji to CCFv3 using AP_histology
% Julia Kaiser, August 2024

% This script plots all traced volumes within a given folder and plots them
% into one 3D brain (flipped if necessary). It also calculates overlaps to
% a provided array of Allen Brain Atlas structures

% Bregma is estimated at (x,y,z) (540, 44, 570) - to be clarified?

clearvars; clc;

ExperimentName = 'P35NpyCartptM1S1';
groups = {'Npy', 'Cartpt', 'M1S1'}; % provide if grouping by filename (eg Npy Cartpt)
groupColors = {[0.9882, 0.6706, 0.3922], [244/255, 91/255, 105/255], 'blue'};  % defines colors for all following plots
flipside = 'L'; %can be L or R or empty for no flipping
alpha = 0.1;
resolution = 100; % 10 for high resolution, 100 for fast testruns

baseDir = pwd;
outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end
    
%% Create volumes data 
% and calculated min and max for each volume on all axes

forceRun = false; % Set this to true to force running the function even if the file exists
savename = fullfile(outDir, [ExperimentName, '_3D_VolumeCalc.mat']);
% Check if the file exists
if exist(savename, 'file') && ~forceRun
    % Load the existing volumes data
    load(savename, 'volumes');
    disp(['Loaded existing volumes data from ', savename]);
else
    % Run the function to create volumes data
    volumes = create_volumes_data(baseDir, outDir, ExperimentName, resolution, flipside, groups, groupColors, []);
     disp('Created new volumes data.');
end

%% Plot volumes with brain

plot_volumes_with_brain(volumes, outDir, ExperimentName, 0.1, 'group', 2); 

%colorType can be group or channel to choose what to color by
%plotMode = 0 all in 1 panel, 1 by group, 2 individual

% %it is also possible to run this and following steps on a subset of data (eg Cre channels):
% subvolumes = volumes(ismember({volumes.channel}, {'Ctrl','S1'}));
% plot_volumes_with_brain(subvolumes, outDir, [ExperimentName,'-S1Ctrl'], 0.2, 'group',0); %the last parameter (1 or 0) says to combine groups even if group is present
% 
% subvolumes = volumes(ismember({volumes.channel}, {'Cre'}));
% plot_volumes_with_brain(subvolumes, outDir, ['NpyCartpt'], 0.2, 'group',0);
% 
% subvolumes = volumes(ismember({volumes.channel}, {'M1','S1'}));
% plot_volumes_with_brain(subvolumes, outDir, ['M1S1'], 0.2, 'group',0);

%% Calculate overlap between volumes (or subvolumes)
calculate_volume_overlap(volumes, outDir, ExperimentName, alpha, true);

%% Calculate overlap with brain structures
structure_acronyms = {'MO', 'MOs','MOp','SS','SSp','SSs', 'AUD','VIS','AI','ACA'};
calculate_overlap_with_brain_structures(volumes, structure_acronyms, outDir, ExperimentName, alpha, true);


%% ADDITIONAL CODE THAT ALLOWS MORE FLEXIBILITY BUT IS NOT NECESSARY ALL THE TIME

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