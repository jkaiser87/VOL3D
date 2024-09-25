function rgbOutput = getRGBColor(inputColor)
    % getRGBColor - Convert a color name, hex code, or RGB triplet to an RGB triplet.
    % If inputColor is an RGB triplet, it returns the same triplet.
    % If inputColor is a recognized color name or hex code, it converts it to an RGB triplet.
    % Otherwise, it throws an error.

    if isnumeric(inputColor) && numel(inputColor) == 3 && all(inputColor >= 0 & inputColor <= 1)
        % Input is already an RGB triplet
        rgbOutput = inputColor;
    elseif ischar(inputColor) || isstring(inputColor)
        % Convert color name or hex code to RGB triplet
        inputColor = char(inputColor); % Ensure it's a character array for comparison
        if startsWith(inputColor, '#')
            % Convert hex code to RGB triplet
            rgbOutput = hex2rgb(inputColor);
        else
            % Convert named color to RGB triplet
            switch lower(inputColor)
                case 'red'
                    rgbOutput = [1, 0, 0];
                case 'green'
                    rgbOutput = [0, 1, 0];
                case 'blue'
                    rgbOutput = [0, 0, 1];
                case 'yellow'
                    rgbOutput = [1, 1, 0];
                case 'cyan'
                    rgbOutput = [0, 1, 1];
                case 'magenta'
                    rgbOutput = [1, 0, 1];
                case 'black'
                    rgbOutput = [0, 0, 0];
                case 'white'
                    rgbOutput = [1, 1, 1];
                % Add more color names as needed
                otherwise
                    error('Invalid color input. Provide either a valid RGB triplet, hex code, or a recognized color name.');
            end
        end
    else
        error('Invalid color input. Provide either a valid RGB triplet, hex code, or a recognized color name.');
    end
end

function rgb = hex2rgb(hex)
    % Convert hex color code to RGB triplet
    if hex(1) == '#'
        hex = hex(2:end);
    end
    if numel(hex) ~= 6
        error('Invalid hex color code. Provide a 6-character hex code.');
    end
    rgb = reshape(sscanf(hex, '%2x') / 255, 1, 3);
end
