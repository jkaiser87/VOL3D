function VOL3D_Step2_GUI(baseDir)

if ~checkDependencies()
    return; % Exit if dependencies are missing
end

if nargin < 1 || isempty(baseDir)
    baseDir = pwd;
end

% Get list of volume files
files = dir(fullfile(baseDir, '**', '*_volume.mat'));

% Predefined variables
handles = struct();
handles.btnSaveBatch = [];
handles.btnUpdatePlot = [];

% Define color scheme (RGB 0-1)
handles.colors.lightBg = [0.96 0.96 0.96];    % #F5F5F5
handles.colors.thistle = [244 237 234]/255;    % #DBC2CF
handles.colors.coolGray = [0.62 0.64 0.70];   % #9FA2B2
handles.colors.cerulean = [0.24 0.48 0.54];   % #3C7A89
handles.colors.charcoal = [0.18 0.28 0.34];   % #2E4756
handles.colors.gunmetal = [0.09 0.15 0.18];   % #16262E
handles.colors.white = [1 1 1];               % #FFFFFF
handles.colors.errorRed = [0.8 0.2 0.2];      % For error messages
handles.colors.statusPending = [0.62 0.64 0.70];
handles.colors.successColor = [0.35 0.75 0.45];  % success green #59BF73

groupColorMapping = containers.Map;
defaultColors = {'red', 'green', 'blue', 'cyan', 'magenta', 'yellow', 'black','other...'};
channelColorMapping = containers.Map({'C1','C2','C3','C4'}, {'red','green','blue','cyan'});

% Step 1: Build data from available coordinate files
data = {};
identityKeys = {};  % for checking metadata match later

for i = 1:length(files)
    file = files(i);
    try
        S = load(fullfile(file.folder, file.name));
        animalName = S.Animal;

        % Handle atlasType - default to 'adult' if not found
        atlasTypeVal = 'adult'; % Default value
        if isfield(S, 'atlasType') && ~isempty(S.atlasType)
            atlasTypeVal = S.atlasType;
        end

        groupVal = S.Group;

        channels = {S.volume.channels};
        for j = 1:length(channels)
            chan = char(channels(j));
            % Try to get channel name from S.volume(j).ChannelName if available
            channelName = '';
            if isfield(S.volume(j), 'ChannelName') && ~isempty(S.volume(j).ChannelName)
                channelName = S.volume(j).ChannelName;
            end

            data(end+1,:) = {file.name, animalName, atlasTypeVal, groupVal, chan, channelName, '', false, ''};
            identityKeys{end+1,1} = [file.name '_' chan];  % store unique ID
        end
    catch
        warning('Failed to load file: %s', file.name);
    end
end

% Step 2: Try loading metadata
metaPath = fullfile(baseDir, 'OUT', 'metadata.mat');
if exist(metaPath, 'file')
    try
        loaded = load(metaPath);
        if isfield(loaded, 'data') && size(loaded.data,1) == size(data,1)
            % Build ID keys from loaded metadata
            loadedKeys = strcat(loaded.data(:,1), "_", loaded.data(:,5));
            if isequal(loadedKeys, identityKeys)
                data = loaded.data;  % Apply full metadata
            end
        end
    catch
        disp('Could not load metadata.');
    end
end

fig = uifigure('Name', 'VOL3D Group Manager', 'Position', [100 100 1400 700]);
fig.Color = handles.colors.lightBg;

% Main Layout
mainLayout = uigridlayout(fig, [1, 2]);
mainLayout.RowHeight = {'1x'};
mainLayout.ColumnWidth = {'3x', '2x'};
mainLayout.Padding = [0 0 0 0];         % Remove any padding that might affect sizing

% LEFT SIDE UI
uiLeft = uigridlayout(mainLayout, [6, 1]);
uiLeft.Layout.Row = 1;
uiLeft.Layout.Column = 1;

% Store original row heights (with last row for batch options)
uiLeft.UserData.originalRowHeights = {40, '1x', 60, 50, 50, 'fit'};

% Start with batch options hidden by setting last row height to 0
uiLeft.RowHeight = {uiLeft.UserData.originalRowHeights{1:5}, 0};
uiLeft.Padding = [5 5 5 5]; %padding around whole left box to border

%----- Header
headerPanel = uipanel(uiLeft, 'Title', '', ...
    'BorderType', 'none', ...  % Changed from 'line' to 'none' for cleaner look
    'BackgroundColor', handles.colors.charcoal, ...
    'HighlightColor', handles.colors.cerulean, ...  % Border highlight color when needed
    'ForegroundColor', handles.colors.white);  % Changed from 'white' to handles.colors.white for consistency

headerLayout = uigridlayout(headerPanel, [1 3]);
headerLayout.ColumnWidth = {'1x', 'fit', 'fit'};
headerLayout.Padding = [10 5 10 5];
headerLayout.BackgroundColor = handles.colors.charcoal; % Ensure full coverage


uilabel(headerLayout, 'Text', 'VOL3D - Group and Color Assignment', ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...  % Explicitly set font color
    'BackgroundColor', handles.colors.charcoal); % Match panel background

% Change folder
browseButton = uibutton(headerLayout, 'Text', '📁 Change Folder');
browseButton.Layout.Row = 1;
browseButton.Layout.Column = 2;

% Help Button
btnHelp = uibutton(headerLayout, 'Text', 'Help', 'ButtonPushedFcn', @(btn,event) openHelpDialog());
btnHelp.Layout.Column = 3;
btnHelp.Layout.Row = 1;
btnHelp.FontColor = [1 1 1];  % White text
btnHelp.BackgroundColor = handles.colors.gunmetal;  % Grey background to stand out

%----- Table
t = uitable(uiLeft, 'Data', data, ...
    'ColumnName', {'File Label', 'Animal', 'Atlas Type', 'Group', 'Channel', 'Channel Name', 'PlotColor', 'Exclude', 'ColorSource'}, ...
    'ColumnEditable', [false false false true false true true true false], ...
    'ColumnFormat', {[],[],[],[],[],[],defaultColors,'logical','char'});
t.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', 100, 80, 100};

colNames = t.ColumnName;

handles.colIdx.AtlasType = find(strcmp(colNames, 'Atlas Type'));
handles.colIdx.Animal = find(strcmp(colNames, 'Animal'));
handles.colIdx.Group = find(strcmp(colNames, 'Group'));
handles.colIdx.Channel = find(strcmp(colNames, 'Channel'));
handles.colIdx.ChannelName = find(strcmp(colNames, 'Channel Name'));
handles.colIdx.Exclude = find(strcmp(colNames, 'Exclude'));
handles.colIdx.PlotColor = find(strcmp(colNames, 'PlotColor'));
handles.colIdx.ColorSource = find(strcmp(colNames, 'ColorSource'));


for r = 1:size(t.Data,1)
    color = t.Data{r, handles.colIdx.PlotColor};
    if ischar(color) || isstring(color)
        try
            s = uistyle('BackgroundColor', color);
            addStyle(t, s, 'cell', [r, handles.colIdx.PlotColor]);
        catch
            % optionally log or warn
        end
    end
end

%----- Message Label
% Adjust grid layout for the message panel and button
msgAndButtonLayout = uigridlayout(uiLeft, [1, 2]); % One row, two columns
msgAndButtonLayout.ColumnWidth = {'1x', 'fit'}; % Message takes most space, button takes minimum necessary
msgAndButtonLayout.Layout.Row = 3;
msgAndButtonLayout.Padding = [0 0 0 0]; % No padding

% Create the message panel within the first column of the new grid layout
msgPanel = uipanel(msgAndButtonLayout, 'Title', '', ...
    'BorderType', 'line', ...
    'HighlightColor', handles.colors.charcoal,  ...
    'BackgroundColor', handles.colors.white);          % #3C7A89 (Cerulean)
msgPanel.Layout.Column = 1;

% Create message label within the message panel
% Using uigridlayout for automatic sizing within msgPanel
msgLayout = uigridlayout(msgPanel, [1, 1]); % One cell grid layout
msgLayout.RowHeight = {'1x'};
msgLayout.ColumnWidth = {'1x'};
msgLayout.Padding = [0 0 0 0];  % No padding

msgLabel = uilabel(msgLayout, ...
    'Text', 'No errors in the setup', ...
    'FontWeight', 'bold', ...
    'FontSize', 13, ...
    'HorizontalAlignment', 'center', ...  % Center horizontally
    'VerticalAlignment', 'center', ...  % Center vertically
    'FontColor', handles.colors.charcoal, ...
    'BackgroundColor', handles.colors.white, ...
    'WordWrap', 'on');

% Position metadata save button outside and to the right of the message box
btnSaveMetadata = uibutton(msgAndButtonLayout, 'Text', 'Save Metadata');
btnSaveMetadata.Layout.Column = 2;
btnSaveMetadata.Layout.Row = 1;

%----- Color Buttons Row
colorGrid = uigridlayout(uiLeft, [1, 7]);
colorGrid.Layout.Row = 4;
colorGrid.RowHeight = {40};
colorGrid.ColumnWidth = {180,180, 'fit', 'fit','fit','fit','fit'};
colorGrid.Padding = [0 0 0 0];  % No padding

