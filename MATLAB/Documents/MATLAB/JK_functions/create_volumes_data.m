function volumes = create_volumes_data(baseDir, outDir, ExperimentName, resolution, flipside, groups, groupColors, inj_vol_struct)

load('D:/MATLAB/AP_histology/allenAtlas/997.mat'); %loads CCFv3 object to plot brain struct

% Check if `inj_vol_struct` is provided
if exist('inj_vol_struct','var') && ~isempty(inj_vol_struct)
    % Use the provided `inj_vol_struct`
    inj_vol = inj_vol_struct;
else
    files = dir(fullfile(baseDir, '**', '*_variables.mat'));

    inj_vol = struct; % Initialize an empty struct array to store all inj_vol data

    % Process files to collect all `inj_vol` structures
    inj_vol_combined = []; % Initialize an empty array to combine all inj_vol entries
    for idx = 1:length(files)
        fullPath = fullfile(files(idx).folder, files(idx).name);

        % Load data
        data = load(fullPath, 'inj_vol');

        % Append each `inj_vol` found in the files
        if isfield(data, 'inj_vol')
            inj_vol_combined = [inj_vol_combined, data.inj_vol]; % Concatenate inj_vol structures
        else
            warning(['File ', fullPath, ' does not contain ''inj_vol''. Skipping...']);
        end
    end
    inj_vol = inj_vol_combined; % Use the combined inj_vol structure for further processing
end

% Initialize the volumes struct array with the correct fields
template = struct('animal', '', 'channel', '', 'channel_index', 0, 'channelColor', [0 0 0], 'group', '', 'group_index', 0, ...
    'groupColor', [0 0 0], 'volume', 0, ...
    'bounding_box', struct('minX', 0, 'maxX', 0, 'minY', 0, 'maxY', 0, 'minZ', 0, 'maxZ', 0), ...
    'grid_points', [], 'inside_indices', [], ...
    'volume_mesh', struct('vertices', [], 'faces', []), ...
    'ccf_points_cat_ord', [], 'k1', [], ...
    'resolution', resolution, 'flipside', flipside, ...
    'all_channels', {groups}, 'all_channelColors', {groupColors});
volumes = repmat(template, 0, 1); % Initialize an empty array of this structure

% Initialize scaffold data for CSV
scaffold_data = {};

% Open figure for plotting lines on the brain
figure('Color','w');
brain_axes = axes;
set(brain_axes,'ZDir','reverse');
hold(brain_axes,'on');

plot_brain_outline();
hold on;

