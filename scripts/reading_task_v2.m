%% reading_task_v2.m
% Expressive language task for aphasia study with Time Woman. 

% CHANGELOG (DD/MM/YY)
% 19/02/18 -- Started script from isss_multiband as template. 
% 21/02/18 -- It works and looks pretty. Discussing with KM tomorrow. 
% 01/03/18 -- Scan time determined. Updating code with new timing. Also
%   moved around stimuli. Also changed to make recording not dependent on
%   PTB
% 05/03/18 -- Done with v2? 

function reading_task_v2
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; clearvars; clc; 
Screen('Preference','VisualDebugLevel', 0);  

codeStart = GetSecs(); 
AudioDevice = PsychPortAudio('GetDevices', 3); % Changes based on OS

%% Parameters
prompt = {...
    'Subject number (####YL)', ...
    'Which session (1 - pre/2 - post)', ...
    'First run (1-4), enter 0 for mock', ... 
    'Last run (1-4), enter 0 for mock', ... 
    'RTBox connected (0/1):', ...
    'Script test (type word "test" or leave blank):', ...
    }; 
dlg_ans = inputdlg(prompt); 

subj.Num = dlg_ans{1};
subj.whichSess = str2double(dlg_ans{2}); 
subj.firstRun = str2double(dlg_ans{3}); 
subj.lastRun  = str2double(dlg_ans{4}); 
ConnectedToRTBox = str2double(dlg_ans{5}); 
scriptTest = dlg_ans{6}; 

% Mock exception
if subj.firstRun == 0
    Mock = 1; 
    t.runs = 1;
else
    Mock = 0;
    t.runs = length(subj.firstRun:subj.lastRun); % Maximum 4
end

% Scan type -- Change this?
scan.type   = 'Hybrid';
scan.TR     = 1.000; 
scan.epiNum = 10; % Number of EPI acquisitions

% Timing
t.events      = 16; 
t.stimNum     = 16; 
t.jitWindow   = 1.000; % Change this?
t.presTime    = 4.000; % Change this?
t.epiTime     = 10.000; % Change this?
t.eventTime   = t.presTime + t.epiTime + t.jitWindow;
t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition
    
%% Paths
cd ..
dir_exp     = pwd; 

dir_results = fullfile(dir_exp, 'results');
dir_scripts = fullfile(dir_exp, 'scripts');
dir_stim    = fullfile(dir_exp, 'stim', 'naming_task');

dir_funcs   = fullfile(dir_scripts, 'functions');

% Instructions = 'instructions_lang.txt';

%% Preallocating timing variables. 
maxNumRuns = 4;

AbsEvStart    = NaN(t.events, maxNumRuns); 
AbsStimStart  = NaN(t.events, maxNumRuns); 
AbsStimEnd    = NaN(t.events, maxNumRuns); 
AbsRecStart   = NaN(t.events, maxNumRuns); 
AbsRxnEnd     = NaN(t.events, maxNumRuns); 
AbsEvEnd      = NaN(t.events, maxNumRuns); 
eventEnd      = NaN(t.events, maxNumRuns); 
eventEndKey   = NaN(t.events, maxNumRuns); 
eventStart    = NaN(t.events, maxNumRuns);
eventStartKey = NaN(t.events, maxNumRuns); 
jitterKey     = NaN(t.events, maxNumRuns); 
recStart      = NaN(t.events, maxNumRuns);
recStartKey   = NaN(t.events, maxNumRuns);
stimKey       = NaN(t.events, maxNumRuns);
stimStart     = NaN(t.events, maxNumRuns); 
stimEnd       = NaN(t.events, maxNumRuns); 
stimStartKey  = NaN(t.events, maxNumRuns); 
stimEndKey    = NaN(t.events, maxNumRuns); 

firstPulse = NaN(1, maxNumRuns); 
runEnd     = NaN(1, maxNumRuns); 

%% File names
% if Training
%     filetag = [subj.Num '_practice_']; 
% else
    filetag = [subj.Num '_aphasia_']; 
% end

ResultsXls = fullfile(dir_results, subj.Num, [filetag 'read_results.xlsx']); 
Variables  = fullfile(dir_results, subj.Num, [filetag 'read_variables.mat']); 
    
%% Load stim
if strcmp(scriptTest, 'test')
    stim_filename = 'naming_task_stim_scripttest.txt.';
elseif Mock
    stim_filename = 'naming_task_stim_mock.txt.';
else
    if subj.whichSess == 1
        stim_filename = 'naming_task_stim_pretrain.txt';
    elseif subj.whichSess == 2
        stim_filename = 'naming_task_stim_posttrain.txt';
    end
end

stim_file = fullfile(dir_stim, stim_filename);
stim_line = cell(1, t.stimNum);

