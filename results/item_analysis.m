%% item_analysis
% Analyzes each item of the listening (receptive) grammar task. 
% Author -- Matt Heard

% CHANGELOG (DD Mon YY)
% 26 Mar 18  --  Started script. MH

clear all; clc;

%% Parameters
dir_results = pwd;
dir_data = 'MOCK_09Mar18'; % 'MOCK'

%% Path
cd(dir_data)
files = dir('*per*.xlsx');
num_files = length(files);
disp(['Found ' num2str(num_files) ' exp/listening files in directory ' dir_data])

%% Load data
data(num_files).raw = []; % preallocate struct data, which saves data from each file

for ii = 1:num_files
    
    data(ii).raw = xlsread(files(ii).name, 'run 1');
    data(ii).stimNum = data(ii).raw(:, 9);
    data(ii).ansKey = data(ii).raw(:, 11);
    data(ii).resp = data(ii).raw(:, 12);
    data(ii).RT = data(ii).raw(:, 13);
    data(ii).orsr = mod(data(ii).stimNum, 4);
    disp(['Loaded file ' files(ii).name ' into data struct'])
    
end

disp('Loaded all files into data struct')

%% Analyze data
% 198 total stimuli in \stim\listening_task as of 26 Mar 18
% Mock draws from [129:192] as of 26 Mar 18
% Noise are 197, 198
cor(num_files).all = NaN; % preallocate struct cor, which totals up correct in terms of OR/SR

sent.each = zeros(64, 1); % number of times each unique sentence was correct
sent.skel = zeros(16, 1); % number of times each structure was correct
sent.key = [129:4:192]';  % key of sentence structure

for ii = 1:num_files
    % Set counters to 0
    cor(ii).all = 0;
    cor(ii).O = 0;
    cor(ii).S = 0;
    cor(ii).M = 0;
    cor(ii).F = 0;
    cor(ii).OF = 0;
    cor(ii).OM = 0;
    cor(ii).SF = 0;
    cor(ii).SM = 0;

    
    for jj = 1:length(data(ii).orsr)
        if data(ii).stimNum(jj) < 197
            if data(ii).resp(jj) == data(ii).ansKey(jj) 
                cor(ii).all = cor(ii).all + 1;
                
                % OR/SR accuracy
                if data(ii).orsr(jj) == 1
                    cor(ii).O = cor(ii).O + 1;
                    cor(ii).F = cor(ii).F + 1;
                    cor(ii).OF = cor(ii).OF + 1;
                elseif data(ii).orsr(jj) == 2
                    cor(ii).O = cor(ii).O + 1;
                    cor(ii).M = cor(ii).M + 1;
                    cor(ii).OM = cor(ii).OM + 1;
                elseif data(ii).orsr(jj) == 3
                    cor(ii).S = cor(ii).S + 1;
                    cor(ii).F = cor(ii).F + 1;
                    cor(ii).SF = cor(ii).SF + 1;
                elseif data(ii).orsr(jj) == 0
                    cor(ii).S = cor(ii).S + 1;
                    cor(ii).M = cor(ii).M + 1;
                    cor(ii).SM = cor(ii).SM + 1;
                end
                
                % Item-wise analysis
                thisskel = sum(data(ii).stimNum(jj) >= sent.key);
                thissent = data(ii).stimNum(jj) - 128;
                
                sent.skel(thisskel) = sent.skel(thisskel) + 1;
                sent.each(thissent) = sent.each(thissent) + 1;
                
            end
        end
    end
    
end

% convert to percentages
whichAcc = fields(cor);
num_acc = length(whichAcc);

for ii = 1:num_acc
    acc.(whichAcc{ii}) = 0;
    for jj = 1:num_files
        acc.(whichAcc{ii}) = acc.(whichAcc{ii}) + cor(jj).(whichAcc{ii});
    end
    if ii == 1
        acc.(whichAcc{ii}) = acc.(whichAcc{ii})/(16*num_files);
    elseif ii <= 5
        acc.(whichAcc{ii}) = acc.(whichAcc{ii})/(8*num_files);
    else
        acc.(whichAcc{ii}) = acc.(whichAcc{ii})/(4*num_files);
    end
end

acc.skel = sent.skel/num_files;
acc.each = sent.each/num_files;

%% Make figures
% Object/subject & M/F correct
% Four bars - OM, SM, OF, SF
fig = figure(1);
hold on
y = [acc.OF; acc.OM; acc.SF; acc.SM];
bar(y)
xticks([1, 2, 3, 4])
ylim([0 1])
set(gca, 'xticklabel', {'OF', 'OM', 'SF', 'SM'});
title("Time Woman's Accuracy (listening): Each Sentence Construction")
saveas(fig, 'listening_acc_mock_09Mar18_sentcon.png')

% Object/subject | M/F correct
% Four bars - O, S, M, F
fig = figure(2);
hold on
y = [acc.O; acc.S; acc.M; acc.F];
bar(y)
xticks([1, 2, 3, 4])
ylim([0 1])
set(gca, 'xticklabel', {'O', 'S', 'M', 'F'});
title("Time Woman's Accuracy (listening): Each Sentence Category")
saveas(fig, 'listening_acc_mock_09Mar18_sentcat.png')

% Skeleton analysis
% Sixteen bars - one for each sentence structure
fig = figure(3);
hold on
y = acc.skel;
bar(y)
ylim([0 1])
xlim([0 17])
xticks(1:16)
title("Time Woman's Accuracy (listening): Each Sentence Skeleton")
saveas(fig, 'listening_acc_mock_09Mar18_sentske.png')
