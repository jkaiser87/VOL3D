function [tv, av, st] = load_ABA_files()

allen_atlas_path = fullfile('D:\MATLAB\AP_histology\allenAtlas');
tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']);
st = loadStructureTree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']); % a table of what all the labels mean

end