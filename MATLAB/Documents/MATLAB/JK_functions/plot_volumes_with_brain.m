function plot_volumes_with_brain(volumes, outDir, ExperimentName, alpha, colorType, plotMode)
    % Check if plotMode is provided; if not, set default to 0 (single panel)
    if nargin < 6 || isempty(plotMode)
        plotMode = 0;
    end

    % Load the CCFv3 object to plot brain structure
    load('D:/MATLAB/AP_histology/allenAtlas/997.mat'); 

    % Determine the plotting mode
    switch plotMode
        case 0
            % Plot all volumes in a single panel
            figure('Name', 'All Volumes Combined', 'Color', 'w', 'Position', [100, 100, 700, 700]);
            
            plot_brain_outline();
            plot_all_volumes(volumes, colorType, alpha);

            filesuffix = 'SinglePanel';

        case 1
            % Plot grouped panels
            uniqueGroups = unique({volumes.group});
            numPanels = length(uniqueGroups);

            % Determine the layout dimensions
            numRows = min(2, ceil(numPanels / 2)); % Use 2 rows if more than 3 panels
            numCols = ceil(numPanels / numRows);   % Calculate columns based on rows
            figure('Name', 'Panels with Groups', 'Color', 'w', ...
                   'Position', [100, 100, numCols * 300, numRows * 300]);
            tiledlayout(numRows, numCols, 'TileSpacing', 'compact', 'Padding', 'compact');

            for panelIdx = 1:numPanels
                group = uniqueGroups{panelIdx};
                nexttile;
                plot_brain_outline();
                plot_group_volumes(volumes, group, colorType, alpha);
            end

            filesuffix = 'SplitPanel';

        case 2
            % Plot each volume in an individual panel
            numVolumes = length(volumes);
            numRows = min(2, ceil(numVolumes / 2)); % Use 2 rows if more than 3 panels
            numCols = ceil(numVolumes / numRows);   % Calculate columns based on rows
            figure('Name', 'Individual Panels for Each Volume', 'Color', 'w', ...
                   'Position', [100, 100, numCols * 300, numRows * 300]);
            tiledlayout(numRows, numCols, 'TileSpacing', 'compact', 'Padding', 'compact');

            for volIdx = 1:numVolumes
                nexttile;
                plot_brain_outline();
                plot_single_volume(volumes(volIdx), colorType, alpha);
            end

            filesuffix = 'IndividualPanels';

        otherwise
            error('Invalid plotMode. Use 0 for single panel, 1 for grouped panels, or 2 for individual panels.');
    end

    % Save the plot
    savename = fullfile(outDir, [ExperimentName, '_3DPlot_', filesuffix]);
    savefig(gcf, savename);
    print([savename, '.png'], '-dpng');
    %print('-dpng', '-r300', [savename, '_HR.png']);
    disp([filesuffix, ' plot saved as ', savename, '.png and .m']);

    % Save the angled view only if filesuffix is "SinglePanel"
    if strcmp(filesuffix, 'SinglePanel')
        view([-40, 30]); % Adjust this if a different angle is needed
        angledSavename = [savename, '_Angled'];
        savefig(gcf, angledSavename);
        print([angledSavename, '.png'], '-dpng');
        %print('-dpng', '-r300', [angledSavename, '_HR.png']);
        disp(['Angled view for ', filesuffix, ' plot saved as ', angledSavename, '.png and .m']);
    end

    close(gcf);
end

% Helper function to plot volumes for a specific group
function plot_group_volumes(volumes, group, colorType, alpha)
    legendHandles = [];
    legends = {};
    uniqueColors = {}; % Track unique colors to avoid duplicates in the legend

    for v = 1:length(volumes)
        if strcmp(volumes(v).group, group)
            [h, colorStr] = plot_volume(volumes(v), colorType, alpha);

            % Add to legend only if color is unique
            if ~ismember(colorStr, uniqueColors)
                legendHandles(end+1) = h;  % Add handle
                if strcmp(colorType, 'channel')
                    legends{end+1} = sprintf('%s', volumes(v).channel);
                elseif strcmp(colorType, 'group')
                    legends{end+1} = sprintf('%s', volumes(v).group);
                end
                uniqueColors{end+1} = colorStr;
            end
        end
    end
    legend(legendHandles, legends, 'Location', 'northeast');
end

% Helper function to plot all volumes in a single panel
function plot_all_volumes(volumes, colorType, alpha)
    legendHandles = [];
    legends = {};
    uniqueColors = {}; % Track unique colors to avoid duplicates in the legend

    for v = 1:length(volumes)
        [h, colorStr] = plot_volume(volumes(v), colorType, alpha);

        % Add to legend only if color is unique
        if ~ismember(colorStr, uniqueColors)
            legendHandles(end+1) = h;  % Add handle
            if strcmp(colorType, 'channel')
                legends{end+1} = sprintf('%s', volumes(v).channel);
            elseif strcmp(colorType, 'group')
                legends{end+1} = sprintf('%s', volumes(v).group);
            end
            uniqueColors{end+1} = colorStr;
        end
    end
    legend(legendHandles, legends, 'Location', 'northeast');
    rotate3d on;
end

% Helper function to plot a single volume
function plot_single_volume(volume, colorType, alpha)
    plot_brain_outline(); % Ensure the brain outline is plotted
    h = plot_volume(volume, colorType, alpha); % Plot the volume
  % Concatenate animal and channel for the legend
    legendText = sprintf('%s - %s', volume.animal, volume.channel);
    
    % Add legend for the single volume
    legend(h, legendText, 'Location', 'northeast');
end

% Helper function to plot a single volume
function [h, colorStr] = plot_volume(volume, colorType, alpha)
    vertices = volume.ccf_points_cat_ord;
    k1 = volume.k1;

    % Choose color based on colorType parameter
    if strcmp(colorType, 'channel')
        selectedColor = volume.channelColor;
    elseif strcmp(colorType, 'group')
        selectedColor = volume.groupColor;
    else
        error('Invalid colorType. Use ''channel'' or ''group''.');
    end

    h = patch('Vertices', vertices, 'Faces', k1, ...
              'FaceColor', selectedColor, 'FaceAlpha', alpha, 'EdgeColor', 'none');

    % Return the color string for unique legend management
    colorStr = mat2str(selectedColor);
end