% Replace the existing color button callbacks with:
btnColorByGroup = uibutton(colorGrid, 'Text', 'Set plotColor by Group', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', [1 1 1], ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

btnColorByChannel = uibutton(colorGrid, 'Text', 'Set plotColor by Channel', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', [1 1 1], ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

% Flip
uilabel(colorGrid, 'Text', 'Flip to hemisphere:', 'HorizontalAlignment', 'right');
flipDropdown = uidropdown(colorGrid, ...
    'Items', {'none','left','right'}, ...
    'Value', 'none');

% Color by
uilabel(colorGrid, 'Text', 'Color by:', 'HorizontalAlignment', 'right');
columnDropdown = uidropdown(colorGrid, ...
    'Items', {'plotColor','Animal','Group','Channel','Hemisphere'}, ...
    'Value', 'plotColor', ...
    'BackgroundColor', handles.colors.gunmetal, ...
    'FontColor', handles.colors.white);

btnCustomPalette = uibutton(colorGrid, 'Text', 'Define Palette');

%----- Plot Options Controls
plotOptionsRow = uigridlayout(uiLeft, [1, 4]);
plotOptionsRow.Layout.Row = 5;
plotOptionsRow.ColumnWidth = {180,180, '1x','fit'};  % Adjust as needed for balance
plotOptionsRow.Padding = [0 0 0 0];

% ----- calculate vol overlap
btnCalcVolumeOverlap = uibutton(plotOptionsRow, 'Text', 'Calculate Overlap btw Volumes', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', [1 1 1], ...
    'FontSize', 12);

btnSelectABAStruct = uibutton(plotOptionsRow, 'Text', '>> Select Brain Structures', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', [1 1 1], ...
    'FontSize', 12);

btnCalcABAOverlap = uibutton(plotOptionsRow, 'Text', sprintf('Calculate Overlap with%sselected Brain Structures', char(10)), ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', [1 1 1], ...
    'FontSize', 12, ...
    'Tag', 'btnCalcABAOverlap', ...
    'Enable','off');


% Create checkbox first (without callback)
saveCheckbox = uicheckbox(plotOptionsRow, ...
    'Text', 'Show Batch Save Options', ...
    'Value', false, ... % Starts unchecked
    'FontWeight', 'bold');
saveCheckbox.Layout.Column = 4;

% ----- Bottom Controls (Save Button Row) -----
OptionalSaveBatch = uigridlayout(uiLeft, [2, 4]); % 2 rows, 3 columns
OptionalSaveBatch.Layout.Row = 6;
OptionalSaveBatch.ColumnWidth = {'fit', '1x', 'fit','fit'}; % Label | Options | Buttons 2x
OptionalSaveBatch.RowHeight = {'fit', 'fit'};
OptionalSaveBatch.Visible = 'off'; % Start hidden

% Now safely connect the callback
saveCheckbox.ValueChangedFcn = @(src,event) toggleBatchOptions(src.Value, OptionalSaveBatch, uiLeft);

% ---- Column 1: Labels ----
% Split By Label
splitByLabel = uilabel(OptionalSaveBatch, 'Text', 'Split By:', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
splitByLabel.Layout.Row = 1;
splitByLabel.Layout.Column = 1;

% Color By Label
colorByLabel = uilabel(OptionalSaveBatch, 'Text', 'Color By:', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
colorByLabel.Layout.Row = 2;
colorByLabel.Layout.Column = 1;

% ---- Column 2: Options ----
% Split By Options (Row 1)
optionsBox = uipanel(OptionalSaveBatch, 'BorderType', 'line', ...
    'HighlightColor', [0.5 0.5 0.5], 'BackgroundColor', [1 1 1]);
optionsBox.Layout.Row = 1;
optionsBox.Layout.Column = 2;

% Split By Checkboxes (inside box)
splitByGrid = uigridlayout(optionsBox, [1, 4], 'Padding', [5 5 5 5]); % Add padding
uicheckbox(splitByGrid, 'Text', 'None', 'Tag', 'none', 'Value', true);
uicheckbox(splitByGrid, 'Text', 'Group', 'Tag', 'Group');
uicheckbox(splitByGrid, 'Text', 'Channel', 'Tag', 'Channel');
uicheckbox(splitByGrid, 'Text', 'Animal', 'Tag', 'Animal');

% Color By Options (Row 2)
colorByBox  = uipanel(OptionalSaveBatch, 'BorderType', 'line', ...
    'HighlightColor', [0.5 0.5 0.5], 'BackgroundColor', [1 1 1]);
colorByBox .Layout.Row = 2;
colorByBox .Layout.Column = 2;

colorByGrid = uigridlayout(colorByBox , [1, 5], 'Padding', [5 5 5 5]);

% Row 1
cb1 = uicheckbox(colorByGrid, 'Text', 'plotColor', 'Tag', 'plotColor', 'Value', true);
cb1.Layout.Row = 1;
cb1.Layout.Column = 1;

cb2 = uicheckbox(colorByGrid, 'Text', 'Animal', 'Tag', 'Animal');
cb2.Layout.Row = 1;
cb2.Layout.Column = 2;

cb3 = uicheckbox(colorByGrid, 'Text', 'Group', 'Tag', 'Group');
cb3.Layout.Row = 1;
cb3.Layout.Column = 3;

cb4 = uicheckbox(colorByGrid, 'Text', 'Channel', 'Tag', 'Channel');
cb4.Layout.Row = 1;
cb4.Layout.Column = 4;

cb5 = uicheckbox(colorByGrid, 'Text', 'Hemisphere', 'Tag', 'classifier');
cb5.Layout.Row = 1;
cb5.Layout.Column = 5;

% ---- Column 3: Prefix & Button ----
% Prefix (Row 1)
prefixGrid = uigridlayout(OptionalSaveBatch, [2, 2]);
prefixGrid.Layout.Row = [1, 2];
prefixGrid.Layout.Column = 3;
prefixGrid.ColumnWidth = {'fit','fit'};
prefixGrid.RowHeight = {'fit', '1x'};

prefixLabel = uilabel(prefixGrid, 'Text', 'Prefix:', 'HorizontalAlignment', 'right');
prefixLabel.Layout.Row = 1;
prefixLabel.Layout.Column = 1;

prefixField = uieditfield(prefixGrid, 'text');
prefixField.Layout.Row = 1;
prefixField.Layout.Column = 2;

% ---- Column 3: Save Batch Button ----
btnSaveBatch = uibutton(prefixGrid, ...
    'Text', 'Save Batch Plots', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'ButtonPushedFcn', @(btn,event) saveBatchCallback(t, flipDropdown, prefixField, splitByGrid, colorByGrid, baseDir, msgLabel));

btnSaveBatch.Layout.Row = 2;
btnSaveBatch.Layout.Column = [1 2];

% RIGHT SIDE AXES FOR PLOTTING
rightPanel = uipanel(mainLayout, ...
    'BorderType','none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

rightPanel.Layout.Row = 1;
rightPanel.Layout.Column = 2;
% Use grid layout inside panel for better control
rightLayout = uigridlayout(rightPanel, [4, 1]);
rightLayout.RowHeight = {40, 50,'1x', 50};          % Plot area and button
rightLayout.Padding = [5 5 5 5];

%----- Header
%----- Row 1: Right Header (renamed from headerPanel to rightHeader)
rightHeader = uipanel(rightLayout, 'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

rightHeader.Layout.Row = 1;  % Assign to first row of rightLayout

rightHeaderLayout = uigridlayout(rightHeader, [1, 1]);
rightHeaderLayout.Padding = [10 5 10 5];
rightHeaderLayout.BackgroundColor = handles.colors.charcoal;

uilabel(rightHeaderLayout, 'Text', 'Preview Plot', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...
    'BackgroundColor', handles.colors.charcoal);
% ---- Row 2 View Buttons

% Assuming 'rightLayout' is your grid layout for plotting area
viewControlGrid = uigridlayout(rightLayout, [1, 3]); % One row, three columns for buttons
viewControlGrid.Layout.Row = 2;  % Assign to second row
% Define buttons

btnSideView = uibutton(viewControlGrid, 'Text', 'Side View');
btnTopView = uibutton(viewControlGrid, 'Text', 'Top View');
btnFrontView = uibutton(viewControlGrid, 'Text', 'Frontal View');

% Distribute buttons equally
btnSideView.Layout.Column = 1;
btnTopView.Layout.Column = 2;
btnFrontView.Layout.Column = 3;

%----- Row 3: Axes (plot area)
ax = uiaxes(rightLayout);
ax.Layout.Row = 3;
ax.XColor = handles.colors.charcoal;  % Axis text/lines
ax.YColor = handles.colors.charcoal;
ax.ZColor = handles.colors.charcoal;

xlabel(ax, 'X (ML)');
ylabel(ax, 'Y (DV)');
zlabel(ax, 'Z (AP)');

view(ax, 90, 90); %default: set to top view


%----- Row 3: Button and Dropdown Container
bottomControlGrid = uigridlayout(rightLayout, [1, 2]);
bottomControlGrid.Layout.Row = 4;
bottomControlGrid.ColumnWidth = {'1x', '1x'};
bottomControlGrid.Padding = [0 0 0 0];  % no padding for tight fit

% Update button
btnUpdatePlot = uibutton(bottomControlGrid, 'Text', 'Update Preview Plot', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.gunmetal, ...
    'FontWeight', 'bold');
btnUpdatePlot.Layout.Row = 1;
btnUpdatePlot.Layout.Column = 1;

% Save current view
btnSavePreview = uibutton(bottomControlGrid, ...
    'Text', 'Save Preview Plot', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'ButtonPushedFcn', @(btn,event) savePreviewPlot(ax,msgLabel));
btnSavePreview.Layout.Row = 1;
btnSavePreview.Layout.Column = 2;

% Store all handles
handles.t = t;
handles.msgLabel = msgLabel;
handles.btnSaveBatch = btnSaveBatch;
handles.btnUpdatePlot = btnUpdatePlot;
handles.fig = fig;
handles.ax = ax;
handles.flipDropdown = flipDropdown;
handles.columnDropdown = columnDropdown;
handles.prefixField = prefixField;
handles.splitByGrid = splitByGrid;
handles.colorByGrid = colorByGrid;
handles.baseDir = baseDir; % Add this line
handles.volumes = loadVolumesFromTable(t, baseDir);

% Store color mappings and handles in figure
fig.UserData.channelColorMapping = channelColorMapping;
fig.UserData.groupColorMapping = groupColorMapping;
fig.UserData.handles = handles;

% Update callbacks to use handles
t.CellEditCallback = @(src, event) cellEditCallback(src, event, handles);
btnUpdatePlot.ButtonPushedFcn = @(btn,event) plotDataToAxes(handles, handles.flipDropdown.Value, handles.columnDropdown.Value);
btnSavePreview.ButtonPushedFcn = @(btn,event) savePreviewPlot(handles);
btnSaveMetadata.ButtonPushedFcn = @(btn,event) saveMetadata(handles);
btnCalcVolumeOverlap.ButtonPushedFcn = @(btn,event) CalcVolumeOverlap(handles);
btnSelectABAStruct.ButtonPushedFcn = @(btn,event) SelectABAStruct(handles);
btnCalcABAOverlap.ButtonPushedFcn = @(btn,event) CalcABAOverlap(handles);
btnSaveBatch.ButtonPushedFcn = @(btn,event) saveBatchCallback(handles);
btnColorByGroup.ButtonPushedFcn = @(btn,event) colorByGroup(handles);
btnColorByChannel.ButtonPushedFcn = @(btn,event) colorByChannel(handles);
columnDropdown.ValueChangedFcn = @(dd, event) updateMessage(handles, dd.Value);
btnSideView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, 0, 0);
btnTopView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, 90, 90);
btnFrontView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, -90, 0);
btnCustomPalette.ButtonPushedFcn = @(src,evt) openPaletteEditor(handles);


% Set initial button states and message
updateMessage(handles, handles.columnDropdown.Value);

end

%% GUI functions

function updateMessage(handles, colorby)
if ~isfield(handles, 'btnSaveBatch') || ~isvalid(handles.btnSaveBatch)
    error('Invalid button handle');
end

% Set default handles.colors
normalColor = [0.09 0.15 0.18];       % gunmetal
warningColor = [1.0 0.8 0.4];           % pastel amber, hex #FFCC66
errorColor = [0.8 0.2 0.2];           % Complementary red for errors

% Access components from handles
msgLabel = handles.msgLabel;
t = handles.t;
btnSaveBatch = handles.btnSaveBatch;
btnUpdatePlot = handles.btnUpdatePlot;

% Initialize with no errors
issues = {};
msgColor = normalColor;
btnState = 'on'; % Default to enabled

% Check if table has data
if isempty(t.Data)
    issues{end+1} = 'No files found in the selected folder.';
    msgColor = errorColor;
    btnState = 'off';
else
    data = t.Data;

    % Check excluded rows
    excluded = false(size(data,1),1);
    for i = 1:size(data,1)
        excluded(i) = isequal(data{i,7}, true);
    end
    included = ~excluded;

    if ~any(included)
        issues{end+1} = 'No files included. All are marked as excluded.';
        msgColor = errorColor;
        btnState = 'off';
    else
        % Check for missing Group information
        groups = data(included, 4);
        if any(cellfun(@isempty, groups))
            issues{end+1} = 'Warning: Some included entries are missing Group information.';
            msgColor = warningColor;
        end

        % Check for missing Channel information
        channels = data(included, 5);
        if any(cellfun(@isempty, channels))
            issues{end+1} = 'Warning: Some files are missing Channel information.';
            msgColor = warningColor;
        end

        % Check atlas type consistency
        atlasTypes = data(included, 3);
        if numel(unique(atlasTypes)) > 1
            issues{end+1} = 'Not all included files share the same atlasType.';
            msgColor = errorColor;
            btnState = 'off';
        end


        % Check plot colors if needed
        if strcmpi(colorby, 'plotColor')
            plotColors = data(included, 6);
            if all(cellfun(@isempty, plotColors))
                issues{end+1} = 'No colors assigned, cannot plot.';
                msgColor = errorColor;
                btnState = 'off';
            elseif any(cellfun(@isempty, plotColors))
                issues{end+1} = 'Some PlotColors missing, these will not be plotted!';
                msgColor = warningColor;
            end
        end
    end
end

% Update message display
if isempty(issues)
    msgLabel.Text = 'No errors in the setup';
    msgLabel.FontColor = normalColor;
else
    msgLabel.Text = strjoin(issues, newline);
    msgLabel.FontColor = msgColor;
end

% Update button states
btnSaveBatch.Enable = btnState;
btnUpdatePlot.Enable = btnState;

drawnow;
end



function toggleBatchOptions(show, OptionalSaveBatch, uiLeft)
if show
    OptionalSaveBatch.Visible = 'on';
    % Restore original row heights to show the row
    uiLeft.RowHeight = uiLeft.UserData.originalRowHeights;
else
    OptionalSaveBatch.Visible = 'off';
    % Collapse the row by setting height to 0
    newHeights = uiLeft.UserData.originalRowHeights;
    newHeights{end} = 0;
    uiLeft.RowHeight = newHeights;
end
drawnow; % More efficient than full drawnow
end

function colorByGroup(handles)
% Get components from handles
t = handles.t;
msgLabel = handles.msgLabel;

% Get current palette (custom or default)
palette = getCurrentPalette(handles.baseDir);

% Get groups from table data
groups = unique(handles.t.Data(:,4));
groups(cellfun(@isempty, groups)) = [];

groupColorMapping = containers.Map();

% Get table data
data = t.Data;

% Temporarily disable cell edit callback if it exists
if isprop(t, 'CellEditCallback')
    originalCallback = t.CellEditCallback;
    t.CellEditCallback = [];
else
    originalCallback = [];
end

% Get unique groups (excluding empty)
groups = unique(data(:,4));
groups(cellfun(@isempty, groups)) = [];

if isempty(groups)
    warning('No groups found in the data');
    return;
end

% Update mapping using custom palette with cycling
for i = 1:length(groups)
    group = groups{i};
    if ~isKey(groupColorMapping, group)
        % Cycle through palette handles.colors if more groups than handles.colors
        colorIdx = mod(i-1, size(palette,1)) + 1;
        groupColorMapping(group) = palette(colorIdx,:);
    end
end


% Apply handles.colors to table
for r = 1:size(data,1)
    grp = data{r,4};
    if ~isempty(grp) && isKey(groupColorMapping, grp)
        rgb = groupColorMapping(grp);
        data{r,handles.colIdx.PlotColor} = sprintf('#%02X%02X%02X', round(rgb*255));
        data{r,handles.colIdx.ColorSource} = 'Group';
        try
            s = uistyle('BackgroundColor', rgb);
            addStyle(t, s, 'cell', [r,handles.colIdx.PlotColor]);
        catch ME
            warning('Failed to add style to row %d: %s', r, ME.message);
        end
    end
end

% Update table data
t.Data = data;

% Update the mapping in UserData
handles.t.Parent.UserData.groupColorMapping = groupColorMapping;

% Restore original callback if it existed
if ~isempty(originalCallback)
    t.CellEditCallback = originalCallback;
end

% Update message display
updateMessage(handles, handles.columnDropdown.Value);
end

function colorByChannel(handles)
% Get components from handles
t = handles.t;
msgLabel = handles.msgLabel;

% Get current palette (custom or default)
palette = getCurrentPalette(handles.baseDir);
channelColorMapping = containers.Map();

% Get table data and unique channels (excluding empty)
data = t.Data;
channels = unique(data(:,handles.colIdx.Channel));
channels(cellfun(@isempty, channels)) = [];

if isempty(channels)
    warning('No channels found in the data');
    return;
end

% Temporarily disable cell edit callback if it exists
if isprop(t, 'CellEditCallback')
    originalCallback = t.CellEditCallback;
    t.CellEditCallback = [];
else
    originalCallback = [];
end

% Ensure all channels have a color assignment
for i = 1:length(channels)
    ch = channels{i};
    if ~isKey(channelColorMapping, ch)
        % Assign a default color if channel not in mapping
        colorIdx = mod(i-1, size(palette,1)) + 1;
        channelColorMapping(ch) = palette(colorIdx,:);
    end
end

% Apply handles.colors to table
for r = 1:size(data,1)
    ch = data{r,handles.colIdx.Channel};
    if ~isempty(ch) && isKey(channelColorMapping, ch)
        color = channelColorMapping(ch);
        data{r,handles.colIdx.PlotColor} = sprintf('#%02X%02X%02X', round(color*255));
        data{r,handles.colIdx.ColorSource} = 'Channel';
        try
            s = uistyle('BackgroundColor', color);
            addStyle(t, s, 'cell', [r,handles.colIdx.PlotColor]);
        catch ME
            warning('Failed to add style to row %d: %s', r, ME.message);
        end
    end
end

% Update table data and store mapping
t.Data = data;
handles.t.Parent.UserData.channelColorMapping = channelColorMapping;

% Restore original callback if it existed
if ~isempty(originalCallback)
    t.CellEditCallback = originalCallback;
end

% Update message display
updateMessage(handles, handles.columnDropdown.Value);
end

function cellEditCallback(src, event, handles)
% Get components from handles
t = handles.t;
msgLabel = handles.msgLabel;

data = t.Data;
row = event.Indices(1);
col = event.Indices(2);

% If user edited plotColor column (col 7)
if col == handles.colIdx.PlotColor
    newColor = data{row,handles.colIdx.PlotColor};

    if ischar(newColor) && strcmp(newColor, 'other...')
        chosenColor = uisetcolor();

        if ~isequal(chosenColor, 0) % User didn't cancel
            hexColor = sprintf('#%02X%02X%02X', round(chosenColor*255));
            data{row,handles.colIdx.PlotColor} = hexColor;
            data{row,handles.colIdx.ColorSource} = 'manual';  % mark source
            try
                s = uistyle('BackgroundColor', chosenColor);
                addStyle(t, s, 'cell', [row, handles.colIdx.PlotColor]);
            catch, end
        else
            data{row,handles.colIdx.PlotColor} = '';  % reset if user cancels
        end
    else
        try
            if isempty(newColor)
                removeStyle(t, 'cell', [row, handles.colIdx.PlotColor]);
            else
                s = uistyle('BackgroundColor', newColor);
                addStyle(t, s, 'cell', [row, handles.colIdx.PlotColor]);
                data{row,handles.colIdx.ColorSource} = 'manual';
            end
        catch
            data{row,handles.colIdx.PlotColor} = '';
            data{row,handles.colIdx.ColorSource} = '';
        end
    end
end


% Reapply styles and update
for r = 1:size(data,1)
    color = data{r,handles.colIdx.PlotColor};
    if ischar(color) || isstring(color)
        try
            s = uistyle('BackgroundColor', color);
            addStyle(src, s, 'cell', [r, handles.colIdx.PlotColor]);
        catch, end
    end
end

t.Data = data;
updateMessage(handles, handles.columnDropdown.Value);
end

function hex = rgb2hex(rgb)
rgb = round(rgb * 255);
hex = sprintf('#%02X%02X%02X', rgb(1), rgb(2), rgb(3));
end

function volumes = loadVolumesFromTable(t, baseDir)
% Return volumes struct array for plotting based on table content
if isa(t, 'matlab.ui.control.Table')
    data = t.Data;
else
    data = t;
end

% Predefine empty struct with all expected fields
volumes = struct( ...
    'Animal', {}, ...
    'Group', {}, ...
    'Channel', {}, ...
    'ChannelName', {}, ...
    'hemi', {}, ...
    'ccf_points_cat_ord', {}, ...
    'k1', {}, ...
    'smoothedVertices', {});  % include even if it's sometimes missing

for i = 1:size(data, 1)
    try
        fileName = data{i, 1};
        fullPath = fullfile(baseDir, fileName);
        chanTable = data{i, 5};
        channelName = data{i, 6};
        group = data{i, 4};
        animal = data{i, 2};

        S = load(fullPath, 'volume');
        for j = 1:length(S.volume)
            vol = S.volume(j);
            if isfield(vol, 'channels') && strcmp(vol.channels, chanTable)
                v.Animal = animal;
                v.Group = group;
                v.Channel = vol.channels;
                v.ChannelName = channelName;
                v.ccf_points_cat_ord = vol.ccf_points_cat_ord;
                v.k1 = vol.k1;
                if isfield(vol, 'smoothedVertices')
                    v.smoothedVertices = vol.smoothedVertices;
                else
                    v.smoothedVertices = [];  % Ensure field exists
                end
                if isfield(vol, 'hemi')
                    v.hemi = vol.hemi;
                else
                    v.hemi = [];  % Ensure field exists
                end
                volumes(end+1) = v; %#ok<AGROW>
                break;
            end
        end
    catch ME
        sprintf('Failed to load volume from %s: %s', baseDir, ME.message);
    end
end

end


%% Plotting functions

% ------ plotDataToAxes -------------

function [legendHandles, legendLabels] = plotDataToAxes(handles, flipDirection, colorby, subsetIdx, ax)

% --- Setup
if nargin < 4 || isempty(subsetIdx)
    subsetIdx = true(height(handles.t.Data), 1);
end
if nargin < 5 || isempty(ax)
    ax = handles.ax;
end

[az, el] = view(ax);
cla(ax); hold(ax, 'on');
legend(ax, 'off'); colorbar(ax, 'off');

% Extract data and volumes
data = handles.t.Data;
allData = handles.t.Data;
excludeFlags = cellfun(@(x) isequal(x, true), data(:, handles.colIdx.Exclude));
includeFlags = ~excludeFlags;
includedIdx = includeFlags & subsetIdx; 

% Predefine keys
Globalkeys = strings(sum(includeFlags), 1);

% Final subset - excluding subset for paneling and exluded rows
data = data(includedIdx, :);
volumes = handles.volumes(includedIdx);

% Validate atlas consistency and load
atlasTypes = data(:, handles.colIdx.AtlasType);
if numel(unique(atlasTypes)) ~= 1
    handles.msgLabel.Text = 'Error: All included volumes must have the same Atlas Type.';
    handles.msgLabel.FontColor = handles.colors.errorRed;
    return;
end
[~, ~, brain_data] = getAtlasFilesForType(atlasTypes{1});

% Plot reference brain
patch(ax, 'Vertices', brain_data.brain.v, 'Faces', brain_data.brain.f, ...
      'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);


% Flip settings
midline = mean([min(brain_data.brain.v(:,2)), max(brain_data.brain.v(:,2))]);
flipToRight = strcmp(flipDirection, 'right');
flipToLeft  = strcmp(flipDirection, 'left');

% Predefine
useManual = any(strcmpi(data(:, handles.colIdx.ColorSource), 'manual'));

% --- Define Color Keys & Map
Globalkeys = strings(sum(includeFlags), 1);
labels = strings(numel(volumes), 1); 

if ~strcmpi(colorby, 'plotColor')
    switch lower(colorby)
        case 'animal'
           Globalkeys = string(allData(includeFlags, handles.colIdx.Animal));
        case 'group'
            Globalkeys = string(allData(includeFlags, handles.colIdx.Group));
        case 'hemisphere'
            Globalkeys = string({volumes.hemi});
        case 'channel'
            Globalkeys = strings(sum(includeFlags), 1);
            for k = 1:sum(includeFlags)
                chanNameIdx = handles.colIdx.ChannelName;
                chanIdx = handles.colIdx.Channel;
                thisRow = find(includeFlags);  % map included row to global row index
                r = thisRow(k);
                 if isfield(handles.colIdx, 'ChannelName') && chanNameIdx > 0
                    val = allData{r, chanNameIdx};
                    if ~isempty(val)
                        Globalkeys(k) = string(val);
                        continue;
                    end
                end
                Globalkeys(k) = string(allData{r, chanIdx});
            end
        otherwise
            Globalkeys = repmat("undefined", sum(includeFlags), 1);
    end

    % Assign color map based only on included keys
    uniqueKeys = unique(Globalkeys);
    cmap = getCurrentPalette(handles.baseDir);
    colorMap = containers.Map();
    for k = 1:numel(uniqueKeys)
        colorMap(uniqueKeys(k)) = cmap(mod(k-1, size(cmap,1)) + 1, :);
    end
end

% --- Plotting
legendHandles = gobjects(0);
legendLabels = {};

for i = 1:numel(volumes)
    vol = volumes(i);
    vertices = vol.ccf_points_cat_ord;

    % Apply flipping
    if flipToRight
        flip_idx = vertices(:, 2) < midline;
        vertices(flip_idx, 2) = 2 * midline - vertices(flip_idx, 2);
    elseif flipToLeft
        flip_idx = vertices(:, 2) > midline;
        vertices(flip_idx, 2) = 2 * midline - vertices(flip_idx, 2);
    end

     % Assign color & label
    if strcmpi(colorby, 'plotColor')
        color = hex2rgb(data{i, handles.colIdx.PlotColor});
        source = data{i, handles.colIdx.ColorSource};
        if useManual
            label = string(vol.Animal) + " - " + string(vol.Channel);
        else
            switch lower(string(source))
                case 'group'
                    label = string(vol.Group);
                case 'animal'
                    label = string(vol.Animal);
                case 'channel'
                    if isfield(vol, 'ChannelName') && ~isempty(vol.ChannelName)
                        label = string(vol.ChannelName);
                    else
                        label = string(vol.Channel);
                    end
                otherwise
                    label = string(vol.Animal) + " - " + string(vol.Channel);
            end
        end
    else
        % Recompute key dynamically for this volume
        switch lower(colorby)
            case 'animal'
                label = string(vol.Animal);
            case 'group'
                label = string(vol.Group);
            case 'channel'
                if isfield(vol, 'ChannelName') && ~isempty(vol.ChannelName)
                    label = string(vol.ChannelName);
                else
                    label = string(vol.Channel);
                end
            case 'hemisphere'
                label = string(vol.hemi);
            otherwise
                label = "undefined";
        end

        color = colorMap(label);
    end

    % Plot patch
    h = patch(ax, 'Vertices', vertices, 'Faces', vol.k1, ...
        'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 0.2);

     % Legend
    label = char(label);
    if ~any(strcmp(legendLabels, label))
        h.DisplayName = label;
        legendHandles(end+1) = h;
        legendLabels{end+1} = label;
    else
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end
end

% Draw legend if needed
if ~isempty(legendHandles)
    legend(ax, legendHandles, legendLabels, 'Location', 'southoutside', 'NumColumns', 2);
end

axis(ax, 'equal'); axis(ax, 'off'); set(ax, 'ZDir', 'reverse');
view(ax, az, el); hold(ax, 'off');

% Enable realistic lighting
lighting(ax, 'gouraud');         % Smooth lighting (or try 'phong' for shinier surface)
material(ax, 'dull');            % 'dull', 'shiny', or 'metal' affect reflectivity
camlight(ax, 'headlight');       % Attach light to camera

end
    


function rgb = hex2rgb(hex)
    if startsWith(hex, '#'), hex = hex(2:end); end
    rgb = reshape(sscanf(hex, '%2x') / 255, 1, 3);
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

% Load atlas files
tv = readNPY(template_path);
av = readNPY(annotation_path);
st = loadStructureTree(structure_tree_path);
% Display confirmation message
fprintf('Atlas files for "%s" loaded successfully.\n', atlasType);
end


%% saving functions
function saveMetadata(handles)
msgLabel = handles.msgLabel;
t = handles.t;
baseDir = handles.baseDir;

outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

data = t.Data;
save(fullfile(outDir, 'metadata.mat'), 'data');

msgLabel.Text = sprintf('Metadata saved.');
msgLabel.FontColor = handles.colors.successColor;  % success green #59BF73
end

function savePreviewPlot(handles)
msgLabel = handles.msgLabel;
ax = handles.ax;  % Access the axes from the handles

% Capture the current view angles
currentView = get(ax, 'View');  % This returns [azimuth, elevation]

[file, path] = uiputfile({'*.png','Image (*.png)'}, 'Save Preview As');
if isequal(file, 0), return; end
[~, name] = fileparts(file);

% Create new figure + axes
f = figure('Visible', 'off', 'Color', 'w', 'Units', 'normalized');
f.Position = [0.1 0.1 0.8 0.8];
axNew  = axes('Parent', f);

% Create minimal handles struct for plotting
tempHandles = struct();
tempHandles.t = handles.t;
tempHandles.colIdx = handles.colIdx;
tempHandles.ax = axNew ;
tempHandles.baseDir = handles.baseDir;
tempHandles.flipDirection = handles.flipDropdown.Value;
tempHandles.colorby = handles.columnDropdown.Value;
tempHandles.volumes = handles.volumes;

% Plot to this new axis
plotDataToAxes(tempHandles, tempHandles.flipDirection, tempHandles.colorby);
view(axNew , currentView); % Set the view to stored angles

% Use unified save function
savePlot(f, path, name, '', '');

% Clean up and update message
close(f);

msgLabel.Text = sprintf('Preview Plot saved.');
msgLabel.FontColor = handles.colors.successColor;

end


function savePlot(figHandle, outputDir, baseName, splitBy, colorBy)
% Ensure output directory exists
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Set up export
ax = findobj(figHandle, 'Type', 'Axes', '-not', 'Tag', 'legend');

% Set common axis styles
for i = 1:length(ax)
    set(ax(i), 'Color', 'w');
    axis(ax(i), 'vis3d', 'equal', 'off');
    set(ax(i), 'ZDir', 'reverse');
end

set(figHandle, 'visible', 'on');

% Export as PNG
outFile = fullfile(outputDir, [baseName, '.png']);
exportgraphics(figHandle, outFile, 'Resolution', 300, 'BackgroundColor', 'white');
saveas(figHandle, fullfile(outputDir, [baseName, '.fig']));
% could include PDF but takes VERY long to save
end


function saveBatchCallback(handles)
% Save batch plots without mutating GUI state, using unified subset index

% Components from GUI
t = handles.t;
baseDir = handles.baseDir;
flipDropdown = handles.flipDropdown;
prefixField = handles.prefixField;
splitByGrid = handles.splitByGrid;
colorByGrid = handles.colorByGrid;
msgLabel = handles.msgLabel;
mainAx = handles.ax;

% Setup
currentView = get(mainAx, 'View');
outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end
prefix = prefixField.Value;
if isempty(prefix), prefix = 'VOL3D'; end

% Options
splitByTags = getCheckedTags(splitByGrid);
colorByTags = getCheckedTags(colorByGrid);

if isempty(splitByTags) || isempty(colorByTags)
    msgLabel.Text = 'Select at least one Split By and Color By option';
    msgLabel.FontColor = handles.colors.errorRed;
    return;
end

% Get full table and volume list
data = t.Data;
volumes = handles.volumes;

% Loop through options
for iColor = 1:length(colorByTags)
    colorBy = colorByTags{iColor};
    for iSplit = 1:length(splitByTags)
        splitBy = splitByTags{iSplit};

         f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 800]);


        % Handle splitBy 'none'
        if strcmpi(splitBy, 'none')
            subsetIdx = true(size(handles.t.Data, 1), 1);  % Include all
            label = 'All';

            set(f, 'Position', [100 100 1200 800]);
            ax = axes('Parent', f, 'Position', [0.1 0.1 0.8 0.8]);

            [h, labels] = plotDataToAxes(handles, flipDropdown.Value, colorBy, subsetIdx);
             if ~isempty(hScatter)
                legend(ax, hScatter, labels, 'Location', 'southoutside');
            end
                        
            set(ax, 'View', currentView);
            filename = sprintf('%s_%s_coloredby-%s', prefix, label, colorBy);
            savePlot(f, outDir, filename, splitBy, colorBy);

        else

        excludeFlags = cellfun(@(x) isequal(x, true), handles.t.Data(:, handles.colIdx.Exclude));
        baseIdx = ~excludeFlags; %incorporating excluded rows here in case a full subset gets excluded, otherwise results in empty panel
        % Determine tag values for all rows (must match t.Data size!)
        
        switch lower(splitBy)
            case 'group'
                tags = string(handles.t.Data(:, handles.colIdx.Group));
            case 'animal'
                tags = string(handles.t.Data(:, handles.colIdx.Animal));
            case 'channel'
                if isfield(handles.colIdx, 'ChannelName') && handles.colIdx.ChannelName > 0
                    tags = string(handles.t.Data(:, handles.colIdx.ChannelName));
                else
                    tags = string(handles.t.Data(:, handles.colIdx.Channel));
                end
        end

        uniqueVals = unique(tags(baseIdx));
        nGroups = length(uniqueVals);

            if nGroups == 0
                close(f);
                continue;
            end
            
        % Create subplot grid
            [nRows, nCols] = numSubplots(nGroups);
            if nGroups <= 3
                nRows = 1; nCols = nGroups; % Horizontal layout
            end

                        % Collect legend entries across all panels
            allh = [];
            allLabels = {};

            % Create tight subplots
            gap = [0.01 0.01];       % [vertical horizontal] gap between plots
            marg_h = [0.1 0.4];    % [bottom top] margins
            marg_w = [0.01 0.01];    % [left right] margins
            axArray = tight_subplot(nRows, nCols, gap, marg_h, marg_w);



        for u = 1:numel(uniqueVals)
            ax = axArray(u);
            thisVal = uniqueVals(u);
            splitMask = strcmp(tags, thisVal);
            subsetIdx = baseIdx & splitMask; %both panel and excluded subset

            if ~any(subsetIdx), continue; end
            [temph, tempLabels] = plotDataToAxes(handles, flipDropdown.Value, colorBy, subsetIdx, ax);
            legend(ax, 'off');  % Force disable panel legend
             set(ax, 'View', currentView);

         % Collect unique legend entries
                if ~isempty(temph)
                    for k = 1:length(temph)
                        thisLabel = tempLabels{k};
                        if ~any(strcmp(thisLabel, allLabels))
                            allh(end+1) = temph(k);
                            allLabels{end+1} = thisLabel;
                        end
                    end
                end
        end

           if ~isempty(allh)
                validIdx = isgraphics(allh);
                if any(validIdx)
                    % Create a new axes at the bottom for the legend
                    legendAx = axes('Parent', f, ...
                        'Position', [0 0 1 0.05], ... % Full width, short height
                        'Visible', 'off');

                    % Create dummy plot in that axes to host the legend
                    axes(legendAx); %#ok<LAXES> % set current axes to legendAx
                    lgd = legend(allh(validIdx), allLabels(validIdx), ...
                        'Orientation', 'horizontal', ...
                        'Location', 'southoutside');
                    lgd.Units = 'normalized';
                    lgd.Position = [0.5 - lgd.Position(3)/2, 0, lgd.Position(3), lgd.Position(4)];
                end
           end

        end
filename = sprintf('%s_splitby-%s_coloredby-%s', prefix, splitBy, colorBy);
savePlot(f, outDir, filename, splitBy, colorBy);

        %close(f);
    end
end

msgLabel.Text = sprintf('✅ Done! Saved %d figure sets.', length(splitByTags) * length(colorByTags));
msgLabel.FontColor = handles.colors.successColor;
end

function tags = getCheckedTags(grid)
% Return tags from all checked checkboxes in a grid
boxes = findobj(grid, 'Type', 'uicheckbox', 'Value', true);
tags = cellfun(@(x) x.Tag, num2cell(boxes), 'UniformOutput', false);
end


% Helper function to dynamically find and set the view of the axes
function setDynamicView(fig, az, el)
ax = findobj(fig, 'Type', 'Axes');  % Find axes in the figure
    if isempty(ax)
        disp('No axes found in the figure.');
        return;
    end    
view(ax, az, el); % Set the view
    % Store the current view settings in the figure's UserData
    fig.UserData.currentView = [az, el];
end


%% Color palette

function openPaletteEditor(handles)
fig = uifigure('Name', 'Color Palette Editor', 'Position', [100 100 600 200]);
outDir = fullfile(handles.baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Load or initialize palette
paletteFile = fullfile(handles.baseDir, 'OUT', 'customPalette.mat');
if exist(paletteFile, 'file')
    load(paletteFile, 'palette');
else
    palette = linspecer(6); % Default to 6 handles.colors
end

% Main grid layout
mainGrid = uigridlayout(fig, [2 1]);
mainGrid.RowHeight = {120, 40}; % Color swatches row, controls row
mainGrid.RowSpacing = 10;
mainGrid.Padding = [20 20 20 20];

% Color swatches grid (horizontal layout)
swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
swatchGrid.Layout.Row = 1;
swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
swatchGrid.RowHeight = {'1x'};
swatchGrid.Padding = [0 0 0 0];

% Create color buttons (swatches)
colorButtons = gobjects(size(palette,1), 1);
for i = 1:size(palette,1)
    colorButtons(i) = uibutton(swatchGrid);
    colorButtons(i).BackgroundColor = palette(i,:);
    colorButtons(i).Text = '';
    colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
    colorButtons(i).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', palette(i,1), palette(i,2), palette(i,3));
end

% Control buttons
controlGrid = uigridlayout(mainGrid, [1 4]);
controlGrid.Layout.Row = 2;
controlGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};

btnAdd = uibutton(controlGrid, 'Text', '＋ Add', ...
    'ButtonPushedFcn', @addColor);

btnRemove = uibutton(controlGrid, 'Text', '－ Remove', ...
    'ButtonPushedFcn', @removeColor);

btnReset = uibutton(controlGrid, 'Text', '↻ Reset', ...
    'ButtonPushedFcn', @resetDefault);

btnSave = uibutton(controlGrid, 'Text', '💾 Save', ...
    'ButtonPushedFcn', @savePalette);

% Callback functions
    function changeColor(idx)
        newColor = uisetcolor(palette(idx,:));
        if ~isequal(newColor, 0)
            palette(idx,:) = newColor;
            colorButtons(idx).BackgroundColor = newColor;
            colorButtons(idx).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', newColor(1), newColor(2), newColor(3));
        end
    end

    function addColor(~,~)
        palette = [palette; rand(1,3)]; % Add random color
        updateSwatches();
    end

    function removeColor(~,~)
        if size(palette,1) > 1
            palette(end,:) = []; % Remove last color
            updateSwatches();
        else
            uialert(fig, 'You must keep at least one color', 'Warning');
        end
    end

    function resetDefault(~,~)
        palette = linspecer(6); % Reset to default
        updateSwatches();
    end

    function savePalette(~,~)
        save(paletteFile, 'palette');
        uialert(fig, 'Palette saved successfully!', 'Success', 'Icon', 'success');
    end

    function updateSwatches()
        % Delete old grid
        delete(swatchGrid.Children);

        % Create new grid with updated dimensions
        swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
        swatchGrid.Layout.Row = 1;
        swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
        swatchGrid.RowHeight = {'1x'};

        % Recreate color buttons
        colorButtons = gobjects(size(palette,1), 1);
        for i = 1:size(palette,1)
            colorButtons(i) = uibutton(swatchGrid);
            colorButtons(i).BackgroundColor = palette(i,:);
            colorButtons(i).Text = '';
            colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
            colorButtons(i).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', palette(i,1), palette(i,2), palette(i,3));
        end
    end
end

function palette = getCurrentPalette(baseDir)
% Check for custom palette file
paletteFile = fullfile(baseDir, 'OUT', 'customPalette.mat');

if exist(paletteFile, 'file')
    % Load custom palette
    load(paletteFile, 'palette');
else
    % Use default palette (linspecer or any other default)
    palette = linspecer(8); % Default to 8 handles.colors
end
end
%% Calculations

% CalcVolumeOverlap - GUI-triggered function to calculate 3D overlaps between volumes
function CalcVolumeOverlap(handles)

% CalcVolumeOverlap - Estimates volume overlap between all volume pairs using voxel grid method
handles.msgLabel.Text = sprintf('Starting Overlap calculation between volumes.');
handles.msgLabel.FontColor = handles.colors.statusPending;
drawnow;

volumesAll = loadVolumesFromTable(handles.t, handles.baseDir);
excludeCol = handles.colIdx.Exclude;
includedIdx = find(~cellfun(@(x) isequal(x, true), handles.t.Data(:, excludeCol)));
volumes = volumesAll(includedIdx);

flipDirection = lower(handles.flipDropdown.Value); % 'none', 'left', or 'right'

% Load brain to determine midline
[~, ~, brain_data] = getAtlasFilesForType(handles.t.Data{find(~cellfun(@isempty, handles.t.Data(:,3)), 1), 3});
midline = mean([min(brain_data.brain.v(:,2)), max(brain_data.brain.v(:,2))]);

% Apply flipping logic if needed
for i = 1:numel(volumes)

    vol = volumes(i);
    flipped = false;

    if strcmp(flipDirection, 'right') && isfield(vol, 'hemi') && strcmpi(vol.hemi, 'left')
        flip_idx = vol.smoothedVertices(:,2) < midline;
        vol.smoothedVertices(flip_idx,2) = 2 * midline - vol.smoothedVertices(flip_idx,2);
        flipped = true;
    elseif strcmp(flipDirection, 'left') && isfield(vol, 'hemi') && strcmpi(vol.hemi, 'right')
        flip_idx = vol.smoothedVertices(:,2) > midline;
        vol.smoothedVertices(flip_idx,2) = 2 * midline - vol.smoothedVertices(flip_idx,2);
        flipped = true;
    end

    if flipped
        volumes(i).smoothedVertices = vol.smoothedVertices;
        volumes(i).ChannelName = [vol.ChannelName '_flip'];
    end
end

outDir = fullfile(handles.baseDir, 'OUT');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

resolution = 10; % µm, * atlas resolution !
plotResults = false; %default, have not tried with true but should work

if plotResults
    figDir = fullfile(outDir, 'FIG-VOL');
    if ~exist(figDir, 'dir'), mkdir(figDir); end
end

% Precompute voxel-based volume estimates and grid points
nVol = numel(volumes);
estVolumes = zeros(1, nVol);
gridInside = cell(1, nVol);

for i = 1:nVol
    vol = volumes(i);
    mins = min(vol.smoothedVertices);
    maxs = max(vol.smoothedVertices);
    [X, Y, Z] = ndgrid(mins(1):resolution:maxs(1), ...
        mins(2):resolution:maxs(2), ...
        mins(3):resolution:maxs(3));
    grid_points = [X(:), Y(:), Z(:)];
    inside_mask = inpolyhedron(vol.k1, vol.smoothedVertices, grid_points);
    gridInside{i} = grid_points(inside_mask, :);
    estVolumes(i) = size(gridInside{i}, 1) * resolution^3;
end

% Compare all pairs
overlapResults = struct('animal1', {}, 'channel1', {}, 'animal2', {}, 'channel2', {}, ...
    'Comp', {}, 'volume', {}, 'overlap_volume', {}, 'overlap_percentage', {});

for i = 1:nVol
    vol1 = volumes(i);
    
    % --- PROGRESS BAR DISPLAY (per volume)
    nBlocks = 20;  % Number of visual blocks in the progress bar
    progress = i / length(volumes);
    filledBlocks = round(progress * nBlocks);
    barStr = [repmat('█', 1, filledBlocks), repmat('░', 1, nBlocks - filledBlocks)];
    handles.msgLabel.Text = sprintf('Calculating Overlap [%s] %d/%d Volumes', barStr, i, length(volumes));
    drawnow;
    

    for j = i+1:nVol

        vol2 = volumes(j);

        % --- vol1 → vol2
        overlap_mask_12 = inpolyhedron(vol2.k1, vol2.smoothedVertices, gridInside{i});
        overlap_points_12 = gridInside{i}(overlap_mask_12, :);
        overlap_volume_12 = sum(overlap_mask_12) * resolution^3;
        perc1 = (overlap_volume_12 / estVolumes(i)) * 100;

        overlapResults(end+1) = struct( ...
            'animal1', vol1.Animal, ...
            'channel1', vol1.ChannelName, ...
            'animal2', vol2.Animal, ...
            'channel2', vol2.ChannelName, ...
            'Comp', [vol1.ChannelName, '-', vol2.ChannelName], ...
            'volume', estVolumes(i), ...
            'overlap_volume', overlap_volume_12, ...
            'overlap_percentage', perc1);

        % --- vol2 → vol1
        overlap_mask_21 = inpolyhedron(vol1.k1, vol1.smoothedVertices, gridInside{j});
        overlap_points_21 = gridInside{j}(overlap_mask_21, :);
        overlap_volume_21 = sum(overlap_mask_21) * resolution^3;
        perc2 = (overlap_volume_21 / estVolumes(j)) * 100;

        overlapResults(end+1) = struct( ...
            'animal1', vol2.Animal, ...
            'channel1', vol2.ChannelName, ...
            'animal2', vol1.Animal, ...
            'channel2', vol1.ChannelName, ...
            'Comp', [vol2.ChannelName, '-', vol1.ChannelName], ...
            'volume', estVolumes(j), ...
            'overlap_volume', overlap_volume_21, ...
            'overlap_percentage', perc2);

        % --- Optional plot for 12 (or both directions if wanted)
        if plotResults
            alphaVal = 0.2;
            f = figure('Color', 'w');
            hold on
            patch('Vertices', vol1.smoothedVertices, 'Faces', vol1.k1, ...
                'FaceColor', vol1.channelColor, 'FaceAlpha', alphaVal, 'EdgeColor', 'none');
            patch('Vertices', vol2.smoothedVertices, 'Faces', vol2.k1, ...
                'FaceColor', vol2.channelColor, 'FaceAlpha', alphaVal, 'EdgeColor', 'none');
            scatter3(overlap_points_12(:,1), overlap_points_12(:,2), overlap_points_12(:,3), 10, 'k', 'filled');
            legend({vol1.ChannelName, vol2.ChannelName, 'Overlap'});
            axis equal; axis off; view(3); rotate3d on
            title(sprintf('%s × %s', vol1.ChannelName, vol2.ChannelName));
            savefig(f, fullfile(figDir, sprintf('%s--%s_overlap.fig', ...
                vol1.ChannelName, vol2.ChannelName)));
            close(f);
        end
    end
end



% Export to CSV
resultsTable = struct2table(overlapResults);
csvname = fullfile(outDir, sprintf('VOL3D_VolumeOverlap.csv'));
writetable(resultsTable, csvname);

% ---- Generate Overlap Heatmap ----
labels = cellfun(@(a, c) sprintf('%s_%s', a, c), ...
    {overlapResults.animal1}, {overlapResults.channel1}, 'UniformOutput', false);
uniqueLabels = unique(labels, 'stable');
n = numel(uniqueLabels);

heatMatrix = nan(n);  % initialize with NaN
for k = 1:numel(overlapResults)
    row = find(strcmp(uniqueLabels, ...
        sprintf('%s_%s', overlapResults(k).animal1, overlapResults(k).channel1)));
    col = find(strcmp(uniqueLabels, ...
        sprintf('%s_%s', overlapResults(k).animal2, overlapResults(k).channel2)));
    heatMatrix(row, col) = overlapResults(k).overlap_percentage;
end

% Add self-comparisons = 100%
for k = 1:n
    heatMatrix(k,k) = 100;
end

% Create heatmap figure
figHeat = figure('Color', 'w', 'Name', 'Volume Overlap Heatmap');
imagesc(heatMatrix);
colormap(parula);
colorbar;
caxis([0 100]);
xticks(1:n);
yticks(1:n);
xticklabels(uniqueLabels);
yticklabels(uniqueLabels);
set(gca, 'TickLabelInterpreter', 'none');  % 👈 prevents subscript formatting
xtickangle(45);
title('Volume Overlap (% of Row Volume in Column)');
axis equal tight;

% Save it
heatname = fullfile(outDir, sprintf('VOL3D_VolumeOverlap_Heatmap.png'));
exportgraphics(figHeat, heatname, 'Resolution', 300);
savefig(figHeat, strrep(heatname, '.png', '.fig'));
% close(figHeat);

handles.msgLabel.Text = sprintf('✅ Volume overlap results saved:\n%s', csvname);
handles.msgLabel.FontColor = handles.colors.successColor;
guidata(handles.fig, handles);
end

%% ---------- select ABA structs as extra GUI

function SelectABAStruct(handles)
% GUI to select ABA structures for volume overlap analysis

handles.msgLabel.Text = 'Select Brain structures in new window and save.';
handles.msgLabel.FontColor = handles.colors.statusPending;
drawnow;

atlasCol = handles.colIdx.AtlasType;
excludeCol = handles.colIdx.Exclude;
includedIdx = find(~cellfun(@(x) isequal(x, true), handles.t.Data(:, excludeCol)));
includedAtlasTypes = handles.t.Data(includedIdx, atlasCol);
atlasType = unique(includedAtlasTypes);

if numel(atlasType) ~= 1
    handles.msgLabel.Text = 'Error: All included volumes must have the same Atlas Type.';
    handles.msgLabel.FontColor = handles.colors.errorRed;
    return;
end
atlasType = atlasType{1}; % Convert from cell to string

[~, ~, st] = load_atlas_files(atlasType);

% Keep only relevant columns
if ~ismember('safe_name', st.Properties.VariableNames)
    error('Expected column "safe_name" not found in structure tree.');
end
if ~ismember('depth', st.Properties.VariableNames)
    st.depth = nan(height(st),1); % dummy depth
end
if ~ismember('structure_id_path', st.Properties.VariableNames)
    st.structure_id_path = repmat("error", height(st), 1);
end
st.Include = false(height(st),1);
st = st(:, {'depth', 'safe_name', 'structure_id_path', 'Include'});


% Create figure
f = uifigure('Name', 'Select ABA Structures for overlap calculations', 'Position', [100 100 800 600]);

% Layout
gl = uigridlayout(f, [2, 1]);
gl.RowHeight = {80, '1x'};

% --- Top Controls
ctrlLayout = uigridlayout(gl, [1,7]);
ctrlLayout.Layout.Row = 1;
ctrlLayout.ColumnWidth = {'1x','1x','1x','fit','fit','fit','fit'};

% Buttons
uibutton(ctrlLayout, 'Text', 'Select None', ...
    'ButtonPushedFcn', @(btn,event) setInclude(false));
uibutton(ctrlLayout, 'Text', 'Select All', ...
    'ButtonPushedFcn', @(btn,event) setInclude(true));
uibutton(ctrlLayout, 'Text', 'Select Cortical', ...
    'ButtonPushedFcn', @(btn,event) selectCortical('all'));
uibutton(ctrlLayout, 'Text', 'Select Broad Cortical', ...
    'ButtonPushedFcn', @(btn,event) selectCortical('broad'));

% Depth Filter
% Safe fallback for max depth
depthVals = st.depth;
depthVals = depthVals(~isnan(depthVals)); % remove NaNs
if isempty(depthVals)
    maxDepth = 9; % fallback if all NaN
else
    maxDepth = double(max(depthVals));
end

lbl = uilabel(ctrlLayout, 'Text', 'Depth cutoff:');

depthInput = uieditfield(ctrlLayout, 'numeric', ...
    'Value', maxDepth, ...
    'Limits', [0, maxDepth + 1], ...
    'ValueChangedFcn', @(src,event) selectByDepth());

uibutton(ctrlLayout, 'Text', 'Apply Depth Filter (≤)', ...
    'ButtonPushedFcn', @(btn,event) setInclude(st.depth == 1));

% --- Table with search
tabPanel = uipanel(gl); tabPanel.Layout.Row = 2;
tabLayout = uigridlayout(tabPanel, [3 1]);
tabLayout.RowHeight = {40, '1x', 30};  % Search, Table, Summary
tabLayout.Padding = [0 0 0 0];  % no padding for tight fit

% --- Search + Reset Row
% Change layout to 1x3 for search + reset + select filtered
searchLayout = uigridlayout(tabLayout, [1, 3]);
searchLayout.RowHeight = {'fit'};
searchLayout.ColumnWidth = {'1x', 'fit', 'fit'};  % Search, Reset, Select Filtered

% Search bar
searchField = uieditfield(searchLayout, 'Text', ...
    'Placeholder', 'Search structure name...', ...
    'ValueChangedFcn', @(src,event) filterTable());

% Reset button
uibutton(searchLayout, 'Text', 'Reset', ...
    'ButtonPushedFcn', @(btn,event) clearSearch());

% NEW: Select Filtered button
uibutton(searchLayout, 'Text', 'Select Filtered', ...
    'ButtonPushedFcn', @(btn,event) selectFiltered());

tbl = uitable(tabLayout, 'Data', st, ...
    'ColumnEditable', [false false false true], ...
    'ColumnWidth', {80, '1x', 0, 80}, ...
    'CellEditCallback', @(tbl, event) syncEdits(tbl, event));

% Replace: summaryTbl = uitable(tabLayout, ...
% With new layout (1 row, 2 columns)
summaryLayout = uigridlayout(tabLayout, [1, 2]);
summaryLayout.RowHeight = {'fit'};
summaryLayout.ColumnWidth = {'3x', 'fit'};
summaryLayout.Padding = [0 0 0 0];         % Remove any padding that might affect sizing

% Summary Table
summaryTbl = uitable(summaryLayout, ...
    'Data', {'Total:', height(st), 'Selected:', sum(st.Include)}, ...
    'ColumnEditable', [false, false, false, false], ...
    'ColumnName', {}, ...
    'RowName', {}, ...
    'ColumnWidth', {'1x', '1x', '1x', '1x'}, ...
    'RowStriping', 'off', ...
    'Tag', 'summaryTbl');

% Save Button
uibutton(summaryLayout, ...
    'Text', 'Save Selection', ...
    'ButtonPushedFcn', @(btn, event) saveSelectionToHandles());


% --- Callbacks ---

    function setInclude(mask)
        if islogical(mask) && isvector(mask) && numel(mask) == height(st)
            st.Include = mask;
        elseif isnumeric(mask) || islogical(mask)
            st.Include(:) = false;
            st.Include(mask) = true;
        end

        % Refresh table data without breaking search filter
        filterTable();  % keeps view consistent
        updateSummary();
    end

function selectFiltered()
    filteredNames = tbl.Data.safe_name;
    for k = 1:numel(filteredNames)
        matchIdx = strcmp(st.safe_name, filteredNames{k});
        st.Include(matchIdx) = true;
    end
    tbl.Data = st(ismember(st.safe_name, filteredNames), :);
    updateSummary();
end

    function clearSearch()
        searchField.Value = '';
        filterTable();  % respects the latest st.Include

    end

function syncEdits(tbl, event)
    % Get the row in the filtered table view
    editedRow = event.Indices(1);
    
    % Get the corresponding row in st by matching unique ID (e.g., safe_name)
    editedName = tbl.Data.safe_name{editedRow};
    
    % Find the matching row in st
    matchIdx = strcmp(st.safe_name, editedName);
    
    % Update the Include value
    st.Include(matchIdx) = tbl.Data.Include(editedRow);
    
    % Update summary
    updateSummary();
end



    function selectCortical(mode)
        % Find ID of Isocortex
        isoIdx = find(strcmpi(st.safe_name, 'Isocortex'), 1);

        if isempty(isoIdx)
            uialert(f, 'Isocortex not found in structure tree.', 'Error');
            return;
        end

        isoID = st.structure_id_path(isoIdx);

        if iscell(isoID)
            isoID = isoID{1};  % unwrap from cell
        end

        % Ensure everything is a string
        allPaths = string(st.structure_id_path);      % convert full column to string
        isoIDstr = string(isoID);                     % convert the ID to string

        % Find all that start with the isocortex path
        isoPath = allPaths(strcmp(st.safe_name, 'Isocortex'));  % or however you found isoID earlier
        pathMask = startsWith(allPaths, isoPath);

        % Filter based on mode
        switch lower(mode)
            case 'broad'
                pathMask = pathMask & ~contains(lower(string(st.safe_name)), 'layer');
            case 'all'
                % Do nothing extra
            otherwise
                uialert(f, sprintf('Unknown cortical mode: %s', mode), 'Invalid Option');
                return;
        end

        % Mark all rows where structure_id_path starts with the Isocortex ID
        setInclude(pathMask);
    end

    function selectByDepth()
        val = depthInput.Value;
        mask = st.depth <= val;
        setInclude(mask);  % reuse your helper!
    end

    function filterTable()
        txt = lower(strtrim(searchField.Value));
        if isempty(txt)
            tbl.Data = st;
        else
            mask = contains(lower(st.safe_name), txt);
            tbl.Data = st(mask, :);
        end
        updateSummary();
    end


    function updateSummary()
        total = height(st);
        selected = sum(st.Include);
        summaryTbl.Data = {'Total:', total, 'Selected:', selected};
    end

function saveSelectionToHandles()
    selectedStructs = st(st.Include, :);
    handles.selectedStructs = selectedStructs;

   
    % Store back in main GUI figure
    guidata(handles.fig, handles);

    % Enable the button in the main GUI
    mainHandles = guidata(handles.fig);  % Refresh
    btn = findobj(mainHandles.fig, 'Tag', 'btnCalcABAOverlap');
    if ~isempty(btn)
        btn.Enable = 'on';
    end

    % Optional confirmation
    uialert(f, sprintf('Saved %d selected structures for overlap calculation.%sClose this window and proceed.', height(selectedStructs), char(10)), ...
        'Selection Saved', 'Icon', 'success');


end


end



function CalcABAOverlap(handles)
% GUI-driven function to calculate volume overlap with selected ABA structures
handles = guidata(handles.fig);

handles.msgLabel.Text = sprintf('Starting Overlap calculation with selected brain structures.');
handles.msgLabel.FontColor = handles.colors.statusPending;
drawnow;

if ~isfield(handles, 'selectedStructs') || isempty(handles.selectedStructs)
    handles.msgLabel.Text = sprintf('No Brain structures selected. Please select first.');
    handles.msgLabel.FontColor = handles.colors.errorRed;
    return;
end

selectedStructs = handles.selectedStructs;

% Filter to only included volumes
excludeCol = handles.colIdx.Exclude;
excludeFlags = cellfun(@(x) isequal(x, true), handles.t.Data(:, excludeCol));
includedIdx = ~excludeFlags;
volumes = handles.volumes(includedIdx);

outDir = fullfile(handles.baseDir, 'OUT');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
atlasType = handles.t.Data{find(~cellfun(@(x) isequal(x, true), handles.t.Data(:, handles.colIdx.Exclude)), 1), handles.colIdx.AtlasType};
[~, av, st] = load_atlas_files(atlasType);

% Settings
resolution = 10; % µm
plotResults = false; %internally set to false
slice_spacing = 5;
reduced_av = av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end);

% Plot output dir
if plotResults
    figDir_ABA = fullfile(outDir, 'FIG-ABA');
    if ~exist(figDir_ABA, 'dir'), mkdir(figDir_ABA); end
end

% Prepare structure meshes
struct_vol = struct;
validStructIdx = 0;

for i = 1:height(selectedStructs)
    if ~selectedStructs.Include(i), continue; end

    pathStr = selectedStructs.structure_id_path{i};
    matchedIdx = find(contains(st.structure_id_path, pathStr));
    if isempty(matchedIdx), continue; end

    mask = ismember(reduced_av, matchedIdx);
    structure_3d = isosurface(permute(mask, [3,1,2]), 0);

    if ~isempty(structure_3d.vertices)
        validStructIdx = validStructIdx + 1;
        struct_vol(validStructIdx).name = selectedStructs.safe_name{i};
        struct_vol(validStructIdx).vertices = structure_3d.vertices * slice_spacing;
        struct_vol(validStructIdx).faces = structure_3d.faces;
    end
end

% Calculate overlap
overlapResults = struct('Group',{}, 'Animal', {}, 'ChannelName', {}, 'Structure', {}, 'Volume', {}, 'overlap_volume', {}, 'overlap_fraction_original', {}, 'overlap_fraction_structure', {});
for v = 1:length(volumes)

    % --- PROGRESS BAR DISPLAY (per volume)
    nBlocks = 20;  % Number of visual blocks in the progress bar
    progress = v / length(volumes);
    filledBlocks = round(progress * nBlocks);
    barStr = [repmat('█', 1, filledBlocks), repmat('░', 1, nBlocks - filledBlocks)];
    handles.msgLabel.Text = sprintf('Calculating Overlap [%s] %d/%d Volumes', barStr, v, length(volumes));
    drawnow;


    vol = volumes(v);
    if ~isfield(vol, 'smoothedVertices') || isempty(vol.smoothedVertices), continue; end

    % Create voxel grid
    mins = min(vol.smoothedVertices); maxs = max(vol.smoothedVertices);
    [X, Y, Z] = ndgrid(mins(1):resolution:maxs(1), ...
                       mins(2):resolution:maxs(2), ...
                       mins(3):resolution:maxs(3));
    grid_points = [X(:), Y(:), Z(:)];
    inside_mask = inpolyhedron(vol.k1, vol.smoothedVertices, grid_points);
    vol_inside = grid_points(inside_mask, :);
    vol_volume = size(vol_inside,1) * resolution^3;

    for s = 1:validStructIdx
        structSurf = struct_vol(s);

        % Check overlap
        overlap_mask = inpolyhedron(structSurf.faces, structSurf.vertices, vol_inside);
        overlap_points = vol_inside(overlap_mask, :);
        overlap_volume = sum(overlap_mask) * resolution^3;

        % Structure volume estimation
        struct_mask = inpolyhedron(structSurf.faces, structSurf.vertices, structSurf.vertices);
        struct_volume = sum(struct_mask) * resolution^3;

        % Store result
        overlapResults(end+1) = struct( ...
            'Group', vol.Group, ...
            'Animal', vol.Animal, ...
            'ChannelName', vol.ChannelName, ...
            'Structure', structSurf.name, ...
            'Volume', vol_volume, ...
            'overlap_volume', overlap_volume, ...
            'overlap_fraction_original', 100 * overlap_volume / vol_volume, ...
            'overlap_fraction_structure', 100 * overlap_volume / struct_volume);
        
        if plotResults
            f = figure('Color', 'w'); hold on
            patch('Vertices', vol.smoothedVertices, 'Faces', vol.k1, 'FaceAlpha', 0.2, 'FaceColor', vol.channelColor, 'EdgeColor', 'none');
            patch('Vertices', structSurf.vertices, 'Faces', structSurf.faces, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            scatter3(overlap_points(:,1), overlap_points(:,2), overlap_points(:,3), 10, 'k', 'filled');
            legend('Volume', 'Structure', 'Overlap');
            title(sprintf('%s overlap with %s', vol.channel, structSurf.name));
            savefig(f, fullfile(figDir_ABA, sprintf('%s_%s_overlap.fig', vol.channel, structSurf.name)));
            close(f);
        end
    end
end

% Export
overlapTable = struct2table(overlapResults);
savename = fullfile(outDir, 'VOL3D_Overlap_With_Brain_Structures.csv');
writetable(overlapTable, savename);

% Feedback
handles.msgLabel.Text = sprintf('Brain structure overlap saved:\n%s', savename);
handles.msgLabel.FontColor = handles.colors.successColor;
guidata(handles.fig, handles);
end



%% helper functions


function openHelpDialog()
% Create a uifigure for the help dialog
helpFig = uifigure('Name', 'VOL3D - Group Manager Help', 'Position', [100 100 800 700]);
helpFig.Resize = 'off';
helpFig.Color = [0.96 0.96 0.96]; % Match GUI's lightBg color

% Create a panel that will contain the text control
helpPanel = uipanel(helpFig, 'Position', [10 10 780 680], 'BorderType', 'none');
helpPanel.BackgroundColor = [1 1 1]; % White background
helpPanel.HighlightColor = [0.24 0.48 0.54]; % Cerulean border

% Define help text sections
header = '<html><body style="font-family:Arial; font-size:12px; color:#16262E; line-height:1.6;">';

section1 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">VOL3D Group Manager Overview</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p>This GUI manages 3D volume data after transformation to CCF space, allowing for:</p>'...
    '<ul style="margin-top:10px; line-height:1.5;">'...
    '<li>✅ <b>Group Organization:</b> Assign experimental groups and colors to volumes</li>'...
    '<li>✅ <b>3D Visualization:</b> Preview volume overlaps and spatial relationships</li>'...
    '<li>✅ <b>Quantitative Analysis:</b> Calculate volume overlaps and brain structure colocalization</li>'...
    '<li>✅ <b>Batch Export:</b> Generate consistent plots across conditions</li>'...
    '</ul>'...
    '<p style="color:#CC3333;"><b>Prerequisite:</b> Volumes must be processed through VOL3D Step 1 first.</p>'...
    '</div>'];

section2 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Data Management</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p><b>Main Table Columns:</b></p>'...
    '<table border="1" cellpadding="5" style="border-collapse:collapse; width:100%; margin-bottom:10px;">'...
    '<tr><th style="background-color:#E6E6E6;">Column</th><th style="background-color:#E6E6E6;">Description</th></tr>'...
    '<tr><td>File Label</td><td>Original volume filename</td></tr>'...
    '<tr><td>Animal</td><td>Animal ID from processing</td></tr>'...
    '<tr><td>Atlas Type</td><td>Developmental or adult atlas used</td></tr>'...
    '<tr><td>Group</td><td><b>Editable:</b> Experimental group assignment</td></tr>'...
    '<tr><td>Channel</td><td>Fluorescence channel (C1, C2, etc.)</td></tr>'...
    '<tr><td>Channel Name</td><td><b>Editable:</b> Descriptive name for channel</td></tr>'...
    '<tr><td>PlotColor</td><td><b>Editable:</b> Click to select display color</td></tr>'...
    '<tr><td>Exclude</td><td><b>Checkbox:</b> Remove from analysis/plots</td></tr>'...
    '<tr><td>ColorSource</td><td>Auto-generated (Group/Channel/Manual)</td></tr>'...
    '</table>'...
    '<ul>'...
    '<li><b>📁 Change Folder:</b> Switch to different volume data folder</li>'...
    '<li><b>💾 Save Metadata:</b> Stores current table state to <code>OUT/metadata.mat</code></li>'...
    '</ul>'...
    '</div>'];

section3 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Color Management</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p><b>Color Assignment Methods:</b></p>'...
    '<ul>'...
    '<li><b>Set plotColor by Group:</b> Automatically colors all volumes by their group assignment</li>'...
    '<li><b>Set plotColor by Channel:</b> Colors volumes by their fluorescence channel</li>'...
    '<li><b>Manual Color:</b> Click any color cell to select custom colors (choose "other...")</li>'...
    '</ul>'...
    '<p><b>Color By Dropdown:</b> Determines how colors are interpreted in the preview plot:</p>'...
    '<ul>'...
    '<li><b>plotColor:</b> Uses exact colors from table</li>'...
    '<li><b>Animal/Group/Channel:</b> Dynamically maps categories to colors</li>'...
    '<li><b>Hemisphere:</b> Colors by left/right hemisphere (if data contains this info)</li>'...
    '</ul>'...
    '<p><b>🎨 Define Palette:</b> Opens color palette editor to customize categorical color schemes</p>'...
    '</div>'];

section4 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Visualization & Analysis</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p><b>3D View Controls:</b></p>'...
    '<ul>'...
    '<li><b>Side/Top/Front Views:</b> Preset camera angles</li>'...
    '<li><b>↔️ Flip to Hemisphere:</b> Mirror volumes across midline for comparison</li>'...
    '<li><b>🔄 Update Preview Plot:</b> Refresh with current settings</li>'...
    '<li><b>💾 Save Preview Plot:</b> Export current view as PNG/FIG</li>'...
    '</ul>'...
    '<p><b>Analysis Tools:</b></p>'...
    '<ul>'...
    '<li><b>Calculate Overlap btw Volumes:</b> Quantifies overlap between all volume pairs</li>'...
    '<li><b>Select Brain Structures:</b> Choose ABA regions for structure-specific analysis</li>'...
    '<li><b>Calculate Overlap with Brain Structures:</b> After selection, compute overlap with chosen regions</li>'...
    '</ul>'...
    '<p style="color:#CC3333;"><b>Note:</b> Overlap calculations use voxel-based approximation at 10µm resolution (CCF space). Atlas resolution not considered.</p>'...
    '</div>'];

