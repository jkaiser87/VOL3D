function [vertices, faces] = loadObj(filePath)
    % loadObj - Simple OBJ file loader for MATLAB
    % This function reads an OBJ file and returns vertices and faces.

    fid = fopen(filePath, 'r');
    if fid == -1
        error('Cannot open the file.');
    end

    vertices = [];
    faces = [];

    % Read the file line by line
    while ~feof(fid)
        tline = fgetl(fid);
        if strncmp(tline, 'v ', 2)
            % Vertex definition
            vertex = sscanf(tline(3:end), '%f %f %f');
            vertices = [vertices; vertex'];
            vertices = vertices/10; % change to pixel/slice value
        elseif strncmp(tline, 'f ', 2)
            % Face definition
            face = sscanf(tline(3:end), '%d %d %d');
            faces = [faces; face'];
        end
    end
    
    fclose(fid);
end