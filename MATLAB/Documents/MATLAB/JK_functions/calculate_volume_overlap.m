function overlapResults = calculate_volume_overlap(volumes, outDir, ExperimentName, alpha, plotResults)
% Initialize overlap results struct
overlapResults = struct('animal1', {}, 'channel1', {}, 'animal2', {}, 'channel2', {}, 'Comp', {}, ...
    'volume', {}, 'overlap_volume', {}, 'overlap_percentage', {});

if plotResults
    figDir_vol = fullfile(outDir, 'FIG-VOL');
    if ~exist(figDir_vol, 'dir'), mkdir(figDir_vol); end
    % Load the CCFv3 object to plot brain structure
    load('D:/MATLAB/AP_histology/allenAtlas/997.mat');
end

% Loop over all pairs of volumes
for i = 1:length(volumes)
    for j = i:length(volumes)
        % Skip self-comparisons
        if i == j
            continue;
        end

       % Get volume information
        vol1 = volumes(i);
        vol2 = volumes(j);

        % Calculate overlap
        overlap_in = inpolyhedron(vol2.k1, vol2.ccf_points_cat_ord, vol1.grid_points(vol1.inside_indices, :));
        overlap_points = vol1.grid_points(vol1.inside_indices(overlap_in), :);

        if sum(overlap_in) == 0
            estimated_overlap_volume = 0;
            fraction_of_vol1 = 0;
            fraction_of_vol2 = 0;
        else
            % Calculate overlap volume
            estimated_overlap_volume = sum(overlap_in) * (vol1.resolution^3);

            % Fraction relative to volume1
            fraction_of_vol1 = (estimated_overlap_volume / vol1.volume) * 100;

            % Fraction relative to volume2
            fraction_of_vol2 = (estimated_overlap_volume / vol2.volume) * 100;
        end

        
        % Add first comparison: vol1 -> vol2
        overlapResults(end+1) = struct('animal1', vol1.animal, ...
            'channel1', vol1.channel, ...
            'animal2', vol2.animal, ...
            'channel2', vol2.channel, ...
            'Comp', [vol1.channel, '-', vol2.channel], ...
            'volume', vol1.volume, ...
            'overlap_volume', estimated_overlap_volume, ...
            'overlap_percentage', fraction_of_vol1);  % Use fraction_of_vol1

% Add second comparison: vol2 -> vol1 (reverse order)
        overlapResults(end+1) = struct('animal1', vol2.animal, ...
            'channel1', vol2.channel, ...
            'animal2', vol1.animal, ...
            'channel2', vol1.channel, ...
            'Comp', [vol2.channel, '-', vol1.channel], ...  % Reverse order of comparison
            'volume', vol2.volume, ...
            'overlap_volume', estimated_overlap_volume, ...
            'overlap_percentage', fraction_of_vol2);  % Use fraction_of_vol2

        % Plot the overlap dots as a sanity check and save fig
        if plotResults
            figureOverlap = figure('Name', 'Overlap Dots', 'Color', 'w');

            plot_brain_outline;

            % Determine colors to use (groupColor if available, otherwise channelColor)
            color1 = vol1.groupColor;
            if isempty(color1)
                color1 = vol1.channelColor;
            end

            color2 = vol2.groupColor;
            if isempty(color2)
                color2 = vol2.channelColor;
            end

            % Plot volumes A and B
            h1 = patch('Vertices', vol1.ccf_points_cat_ord, 'Faces', vol1.k1, ...
                'FaceColor', color1, 'FaceAlpha', alpha, 'EdgeColor', 'none');
            h2 = patch('Vertices', vol2.ccf_points_cat_ord, 'Faces', vol2.k1, ...
                'FaceColor', color2, 'FaceAlpha', alpha, 'EdgeColor', 'none');

            % Plot the overlap points
            scatter3(overlap_points(:, 1), overlap_points(:, 2), overlap_points(:, 3), 15, 'filled', 'black');

            % Finalize and save the figure
            xlabel('AP');
            ylabel('ML');
            zlabel('DV');
            legend([h1, h2], {sprintf('%s - %s', vol1.animal, vol1.channel), ...
                sprintf('%s - %s', vol2.animal, vol2.channel)}, ...
                'Location', 'northeastoutside');
            rotate3d on;

            savename = fullfile(figDir_vol, [vol1.animal, '--', vol1.channel, ...
                '_x_', vol2.animal, '--', vol2.channel, ...
                '.fig']);
            savefig(gcf, savename);
            close(gcf);
        end
    end
end

% Save overlap results as CSV
overlapTable = struct2table(overlapResults);
savename = fullfile(outDir, [ExperimentName, '_3D_Overlap_Results_AllPairs.csv']);
writetable(overlapTable, savename);
disp('Saved overlap results between volumes as:');
disp(savename);
end
