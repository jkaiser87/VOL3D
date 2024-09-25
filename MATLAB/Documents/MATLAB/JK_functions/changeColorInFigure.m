function changeColorInFigure(originColor, targetColor)
    % changeColorInFigure changes all elements with the specified origin color to the target color
    % 
    % Inputs:
    %   - originColor: RGB triplet or color name to find (e.g., [1 0 0] or 'red')
    %   - targetColor: RGB triplet or color name to change to (e.g., [0 0 1] or 'blue')
    
    % Convert color names to RGB triplets if needed
    originColor = getRGBColor(originColor);
    targetColor = getRGBColor(targetColor);

    % Find all patch objects in the current figure
    patchHandles = findobj(gcf, 'Type', 'patch');

    % Loop through each patch and check if its color matches the origin color
    for i = 1:length(patchHandles)
        % Check if the patch face color matches the origin color
        if isequal(patchHandles(i).FaceColor, originColor)
            % Change the color to the target color
            patchHandles(i).FaceColor = targetColor;
        end
    end

    % Find all line objects in the current figure (if you want to include lines as well)
    lineHandles = findobj(gcf, 'Type', 'line');
    
    % Loop through each line and check if its color matches the origin color
    for i = 1:length(lineHandles)
        % Check if the line color matches the origin color
        if isequal(lineHandles(i).Color, originColor)
            % Change the color to the target color
            lineHandles(i).Color = targetColor;
        end
    end

    % Update the figure
    drawnow;
end
