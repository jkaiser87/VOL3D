function drawCCFCoordinates(ccf_summary, colorcellsby, suffix)
% drawCCFCoordinates Draw 3-view outline of the brain with selected structures
%   drawCCFCoordinates(ccf_summary, colorcellsby) plots 3D scatter plot
%   colored by the specified category.

% Constants and initialization
allen_atlas_path = fullfile(userpath,'AP_histology\allenAtlas');
tv = readNPY(fullfile(allen_atlas_path, 'template_volume_10um.npy'));
av = readNPY(fullfile(allen_atlas_path, 'annotation_volume_10um_by_index.npy'));
st = loadStructureTree(fullfile(allen_atlas_path, 'structure_tree_safe_2017.csv'));

% Set up the color map for different categories
colorMap = setupColorMap();

% Determine which column to use based on 'colorcellsby'
categoryColumn = determineCategoryColumn(colorcellsby);
categories = categorical(ccf_summary.(categoryColumn));
[uniqueCategories, ~, idx] = unique(categories);

% one big brain with all animals in same color, colored by choice

% Prepare the plot
figure('Color','w');
ccf_3d_axes = axes;
set(ccf_3d_axes,'ZDir','reverse');
hold(ccf_3d_axes,'on');
axis(ccf_3d_axes,'vis3d','equal','off','manual');
view([-30,25]);
axis tight;
rotate3d on;

% Plot colored scatter if categoryColumn is part of the dataset
plotBrainAndScatter(ccf_3d_axes, ccf_summary, categories, colorMap, av);

% Add legend and other plot formatting
legend('Location', 'bestoutside');
title(ccf_3d_axes, ['3D Scatter Plot', suffix]);
subtitle(ccf_3d_axes, ['colored by ', colorcellsby]);
grid(ccf_3d_axes, 'on');
view(ccf_3d_axes, 3);
rotate3d on;

% save
savename = fullfile(pwd,['AllAnimals_3DPlot_',colorcellsby,suffix]);
saveFigure(savename)

% plot each category seperate

plotBrainAndScatter_Panels(ccf_summary, categories, colorMap, av);
% save
savename = fullfile(pwd,['AllAnimals_3DPlot_sepby_',colorcellsby,suffix]);
saveFigure(savename)

end

function colorMap = setupColorMap()
% Define color map for categories
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
end

function categoryColumn = determineCategoryColumn(colorcellsby)
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
        categoryColumn = 'Timepoint';
    case 'Time'
        categoryColumn = 'Timepoint';
    case 'Area'
        Areas = regexprep(ccf_summary.Brainstruct, 'layer.*$', '', 'ignorecase');
        categoryColumn = Areas;
    otherwise
        categoryColumn = '';  % No categorical data to color by
end

end


function plotBrainAndScatter(ccf_3d_axes, ccf_summary, categories, colorMap, av)
% Plot scatter points colored by category

% Generate a binary volume where non-zero voxels are considered part of the brain
slice_spacing = 5;
brain_volume = bwmorph3(bwmorph3(av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end) > 1,'majority'), 'majority');

% Generate the mesh using isosurface
brain_outline_patchdata = isosurface(permute(brain_volume,[3,1,2]), 0.5);

% Plot the mesh as a patch on the 3D axes
patch(ccf_3d_axes, ...
    'Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
    'Faces', brain_outline_patchdata.faces, ...
    'FaceColor', [0.7,0.7,0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
hold on; % Hold on to plot multiple categories

[uniqueCategories, ~, idx] = unique(categories);
% Cycle through each category to plot
    for i = 1:numel(uniqueCategories)
        category = uniqueCategories(i);
        if isKey(colorMap, char(category)) % Check if the category has a defined color
            categoryColor = colorMap(char(category)); % Retrieve color from colorMap
        else
            categoryColor = [0, 0, 1]; % Default color (blue) if no color defined for category
            warning('No Color Code found for %s, blue used instead.', char(category));
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
end

function plotBrainAndScatter_Panels(ccf_summary, categories, colorMap, av)
 % Specify alphaValue if not already done
[uniqueCategories, ~, idx] = unique(categories);

% Generate a binary volume where non-zero voxels are considered part of the brain
slice_spacing = 5;
brain_volume = bwmorph3(bwmorph3(av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end) > 1,'majority'), 'majority');

% Generate the mesh using isosurface
brain_outline_patchdata = isosurface(permute(brain_volume,[3,1,2]), 0.5);


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


function saveFigure(savename)
% Save current figure
savefig(gcf, savename);
print([savename,'.png'], '-dpng');
disp(['Figure saved as ', savename]);
end