section5 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Batch Export</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p><b>How to use batch plotting:</b></p>'...
    '<ol>'...
    '<li>Check "Show Batch Save Options"</li>'...
    '<li>Select how to <b>split</b> plots (none, by group, by animal, or by channel)</li>'...
    '<li>Choose what to <b>color by</b> in each plot</li>'...
    '<li>Add optional filename prefix</li>'...
    '<li>Click "Save Batch Plots"</li>'...
    '</ol>'...
    '<p><b>Output Files:</b></p>'...
    '<ul>'...
    '<li>Each combination generates a multi-panel figure with consistent scaling</li>'...
    '<li>Files are saved to <code>OUT/</code> with descriptive names</li>'...
    '<li>Includes both PNG (high-res image) and FIG (editable MATLAB figure)</li>'...
    '</ul>'...
    '</div>'];

section6 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Output Files Explained</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p><b>Volume Overlap Analysis:</b> (from Calculate Overlap buttons)</p>'...
    '<table border="1" cellpadding="5" style="border-collapse:collapse; width:100%; margin-bottom:10px;">'...
    '<tr><th style="background-color:#E6E6E6;">File</th><th style="background-color:#E6E6E6;">Contents</th></tr>'...
    '<tr><td>VOL3D_VolumeOverlap.csv</td><td>Pairwise overlap metrics between volumes</td></tr>'...
    '<tr><td>VOL3D_VolumeOverlap_Heatmap.png</td><td>Visual summary of overlap percentages</td></tr>'...
    '<tr><td>VOL3D_Overlap_With_Brain_Structures.csv</td><td>Structure-specific overlap metrics</td></tr>'...
    '</table>'...
    '<h3 style="color:#3C7A89; margin-top:15px;">Volume Calculation Details</h3>'...
    '<ul>'...
    '<li><b>Calculation Method:</b> The voxel-based estimation uses 10µm grid spacing to fill volume. Based on this, volume estimation is calculated (sum of voxels).</li>'...
    '<li><b>This does not take into account the actual scaling of the atlas!</b> Adult Atlas (10µm), Developmental Atlas (20µm)</li>'...
    '</ul>'...
    '<table border="1" cellpadding="5" style="border-collapse:collapse; width:100%; margin-top:10px;">'...
    '<tr><th style="background-color:#E6E6E6;">Column</th><th style="background-color:#E6E6E6;">Description</th></tr>'...
    '<tr><td>overlap_volume</td><td>Absolute overlap volume in µm³</td></tr>'...
    '<tr><td>overlap_percentage</td><td>% of row volume that overlaps column volume</td></tr>'...
    '<tr><td>overlap_fraction_structure</td><td>For ABA analysis, % of structure volume occupied</td></tr>'...
    '</table>'...
    '</div>'];

