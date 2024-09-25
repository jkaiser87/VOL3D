function plot_brain_outline()

load('D:/MATLAB/AP_histology/allenAtlas/997.mat','brain');

patch('Vertices', brain.v, ...
    'Faces', brain.f, ...
    'FaceColor', [0.6, 0.6, 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.1);

hold on;
view([90, 90]);
set(gca, 'ZDir', 'Reverse');
axis('vis3d', 'equal', 'off', 'manual', 'tight');
    
ylim([-10, 1140]); % Set appropriate x-axis limits
xlim([-10, 1320]); % Set appropriate y-axis limits
zlim([-10, 800]);  % Set appropriate z-axis limits
daspect([1 1 1]);  % Set data aspect ratio

% Enhance visualization
camlight(355,0,'local'); % top    light
lighting gouraud;      % Smooth shading
%material shiny;        % Glossy appearance
rotate3d on;           % Enable interactive rotation



end