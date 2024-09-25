function MATLAB_Fiji_Medlat_classification_RNAScope(folderPath, channels)

% Setup folder paths for CSV and output
csvFolderPath = fullfile(folderPath, 'CSV');
coordsFolderPath = fullfile(csvFolderPath, 'COORD');
outFolderPath = fullfile(folderPath, 'OUT');
figFolderPath = fullfile(outFolderPath, 'FIG');

% Create output directories if they do not exist
if ~exist(outFolderPath, 'dir')
    mkdir(outFolderPath);
end
if ~exist(figFolderPath, 'dir')
    mkdir(figFolderPath);
end

% Get a list of TIFF files
tifFolder = fullfile(folderPath, 'TIF');
tifFiles = dir(fullfile(tifFolder, '*.tif'));
tifFiles = tifFiles(arrayfun(@(x) any(startsWith(x.name, channels)), tifFiles)); %this removes all channels that were not selected in the user defined array "channels"

% Process each TIFF file
for i = 1:length(tifFiles)
 
baseFileName = tifFiles(i).name;
[~, name, ~] = fileparts(baseFileName);
tifFilePath = fullfile(tifFolder, baseFileName);

% Extract image information
info = imfinfo(tifFilePath);
imgWidth = info.Width;
imgHeight = info.Height;

% Paths to CSV files for cells and brain landmarks
csvFilePath = fullfile(csvFolderPath, [name, '.csv']);
coordsCsvFilePath = fullfile(coordsFolderPath, [name(4:end), '.csv']);

% Check if the CSV files exist
if isfile(csvFilePath) && isfile(coordsCsvFilePath)
    % Read the brain landmarks
    coords = readtable(coordsCsvFilePath);

    % Extracting coordinates based on the provided structure
    leftMostX = coords.X(1); % X coordinate of the left-most point from the first row
    midlineX = coords.X(2);  % X coordinate of the midline from the second row
    rightMostX = coords.X(3); % X coordinate of the right-most point from the third row

    % Read cell coordinates
    cells = readtable(csvFilePath);

    %add coordinates into master table
    cells.leftX = repelem(leftMostX,size(cells, 1)).';
    cells.midX = repelem(midlineX,size(cells, 1)).';
    cells.rightX = repelem(rightMostX,size(cells, 1)).';
    cells.imgWidth = repelem(imgWidth,size(cells, 1)).';
    cells.imgHeight = repelem(imgHeight,size(cells, 1)).';

    % ------------- classify into medial/lateral/cingulate
    % Assuming the cells table, midlineX, leftMostX, and rightMostX are already defined
    % Calculate section widths for each hemisphere
    sectionWidthLeft = (midlineX - leftMostX) / 5;
    sectionWidthRight = (rightMostX - midlineX) / 5;

    % Initialize an array for the classification results
    cellClassifications = strings(size(cells, 1), 1);
    cellSection = size(cells, 1);
    hemisphere = cell(size(cells, 1), 1);

    % Classify cells based on their X coordinate
    for cc = 1:size(cells, 1)
        xCoord = cells.X(cc);

        if xCoord < midlineX  % Left hemisphere
            % Calculate relative section from the left
            cellSection(cc) = ceil((xCoord - leftMostX) / sectionWidthLeft);
            hemisphere{cc} = 'L';
        else  % Right hemisphere
            % Calculate relative section from the right
            cellSection(cc) = ceil((rightMostX - xCoord) / sectionWidthRight);
            hemisphere{cc} = 'R';
        end

        % Determine classification based on section
        switch cellSection(cc)
            case {1, 2}
                cellClassifications(cc) = "Lateral";
            case {3, 4}
                cellClassifications(cc) = "Medial";
            case 5
                cellClassifications(cc) = "Cingulate";
            otherwise
                cellClassifications(cc) = "Undefined";
        end
    end

    % Add the classification to the cells table
    cells.classifier = cellClassifications;
    cells.section = cellSection.';
    cells.hemisphere = hemisphere;

    % ------------- plot as overview
    % Plot all cells based on their X and Y coordinates
    figure; % Open a new figure window
    [~, ~, classIndices] = unique(cells.classifier);
    scatter(cells.X, cells.Y, 10, classIndices, 'filled'); % Creates a scatter plot of cells
    hold on; % Keeps the figure open to overlay more plots
    % Calculate section widths for each hemisphere
    sectionWidthLeft = (midlineX - leftMostX) / 5;
    sectionWidthRight = (rightMostX - midlineX) / 5;
    % Add vertical lines for section boundaries in the left hemisphere
    for b = 1:4 % There are 4 boundaries within the 5 sections
        xline(leftMostX + b * sectionWidthLeft, '--');
    end
    % Add a vertical line at the midline X coordinate
    xline(midlineX, 'k-', 'Midline'); % 'k-' specifies a black solid line, and 'Midline' is the label.
    % Add vertical lines for section boundaries in the right hemisphere
    for b = 1:4 % There are 4 boundaries within the 5 sections
        xline(midlineX + b * sectionWidthRight, '--');
    end
    % Adjust labels, title, and axis
    axis([0 imgWidth 0 imgHeight]);% Set axis boundaries to match the image dimensions
    title('Cell Distribution with Classification');
    xlabel('X Coordinate');
    ylabel('Y Coordinate');
    axis equal;
    set(gca, 'YDir','reverse'); % Flip the Y-axis to match image orientation
    colorbar;    % Add a colorbar for reference
    colormap(jet(max(classIndices))); % Use a colormap that provides distinct colors
    colorbar('Ticks', 1:length(unique(cells.classifier)), 'TickLabels', unique(cells.classifier));
    hold off;

    saveas(gcf, fullfile(figFolderPath, ['CLASS_', name, '.fig']));
    close(gcf);


    % ------------- percentages to plot histogram


    % Initialize an array for percentage distances
    percentageDistances = zeros(size(cells, 1), 1);

    % Calculate percentage distance for each cell
    for pp = 1:size(cells, 1)
        if cells.X(pp) < midlineX
            % Left hemisphere
            percentageDistances(pp) = ((midlineX - cells.X(pp)) / (midlineX - leftMostX)) * 100;
        else
            % Right hemisphere
            percentageDistances(pp) = ((cells.X(pp) - midlineX) / (rightMostX - midlineX)) * 100;
        end
    end

    cells.PercToMidline = percentageDistances;


    % Save cells table to results

    resultCsvPath = fullfile(outFolderPath, ['CLASS_' name, '.csv']);
    writetable(cells, resultCsvPath);
else
    warning(['CSV files for ', name, ' are missing.']);
end
end
disp('Med/Lat classifier complete.');
end


