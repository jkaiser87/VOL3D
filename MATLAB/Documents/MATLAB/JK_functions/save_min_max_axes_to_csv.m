function save_min_max_axes_to_csv(volumes, outDir, ExperimentName, plotResults)
    % Create directory for CSV file
    csvDir = fullfile(outDir, 'MinMax');
    if ~exist(csvDir, 'dir'), mkdir(csvDir); end

    % Initialize data storage for the CSV file
    csvData = {};

    % Check if volumes have been grouped
    if isfield(volumes, 'group') && ~isempty([volumes.group])
        % Get unique groups
        uniqueGroups = unique({volumes.group});
        numPanels = length(uniqueGroups);

        % Create figure with separate panels for each group
        if plotResults
            figure('Name', 'Min-Max Scaffold', 'Color', 'w');
            tiledlayout(1, numPanels, 'TileSpacing', 'compact', 'Padding', 'compact');
        end

        for panelIdx = 1:numPanels
            group = uniqueGroups{panelIdx};

            if plotResults
                nexttile;
                patch('Vertices', volumes(1).brain_outline_patchdata.vertices * volumes(1).slice_spacing, ...
                    'Faces', volumes(1).brain_outline_patchdata.faces, ...
                    'FaceColor', [0.7,0.7,0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
                hold on;
                view([90,90]);
                axis('vis3d','equal','off','manual');
                axis tight;
                set(gca, 'ZDir', 'Reverse');
            end

            legendHandles = [];
            legends = {};

            for v = 1:length(volumes)
                if strcmp(volumes(v).group, group)
                    % Extract the min and max values
                    minX = volumes(v).bounding_box.minX;
                    maxX = volumes(v).bounding_box.maxX;
                    minY = volumes(v).bounding_box.minY;
                    maxY = volumes(v).bounding_box.maxY;
                    minZ = volumes(v).bounding_box.minZ;
                    maxZ = volumes(v).bounding_box.maxZ;

                    % Calculate the center of the bounding box
                    centerX = (minX + maxX) / 2;
                    centerY = (minY + maxY) / 2;
                    centerZ = (minZ + maxZ) / 2;

                    % Plot the centerline along each axis within the bounding box
                    if plotResults
                        h1 = plot3([minX, maxX], [centerY, centerY], [centerZ, centerZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);
                        h2 = plot3([centerX, centerX], [minY, maxY], [centerZ, centerZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);
                        h3 = plot3([centerX, centerX], [centerY, centerY], [minZ, maxZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);

                        legendHandles = [legendHandles, h1, h2, h3];
                        legends = [legends, {sprintf('%s - %s', volumes(v).channel, volumes(v).animal)}];
                    end

                    % Store data for the CSV file
                    csvData{end+1, 1} = volumes(v).group;
                    csvData{end+1, 2} = volumes(v).animal;
                    csvData{end+1, 3} = volumes(v).channel;
                    csvData{end+1, 4} = minX;
                    csvData{end+1, 5} = maxX;
                    csvData{end+1, 6} = minY;
                    csvData{end+1, 7} = maxY;
                    csvData{end+1, 8} = minZ;
                    csvData{end+1, 9} = maxZ;
                end
            end

            if plotResults
                legend(legendHandles, legends, 'Location', 'northeastoutside');
                title([group, ' - Min-Max Scaffold']);
            end
        end
    else
        % If no groups, plot all volumes in a single panel
        if plotResults
            figure('Name', 'Min-Max Scaffold', 'Color', 'w');
            patch('Vertices', volumes(1).brain_outline_patchdata.vertices * volumes(1).slice_spacing, ...
                'Faces', volumes(1).brain_outline_patchdata.faces, ...
                'FaceColor', [0.7,0.7,0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
            hold on;
            view([90,90]);
            axis('vis3d','equal','off','manual');
            axis tight;
            set(gca, 'ZDir', 'Reverse');

            legendHandles = [];
            legends = {};
        end

        for v = 1:length(volumes)
            % Extract the min and max values
            minX = volumes(v).bounding_box.minX;
            maxX = volumes(v).bounding_box.maxX;
            minY = volumes(v).bounding_box.minY;
            maxY = volumes(v).bounding_box.maxY;
            minZ = volumes(v).bounding_box.minZ;
            maxZ = volumes(v).bounding_box.maxZ;

            % Calculate the center of the bounding box
            centerX = (minX + maxX) / 2;
            centerY = (minY + maxY) / 2;
            centerZ = (minZ + maxZ) / 2;

            % Plot the centerline along each axis within the bounding box
            if plotResults
                h1 = plot3([minX, maxX], [centerY, centerY], [centerZ, centerZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);
                h2 = plot3([centerX, centerX], [minY, maxY], [centerZ, centerZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);
                h3 = plot3([centerX, centerX], [centerY, centerY], [minZ, maxZ], 'Color', volumes(v).channelColors{volumes(v).channel_index}, 'LineWidth', 2);

                legendHandles = [legendHandles, h1, h2, h3];
                legends = [legends, {sprintf('%s - %s', volumes(v).channel, volumes(v).animal)}];
            end

            % Store data for the CSV file
            csvData{end+1, 1} = volumes(v).group;
            csvData{end+1, 2} = volumes(v).animal;
            csvData{end+1, 3} = volumes(v).channel;
            csvData{end+1, 4} = minX;
            csvData{end+1, 5} = maxX;
            csvData{end+1, 6} = minY;
            csvData{end+1, 7} = maxY;
            csvData{end+1, 8} = minZ;
            csvData{end+1, 9} = maxZ;
        end

        if plotResults
            legend(legendHandles, legends, 'Location', 'northeastoutside');
            title('Min-Max Scaffold');
        end
    end

    % Convert the data to a table and save as CSV
    csvTable = cell2table(csvData, 'VariableNames', {'Group', 'Animal', 'Channel', 'X_Min', 'X_Max', 'Y_Min', 'Y_Max', 'Z_Min', 'Z_Max'});
    csvFilename = fullfile(csvDir, [ExperimentName, '_MinMax.csv']);
    writetable(csvTable, csvFilename);
    disp(['Saved Min-Max data as ', csvFilename]);
end
