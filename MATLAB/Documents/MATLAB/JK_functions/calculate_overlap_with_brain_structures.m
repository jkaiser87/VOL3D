function calculate_overlap_with_brain_structures(volumes, structure_acronyms, outDir, ExperimentName, alpha, plotResults)
    [~, av, st] = load_ABA_files();
    slice_spacing = 5;
    reduced_av = av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end);
    
    if plotResults
        figDir_ABA = fullfile(outDir, 'FIG-ABA');
        if ~exist(figDir_ABA, 'dir'), mkdir(figDir_ABA); end
            % Load the CCFv3 object to plot brain structure
    load('D:/MATLAB/AP_histology/allenAtlas/997.mat');
    end

    num_structures = length(structure_acronyms);
    grey_values = linspace(0.2, 0.8, num_structures);  % Create a gradient from light grey to dark grey

    struct_vol = struct;
    valid_struct_idx = 0; % Initialize valid structure index

    for i = 1:num_structures
        structure_name = structure_acronyms{i};
        structure_index = find(strcmpi(st.acronym, structure_name), 1);

        if isempty(structure_index)
            warning(['Structure not found and will not be used: ', structure_name]);
            continue;
        end

        target_path = st.structure_id_path{structure_index};
        plot_ccf_idx = find(cellfun(@(x) contains(x, target_path), st.structure_id_path));
        plot_ccf_volume = ismember(reduced_av, plot_ccf_idx);
        structure_3d = isosurface(permute(plot_ccf_volume, [3, 1, 2]), 0);

        if ~isempty(structure_3d.vertices)
            valid_struct_idx = valid_struct_idx + 1; % Increment the valid structure index
            struct_vol(i).name = structure_name;
            struct_vol(i).vertices = structure_3d.vertices * slice_spacing;  % Use slice_spacing from the volumes structure
            struct_vol(i).faces = structure_3d.faces;
        else
            warning(['No visible structure found for: ', structure_name, ' and will not be used.']);
        end
    end

    overlapResults = struct('group',{}, 'animal', {}, 'channel', {}, 'structure', {}, 'volume', {}, 'overlap_volume', {}, 'overlap_fraction_original', {}, 'overlap_fraction_structure', {});

    for v = 1:length(volumes)
        vol_vertices = volumes(v).grid_points(volumes(v).inside_indices, :);

        for s = 1:valid_struct_idx
            if isempty(struct_vol(s).vertices)
                continue;
            end

            brain_struct = struct_vol(s);

            % Calculate the overlap between your volume and the brain structure
            overlap_in = inpolyhedron(brain_struct.faces, brain_struct.vertices, vol_vertices);
            overlap_points = vol_vertices(overlap_in, :);

            if sum(overlap_in) == 0
                estimated_overlap_volume = 0;
                fraction_of_original = 0;
                fraction_of_structure = 0;
            else
                % Calculate overlap volume
                estimated_overlap_volume = sum(overlap_in) * (volumes(v).resolution^3); % Adjust volume for the chosen resolution

                % Fraction of the original structure's volume that overlaps with the brain structure
                fraction_of_original = (estimated_overlap_volume / volumes(v).volume) * 100;

                % Calculate the volume of the brain structure
                brain_structure_in = inpolyhedron(brain_struct.faces, brain_struct.vertices, brain_struct.vertices);
                brain_structure_volume = sum(brain_structure_in) * (volumes(v).resolution^3); % Correctly calculate the volume

                % Fraction of the brain structure's volume that overlaps with the original structure
                fraction_of_structure = (estimated_overlap_volume / brain_structure_volume) * 100;

            end
            % Store overlap result
            overlapResults(end+1) = struct('group', volumes(v).group, ...
                'animal', volumes(v).animal, ...
                'channel', volumes(v).channel, ...
                'structure', brain_struct.name, ...
                'volume', volumes(v).volume, ...
                'overlap_volume', estimated_overlap_volume, ...
                'overlap_fraction_original', fraction_of_original, ...
                'overlap_fraction_structure', fraction_of_structure);

            % Plot the overlap points as a sanity check
            if plotResults
                legendHandles = [];
                legends = {'Brain'};

                figureOverlap = figure('Name', ['Overlap with ', brain_struct.name], 'Color', 'w');
                
                plot_brain_outline;

                h = patch('Vertices', volumes(v).ccf_points_cat_ord, 'Faces', volumes(v).k1, ...
                    'FaceColor', volumes(v).channelColor, 'FaceAlpha', alpha, 'EdgeColor', 'none');
                legends{end+1} = sprintf('%s - %s', volumes(v).animal, volumes(v).channel);
                h = patch('Vertices', brain_struct.vertices, 'Faces', brain_struct.faces, ...
                    'FaceColor', [1 1 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                legends{end+1} = brain_struct.name;
                scatter3(overlap_points(:, 1), overlap_points(:, 2), overlap_points(:, 3), 15, 'filled','black');
                legends{end+1} = 'overlap';
                % Finalize and save the combined figure
                xlabel('AP');
                ylabel('ML');
                zlabel('DV');
                legend(legendHandles, legends, 'Location', 'northeastoutside');
                rotate3d on;

                savename = fullfile(figDir_ABA, [volumes(v).animal, '_', volumes(v).channel, ...
                    '_x_', brain_struct.name, ...
                    '.fig']);
                savefig(gcf, savename);
                close(gcf);
            end
        end
    end

    % Save overlap results as CSV
    overlapTable = struct2table(overlapResults);
    savename = fullfile(outDir, [ExperimentName, '_3D_Overlap_Results_VolumestoBrainStructures.csv']);
    writetable(overlapTable, savename);

    disp(['Calculated overlap between all volumes and selected brain structures:']);
    disp(structure_acronyms);
    disp(['Saved Overlap Table as ',savename]);

end