section7 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Resources & Technical Notes</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
    '<p><b>Key Technical Details:</b></p>'...
    '<ul>'...
    '<li>Volume calculations use <code>inpolyhedron</code> for robust 3D containment testing</li>'...
    '<li>Default grid spacing (10µm) applied</li>'...
    '<li>All spatial coordinates follow CCF orientation standards</li>'...
    '</ul>'...
    '<p><b>External Resources:</b></p>'...
    '<ul>'...
    '<li><a href="https://github.com/cortex-lab/AP_histology" target="_blank">📦 AP_histology GitHub Repository</a></li>'...
    '<li><a href="https://kimlab.io/dev-atlas/" target="_blank">🧭 Kim Lab DevAtlas Website</a></li>'...
    '<li><a href="https://scalablebrainatlas.incf.org/" target="_blank">🌐 Scalable Brain Atlas Reference</a></li>'...
    '</ul>'...
    '</div>'...
    '</body></html>'];

helpText = [header section1 section2 section3 section4 section5 section6 section7];

% Create a HTML-enabled text control
helpTextControl = uihtml(helpPanel, 'Position', [10 10 760 660]);
helpTextControl.HTMLSource = helpText;
end

function allPresent = checkDependencies()
% External required functions (from File Exchange)
requiredFunctions = {
    struct('name', 'linspecer', ...
    'url', 'https://www.mathworks.com/matlabcentral/fileexchange/42673-beautiful-and-distinguishable-line-handles.colors-colormap', ...
    'purpose', 'Color generation for distinguishable lines'),
    struct('name', 'inpolyhedron', ...
    'url', 'https://www.mathworks.com/matlabcentral/fileexchange/47245-inpolyhedron', ...
    'purpose', 'Overlap detection between 3D volumes')
    };

