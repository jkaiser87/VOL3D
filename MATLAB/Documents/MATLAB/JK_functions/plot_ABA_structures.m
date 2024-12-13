function plot_ABA_structures(structure_acronyms, add_to_existing)
    % Plots brain structures from the Allen Brain Atlas (ABA) based on structure acronyms
    % Inputs:
    %   structure_acronyms: Cell array of acronyms (e.g., {'MO', 'SS', 'AUD'})
    %   add_to_existing: Boolean. Set to true to add structures to an open plot, false to create a new plot.

    [~, av, st] = load_ABA_files();

    slice_spacing = 5;  % Set slice spacing for downsampling the volume
    alpha = 0.2;

    % Check if we need to create a new figure or add to an existing one
    if add_to_existing
        % Check if there is an existing figure with a brain outline
        fig = findobj('Type', 'figure');
        if isempty(fig)
            % No figure found, create a new one with the brain outline
            plot_brain_outline(); % Create new figure and brain outline
            ccf_3d_axes = gca;
            
        else
            % Find if the brain outline is already plotted by searching for specific objects
            axes_found = findall(fig, 'Type', 'axes');
            outline_found = findall(axes_found, 'Type', 'patch'); % Find patches (which might represent the brain outline)
            
            if isempty(outline_found)
                % If no outline is found, plot a new brain outline
                figure(fig); % Bring the figure to focus
                plot_brain_outline(); % Plot the brain outline in the existing figure
                ccf_3d_axes = gca; % Use the current axes
            else
                % Brain outline found, just use the existing figure and axes
                ccf_3d_axes = gca;
                alpha = 0.05;
                figure(fig); % Bring the existing figure to focus
            end
        end
    else
        % Create a new figure and plot the brain outline
        plot_brain_outline(); % Create a new figure with the brain outline
        ccf_3d_axes = gca;
    end

    % Initialize arrays to store handles and legend entries
    legendHandles = [];
    legendEntries = {};

    % Loop through each provided acronym and plot the corresponding structure
    for g = 1:length(structure_acronyms)
        structure_search = lower(structure_acronyms{g});

        % Find the structures matching the acronym
        structure_match = find(strcmpi(st.acronym, structure_search), 1);

        if isempty(structure_match)
            warning(['Acronym "', structure_acronyms{g}, '" not found in the structure tree. Skipping...']);
            continue;
        end

        % Get structure info
        plot_structure = structure_match;
        plot_structure_id = st.structure_id_path{plot_structure};

        % Get all areas within and below the selected hierarchy level
        plot_ccf_idx = find(cellfun(@(x) contains(x, plot_structure_id), st.structure_id_path));

        % Assign a random color
        plot_structure_color = rand(1, 3);  % Random RGB color

        % Get structure volume
        plot_ccf_volume = ismember(av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end), plot_ccf_idx);

        % Smooth the volume before generating the isosurface
        smoothed_volume = smooth3(plot_ccf_volume, 'box', 5); % Box filter with size 5

        % Generate the smoothed isosurface
        structure_3d = isosurface(permute(smoothed_volume, [3, 1, 2]), 0);

        % Plot the structure and store the handle
        h = patch(ccf_3d_axes, ...
            'Vertices', structure_3d.vertices * slice_spacing, ...
            'Faces', structure_3d.faces, ...
            'FaceColor', plot_structure_color, ...
            'EdgeColor', 'none', ...
            'FaceAlpha', alpha);

        % Explicitly set display name for the legend
        set(h, 'DisplayName', structure_acronyms{g});
        % Store the handle and the corresponding acronym for the legend
        legendHandles(end + 1) = h;
        legendEntries{end + 1} = structure_acronyms{g};
    end

    legend(legendHandles, legendEntries, 'Location', 'northeastoutside');

    % Add a new light from different directions to reduce the appearance of shadows
    delete(findall(gcf,'Type','light'));
    light('Position', [-1 -1 -1], 'Style', 'infinite');

    % Optional: Adjust the material properties for better visual appearance
    material([0.3 0.6 0.9 25]);  % Sets material properties [ambient, diffuse, specular, shininess]

    rotate3d on; % Enable rotation for the 3D plot
    hold off;
end
