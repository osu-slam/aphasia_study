%% OutputData_reading.m
% Saves data. Run as part of the main experiment script. Author -- Matt H

% CHANGELOG (DD/MM/YY)
% 08/08/17  Started keeping changelog. --MH
% 08/08/17  Now allows for mulitple runs. --MH
% 10/08/17  Ready for subject 3. --MH
% 21/02/18  Customized for aphasia_study -- MH
% 05/03/18  Finished for aphasia study

headers = {'Jitter key', 'Actual jitter', ... 
        'Stim start key', 'Actual stim start', ...
        'Stim end key', 'Actual stim end', ...
        'Stim duration key', 'Actual stim duration', ...
        'Stimuli key', 'Event duration', ... 
        'Answer key', 'Subj response', 'RT'}; 

%% Saving relevant timing information
% Convert respKey and respTime to matrices
respKey_mat  = nan(size(respKey));
respTime_mat = nan(size(respTime));

for ii = 1:size(respKey, 1)
    for jj = 1:size(respKey, 2)
        respKey_mat(ii, jj)  = str2double(respKey{ii, jj});
        if ~isempty(respTime{ii, jj})
            respTime_mat(ii, jj) = respTime{ii, jj}(1);
        end
    end
end

% Convert to relative time, instead of system
runDur       = runEnd       - firstPulse; 
stimStartRel = stimStart    - firstPulse;
stimEndRel   = stimEnd      - firstPulse;
actStimDur   = stimEnd      - stimStart; 
actJit       = stimStart    - eventStart; 
actEventDur  = eventEnd     - eventStart; 
respTimeRel  = respTime_mat - stimEnd;

% Path
mkdir(fullfile(dir_results, subj.num))
cd(fullfile(dir_results, subj.num))

% Checks if files already exists to prevent overwrite
while exist(ResultsXls, 'file') == 2
	ResultsXls = [ResultsXls(1:end-5), '_new', ResultsXls(end-4:end)]; 
end

while exist(Variables, 'file') == 2
	Variables = [Variables(1:end-4), '_new', Variables(end-3:end)]; 
end


for blk = subj.firstRun:subj.lastRun
    %% Prepare to print to xlsx file
    data = cell(t.events + 1, length(headers)); 
    
    M    = horzcat(jitterKey(:,blk), actJit(:,blk), ...
        stimStartKey(:,blk), stimStartRel(:,blk), ...
        stimEndKey(:,blk), stimEndRel(:,blk), ...
        stimDuration(:,blk), actStimDur(:,blk), ... 
        eventKey(:,blk), actEventDur(:,blk), ...
        ansKey(:,blk), respKey_mat(:,blk), respTimeRel(:,blk));

    data(1,:) = headers; 
    for ii = 1:t.events
        for jj = 1:length(headers)
            data{ii+1, jj} = M(ii, jj); 
        end
    end
    
    %% Print to xlsx file
    warning off
    runNum = ['run ', num2str(blk)];
    
    xlswrite(ResultsXls, data, runNum)
    warning on
    
end

%% Save wav files of subject response -- only for v1 of code
% for ii = 1:size(response, 1)
%     for jj = 1:size(response, 2)
%         file = response{ii, jj};
%         if ~isempty(file)
%             filename = fullfile(dir_results, subj.Num, [subj.Num '_run' num2str(jj) '_stim' num2str(stimKey(ii, jj)) '.wav']);
%             if exist(filename, 'file') == 2
%                 filename = [filename(1:end-4) '_new.wav'];
%             end
%             audiowrite(filename, file', 44100);
%         end
%     end
% end

%% All done!
save(Variables); 
cd(dir_funcs)
