function group_assignments = assign_groups_to_animals(animal_names, group_names)
 
    % Number of animals
    num_animals = numel(animal_names);

   
    % Initialize the group_assignments structure array
    group_assignments(num_animals) = struct('Animal', [], 'Group', []);  % Pre-allocate the structure

    for i = 1:num_animals
        group_assignments(i).Animal = animal_names{i};  % Assign each animal name
        group_assignments(i).Group = 'Unassigned';      % Initialize group as 'Unassigned'
    end


    % Create the UI figure
    fig = uifigure('Name', 'Assign Animals to Groups', 'Position', [100 100 400 50*num_animals+70], 'CloseRequestFcn', @onClose);

    % Initialize storage for dropdown components and their labels
    dd = gobjects(num_animals, 1);
    lbl = gobjects(num_animals, 1);

    % Create dropdowns and labels for each animal
    for i = 1:num_animals
        lbl(i) = uilabel(fig, 'Text', animal_names{i}, 'Position', [10, 50*num_animals-50*i+50, 100, 22]);
        dd(i) = uidropdown(fig, 'Items', group_names, 'Position', [120, 50*num_animals-50*i+50, 100, 22]);
    end

    % Button to finalize selections
    btn = uibutton(fig, 'push', 'Text', 'Submit', 'Position', [230, 20, 100, 22], 'ButtonPushedFcn', @(btn, event) submitSelections(dd, animal_names));

    % Block the function return until the figure is closed
    uiwait(fig);

    % Function to handle figure close request
    function onClose(src, event)
        uiresume(fig);
        delete(fig);
    end

    % Nested function to capture the output
    function submitSelections(dd, animal_names)
        % Retrieve selection from each dropdown and save to structure
        for i = 1:num_animals
            group_assignments(i).Group = dd(i).Value;
            fprintf('%s - Group: %s\n', animal_names{i}, group_assignments(i).Group);
        end
        % Close the figure and allow main function to return results
        uiresume(fig);
        delete(fig);
    end

end
