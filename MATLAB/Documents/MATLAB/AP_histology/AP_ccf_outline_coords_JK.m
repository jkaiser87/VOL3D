function drawCCFCoordinates(ccf_summary, colorcellsby)

% drawCCFCoordinates Draw 3-view outline of the brain with selected structures
%   drawCCFCoordinates(allen_atlas_path, slice_spacing, colorcellsby) draws a 3D plot
%   of the brain from the Allen Brain Atlas data located at 'allen_atlas_path', with
%   specified 'slice_spacing' and colored by the category specified in 'colorcellsby'.
parentFolder = pwd;
[parentFolderPath, parentFolderName, ~] = fileparts(parentFolder);
slice_path = fullfile(parentFolder,'OUT'); %this is the folder you set as output in the step before!
save_path = fullfile(slice_path,'CCF'); %slice_path+filesep+'CCFCoords';

% Load atlas
allen_atlas_path = fullfile(userpath,'AP_histology\allenAtlas');
tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']);
st = loadStructureTree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']); % a table of what all the labels mean

%
% Initialize a figure
figure('Color','w');
ccf_3d_axes = axes;
hold(ccf_3d_axes, 'on');
axis tight;
rotate3d on;

% Define mesh parameters
slice_spacing = 5; % Adjust based on your resolution needs

% Generate a binary volume where non-zero voxels are considered part of the brain
brain_volume = bwmorph3(bwmorph3(av(1:slice_spacing:end, ...
    1:slice_spacing:end,1:slice_spacing:end) > 1,'majority'), 'majority');

% Generate the mesh using isosurface
brain_outline_patchdata = isosurface(permute(brain_volume,[3,1,2]), 0.5);

