%copy into Documents > MATLAB folder
function organizeFiles(currentPath, basePath, animalName)
    % Get a list of all items in the current directory
    items = dir(currentPath);
    items = items(~ismember({items.name}, {'.', '..'})); % Exclude '.' and '..'

    for i = 1:length(items)
        fullPath = fullfile(currentPath, items(i).name);

        if items(i).isdir
            % Recursively handle directories, skipping the target animalName directory
            if ~strcmp(items(i).name, animalName)
                organizeFiles(fullPath, basePath, animalName);
            end
        else
            % Move files containing the animal name in their filename
            if contains(items(i).name, animalName)
                % Construct the relative path excluding the base path
                relativePath = strrep(fullPath, [basePath filesep], '');
                % Define the target path, preserving the original folder structure
                targetPath = fullfile(basePath, animalName, relativePath);
                
                % Ensure the target directory exists
                if ~exist(fileparts(targetPath), 'dir')
                    mkdir(fileparts(targetPath));
                end
                
                % Move the file
                movefile(fullPath, targetPath);
            end
        end
    end
end