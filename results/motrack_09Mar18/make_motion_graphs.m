%% make_motion_graphs
% Generates motion plots from mock scanning motion tracking data. I want to
% create a plot for each run and give it a corresponding title. I think the
% units are displacement at time (mm @ s). This will involve the following
% steps:
% 1 Read in data from text documents.
% 2 Normalize the data based on the starting time, given in hh:mm:ss.sss
%   format.
% 3 Create each plot.

close all; clearvars; clc; 

%% Parameters

%% Pathing
% This should run as long as you keep this script in the correct folder.
files = dir('*.txt');
num_runs = length(files);

% Preallocate data structure
data(num_runs).XYZ = [];
data(num_runs).PYR = [];
column = fields(data);
num_fields = length(column);

%% Load data
for rr = 1:num_runs
% rr = 1;
    % Open file
    this_file = files(rr).name;
    fid = fopen(this_file);
    
    % Read file using fgetl (variable number of columns)
    ii = 1;
    while 1 
        % Get the line
        this_line = fgetl(fid); 
        if this_line == -1
            break
        end
        
        % Parse the line
        if ii ~= 1 % Skip labels
            C = textscan(this_line, '%s', 'Delimiter', '\t');
            C = C{1};

            this_line_xyz = nan(1, 3);
            this_line_pyr = nan(1, 3);
            idx_xyz = 1;
            idx_pyr = 1;
            
            for jj = 2:7
                this_elem = str2double(C{jj}); 
                
                if any(jj == 2:4) % X, Y, Z
                    this_line_xyz(idx_xyz) = this_elem;
                    idx_xyz = idx_xyz +1;
                    
                elseif any(jj == 5:7) % Pitch, Yaw, Roll
                    this_line_pyr(idx_pyr) = this_elem;
                    idx_pyr = idx_pyr +1;
                    
                end 
                
            end
            all_xyz(ii - 1, :) = this_line_xyz; %#ok<SAGROW>
            all_pyr(ii - 1, :) = this_line_pyr; %#ok<SAGROW>
        end
        ii = ii + 1;
    end
    
    fclose(fid);
    data(rr).XYZ = all_xyz;
    data(rr).PYR = all_pyr;
    num_lines = length(data(rr).XYZ);

    %% Create each plot
    xax = 1:num_lines;
    
    % Make titles
    this_task = this_file(end-8:end-5);
    if strcmp(this_task, 'name')
        name = ['Mock scan motion: Run ' num2str(rr) ': Naming task: '];
    elseif strcmp(this_task, 'list')
        name = ['Mock scan motion: Run ' num2str(rr) ': Listening task: '];
    end
    
    % Plot X, Y, Z
    figure
    plot(xax, data(rr).XYZ(:, 1), xax, data(rr).XYZ(:, 2), xax, data(rr).XYZ(:, 3)) 
    hold on
    axis([1, num_lines, min(min(data(rr).XYZ)), max(max(data(rr).XYZ))])
    legend('X', 'Y', 'Z')
    xlabel('time')
    ylabel('mm')
    set(gca, 'XTickLabel', [])
    title([name, 'XYZ motion'])
    filename = fullfile(pwd, ['moTrack_run' num2str(rr) '_' this_task '_XYZ.png']);
    saveas(gcf, filename)
    
    % Plot Pitch, Yaw, Roll
    figure
    xax = 1:num_lines;
    plot(xax, data(rr).PYR(:, 1), xax, data(rr).PYR(:, 2), xax, data(rr).PYR(:, 3))
    hold on
    axis([1, num_lines, min(min(data(rr).PYR)), max(max(data(rr).PYR))])
    legend('Pitch', 'Yaw', 'Roll')
    xlabel('time')
    ylabel('deg')
    set(gca, 'XTickLabel', [])
    title([name, 'Radial motion'])
    filename = fullfile(pwd, ['moTrack_run' num2str(rr) '_' this_task '_PYR.png']);
    saveas(gcf, filename)
    
end