fid = fopen(stim_file);
ii = 0;
while 1
    ii = ii + 1;
    line = fgetl(fid);
    if ~ischar(line)
        break
    end
    stim_line{ii} = line;
end
fclose(fid);

% CHECK -- Did we load correct number of stimuli???
if length(stim_line) ~= t.stimNum
    sca
    error('length(stim_line) ~= t.stimNum: check stimuli folder or t.stimNum')
end

% Shuffle events 
for ii = subj.firstRun:subj.lastRun
    stimKey(:, ii) = Shuffle(1:t.stimNum);
end

%% Open PTB and RTBox
[wPtr, rect] = Screen('OpenWindow', 0, 185);
DrawFormattedText(wPtr, 'Please wait, preparing experiment...');
Screen('Flip', wPtr);

centerX = rect(3)/2;
centerY = rect(4)/2;
crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 
HideCursor(); 
RTBox('fake', ~ConnectedToRTBox);

%% Prepare test
try
    for blk = subj.firstRun:subj.lastRun

        DrawFormattedText(wPtr, 'Please wait, preparing run...');
        Screen('Flip', wPtr); 

        % Prepare timing keys
        eventStartKey(:, blk) = t.epiTime + [0:t.eventTime:((t.events-1)*t.eventTime)]'; %#ok<NBRAK>
        eventEndKey(:, blk) = eventStartKey(:, blk) + t.eventTime;
        jitterKey(:, blk) = rand(t.stimNum, 1);
        stimStartKey(:, blk) = eventStartKey(:, blk) + jitterKey(:, blk); 
        stimEndKey(:, blk) = stimStartKey(:, blk) + t.presTime;
        recStartKey(:, blk) = stimStartKey(:, blk) + 0.1;
         
%         % Display instructions
%         if Training
%             cd(FuncsLoc)
%             DisplayInstructions_bkfw_rtbox(Instructions, wPtr, RTBoxLoc); 
%             cd(expDir)
%         end

        % Wait for first pulse
        DrawFormattedText(wPtr, ['Waiting for first pulse. Block ' num2str(blk)]);
        Screen('Flip', wPtr); 
        
        RTBox('Clear'); 
        RTBox('UntilTimeout', 1);
        firstPulse(blk) = RTBox('WaitTR');

        % Draw onto screen after recieving first pulse
        Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
        Screen('Flip', wPtr); 
        
        % Generate absolute time keys
        AbsEvEnd(:, blk)     = firstPulse(blk) + eventEndKey(:,blk); 
        AbsEvStart(:, blk)   = firstPulse(blk) + eventStartKey(:,blk); 
        AbsRecStart(:, blk)  = firstPulse(blk) + recStartKey(:, blk);
        AbsStimEnd(:, blk)   = firstPulse(blk) + stimEndKey(:,blk); 
        AbsStimStart(:, blk) = firstPulse(blk) + stimStartKey(:,blk); 
        
        WaitTill(firstPulse(blk) + t.epiTime);
                
        %% Present visual stimuli
        for evt = 1:t.events
            eventStart(evt, blk) = GetSecs(); 
            
            % DRAW ON TEXT (flip screen, prepare next screen)
            DrawFormattedText(wPtr, stim_line{stimKey(evt, blk)}, 'center', 'center');
            WaitTill(AbsStimStart(evt, blk) - 0.1);
            stimStart(evt, blk) = Screen('Flip', wPtr, AbsStimStart(evt, blk));
            Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
            
            % Audio recording happens on my laptop
            
            % LEAVE IT FOR A BIT
            WaitTill(AbsStimEnd(evt, blk) - 0.1); 
            
            % REPLACE IT WITH FIXATION CROSS            
            stimEnd(evt, blk) = Screen('Flip', wPtr, AbsStimEnd(evt, blk));

            % WAIT UNTIL END OF EPI ACQUISITION
            WaitTill(AbsEvEnd(evt, blk)); 
            eventEnd(evt, blk) = GetSecs(); 
            
        end

        WaitSecs(t.eventTime); 
        runEnd(blk) = GetSecs(); 

        if blk ~= subj.lastRun
            DrawFormattedText(wPtr, 'End of run. Great job!', 'center', 'center'); 
            Screen('Flip', wPtr); 
            WaitTill(GetSecs() + 6);
        end 
                    
    end
    
catch err
    sca; 
    runEnd(blk) = GetSecs();  %#ok<NASGU>
    cd(dir_funcs)
    disp('Dumping data...')
    OutputData_reading
    cd(dir_scripts)
    disp('Done!')
    rethrow(err)
end

%% Closing down
Screen('CloseAll');
DisableKeysForKbCheck([]); 

% Save data
cd(dir_funcs)
disp('Please wait, saving data...')
OutputData_reading
disp('All done!')
cd(dir_scripts)

end
    