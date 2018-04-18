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
    ax = 1:num_lines;
    
    % Make titles
    this_task = this_file(end-7:end-5);
    if strcmp(this_task, 'exp')
        name = ['Mock scan motion: Run ' num2str(rr) ': Naming task: '];
    elseif strcmp(this_task, 'ure')
        name = ['Mock scan motion: Run ' num2str(rr) ': Picture task: '];
    end
    
    % Plot X, Y, Z
    if rr == 1
        val = 1:1700;
    elseif rr == 2
        val = 120:1750;
    elseif rr == 3
        val = 200:1750;
    elseif rr == 4
        val = 50:1750;
    elseif rr == 5
        val = 110:1750;
    else
        val = ax;
    end
    ax = 1:length(val);
    xyz = [data(rr).XYZ(val, 1), data(rr).XYZ(val, 2), data(rr).XYZ(val, 3)];
    pyr = [data(rr).PYR(val, 1), data(rr).PYR(val, 2), data(rr).PYR(val, 3)];
    
    figure
    plot(ax, xyz(:,1), ax, xyz(:,2), ax, xyz(:,3)) 
    hold on
    axis([1, ax(end), min(min(xyz)), max(max(xyz))])
    legend('X', 'Y', 'Z')
    xlabel('time')
    ylabel('mm')
    set(gca, 'XTickLabel', [])
    title([name, 'XYZ motion'])
    filename = fullfile(pwd, ['moTrack_run' num2str(rr) '_' this_task '_XYZ.png']);
    saveas(gcf, filename)
    
    % Plot Pitch, Yaw, Roll
    figure
    plot(ax, pyr(:,1), ax, pyr(:,2), ax, pyr(:,3))
    hold on
    if any(rr == [1, 2, 3, 8])
        axis([1, ax(end), -3, max(max(pyr))])
    elseif rr == 4
        axis([1, ax(end), -2, 1.5])
    elseif rr == 5
        axis([1, ax(end), -2.5, 2.5])
    elseif rr == 6
        axis([1, ax(end), -2, max(max(pyr))])
    else
        axis([1, ax(end), min(min(pyr)), max(max(pyr))])
    end
    legend('Pitch', 'Yaw', 'Roll')
    xlabel('time')
    ylabel('deg')
    set(gca, 'XTickLabel', [])
    title([name, 'Radial motion'])
    filename = fullfile(pwd, ['moTrack_run' num2str(rr) '_' this_task '_PYR.png']);
    saveas(gcf, filename)
    
end