% Plot the mesh as a patch on the 3D axes
patch(ccf_3d_axes, ...
    'Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
    'Faces', brain_outline_patchdata.faces, ...
    'FaceColor', [0.7,0.7,0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
hold on; % Hold on to plot multiple categories

%%
% Define a more appealing color for each category.
colorMap = containers.Map();

colorMap('Cingulate') = [0.8500, 0.3250, 0.0980]; % A nice shade of orange
colorMap('Medial') = [0, 0.4470, 0.7410]; % A vibrant blue
colorMap('Lateral') = [0.9290, 0.6940, 0.1250]; % A bright yellow

colorMap('C1') = [0, 1, 1]; % cyan
colorMap('C2') = [0, 1, 0]; % green
colorMap('C3') = [1, 0, 0]; % red
colorMap('C4') = [0, 0, 1]; % blue

colorMap('Single') = [187/255, 52/255, 47/255]; % A nice shade of red
colorMap('Double') = [221/255, 164/255, 72/255]; % A nice shade of orange
colorMap('Triple') = [255/255, 239/255, 126/255]; % A nice shade of yellow

colorMap('C2, C3') = [242/255, 173/255, 0]; % Npy+ yellow
colorMap('C3') = [255/255, 37/255, 0]; % red
colorMap('C3, C4') = [1/255, 160/255, 138/255]; % Cartpt+ cyan
colorMap('C2, C3, C4') = [253/255, 100/255, 103/255]; % Npy+ Cartpt+

colorMap('P1') = [0.0000, 0.0000, 0.5168]; 
colorMap('P3') = [0.0000, 0.4980, 0.0000]; 
colorMap('P7') = [0.7410, 0.4470, 0.0000]; 
colorMap('P14') = [0.8471, 0.1608, 0.0000]; 

% Rcolors = [0.0000, 0.0000, 0.5168;  % Blue
%           0.0000, 0.4470, 0.7410;  % Light blue
%           0.0000, 0.4980, 0.0000;  % Green
%           0.7410, 0.4470, 0.0000;  % Orange
%           0.7490, 0.0000, 0.7490;  % Purple
%           0.8471, 0.1608, 0.0000;  % Red
%           0.2510, 0.8784, 0.8157;  % Cyan
%           0.8627, 0.8627, 0.8627]; % Light Gray
    
%%
% Determine which column to use based on 'colorcellsby'
categoryColumn = '';
switch colorcellsby
    case 'ML'
        categoryColumn = 'classifier';  % Assuming 'ML' is a column name
    case 'channel'
        categoryColumn = 'Channel';
    case 'DTLabeling'
        categoryColumn = 'Labeling';
    case 'SCPNpos'
        categoryColumn = 'ChannelsOccurredIn';
    case 'Timepoint'
        categoryColumn = 'ChannelsOccurredIn';
    case 'Area'
        Areas = regexprep(ccf_summary.Brainstruct, 'layer.*$', '', 'ignorecase');
        categoryColumn = Areas;
    otherwise
        categoryColumn = '';  % No categorical data to color by
end

%%

% If categoryColumn selected AND is part of dataset, plot with color. Else
% just black
if ~isempty(categoryColumn) && ismember(categoryColumn, ccf_summary.Properties.VariableNames) 
    categories = categorical(ccf_summary.(categoryColumn));
    [uniqueCategories, ~, idx] = unique(categories);

    % Cycle through each category to plot
    for i = 1:numel(uniqueCategories)
        category = uniqueCategories(i);
        if isKey(colorMap, char(category)) % Check if the category has a defined color
            categoryColor = colorMap(char(category)); % Retrieve color from colorMap
        else
            categoryColor = [0, 0, 1]; % Default color (white) if no color defined for category
            warning('No Color Code found for labeling, blue used instead. Add to color map if necessary');
        end

        % Filter points that belong to the current category
        subset = ccf_summary(idx == i, :);

        % Plotting the data subset using the specified color from colorMap
        scatter3(ccf_3d_axes, subset.Z, subset.Y, subset.X, ...
            36, 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', categoryColor, 'DisplayName', char(category));
        hold on; % Keep the plot open for the next categories
    end

    legend('Location', 'bestoutside');
    hold off;
else
    % Default plain coloring
    warning('No coloring parameter selected or selected parameter does not exist in the dataset. Reverting to default coloring (black).');
    scatter3(ccf_3d_axes, ccf_summary.Z, ccf_summary.Y, ccf_summary.X, ...
        36, 'b', 'filled');
    legend('Location', 'bestoutside');
end


% Add legend and other plot formatting as needed
legend(vertcat('Brain',uniqueCategories), 'Location', 'bestoutside');
hold off; % Close the plot for further additions

title(ccf_3d_axes, ['3D Scatter Plot ',parentFolderName]);
subtitle(ccf_3d_axes, ['colored by ',colorcellsby]);

% Adjust axis appearance
set(ccf_3d_axes, 'ZDir', 'reverse');
set(ccf_3d_axes, 'Color', 'w');  % Set background color to white
axis(ccf_3d_axes, 'vis3d', 'equal');
axis(ccf_3d_axes, 'off');  % Turn off the axis lines and labels
view(ccf_3d_axes, 90, 90);  % Adjust the view angle

% Save the current figure
savename=fullfile(slice_path,'FIG',[parentFolderName,'_3DPlot_',colorcellsby]);
savefig(gcf,savename);
% Save the current figure to a PNG file
print([savename,'.png'], '-dpng');
disp(['Figure saved as ',savename]);

%% plot cells in seperate panels (only if more than 1 present)

[uniqueCategories, ~, idx] = unique(categories);
if length(uniqueCategories) > 1
    if ~isempty(categoryColumn)
        categories = categorical(ccf_summary.(categoryColumn));
        [uniqueCategories, ~, idx] = unique(categories);

        % Specify alphaValue if not already done
        alphaValue = 0.3;  % Adjust transparency level here if needed
        for i = 1:length(uniqueCategories)
            category = uniqueCategories(i);
            categoryColor = colorMap(char(category)); % Retrieve color from colorMap

            % Filter points that belong to the current category
            subset = ccf_summary(idx == i, :);
            % Create subplot and explicitly get its axes handle
            spAxes = subplot(1, length(uniqueCategories), i);
            set(spAxes, 'ZDir', 'reverse');
            hold(spAxes, 'on');
            view(spAxes, 90, 90);  % Adjust the view angle

            % Plot the brain mesh targeting the specific subplot axes
            patch(spAxes, 'Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
                'Faces', brain_outline_patchdata.faces, ...
                'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);

            % Plot the scatter plot using the stored color, targeting the specific subplot axes
            scatter3(spAxes, subset.Z, subset.Y, subset.X, ...
                20, 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', categoryColor, 'DisplayName', char(category));

            % Adjust axis appearance
            set(spAxes, 'Color', 'w');  % Set background color to white
            axis(spAxes, 'vis3d', 'equal');
            axis(spAxes, 'off');  % Turn off the axis lines and labels

            title(spAxes, ['Category: ', char(category)]);

            hold(spAxes, 'off');
        end
    end

    % Save the current figure
    savename=fullfile(slice_path,'FIG',[parentFolderName,'_split-3DPlot_',colorcellsby]);
    savefig(gcf,savename);
    % Save the current figure to a PNG file
    print([savename,'.png'], '-dpng');
    disp(['Figure saved as ',savename]);
end

end