% Required toolboxes
requiredToolboxes = {
    struct('name', 'Image Processing Toolbox', 'checkFcn', 'imfinfo'),
    struct('name', 'Statistics and Machine Learning Toolbox', 'checkFcn', 'pca')
    };

% Check missing custom functions
missingFuncs = requiredFunctions(~cellfun(@(x) exist(x.name, 'file'), requiredFunctions));

% Extract installed toolbox names
v = ver;
installed = {v.Name};

% Collect toolbox names
requiredTBnames = cellfun(@(x) x.name, requiredToolboxes, 'UniformOutput', false);
isToolboxMissing = ~ismember(requiredTBnames, installed);
missingToolboxes = requiredToolboxes(isToolboxMissing);

% Combine HTML message if anything is missing
if ~isempty(missingFuncs) || ~isempty(missingToolboxes)
    htmlMsg = '<html><b>Missing Required Dependencies:</b><br><br>';

    if ~isempty(missingFuncs)
        htmlMsg = [htmlMsg '<u>Functions:</u><br>'];
        for i = 1:length(missingFuncs)
            f = missingFuncs{i};
            htmlMsg = [htmlMsg sprintf('• <a href="%s">%s</a><br><i>%s</i><br><br>', ...
                f.url, f.name, f.purpose)];
        end
    end

    if ~isempty(missingToolboxes)
        htmlMsg = [htmlMsg '<u>Toolboxes:</u><br>'];
        for i = 1:length(missingToolboxes)
            htmlMsg = [htmlMsg sprintf('• %s<br>', missingToolboxes{i}.name)];
        end
    end

    htmlMsg = [htmlMsg '</html>'];
    fig = uifigure('Position', [100 100 500 250]);
    uialert(fig, htmlMsg, 'Missing Dependencies', 'Icon', 'error', 'Interpreter', 'html');

    allPresent = false;
else
    allPresent = true;
end
end


