%% OutputData_reading.m
% Saves data. Run as part of the main experiment script. Author -- Matt H

% CHANGELOG (DD/MM/YY)
% 08/08/17  Started keeping changelog. --MH
% 08/08/17  Now allows for mulitple runs. --MH
% 10/08/17  Ready for subject 3. --MH
% 21/02/18  Customized for aphasia_study -- MH
% 05/03/18  Finished for aphasia study
% 31/07/18  VERSION 3 IS USED IN 

headers = {'Jitter key', 'Actual jitter', ... 
        'Stim start key', 'Actual stim start', ...
        'Stim end key', 'Actual stim end', ...
        'Stim duration key', 'Actual stim duration', ...
        'Stimuli key', 'Event duration'}; 

%% Saving relevant timing information
% Convert to relative time, instead of system
runDur = runEnd - firstPulse; 
fp = repmat(firstPulse, t.events, 1);
stimStartRel = stimStart - fp;
stimEndRel   = stimEnd   - fp;
stimDur = repmat(t.presTime, t.events, blk); 

actStimDur   = stimEnd   - stimStart; 
actJit       = stimStart - eventStart; 
actEventDur  = eventEnd  - eventStart; 

% Path
mkdir(fullfile(dir_results, 'post_screen_17Jul18'))
cd(fullfile(dir_results, 'post_screen_17Jul18'))

% Checks if files already exists to prevent overwrite
while exist(ResultsXls, 'file') == 2
	ResultsXls = [ResultsXls(1:end-5), '_new', ResultsXls(end-4:end)]; 
end

while exist(Variables, 'file') == 2
	Variables = [Variables(1:end-4), '_new', Variables(end-3:end)]; 
end

for rr = 1:blk
    %% Prepare to print to xlsx file
    data = cell(t.events + 1, length(headers)); 
    
    M    = horzcat(jitterKey(:,rr), actJit(:,rr), ...
        stimStartKey(:,rr), stimStartRel(:,rr), ...
        stimEndKey(:,rr), stimEndRel(:,rr), ...
        stimDur(:,rr), actStimDur(:,rr), ... 
        stimKey(:,rr), actEventDur(:,rr));

    data(1,:) = headers; 
    for ii = 1:t.events
        for jj = 1:length(headers)
            data{ii+1, jj} = M(ii, jj); 
        end
    end
    
    %% Print to xlsx file
    warning off
    runNum = ['run ', num2str(rr)];
    
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