% Common processing for both `inj_vol_struct` and loaded from files
for idx = 1:length(inj_vol)
    animalName = inj_vol(idx).animalName;
    channelLabel = inj_vol(idx).ChannelName;
    ccf_points_cat_ord = inj_vol(idx).ccf_points_cat_ord;

    % Convert channel color from inj_vol to RGB triplet format
    channelColor = getRGBColor(inj_vol(idx).channelColor);

    % Initialize variables for group determination
    group = '';
    group_index = 0;
    groupColor = [0, 0, 0];

    if ischar(groups) && strcmp(groups, 'useChannelName')
        % Case 2: Use ChannelName as the "group" and its color
        group = channelLabel;
        group_index = find(strcmp(channelLabel, {inj_vol.ChannelName}));
    else
        % Case 1: Predefined groups - find group based on the filename
        if iscell(groups)
            for g = 1:length(groups)
                if contains(animalName, groups{g}, 'IgnoreCase', true)
                    group = groups{g};
                    group_index = g;
                    break;
                end
            end
        elseif ischar(groups) && ~isempty(groups)
            % Case 3: Single group name provided
            group = groups;
            group_index = 1; % Only one group, so index is 1
        end

        % Determine group color if groups and groupColors are defined
        if group_index > 0 && group_index <= length(groupColors)
            groupColor = getRGBColor(groupColors{group_index}); % Convert to RGB triplet
        end
    end

    % Simplified flip logic
    if strcmpi(flipside, 'R') % Flip to right
        flip_indices = ccf_points_cat_ord(:,2) < midline;
        ccf_points_cat_ord(flip_indices, 2) = 2 * midline - ccf_points_cat_ord(flip_indices, 2);
    elseif strcmpi(flipside, 'L') % Flip to left
        flip_indices = ccf_points_cat_ord(:,2) > midline;
        ccf_points_cat_ord(flip_indices, 2) = 2 * midline - ccf_points_cat_ord(flip_indices, 2);
    end

    % Create the convex hull using the flipped points
    k1 = convhull(ccf_points_cat_ord);

    % Calculate volume here with the provided resolution
    minX = min(ccf_points_cat_ord(:,1));
    maxX = max(ccf_points_cat_ord(:,1));
    minY = min(ccf_points_cat_ord(:,2));
    maxY = max(ccf_points_cat_ord(:,2));
    minZ = min(ccf_points_cat_ord(:,3));
    maxZ = max(ccf_points_cat_ord(:,3));

    % Calculate the midpoint for each axis
    midX = (minX + maxX) / 2;
    midY = (minY + maxY) / 2;
    midZ = (minZ + maxZ) / 2;

    % Add scaffold data to CSV array
    scaffold_data{end+1, 1} = group;
    scaffold_data{end, 2} = animalName;
    scaffold_data{end, 3} = channelLabel;
    scaffold_data{end, 4} = minX;
    scaffold_data{end, 5} = maxX;
    scaffold_data{end, 6} = minY;
    scaffold_data{end, 7}= maxY;
    scaffold_data{end, 8}= minZ;
    scaffold_data{end, 9} = maxZ;
    scaffold_data{end, 10} = midX;
    scaffold_data{end, 11} = midY;
    scaffold_data{end, 12} = midZ;

    % Plot lines for scaffold in the middle of the bounding box
    plot3(brain_axes, [midX, midX], [midY, midY], [minZ, maxZ], '-', 'LineWidth', 1.5, 'Color', channelColor); % Z-axis line
    plot3(brain_axes, [minX, maxX], [midY, midY], [midZ, midZ], '-', 'LineWidth', 1.5, 'Color', channelColor); % X-axis line
    plot3(brain_axes, [midX, midX], [minY, maxY], [midZ, midZ], '-', 'LineWidth', 1.5, 'Color', channelColor); % Y-axis line

    % Create a grid of points with the chosen resolution
    [X, Y, Z] = ndgrid(minX:(resolution/10):maxX, minY:(resolution/10):maxY, minZ:(resolution/10):maxZ);
    grid_points = [X(:), Y(:), Z(:)];

    in = inpolyhedron(k1, ccf_points_cat_ord, grid_points);
    estimated_volume = sum(in) * (resolution^3); % Adjust volume for the chosen resolution
    
    scaffold_data{end, 13} = estimated_volume;

    % Append new data to volumes struct array
    new_volume = struct('animal', animalName, ...
        'channel', channelLabel, ...
        'channel_index', group_index, ...
        'channelColor', channelColor, ... % Store channel color from inj_vol
        'group', group, ...
        'group_index', group_index, ...
        'groupColor', groupColor, ... % Store group color if available
        'volume', estimated_volume, ...
        'bounding_box', struct('minX', minX, 'maxX', maxX, ...
        'minY', minY, 'maxY', maxY, ...
        'minZ', minZ, 'maxZ', maxZ), ...
        'grid_points', grid_points, ...
        'inside_indices', find(in), ...
        'volume_mesh', struct('vertices', ccf_points_cat_ord, 'faces', k1), ...
        'ccf_points_cat_ord', ccf_points_cat_ord, ...
        'k1', k1, ...
        'resolution', resolution, ...
        'flipside', flipside, ...
        'all_channels', {groups}, ...
        'all_channelColors', {groupColors});

    volumes(end+1) = new_volume; % Append the new volume structure
end

% Save the Scaffold (min max) figure
figSavePath = fullfile(outDir, [ExperimentName, '_MinMax-Axes']);
savefig(gcf, [figSavePath,'.fig']);
print(gcf, [figSavePath,'.png'], '-dpng', '-r300');  % '-r300' sets the resolution to 300 DPI for high quality
close;

% Save scaffold data to CSV file
scaffold_csv_path = fullfile(outDir, [ExperimentName, '_MinMax-Axes.csv']);
scaffold_table = cell2table(scaffold_data, 'VariableNames', {'Group', 'Animal', 'Channel', 'MinX', 'MaxX', 'MinY', 'MaxY','MinZ', 'MaxZ','MidX', 'MidY', 'MidZ','volume'});
writetable(scaffold_table, scaffold_csv_path);
disp(['Scaffold data saved as ', scaffold_csv_path]);

% Save the volumes structure to a .mat file
savename = fullfile(outDir, [ExperimentName, '_3D_VolumeCalc.mat']);
save(savename, 'volumes', '-v7.3'); % Use '-v7.3' to handle larger files
disp(['Saved volume variable with all coordinates as ', savename]);

% Return the volumes structure
return;
end
