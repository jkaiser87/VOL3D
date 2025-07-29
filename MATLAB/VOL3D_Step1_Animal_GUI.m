% VOL3D_Step1_Animal_GUI.m
% GUI for processing and visualizing 3D injection volumes from FIJI into CCF space
% Julia Kaiser, April 2025


%add button to calculate overlap with brain structures 
%add help function
% add check for dependencies
% animal coloring does not work?
% assigns hemi wrong?

function VOL3D_Step1_Animal_GUI(baseDir)
if nargin < 1 || isempty(baseDir)
    handles.baseDir = pwd;
end


% Define color scheme (RGB 0-1)
handles.colors.lightBg = [0.96 0.96 0.96];    % #F5F5F5
handles.colors.thistle = [244 237 234]/255;    % #DBC2CF
handles.colors.coolGray = [0.62 0.64 0.70];   % #9FA2B2
handles.colors.cerulean = [0.24 0.48 0.54];   % #3C7A89
handles.colors.charcoal = [0.18 0.28 0.34];   % #2E4756
handles.colors.gunmetal = [0.09 0.15 0.18];   % #16262E
handles.colors.white = [1 1 1];               % #FFFFFF
handles.colors.errorRed = [0.8 0.2 0.2];      % For error messages
handles.colors.warningColor = [1.0 0.8 0.4];           % pastel amber, hex #FFCC66
handles.colors.successColor = [0.35 0.75 0.45]; 

