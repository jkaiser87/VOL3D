function plotBrainAtlasWithColorVariation(Data, plotColor, groups)
% Plot brain atlas data with specified color and optional group-based color variations.
%
% Parameters:
%   Data: Struct containing organized data for plotting, with CCF coordinates
%   plotColor: [R, G, B] color vector for base plotting color
%   groups: (Optional) Vector indicating the group each entry in Data belongs to
%           plotColor is provided as a matrix with one color per row when multiple groups are expected

%% Validate input parameters
if nargin < 3
    groups = ones(size(Data)); % Assign all to the same group if 'groups' not provided
end

%% Fixed path to the Allen Brain Atlas files
allen_atlas_path = 'C:\Users\juk4004\Documents\MATLAB\AP_histology\allenAtlas';

%% Load atlas
tv = readNPY(fullfile(allen_atlas_path, 'template_volume_10um.npy'));
av = readNPY(fullfile(allen_atlas_path, 'annotation_volume_10um_by_index.npy'));
st = loadStructureTree(fullfile(allen_atlas_path, 'structure_tree_safe_2017.csv'));

%% Initialize a figure
figure('Color','w');
ccf_3d_axes = axes;
set(ccf_3d_axes,'ZDir','reverse');
hold(ccf_3d_axes,'on');
axis(ccf_3d_axes,'vis3d','equal','off','manual');
view([-30,25]);
axis tight;
rotate3d on;

%% Generate and plot the brain mesh
slice_spacing = 5;
brain_volume = bwmorph3(bwmorph3(av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end) > 1, 'majority'), 'majority');
brain_outline_patchdata = isosurface(permute(brain_volume, [3,1,2]), 0.5);
patch('Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
    'Faces', brain_outline_patchdata.faces, ...
    'FaceColor', [0.7,0.7,0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
hold on;



%% Color and group setup

% Check if 'groups' is a string array, convert if not
if ~isstring(groups)
    % If 'groups' is numeric or categorical, convert to string for consistent handling
    groups = string(groups);
end

% After conversion, 'uniqueGroups' will also need to work with strings
uniqueGroups = unique(groups);
numGroups = length(uniqueGroups);
baseColors = {plotColor}; % Start with the provided base color

% Check if additional colors are needed and if the provided colors match the number of groups
if numGroups > 1
    if length(plotColor) ~= numGroups
        warning('Mismatch between number of provided colors and number of groups. Generating additional colors.');
        % Generate a random color for the second group, ensure it's different enough from the first color
        additionalColor = rand(1, 3);
        baseColors{2} = additionalColor;
    end
else
    baseColors = repmat(baseColors, 1, numGroups); % Replicate the base color if only one group
end

alphaValue = 0.3; % Transparency level

%% Validate Data and groups before plotting
if isempty(Data)
    error('Data is empty. Please check your dataset.');
end

% Example check for the CCF field in the first entry (if it exists)
if ~isfield(Data, 'CCF') || isempty(Data(1).CCF)
    error('CCF field is missing or empty in the first entry of Data.');
end





%% Plotting with group color variations

legendLabels = {};
legendColors = [];

for iGroup = 1:numGroups
    groupEntries = Data(groups == uniqueGroups(iGroup));
    currentColor = plotColor(iGroup,:);

    legendLabels{end+1} = uniqueGroups(iGroup);
    legendColors = [legendColors; currentColor]; % Append the color

    for iEntry = 1:length(groupEntries)
        ccfData = groupEntries(iEntry).CCF;
        if iscell(ccfData)
            ccfData = cell2mat(ccfData); % This assumes that each cell contains a numeric value
        end
        % Calculate adjusted color based on entry position within the group
        relativePosition = iEntry / length(groupEntries);
        adjustedColor = currentColor * (0.5 + relativePosition * 0.5);
        adjustedColor = min(max(adjustedColor, 0), 1); % Ensure valid color values

        % Check if 'name' field exists for this data entry
        if isfield(groupEntries(iEntry), 'name') && ~isempty(groupEntries(iEntry).name)
            displayName = groupEntries(iEntry).name;  % Use 'name' field as DisplayName
        else
            displayName = uniqueGroups(iGroup);  % Fallback to using the group identifier
        end


        % Ensure ccfData has the correct size
        if size(ccfData, 2) ~= 3
            error(['CCF data for entry ', num2str(iEntry), ' of group ', num2str(uniqueGroups(iGroup)), ' does not have 3 columns.']);
        end

          % Ensure adjustedColor is numeric and has the correct size
        if ~isnumeric(adjustedColor) || length(adjustedColor) ~= 3
            error('Adjusted color must be a numeric array with 3 elements.');
        end

        scatter3(ccf_3d_axes, ccfData(:,1), ccfData(:,3), ccfData(:,2), ...
            36, adjustedColor, 'filled', ...
            'MarkerEdgeAlpha', alphaValue, 'MarkerFaceAlpha', alphaValue, ...
            'DisplayName', displayName);
    end
end

%% Enhancements for plot appearance
xlabel('X Axis');
ylabel('Y Axis');
zlabel('Z Axis');
for i = 1:length(legendLabels)
    % Plot empty data, just to generate legend items
    plot(nan, nan, 's', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', legendColors(i, :), 'DisplayName', legendLabels{i});
end

legend('Location', 'bestoutside'); 
grid on;
view(3); % Adjust for the best viewing angle
hold off;

end
