function groupColorMap = select_group_colors(group_names)
    % Number of groups
    num_groups = numel(group_names);

    % Initialize the containers.Map
    groupColorMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Ask the user to select a color for each group
    for i = 1:num_groups
        % Open color picker dialog
        color = uisetcolor([1 1 1], ['Select Color for ' group_names{i}]);  % Default to white

        % Check if the user cancels the color selection
        if length(color) == 1 && color == 0
            % If the user cancels, assign a default color (white in this case)
            groupColorMap(group_names{i}) = [1 1 1];
        else
            % Store the selected color
            groupColorMap(group_names{i}) = color;
        end
    end
end