% Status colors (adjusted to match your scheme)
handles.colors.statusPending = [0.62 0.64 0.70];  % Your existing coolGray (#9FA2B2)
handles.colors.statusSuccess = [0.30 0.58 0.40];  % Darker, richer green (adjusted from successColor)
handles.colors.statusWarning = [0.85 0.65 0.30];  % Warmer amber (adjusted from warningColor)
handles.colors.statusNotDone = [0.75 0.75 0.78];  % Lighter cool gray variant
handles.colors.statusError = [0.72 0.30 0.30];    % Deeper red (adjusted from errorRed)

% Text colors for contrast (use with above backgrounds)
handles.colors.statusTextDark = [0.18 0.28 0.34]; % Your charcoal (#2E4756)
handles.colors.statusTextLight = [0.96 0.96 0.96]; % Your lightBg (#F5F5F5)
handles.alpha = 0.4;
handles.cellsize = 20;

%GUI setup
handles.fig = uifigure('Name', 'vol3d Step1 - Animal', 'Position', [100 100 1400 700]);
handles.fig.Color = handles.colors.lightBg;

handles.mainLayout = uigridlayout(handles.fig, [1, 2]);  % Two major sections in GUI
handles.mainLayout.RowHeight = {'1x'};
handles.mainLayout.ColumnWidth = {'3x', '2x'};
handles.mainLayout.Padding = [0 0 0 0];

%left side

% LEFT SIDE UI
handles.uiLeft = uigridlayout(handles.mainLayout, [2, 1]); % 2 rows on left
handles.uiLeft.Layout.Row = 1;
handles.uiLeft.Layout.Column = 1;
handles.uiLeft.RowHeight = {40, '1x'};
handles.uiLeft.Padding = [10 10 10 10];

%----- Setup Header
handles.headerPanel = uipanel(handles.uiLeft, 'Title', '', ...
    'BorderType', 'none', ...  % Changed from 'line' to 'none' for cleaner look
    'BackgroundColor', handles.colors.charcoal, ...
    'HighlightColor', handles.colors.cerulean, ...  % Border highlight color when needed
    'ForegroundColor', handles.colors.white);  % Changed from 'white' to colors.white for consistency

handles.headerLayout = uigridlayout(handles.headerPanel, [1 3]);
handles.headerLayout.ColumnWidth = {'1x', 'fit', 'fit'};
handles.headerLayout.Padding = [10 5 10 5];
handles.headerLayout.BackgroundColor = handles.colors.charcoal; % Ensure full coverage

uilabel(handles.headerLayout, 'Text', 'VOL3D Step 1 - Animal', ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...  % Explicitly set font color
    'BackgroundColor', handles.colors.charcoal); % Match panel background

% Change folder
handles.browseButton = uibutton(handles.headerLayout, 'Text', '📁 Change Folder');
handles.browseButton.Layout.Row = 1;
handles.browseButton.Layout.Column = 2;

% Help Button
handles.btnHelp = uibutton(handles.headerLayout, 'Text', 'Help');
handles.btnHelp.Layout.Row = 1;
handles.btnHelp.Layout.Column = 3;
handles.btnHelp.FontColor = handles.colors.white;  % White text
handles.btnHelp.BackgroundColor = handles.colors.gunmetal;  % Grey background to stand out

%----- Main Section (TIFF List + Setup)
% column 1> tif list
handles.uiLeftMain = uigridlayout(handles.uiLeft, [1, 2]); % 2 columns
handles.uiLeftMain.ColumnWidth = {'fit', '1x'};
handles.uiLeftMain.Layout.Row = 2;

handles.tiffListBox = uitable(handles.uiLeftMain, 'Data', cell(0, 1), 'ColumnName', {'Files in Folder'}, 'RowName', []);
handles.tiffListBox.Layout.Column = 1;

% ---  Create Left Right box with setup and buttons as 2 "rows" (first
% setup, 2nd buttons)

handles.uiLeftRight = uigridlayout(handles.uiLeftMain, [4, 1]);
handles.uiLeftRight.Layout.Row = 1;
handles.uiLeftRight.Layout.Column = 2;
handles.uiLeftRight.Padding = [0 0 0 0];
handles.uiLeftRight.RowHeight = {'1x', 80, 150, 150};  % setup panel - status bar - button bar (2 rows now) - status label

% Row 1: Create a dedicated panel for setup options
handles.configPanel = uipanel(handles.uiLeftRight, 'Title', 'Setup');
handles.configPanel.Layout.Column = 1;
handles.configPanel.Layout.Row = 1;
handles.configPanel.FontWeight = 'bold';
handles.configPanel.FontSize = 12;

% Grid layout for the configuration panel
handles.configGrid = uigridlayout(handles.configPanel, [3, 2]);
handles.configGrid.ColumnWidth = {100, '1x'};
handles.configGrid.RowHeight = {'1x', '1x', '1x'};
handles.configGrid.Padding = [10 10 10 10];

% Label for Channel Selection
handles.channelLabel = uilabel(handles.configGrid, 'Text', 'Channels:');
handles.channelLabel.Layout.Row = 1;
handles.channelLabel.Layout.Column = 1;
handles.channelLabel.VerticalAlignment = 'center';

% Grid layout inside the panel for checkboxes
handles.channelsGrid = uigridlayout(handles.configGrid, [1, 4]); % Adjust grid size based on needs
handles.channelsGrid.Layout.Row = 1;
handles.channelsGrid.Layout.Column = 2;
% Creating checkboxes for C1 to C4
handles.channelCheckboxes = gobjects(1, 4); % Pre-allocate a graphics array for checkboxes
channelNames = {'C1', 'C2', 'C3', 'C4'};
for i = 1:4
    handles.channelCheckboxes(i) = uicheckbox(handles.channelsGrid, 'Text', channelNames{i});
    handles.channelCheckboxes(i).Layout.Row = 1;
    handles.channelCheckboxes(i).Layout.Column = i;
end

% Row 4: Channel name input
handles.channelNameLabel = uilabel(handles.configGrid, 'Text', 'Channel Names:');
handles.channelNameLabel.Layout.Row = 2;
handles.channelNameLabel.Layout.Column = 1;
handles.channelNameField = uitextarea(handles.configGrid, 'Placeholder', 'e.g. Cre, Ctrl (optional)');
handles.channelNameField.Layout.Row = 2;
handles.channelNameField.Layout.Column = 2;

% add this as Red, Green, Blue as default

% Label for Group
handles.groupLabel = uilabel(handles.configGrid, 'Text', 'Group:');
handles.groupLabel.Layout.Row = 3;
handles.groupLabel.Layout.Column = 1;
handles.groupLabel.VerticalAlignment = 'center';

% Text field for Group input
handles.groupEditField = uieditfield(handles.configGrid, 'text');
handles.groupEditField.Layout.Row = 3;
handles.groupEditField.Layout.Column = 2;
handles.groupEditField.Placeholder = 'Enter group (optional)';

% Label for Atlas Type
handles.atlasTypeLabel = uilabel(handles.configGrid, 'Text', 'Atlas Type:');
handles.atlasTypeLabel.Layout.Row = 4;
handles.atlasTypeLabel.Layout.Column = 1;
handles.atlasTypeLabel.VerticalAlignment = 'center';

% Dropdown for Atlas Type
atlasTypes = getAvailableAtlasTypes();
handles.atlasTypeDropdown = uidropdown(handles.configGrid);
handles.atlasTypeDropdown.Items = atlasTypes;
handles.atlasTypeDropdown.Value = '-- SELECT ATLAS --'; % Set default to empty
handles.atlasTypeDropdown.Layout.Row = 4;
handles.atlasTypeDropdown.Layout.Column = 2;

handles.atlasValid = false; % Start as invalid

% status bar

% --- Status Panel (Row 4)
statusNames = {'FIJI Coordinates', 'AP_histology', 'VOL3D volume'};
handles.statusGrid = uigridlayout(handles.uiLeftRight, [1, numel(statusNames)]);
handles.statusGrid.Layout.Row = 2;
handles.statusGrid.Layout.Column = 1;
handles.statusGrid.ColumnWidth = repmat({'1x'}, 1, numel(statusNames));
handles.statusGrid.Padding = [5 5 5 5];
handles.statusGrid.BackgroundColor = handles.colors.lightBg;

handles.statusPanels = gobjects(1, numel(statusNames));
handles.statusLabels = gobjects(1, numel(statusNames));

for i = 1:numel(statusNames)
    handles.statusPanels(i) = uipanel(handles.statusGrid, ...
        'Title', statusNames{i}, ...
        'FontWeight', 'bold');
    handles.statusPanels(i).Layout.Row = 1;
    handles.statusPanels(i).Layout.Column = i;

    % Add centered label inside each panel
    panelLayout = uigridlayout(handles.statusPanels(i), [1, 1]);
    panelLayout.RowHeight = {'1x'};
    panelLayout.ColumnWidth = {'1x'};
    panelLayout.Padding = [0 0 0 0];

    handles.statusLabels(i) = uilabel(panelLayout, ...
        'Text', 'Not available', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'center', ...
        'BackgroundColor', handles.colors.warningColor, ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'FontColor', handles.colors.gunmetal);
end

%----- Buttons Row

% Create a horizontal layout inside Row 4, Column 2
handles.buttonGrid = uigridlayout(handles.uiLeftRight, [2, 3]);
handles.buttonGrid.Layout.Row = 3;
handles.buttonGrid.Layout.Column = 1;
handles.buttonGrid.RowHeight = {'1x', '1x'};
handles.buttonGrid.ColumnWidth = {'1x', '1x', '1x'};
handles.buttonGrid.Padding = [0 0 0 0];

handles.btnAPHistology = uibutton(handles.buttonGrid, 'Text', 'Run AP_histology', ...
    'Enable', 'off', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', handles.colors.white);
handles.btnAPHistology.Layout.Row = 1;
handles.btnAPHistology.Layout.Column = 1;


handles.btnRun = uibutton(handles.buttonGrid, 'Text', 'Create 3D Volume in CCF', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontWeight','Bold', ...
    'FontColor', handles.colors.white, ...
    'Enable', 'off');

handles.btnRun.Layout.Row = 1;
handles.btnRun.Layout.Column = 3;

% ---- button row 2

%======= add save coords to diff folder button
subGrid = uigridlayout(handles.buttonGrid);
subGrid.RowHeight = {'1x', '3x'};
subGrid.ColumnWidth = {'1x', '1x', '1x'};
subGrid.Layout.Row = 2;  % Place it in the second row of the parent grid
subGrid.Layout.Column = [1 3];  % Span all three columns of the parent grid
subGrid.Padding = [0 0 0 0];

% save to additional folder
header1 = uilabel(subGrid, 'Text', 'Save to Additional Folder', 'HorizontalAlignment', 'left');
header1.Layout.Row = 1;
header1.Layout.Column = 1;  % Span all three columns for the header

handles.btnSaveAdditional = uibutton(subGrid, 'Text', 'Choose folder...', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.white, ...
    'Enable', 'off');
handles.btnSaveAdditional.Layout.Row = 2;
handles.btnSaveAdditional.Layout.Column = 1;

%flip dropdown
header2 = uilabel(subGrid, 'Text', 'Flip to Hemisphere', 'HorizontalAlignment', 'left');
header2.Layout.Row = 1;
header2.Layout.Column = 2;

handles.flipDropdown = uidropdown(subGrid, 'Items', {'None', 'Left', 'Right'}, 'Value', 'None', 'Enable','off');
handles.flipDropdown.Layout.Row = 2;
handles.flipDropdown.Layout.Column = 2;

% Dropdown for 'Color By'
header3 = uilabel(subGrid, 'Text', 'Color Volume By', 'HorizontalAlignment', 'left');
header3.Layout.Row = 1;
header3.Layout.Column = 3;

handles.colorDropdown = uidropdown(subGrid, 'Items', {'Channel'}, 'Value', 'Channel', 'Enable', 'off');
handles.colorDropdown.Layout.Row = 2;
handles.colorDropdown.Layout.Column = 3;

%--- message box
handles.msgLabelLayout = uigridlayout(handles.uiLeftRight, [1, 1]); % One row, two columns
handles.msgLabelLayout.ColumnWidth = {'1x'};
handles.msgLabelLayout.Layout.Row = 4;
handles.msgLabelLayout.Padding = [0 0 0 0]; % No padding

handles.msgPanel = uipanel(handles.msgLabelLayout, 'Title', 'Status', ...
    'BorderType', 'line', ...
    'HighlightColor', handles.colors.charcoal,  ...
    'BackgroundColor', handles.colors.white);          % #3C7A89 (Cerulean)
handles.msgPanel.Layout.Column = 1;

handles.msgLayout = uigridlayout(handles.msgPanel, [1, 1]); % One cell grid layout
handles.msgLayout.RowHeight = {'1x'};
handles.msgLayout.ColumnWidth = {'1x'};
handles.msgLayout.Padding = [0 0 0 0];  % No padding

handles.msgLabel = uilabel(handles.msgLayout, ...
    'Text', 'No errors in the setup', ...
    'FontWeight', 'bold', ...
    'FontSize', 13, ...
    'HorizontalAlignment', 'center', ...  % Center horizontally
    'VerticalAlignment', 'center', ...  % Center vertically
    'FontColor', handles.colors.charcoal, ...
    'BackgroundColor', handles.colors.white, ...
    'WordWrap', 'on');

% --------- RIGHT SIDE AXES FOR PLOTTING
handles.rightPanel = uipanel(handles.mainLayout, ...
    'BorderType','none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

handles.rightPanel.Layout.Row = 1;
handles.rightPanel.Layout.Column = 2;

handles.rightLayout = uigridlayout(handles.rightPanel, [4, 1]);
handles.rightLayout.RowHeight = {40, 50,'1x', 50};
handles.rightLayout.Padding = [10 20 10 10];


%----- Header
%----- Row 1: Right Header (renamed from headerPanel to rightHeader)
handles.rightHeader = uipanel(handles.rightLayout, 'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

handles.rightHeader.Layout.Row = 1;  % Assign to first row of rightLayout

handles.rightHeaderLayout = uigridlayout(handles.rightHeader, [1, 1]);
handles.rightHeaderLayout.Padding = [10 5 10 5];
handles.rightHeaderLayout.BackgroundColor = handles.colors.charcoal;

uilabel(handles.rightHeaderLayout, 'Text', 'CCF Coordinates Plot', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...
    'BackgroundColor', handles.colors.charcoal);

% ---- Row 2 View Buttons
handles.viewControlGrid = uigridlayout(handles.rightLayout, [1, 3]); % One row, three columns for buttons
handles.viewControlGrid.Layout.Row = 2;  % Assign to second row
% Define buttons

handles.btnSideView = uibutton(handles.viewControlGrid, 'Text', 'Side View');
handles.btnTopView = uibutton(handles.viewControlGrid, 'Text', 'Top View');
handles.btnFrontView = uibutton(handles.viewControlGrid, 'Text', 'Frontal View');

% Distribute buttons equally
handles.btnSideView.Layout.Column = 1;
handles.btnTopView.Layout.Column = 2;
handles.btnFrontView.Layout.Column = 3;

%----- Row 3: Axes (plot area)
handles.ax = uiaxes(handles.rightLayout);
handles.ax.Layout.Row = 3;
handles.ax.XColor = handles.colors.charcoal;  % Axis text/lines
handles.ax.YColor = handles.colors.charcoal;
handles.ax.ZColor = handles.colors.charcoal;

xlabel(handles.ax, 'X (ML)');
ylabel(handles.ax, 'Y (DV)');
zlabel(handles.ax, 'Z (AP)');

view(handles.ax, 90, 90); %default: set to top view

%----- Row 3: Button
handles.bottomControlGrid = uigridlayout(handles.rightLayout, [1, 3]);
handles.bottomControlGrid.Layout.Row = 4;
handles.bottomControlGrid.ColumnWidth = {'1x', '1x','1x'};
handles.bottomControlGrid.Padding = [0 0 0 0];  % no padding for tight fit

% define pallette button
handles.btnCustomPalette = uibutton(handles.bottomControlGrid, 'Text', 'Define Color Palette', ...
    'Enable', 'off');
handles.btnCustomPalette.Layout.Row = 1;
handles.btnCustomPalette.Layout.Column = 1;

% Update button
handles.btnUpdatePlot = uibutton(handles.bottomControlGrid, 'Text', 'Update Plot', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.gunmetal, ...
    'FontWeight', 'bold', ...
    'Enable', 'off');
handles.btnUpdatePlot.Layout.Row = 1;
handles.btnUpdatePlot.Layout.Column = 2;

% save Current view
handles.btnSavePreview = uibutton(handles.bottomControlGrid, ...
    'Text', 'Save Plot', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'Enable', 'off');
handles.btnSavePreview.Layout.Row = 1;
handles.btnSavePreview.Layout.Column = 3;


% trigger all events here
updateTiffList(handles.baseDir, handles);
tifFiles = dir(fullfile(handles.baseDir, '*.tif'));
if isempty(tifFiles)
    handles.msgLabel.Text = 'No TIF files found. Please choose another folder.';
    handles.msgLabel.FontColor = handles.colors.errorRed;
else
    checkChannelAvailability(handles);
    handles = updateStatusPanels(handles);
end

handles = LoadInjVol(handles); %load InjVOl if already existing
guidata(handles.fig, handles);  % store updated struct

% Set callbacks after initialization
handles.browseButton.ButtonPushedFcn = @(btn, event) ...
    guidata(btn, browseForFolder(guidata(btn)));
handles.btnHelp.ButtonPushedFcn = @(btn,event) openHelpDialog();

handles.atlasTypeDropdown.ValueChangedFcn = @(src,event) guidata(src, validateAtlasSelection(guidata(src)));
handles.btnAPHistology.ButtonPushedFcn = @(btn, event) guidata(btn, launchAPHistology(guidata(btn)));
handles.btnRun.ButtonPushedFcn = @(btn, event) ...
    runVOL3DTransformation(guidata(btn), getSelectedChannels(guidata(btn)));
handles.btnCustomPalette.ButtonPushedFcn = @(src,evt) openPaletteEditor(guidata(src));
handles.btnUpdatePlot.ButtonPushedFcn = @(src, event) guidata(src, updatePlot(guidata(src)));
handles.btnSavePreview.ButtonPushedFcn = @(btn, event) saveCurrentPlot(guidata(btn));
handles.btnSideView.ButtonPushedFcn = @(btn,event) view(handles.ax, 0, 0);
handles.btnTopView.ButtonPushedFcn = @(btn,event) view(handles.ax, 90, 90);
handles.btnFrontView.ButtonPushedFcn = @(btn,event) view(handles.ax, -90, 0);
handles.btnSaveAdditional.ButtonPushedFcn = @(btn, event) guidata(btn, saveCCFToAdditionalFolder(guidata(btn)));

% Update plot if data exists
if isfield(handles, 'volume') && ~isempty(handles.volume)
    guidata(handles.fig, handles);
    updatePlot(handles);
end

handles = validateAtlasSelection(handles);
guidata(handles.fig, handles);


end

%% GUI setup helper functions

function handles = browseForFolder(handles);
    folder_name = uigetdir();
    if folder_name ~= 0
        handles.baseDir = folder_name;
        updateTiffList(folder_name, handles);

        tifFiles = dir(fullfile(folder_name, '*.tif'));
        if isempty(tifFiles)
            handles.msgLabel.Text = 'No TIF files found in folder. Please choose another one.';
            handles.msgLabel.FontColor = handles.colors.errorRed;
        else
            handles = LoadInjVol(handles); % <- reloads CCF if present
            checkChannelAvailability(handles);
            handles = updateStatusPanels(handles); % <- calls updatePlotControlsAvailability
            updatePlot(handles); % <- optional, plot automatically
        end

        guidata(handles.fig, handles);  % <- Save updated handles!
        cd(folder_name); % not critical, but keeps file dialogs consistent
    end

end


function updateTiffList(folderPath, handles)
% Find TIFF files in the specified folder, considering common TIFF extensions
tiffFiles = dir(fullfile(folderPath, '*.tif'));

if isempty(tiffFiles)
    handles.tiffListBox.Data = {'Empty'};
    handles.msgLabel.Text = 'No TIF files found! Select another folder containing tif files.';
    handles.msgLabel.FontColor = handles.colors.warningColor;
else
    % Extract file names and populate the table
    handles.tiffListBox.Data = {tiffFiles.name}';
    handles.msgLabel.Text = 'TIF Files loaded successfully';
    handles.msgLabel.FontColor = handles.colors.charcoal;
end
end

function checkChannelAvailability(handles)
% Define the subfolder path for CSV files
csvFolderPath = fullfile(handles.baseDir, 'VOL\CSV');

% Check if the CSV folder exists
if ~exist(csvFolderPath, 'dir')
    handles.msgLabel.Text = sprintf('CSV subfolder does not exist in the specified directory: \n%s', csvFolderPath);
    handles.msgLabel.FontColor = handles.colors.errorRed;
end

% Get a list of CSV files in the folder
csvFiles = dir(fullfile(csvFolderPath, '*.csv'));
csvFileNames = {csvFiles.name};

% Determine available channels based on file names
channels = {'C1', 'C2', 'C3', 'C4'};
channelAvailable = false(1, length(channels)); % Initialize availability array

for i = 1:length(channels)
    % Check for each channel if there is a corresponding file
    pattern = sprintf('%s_*', channels{i}); % e.g., 'C1_*'
    match = any(~cellfun(@isempty, regexp(csvFileNames, pattern)));
    channelAvailable(i) = match;

    % Enable/disable the checkbox based on file presence
    handles.channelCheckboxes(i).Enable = 'on';
    handles.channelCheckboxes(i).Value = true;
    if ~match
        handles.channelCheckboxes(i).Enable = 'off';
        handles.channelCheckboxes(i).Value = false;
    end
end
end

function channels = getSelectedChannels(handles)
channelNames = {'C1', 'C2', 'C3', 'C4'};
selectedIdx = arrayfun(@(cb) cb.Value, handles.channelCheckboxes);
channels = channelNames(selectedIdx);
end

function atlasTypes = getAvailableAtlasTypes()
% Locate AP_histology path
ap_histology_path = which('AP_histology');
if isempty(ap_histology_path)
    error('AP_histology.m not found in MATLAB path.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Check for the existence of the atlas settings file
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');
if ~exist(atlas_settings_path, 'file')
    error('atlas_paths.mat not found. Please run save_atlas_paths.m first.');
end

% Load available templates from atlas settings
load(atlas_settings_path, 'templates');

% Extract and return all available atlas types
 atlasTypes = ['-- SELECT ATLAS --'; fieldnames(templates)];
end



function handles = updateStatusPanels(handles)
    status = checkProcessingSteps(handles.baseDir);

    % Match status field names to order in GUI
    keys = {'fiji', 'aphist', 'vol3d'};
    for i = 1:numel(keys)
        key = keys{i};
        val = status.(key);
        label = handles.statusLabels(i);

        % General handler for enriched status information
        if val == "available"
            % Get additional context information if available
            extraInfoFields = setdiff(fieldnames(status), keys);
            matchedExtras = startsWith(extraInfoFields, key);
            infoToShow = '';
            
            for ef = extraInfoFields(matchedExtras)'
                valExtra = status.(ef{1});
                if iscell(valExtra)
                    infoToShow = strjoin(valExtra, ' | ');
                elseif isstring(valExtra) || ischar(valExtra)
                    infoToShow = valExtra;
                end
            end

            % Set label text and styling
            if ~isempty(infoToShow)
                label.Text = ['Done (', infoToShow, ')'];
            else
                label.Text = 'Done';
            end
            label.BackgroundColor = handles.colors.statusSuccess;
            label.FontColor = handles.colors.statusTextLight;

        elseif val == "in_progress"
            label.Text = 'In Process';
            label.BackgroundColor = handles.colors.statusWarning;
            label.FontColor = handles.colors.statusTextDark;

        elseif val == "not_started"
            label.Text = 'Not Started';
            label.BackgroundColor = handles.colors.statusNotDone;
            label.FontColor = handles.colors.statusTextDark;

        else % "not_available"
            label.Text = 'Not Available';
            label.BackgroundColor = handles.colors.statusError;
            label.FontColor = handles.colors.statusTextLight;
        end
    end

    updatePlotControlsAvailability(handles, status);
    
    % Update color dropdown if CCF data exists
    if strcmp(status.vol3d, "available") && isfield(handles, 'volume')
        handles = updateColorDropdown(handles);
        guidata(handles.fig, handles); % Save the updated handles
    end
end

function status = checkProcessingSteps(baseDir)
    status = struct();

    % --- 0. Check for base TIF files ---
    tifFiles = dir(fullfile(baseDir, '*.tif'));
    status.tifs = "not_available";
    if ~isempty(tifFiles)
        status.tifs = "available";
    end

    % --- 1. FIJI Coordinates ---
    csvDir = fullfile(baseDir, 'VOL\CSV');
    status.fiji = "not_available"; % default
    
    if isfolder(csvDir)
        processedChannels = {};
        for c = 1:4
            pattern = sprintf('C%d_*.csv', c);
            if ~isempty(dir(fullfile(csvDir, pattern)))
                processedChannels{end+1} = sprintf('C%d', c);
            end
        end
        
        if ~isempty(processedChannels)
            status.fiji = "available";
            status.fiji_channels = processedChannels;
        else
            status.fiji = "not_started"; % CSV folder exists but no files
        end
    end

    % --- 2. AP Histology ---
    outDir = fullfile(baseDir, 'OUT');
    status.aphist = "not_available"; % default
    
    % Check if AP histology is installed (basic check)
    if ~exist('AP_histology', 'file')
        status.aphist = "not_available";
    elseif isfolder(outDir)
        histologyFiles = dir(fullfile(outDir, 'atlas2histology_*tform.mat'));
        intermediateTifs = dir(fullfile(outDir, 'slice_*.tif'));
        
        if ~isempty(histologyFiles)
            status.aphist = "available";
            atlasTypes = {};
            
            for f = 1:length(histologyFiles)
                tokens = regexp(histologyFiles(f).name, 'atlas2histology_([^_]+)?tform\.mat', 'tokens');
                if ~isempty(tokens)
                    match = tokens{1}{1};
                    if isempty(match)
                        atlasTypes{end+1} = 'adult';
                    else
                        atlasTypes{end+1} = match;
                    end
                end
            end
            
            if ~isempty(atlasTypes)
                status.aphist_atlas = strjoin(unique(atlasTypes), ' | ');
            end
            
        elseif ~isempty(intermediateTifs)
            status.aphist = "in_progress";
        elseif status.tifs == "available"
            status.aphist = "not_started"; % TIFs exist but no processing started
        end
    elseif status.tifs == "available"
        status.aphist = "not_started"; % TIFs exist but OUT folder doesn't
    end

  
    % --- 4. vol3d Coordinates ---
    [~, name] = fileparts(baseDir);
    ccfDir = fullfile(baseDir, 'OUT', 'CCF');
    status.vol3d = "not_available"; % default
    
    % Check if AP histology is complete first
    if strcmp(status.aphist, "available")
        if isfolder(ccfDir)
            coordFiles = dir(fullfile(ccfDir, [name, '_volume*.mat']));
            if ~isempty(coordFiles)
                status.vol3d = "available";
                % Extract atlas type
                tokens = regexp(coordFiles(1).name, '_volume(.*)\.mat', 'tokens');
                if ~isempty(tokens)
                    status.vol3d_atlas = tokens{1}{1};
                end
            else
                status.vol3d = "not_started"; % CCF folder exists but no files
            end
        else
            status.vol3d = "not_started"; % AP hist done but no CCF folder
        end
    end
end

function handles = validateAtlasSelection(handles)
    % Check if a valid atlas is selected (not the placeholder)
    selectedAtlas = handles.atlasTypeDropdown.Value;
    handles.atlasValid = ~strcmp(selectedAtlas, '-- SELECT ATLAS --');
    
    % Update button states
    status = checkProcessingSteps(handles.baseDir);
    updatePlotControlsAvailability(handles, status);
    
    % Update status message
    if handles.atlasValid
        handles.msgLabel.Text = ['Selected atlas: ' selectedAtlas];
        handles.msgLabel.FontColor = handles.colors.charcoal;
    else
        handles.msgLabel.Text = 'Please select a valid atlas type before proceeding.';
        handles.msgLabel.FontColor = handles.colors.warningColor;
    end
end


function handles = LoadInjVol(handles)
% Store current selection if it exists
if isfield(handles, 'colorDropdown') && isvalid(handles.colorDropdown)
    currentSelection = handles.colorDropdown.Value;
else
    currentSelection = 'Animal';
end

% Look for CCF summary in OUT/CCF
ccfDir = fullfile(handles.baseDir, 'OUT', 'CCF');
if ~isfolder(ccfDir), return; end

[~, name] = fileparts(handles.baseDir);
ccfFiles = dir(fullfile(ccfDir, [name, '_volume*.mat']));
if isempty(ccfFiles), return; end

try
    loaded = load(fullfile(ccfDir, ccfFiles(1).name));
    
    % Load injection volume
    if isfield(loaded, 'volume')
        handles.volume = loaded.volume;

        % Try pushing channel names into text field
        if isfield(loaded.volume, 'ChannelName')
            chanNames = string({loaded.volume.ChannelName});
            handles.channelNameField.Value = strjoin(chanNames, ', ');
        end

        % Try pushing group name into group field (if all same)
        if isfield(loaded, 'Group')
            handles.groupEditField.Value = loaded.Group;
        end
    end
    
    % Set atlas if stored
    if isfield(loaded, 'atlasType')
        handles.atlasType = loaded.atlasType;
        if any(strcmp(handles.atlasTypeDropdown.Items, loaded.atlasType))
            handles.atlasTypeDropdown.Value = loaded.atlasType;
            handles.atlasValid = true;
        end
    end

    % Update dropdowns and button availability
    handles = updateColorDropdown(handles);   
    updatePlotControlsAvailability(handles, checkProcessingSteps(handles.baseDir));

catch ME
    warning(sprintf('Failed to load CCF data: %s', ME.message));
end

% Restore previous dropdown selection if still valid
if isfield(handles, 'colorDropdown') && isvalid(handles.colorDropdown)
    if any(strcmp(handles.colorDropdown.Items, currentSelection))
        handles.colorDropdown.Value = currentSelection;
    else
        handles.colorDropdown.Value = 'Animal'; % fallback
    end
end

guidata(handles.fig, handles); % Save the state
end




function updatePlotControlsAvailability(handles, status)
    % Enable plot-related controls if CCF coords exist
    hasCCF = strcmp(status.vol3d, "available");

    % List of controls that depend on CCF data
    ccfControls = {handles.colorDropdown, handles.btnUpdatePlot, ...
                   handles.btnSavePreview, handles.btnCustomPalette, ...
                   handles.btnSaveAdditional, handles.flipDropdown};
    
    for i = 1:numel(ccfControls)
        if isvalid(ccfControls{i})
            ccfControls{i}.Enable = bool2onoff(hasCCF);
        end
    end


     % AP_histology requires TIFs AND valid atlas selection
    if isfield(handles, 'btnAPHistology') && isvalid(handles.btnAPHistology)
        handles.btnAPHistology.Enable = bool2onoff(...
            strcmp(status.tifs, "available") && handles.atlasValid);
    end

    % Run button requires AP_histology completion AND valid atlas
    if isfield(handles, 'btnRun') && isvalid(handles.btnRun)
        handles.btnRun.Enable = bool2onoff(...
            strcmp(status.aphist, "available") && handles.atlasValid);
    end
end

function val = bool2onoff(flag)
val = 'off';
if flag
    val = 'on';
end
end

%% Processing steps

% ------ AP Histology launch
%does not update status about process while open
function handles = launchAPHistology(handles)
% Check if atlas is valid
    if ~handles.atlasValid
        handles.msgLabel.Text = 'Please select a valid atlas type before running AP_histology.';
        handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end
handles.msgLabel.Text = sprintf([ ...
    'Loading AP_histology GUI for atlas type "%s"...\n', ...
    'Run through all steps including manual alignment of histology to atlas.\n', ...
    'Re-load the GUI after finishing.'], ...
    handles.atlasTypeDropdown.Value);
handles.msgLabel.FontColor = handles.colors.charcoal;
drawnow;  % update label before running

AP_histology(handles.atlasTypeDropdown.Value);
guidata(handles.fig, handles);
end

function runVOL3DTransformation(handles, selectedChannels)

    % Update status
    handles.msgLabel.Text = '⏳ Running VOL3D transformation...';
    atlasType = handles.atlasTypeDropdown.Value;
    drawnow;

    % Setup
    folder = handles.baseDir;
    csvDir = fullfile(folder, 'VOL', 'CSV');
    tiffFiles = dir(fullfile(folder, '*.tif'));

    if isempty(tiffFiles)
        handles.msgLabel.Text = '⚠️ No TIF files found in folder.';
        handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end

% Parse channel names from text field
rawText = strjoin(handles.channelNameField.Value, ' '); % Combine lines into one string
rawText = strtrim(rawText);

if isempty(rawText)
    % If empty, autofill with C1, C2, ...
    channelNames = arrayfun(@(i) sprintf('C%d', i), 1:numel(selectedChannels), 'UniformOutput', false);
    handles.channelNameField.Value = strjoin(channelNames, ', ');
else
    % Try splitting by comma or semicolon
    rawNames = strsplit(rawText, {',', ';'});
    rawNames = strtrim(rawNames); % Trim whitespace

    % Validate name count
    if numel(rawNames) ~= numel(selectedChannels)
            handles.msgLabel.Text = sprintf('The number of channel names (%d) does not match the number of selected channels (%d).\n\n Please separate names with commas or semicolons and ensure the count matches.', numel(rawNames), numel(selectedChannels));
            handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end
    channelNames = rawNames(1:numel(selectedChannels)); % Use only the needed names
end

    % Group name
    Group = handles.groupEditField.Value;
    Animal = getFolderName(folder);

    % Load transformation
    tformFile = fullfile(folder, 'OUT', 'atlas2histology_tform.mat');
    histFile = fullfile(folder, 'OUT', 'histology_ccf.mat');

    if ~isfile(tformFile) || ~isfile(histFile)
        handles.msgLabel.Text = '❌ Missing AP_histology output. Run AP_histology first.';
        handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end

    load(tformFile, 'atlas2histology_tform');
    load(histFile, 'histology_ccf');

    % Loop through channels and files
    volume = struct;
    for ch = 1:numel(selectedChannels)
        chan = selectedChannels{ch};
        coordCCF = [];

        for i = 1:numel(tiffFiles)
            tifname = tiffFiles(i).name;
            csvname = fullfile(csvDir, sprintf('%s_%s.csv', chan, erase(tifname, '.tif')));

            if isfile(csvname)
                tab = readtable(csvname);
                pts = [tab.X, tab.Y];

                tform = invert(affine2d(atlas2histology_tform{i}));
                [x, y] = transformPointsForward(tform, pts(:,1), pts(:,2));
                [M, N] = size(histology_ccf(i).av_slices);

                valid = x > 0 & x <= N & y > 0 & y <= M;
                idx = sub2ind([M, N], round(y(valid)), round(x(valid)));
                ccf_xyz = [histology_ccf(i).plane_ap(idx), histology_ccf(i).plane_dv(idx), histology_ccf(i).plane_ml(idx)];
                coordCCF = [coordCCF; ccf_xyz];
            end
        end

        % Make smoothed volume
        coord3D = coordCCF(:, [1 3 2]); % reorder to Z, X, Y
        [k1, f] = boundary(coord3D);


        vSmooth = laplacianSmooth(coord3D, k1, 0.1, 5);
        
        % --- Hemisphere and summary ---
        [~, ~, brain_data] = getAtlasFilesForType(atlasType);

        midline = mean([min(brain_data.brain.v(:,2)) max(brain_data.brain.v(:,2))]);
  
        hemi = "Unknown";
        
        % Logical checks
        hasLeft = any(coord3D(:,2) < midline);
        hasRight = any(coord3D(:,2) > midline);
        
        if hasLeft && ~hasRight
            hemi = "Left";
        elseif hasRight && ~hasLeft
            hemi = "Right";
        elseif hasLeft && hasRight
            hemi = "Mixed";
        end
        
        palette = getCurrentPalette(handles.baseDir);
        channelColor = palette(mod(ch-1, size(palette, 1)) + 1, :);  % cycle if more volumes than colors
        volume(ch).Animal = Animal;
        volume(ch).channels = chan;
        volume(ch).ChannelName = channelNames{ch};
        volume(ch).channelColor = channelColor;
        volume(ch).smoothedVertices = vSmooth;
        volume(ch).k1 = k1;
        volume(ch).ccf_points_cat_ord = coord3D;
        volume(ch).hemi = hemi;

    end
   

    % --- Save output ---
    savePath = fullfile(folder, 'OUT', 'CCF');
    if ~exist(savePath, 'dir'), mkdir(savePath); end
    save(fullfile(savePath, [getFolderName(folder), '_volume.mat']), 'volume','atlasType','Group','Animal');
    handles.msgLabel.Text = '✅ VOL3D transformaftion completed and saved.';
    handles.msgLabel.FontColor = handles.colors.statusSuccess;

    handles = LoadInjVol(handles);                      % Load the volume data into handles
    handles = updateStatusPanels(handles);              % Refresh the status grid visually
    guidata(handles.fig, handles);                      % Save updates to GUI
    updatePlot(handles);                                % Optionally re-plot immediately


end

function name = getFolderName(path)
    [~, name] = fileparts(path);
end

function handles = saveCCFToAdditionalFolder(handles)
    % Check if CCF file exists in the expected location
    ccfDir = fullfile(handles.baseDir, 'OUT', 'CCF');
    ccfFiles = dir(fullfile(ccfDir, '*volume*.mat'));
    
    if isempty(ccfFiles)
        handles.msgLabel.Text = 'Error: No CCF coordinate file found in OUT/CCF folder';
        handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end
    
    % Get the most recent CCF file if multiple exist
    [~, idx] = max([ccfFiles.datenum]);
    sourceFile = fullfile(ccfDir, ccfFiles(idx).name);
    
    % Ask user where to save the file
    targetDir = uigetdir(handles.baseDir, 'Select Folder to Save CCF File');
    if isequal(targetDir, 0)
        return; % User canceled
    end
    
    % Copy the file
    try
        destinationFile = fullfile(targetDir, ccfFiles(idx).name);
        copyfile(sourceFile, destinationFile);
        
        handles.msgLabel.Text = sprintf('Volume file successfully copied to:\n%s', ...
                                      destinationFile);
        handles.msgLabel.FontColor = handles.colors.successColor;
    catch ME
        handles.msgLabel.Text = sprintf('Error: File could not be copied\n%s', ME.message);
        handles.msgLabel.FontColor = handles.colors.errorRed;
    end
    
    guidata(handles.fig, handles);
end



%% plotting

function handles = updatePlot(handles)
 % Debug: Check what's actually in handles
   if ~isfield(handles, 'volume') || isempty(handles.volume)
        handles = LoadInjVol(handles); % Attempt to reload
        guidata(handles.fig, handles); % Save updates

   % Check if loading succeeded
        if ~isfield(handles, 'volume') || isempty(handles.volume)
            handles.msgLabel.Text = 'No volume data available for plotting.';
            handles.msgLabel.FontColor = handles.colors.errorRed;
            return;
        end
    end

selectedLabel = handles.colorDropdown.Value;
if strcmp(selectedLabel, 'Animal')
    colorField = '';
elseif isfield(handles, 'colorDropdownMap') && isKey(handles.colorDropdownMap, selectedLabel)
    colorField = handles.colorDropdownMap(selectedLabel);
else
    colorField = '';
end

 plotInjVolInGUI(handles);
end


function plotInjVolInGUI(handles)
    ax = handles.ax;
    colorcellsby = handles.colorDropdown.Value;
    volume = handles.volume;
    [az, el] = view(ax);


% Get flip direction safely
if isfield(handles, 'flipDropdown') && isvalid(handles.flipDropdown)
    flipDirection = handles.flipDropdown.Value;
elseif isfield(handles, 'flipDirection')
    flipDirection = handles.flipDirection;
else
    flipDirection = 'none';
end


    % Load brain mesh (outline)
    [~, ~, brain_data] = getAtlasFilesForType(handles.atlasTypeDropdown.Value);
    v = brain_data.brain.v;
    f = brain_data.brain.f;


    % Clear previous contents
    cla(ax);
    legend(ax, 'off');
    colorbar(ax, 'off');

    % Plot brain outline
    patch(ax, 'Vertices', v, 'Faces', f, 'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
    hold(ax, 'on');



% Hemisphere flipping setup
flipToRight = strcmp(flipDirection, 'Right');
flipToLeft = strcmp(flipDirection, 'Left');
midline = mean([min(brain_data.brain.v(:,2)) max(brain_data.brain.v(:,2))]);

% Determine which column to use
switch lower(colorcellsby)
    case 'channel', categoryCol = 'ChannelName';
    case 'group', categoryCol = 'GroupName';
    case 'hemisphere', categoryCol = 'hemi';
    case 'animal', categoryCol = 'Animal';
    otherwise, categoryCol = '';
end

% Load color palette
palette = getCurrentPalette(handles.baseDir);

% Assign unique categories based on dropdown
if ~isempty(categoryCol) && isfield(volume, categoryCol)
    categoryValues = arrayfun(@(v) string(getfield(v, categoryCol)), volume, 'UniformOutput', true);
    [uniqueCats, ~, catIdx] = unique(categoryValues);
    nColors = size(palette, 1);
    colors = palette(mod(0:numel(uniqueCats)-1, nColors)+1, :);
else
    % fallback if no valid category found
    catIdx = 1:numel(volume);
    colors = palette(mod(0:numel(volume)-1, size(palette,1)) + 1, :);
    uniqueCats = {};
end

  % Initialize
patch_handles = gobjects(0);
legends = {};

for j = 1:length(volume)
    vol = volume(j);

    % Flip vol if selected
    if flipToRight
        flip_idx = vol.ccf_points_cat_ord(:,2) < midline;
        vol.ccf_points_cat_ord(flip_idx,2) = 2 * midline - vol.ccf_points_cat_ord(flip_idx,2);

        flip_idx = vol.smoothedVertices(:,2) < midline;
        vol.smoothedVertices(flip_idx,2) = 2 * midline - vol.smoothedVertices(flip_idx,2);

    elseif flipToLeft
        flip_idx = vol.ccf_points_cat_ord(:,2) > midline;
        vol.ccf_points_cat_ord(flip_idx,2) = 2 * midline - vol.ccf_points_cat_ord(flip_idx,2);

        flip_idx = vol.smoothedVertices(:,2) > midline;
        vol.smoothedVertices(flip_idx,2) = 2 * midline - vol.smoothedVertices(flip_idx,2);
    end

    % Assign color and label
    color = colors(catIdx(j), :);
    label = categoryValues{j};

    % Plot patch
    h = patch(ax, 'Vertices', vol.smoothedVertices, 'Faces', vol.k1, ...
        'FaceColor', color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Add to legend only if label is new
    if ~any(strcmp(legends, label))
        legends{end+1} = label;
        patch_handles(end+1) = h;
        h.DisplayName = label;
    else
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end
end

   % Add legend if meaningful
if ~isempty(legends)
    hLeg = legend(ax, patch_handles, legends, 'Location', 'southoutside');
    hLeg.Box = 'off';
    hLeg.FontSize = 7;
    hLeg.ItemTokenSize = [10, 8];
    if numel(legends) >= 12
        hLeg.NumColumns = ceil(numel(legends)/10);
        hLeg.FontSize = 5;
    elseif numel(legends) >= 6
        hLeg.NumColumns = 4;
    else
        hLeg.NumColumns = numel(legends);
    end
end

    % Final styling
    axis(ax, 'equal');
    axis(ax, 'off');
    set(ax, 'ZDir', 'reverse');
    view(ax, az, el);
    hold(ax, 'off');
end

function smoothedVertices = laplacianSmooth(vertices, faces, lambda, iterations)
    % vertices: Nx3 matrix of vertex coordinates
    % faces: Mx3 matrix of indices into vertices
    % lambda: Smoothing factor, typical values are in the range 0.5 - 1
    % iterations: Number of times the smoothing operation is applied

    smoothedVertices = vertices;
    for iter = 1:iterations
        for i = 1:size(vertices, 1)
            % Find all faces that include this vertex
            [row, ~] = find(faces == i);
            % Get unique vertices connected to the current vertex
            neighborIdx = unique(faces(row, :));
            neighborIdx(neighborIdx == i) = [];  % Remove the vertex itself

            % Calculate the mean position of neighboring vertices
            meanPos = mean(smoothedVertices(neighborIdx, :), 1);

            % Update the vertex position
            smoothedVertices(i, :) = smoothedVertices(i, :) + lambda * (meanPos - smoothedVertices(i, :));
        end
    end
end

%% plotting helper

function saveCurrentPlot(handles)
    % Prompt user to choose where to save
    [file, path] = uiputfile({'*.png'; '*.fig'}, 'Save Plot As', fullfile(handles.baseDir, 'VOL_plot.png'));
    if isequal(file, 0)
        return;  % User canceled
    end

    % Get full file path and strip extension
    [~, name, ~] = fileparts(file);
    pngPath = fullfile(path, [name, '.png']);
    figPath = fullfile(path, [name, '.fig']);

    % Save .png with good resolution
    exportgraphics(handles.ax, pngPath, 'Resolution', 300);

    % Save .fig for future edits
    f = figure();
    copyobj(handles.ax, f);
    savefig(f, figPath);
    close(f);

    % Optional feedback
    handles.msgLabel.Text = sprintf('Plot saved as:\n%s\n%s', pngPath, figPath);
    handles.msgLabel.FontColor = handles.colors.successColor;
end


function [atlas_files, atlas_base_dir, brain_data] = getAtlasFilesForType(atlasType)
% getAtlasFilesForType - Load atlas files, base dir, and brain hull (with midline) for a given atlasType

% Locate AP_histology path
ap_histology_path = which('AP_histology');
if isempty(ap_histology_path)
    error('AP_histology.m not found in MATLAB path.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Load atlas templates
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');
if ~exist(atlas_settings_path, 'file')
    error('atlas_paths.mat not found. Run save_atlas_paths.m first.');
end
load(atlas_settings_path, 'templates');

% Validate atlasType
if ~isfield(templates, atlasType)
    error('Atlas type "%s" not found. Available: %s', ...
        atlasType, strjoin(fieldnames(templates), ', '));
end
atlas_files = templates.(atlasType);

% Determine atlas base directory
if strcmp(atlasType, 'adult')
    atlas_base_dir = fullfile(ap_histology_dir, 'allenAtlas');
else
    atlas_base_dir = fullfile(ap_histology_dir, 'devAtlas');
end

% Load brain hull .mat (includes .v, .f, and .midline)
brain_path = fullfile(atlas_base_dir, atlas_files.brain);
if ~exist(brain_path, 'file')
    error('Brain hull file not found: %s', brain_path);
end
brain_data = load(brain_path);  % should include fields like brain.v, brain.f, brain.midline
end

function [tv, av, st] = load_atlas_files(atlasType)

% Default to 'adult' if atlasType is empty
if isempty(atlasType)
    atlasType = 'adult';
end

% Get the directory where AP_histology.m is located
ap_histology_path = which('AP_histology'); % Find the function file
if isempty(ap_histology_path)
    error('AP_histology.m not found in the MATLAB path. Ensure it is accessible.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Define the path for the atlas settings file
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');

% Check if the atlas paths file exists
if exist(atlas_settings_path, 'file')
    load(atlas_settings_path, 'templates');
else
    error('Atlas settings file not found! Run `save_atlas_paths.m` to generate it.');
end

% Validate the atlas type
if ~isfield(templates, atlasType)
    error('Atlas type "%s" not found. Available options: %s', atlasType, strjoin(fieldnames(templates), ', '));
end

% Get the paths for the selected atlas
atlas_files = templates.(atlasType);

% Determine the correct base directory for atlas files
if strcmp(atlasType, 'adult')
    atlas_base_dir = fullfile(ap_histology_dir, 'allenAtlas');
else
    atlas_base_dir = fullfile(ap_histology_dir, 'devAtlas');
end

% Build full paths for each atlas file
template_path = fullfile(atlas_base_dir, atlas_files.template);
annotation_path = fullfile(atlas_base_dir, atlas_files.annotation);
structure_tree_path = fullfile(atlas_base_dir, atlas_files.structure_tree);

% Debug: Print the full paths of the files being loaded
fprintf('Loading template from: %s\n', template_path);
fprintf('Loading annotation from: %s\n', annotation_path);
fprintf('Loading structure tree from: %s\n', structure_tree_path);

% Load atlas files
tv = readNPY(template_path);
av = readNPY(annotation_path);
st = loadStructureTree(structure_tree_path);
% Display confirmation message
fprintf('Atlas files for "%s" loaded successfully.\n', atlasType);
end

function palette = getCurrentPalette(baseDir)
% Check for custom palette file
paletteFile = fullfile(baseDir, 'OUT', 'customPalette.mat');

if exist(paletteFile, 'file')
    % Load custom palette
    load(paletteFile, 'palette');
else
    % Use default palette (linspecer or any other default)
    palette = linspecer(8); % Default to 8 colors
end
end

function openPaletteEditor(handles)
fig = uifigure('Name', 'Color Palette Editor', 'Position', [100 100 600 200]);
outDir = fullfile(handles.baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Load or initialize palette
paletteFile = fullfile(handles.baseDir, 'OUT', 'customPalette.mat');
if exist(paletteFile, 'file')
    load(paletteFile, 'palette');
else
    palette = linspecer(6); % Default to 6 colors
end

% Main grid layout
mainGrid = uigridlayout(fig, [2 1]);
mainGrid.RowHeight = {120, 40};
mainGrid.Padding = [20 20 20 20];

swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
swatchGrid.Layout.Row = 1;
swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));

colorButtons = gobjects(size(palette,1), 1);
for i = 1:size(palette,1)
    colorButtons(i) = uibutton(swatchGrid);
    colorButtons(i).BackgroundColor = palette(i,:);
    colorButtons(i).Text = '';
    colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
end

controlGrid = uigridlayout(mainGrid, [1 4]);
controlGrid.Layout.Row = 2;

btnAdd = uibutton(controlGrid, 'Text', '＋ Add Color', 'ButtonPushedFcn', @addColor);
btnRemove = uibutton(controlGrid, 'Text', '－ Remove Color', 'ButtonPushedFcn', @removeColor);
btnReset = uibutton(controlGrid, 'Text', '↻ Reset to Default', 'ButtonPushedFcn', @resetDefault);
btnSave = uibutton(controlGrid, 'Text', '💾 Save for Usage', 'ButtonPushedFcn', @savePalette);

    function changeColor(idx)
        newColor = uisetcolor(palette(idx,:));
        if ~isequal(newColor, 0)
            palette(idx,:) = newColor;
            colorButtons(idx).BackgroundColor = newColor;
        end
    end

    function addColor(~,~)
        palette = [palette; rand(1,3)];
        updateSwatches();
    end

    function removeColor(~,~)
        if size(palette,1) > 1
            palette(end,:) = [];
            updateSwatches();
        end
    end

    function resetDefault(~,~)
        palette = linspecer(6);
        updateSwatches();
    end

    function savePalette(~,~)
        save(paletteFile, 'palette');
        uialert(fig, 'Palette saved successfully!', 'Success', 'Icon', 'success');
    end

    function updateSwatches()
        delete(swatchGrid.Children);
        swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
        swatchGrid.Layout.Row = 1;
        swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
        colorButtons = gobjects(size(palette,1), 1);
        for i = 1:size(palette,1)
            colorButtons(i) = uibutton(swatchGrid);
            colorButtons(i).BackgroundColor = palette(i,:);
            colorButtons(i).Text = '';
            colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
        end
    end
end

function handles = updateColorDropdown(handles)
% Define manually which fields can be used for coloring
customOptions = {
    'Animal', 'Animal';
    'Channel', 'ChannelName';
%     'Group', 'GroupName';
    'Hemisphere', 'hemi'
};

% Validate that volume exists
if ~isfield(handles, 'volume') || isempty(handles.volume)
    handles.colorDropdown.Items = {'Animal'};
    handles.colorDropdown.Value = 'Animal';
    handles.colorDropdown.Enable = 'off';
    return;
end

% Determine which of these fields actually exist in volume
validOptions = {};
validKeys = {};
for i = 1:size(customOptions,1)
    prettyName = customOptions{i,1};
    fieldName = customOptions{i,2};

    hasField = all(arrayfun(@(v) isfield(v, fieldName), handles.volume));
    nonEmptyField = any(arrayfun(@(v) ~isempty(getfield(v, fieldName)), handles.volume));
    
    if hasField && nonEmptyField
        validOptions{end+1} = prettyName; %#ok<AGROW>
        validKeys{end+1} = fieldName; %#ok<AGROW>
    end
end


% Always include "Animal" as fallback
if isempty(validOptions)
    validOptions = {'Animal'};
    validKeys = {'Animal'};
end

% Create mapping
handles.colorDropdown.Items = validOptions;
handles.colorDropdown.Value = validOptions{1}; % default
handles.colorDropdownMap = containers.Map(validOptions, validKeys);
handles.colorDropdown.Enable = 'on';
end



function allPresent = checkDependencies()
% checkDependencies - Verifies required toolboxes and functions are present

allPresent = true;
missing = {};

% Required Toolboxes
reqToolboxes = {
    'Image Processing Toolbox', ...
    'MATLAB'  % Base MATLAB
};

v = ver;
installedToolboxes = {v.Name};

for i = 1:length(reqToolboxes)
    if ~any(strcmp(reqToolboxes{i}, installedToolboxes))
        warning('Missing toolbox: %s', reqToolboxes{i});
        missing{end+1} = reqToolboxes{i};
    end
end

% Required Functions (add more if needed)
requiredFunctions = {
    'AP_histology', ...
    'readNPY', ...
    'loadStructureTree', ...
    'linspecer', ...
    'inpolyhedron'
};

for i = 1:length(requiredFunctions)
    if isempty(which(requiredFunctions{i}))
        warning('Missing required function: %s', requiredFunctions{i});
        missing{end+1} = requiredFunctions{i};
    end
end

% Final status
if ~isempty(missing)
    allPresent = false;
    msg = sprintf('Missing dependencies:\n- %s', strjoin(missing, '\n- '));
    errordlg(msg, 'Missing Dependencies');
end

end

function openHelpDialog()
% Create a uifigure for the help dialog
helpFig = uifigure('Name', 'VOL3D Step 1 (Animal) - Help', 'Position', [100 100 700 660]);
helpFig.Resize = 'off';
helpFig.Color = [0.96 0.96 0.96]; % Match GUI's lightBg color

% Create a panel that will contain the text control
helpPanel = uipanel(helpFig, 'Position', [10 10 680 640], 'BorderType', 'none');
helpPanel.BackgroundColor = [1 1 1]; % White background
helpPanel.HighlightColor = [0.24 0.48 0.54]; % Cerulean border

% Define help text sections
header = '<html><body style="font-family:Arial; font-size:12px; color:#16262E; line-height:1.6;">';

section1 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">📁 Folder and File Setup</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li><b>📂 Change Folder:</b> Set the working directory for processing volumes</li>'...
'<li><b>🧬 Channel Selection:</b> Select available channels (C1–C4) with optional naming</li>'...
'<li><b>🔠 Group & Atlas:</b> Enter group name and choose atlas type for transformation</li>'...
'</ul>'...
'</div>'...
];


section2 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">🧪 Preprocessing and Transformation</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li><b>🧭 Run AP_histology:</b> Align histology slices to atlas</li>'...
'<li><b>🧱 Create 3D Volume:</b> Map CSV coordinates into CCF space and generate surface mesh</li>'...
'<li><b>🧠 Atlas Selection:</b> Required for any transformation step</li>'...
'</ul>'...
'</div>'...
];

section3 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">🎨 Visualization Controls</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li><b>🔁 Flip Hemisphere:</b> Mirror the injection volume to Left/Right</li>'...
'<li><b>🎨 Color Volume By:</b> Color by Channel, Hemisphere, or Animal</li>'...
'<li><b>👁️ View Controls:</b> Side, Top, Frontal Views of 3D brain</li>'...
'<li><b>🧃 Define Color Palette:</b> Custom color setup for plotting</li>'...
'</ul>'...
'</div>'...
];

section4 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">💾 Saving and Outputs</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li><b>🖼️ Save Plot:</b> Export current 3D view as PNG and FIG</li>'...
'<li><b>📁 Save to Additional Folder:</b> Export CCF volume `.mat` file to a new location</li>'...
'<li><b>🧠 Output Folder:</b> Default: <code>OUT/CCF/</code> stores transformed volumes</li>'...
'</ul>'...
'</div>'...
];


section5 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">📊 Status and Feedback</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li><b>✅ Status Panel:</b> Monitors availability of TIFF, AP_histology, and 3D volume</li>'...
'<li><b>💬 Message Box:</b> Displays feedback and errors during processing</li>'...
'</ul>'...
'</div>'...
];

section6 = [...
'<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">📚 Advanced Tips</h2>'...
'<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
'<ul>'...
'<li>Ensure consistent naming for TIFF and CSV files</li>'...
'<li>Run <code>save_atlas_paths.m</code> to add custom atlases</li>'...
'<li>Confirm that <code>atlas2histology_tform.mat</code> is present before CCF mapping</li>'...
'<li><a href="https://github.com/cortex-lab/AP_histology" target="_blank">AP_histology GitHub</a></li>'...
'<li><a href="https://kimlab.io/devatlas" target="_blank">Kim Lab devAtlas</a></li>'...
'</ul>'...
'</div>'...
'</body></html>'...
];



helpText = [header section1 section2 section3 section4 section5 section6];

% Create a HTML-enabled text control
helpTextControl = uihtml(helpPanel, 'Position', [10 10 660 620]);
helpTextControl.HTMLSource = helpText;
end
