    %% reading_task.m
% Expressive language task for aphasia study with Time Woman. 

% CHANGELOG (DD/MM/YY)
% 19/02/18 -- Started script from isss_multiband as template. 
% 21/02/18 -- It works and looks pretty. Discussing with KM tomorrow. 
% 01/03/18 -- Scan time determined. Updating code with new timing. Also
%   moved around stimuli. 

% function reading_task_v1
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; clearvars; clc; 
Screen('Preference','VisualDebugLevel', 0);  

PsychPortAudio('Close'); 
InitializePsychSound

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
    p.runs = 1;
else
    Mock = 0;
    p.runs = length(subj.firstRun:subj.lastRun); % Maximum 4
end

% Scan type -- Change this?
scan.type   = 'Hybrid';
scan.TR     = 1.000; 
scan.epiNum = 10; % Number of EPI acquisitions

% Timing
p.events      = 16; % Change this?
p.stimNum     = 32; 
p.jitWindow   = 1.000; % Change this?
p.presTime    = 4.000; % Change this?
p.epiTime     = 10.000; % Change this?
p.eventTime   = p.presTime + p.epiTime + p.jitWindow;
p.runDuration = p.epiTime + ...   % After first pulse
    p.eventTime * p.events + ...  % Each event
    p.eventTime;                  % After last acquisition
    
%% Paths
cd ..
dir_exp     = pwd; 

dir_results = fullfile(dir_exp, 'results');
dir_scripts = fullfile(dir_exp, 'scripts');
dir_stim    = fullfile(dir_exp, 'stim', 'naming_task');

dir_funcs   = fullfile(dir_scripts, 'functions');

% Instructions = 'instructions_lang.txt';

%% Preallocating timing variables. 
% if Training
%     maxNumRuns = 1;
% else
%     maxNumRuns = 6; 
% end
maxNumRuns = 4;

AbsEvStart    = NaN(p.events, maxNumRuns); 
AbsStimStart  = NaN(p.events, maxNumRuns); 
AbsStimEnd    = NaN(p.events, maxNumRuns); 
AbsRecStart   = NaN(p.events, maxNumRuns); 
AbsRxnEnd     = NaN(p.events, maxNumRuns); 
AbsEvEnd      = NaN(p.events, maxNumRuns); 
eventEnd      = NaN(p.events, maxNumRuns); 
eventEndKey   = NaN(p.events, maxNumRuns); 
eventStart    = NaN(p.events, maxNumRuns);
eventStartKey = NaN(p.events, maxNumRuns); 
jitterKey     = NaN(p.events, maxNumRuns); 
recStart      = NaN(p.events, maxNumRuns);
recStartKey   = NaN(p.events, maxNumRuns);
stimKey       = NaN(p.events, maxNumRuns);
stimStart     = NaN(p.events, maxNumRuns); 
stimEnd       = NaN(p.events, maxNumRuns); 
stimStartKey  = NaN(p.events, maxNumRuns); 
stimEndKey    = NaN(p.events, maxNumRuns); 

response = cell(p.events, maxNumRuns);

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
    
%% Load PTB and stimuli
% PTB SCREEN
% [wPtr, rect] = Screen('OpenWindow', 0, 185);
% DrawFormattedText(wPtr, 'Please wait, preparing experiment...');
% Screen('Flip', wPtr);
% 
% centerX = rect(3)/2;
% centerY = rect(4)/2;
% crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 
% HideCursor(); 

% Load phrases
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
stim_line = cell(1, p.stimNum);

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
if length(stim_line) ~= p.stimNum
    sca
    error('length(stim_line) ~= p.stimNum: check stimuli folder or p.stimNum')
end

% Shuffle events -- might need updating based on Yune's answer
for ii = subj.firstRun:subj.lastRun
    stimKey(:, ii) = Shuffle(1:p.stimNum);
end

% Last couple of things....
RTBox('fake', ~ConnectedToRTBox);
pahandle = PsychPortAudio('Open', [], 2, 0, 44100, 2);
PsychPortAudio('GetAudioData', pahandle, p.presTime - 0.1); % Preallocate buffer. Setting value to p.presTime - 0.1; gives system enough time to start recording. 

%% Prepare test
try
    for run = subj.firstRun:subj.lastRun

        DrawFormattedText(wPtr, 'Please wait, preparing run...');
        Screen('Flip', wPtr); 

        % Prepare timing keys
        eventStartKey(:, run) = p.epiTime + [0:p.eventTime:((p.events-1)*p.eventTime)]'; %#ok<NBRAK>
        eventEndKey(:, run) = eventStartKey(:, run) + p.eventTime;
        jitterKey(:, run) = rand(p.stimNum, 1);
        stimStartKey(:, run) = eventStartKey(:, run) + jitterKey(:, run); 
        stimEndKey(:, run) = stimStartKey(:, run) + p.presTime;
        recStartKey(:, run) = stimStartKey(:, run) + 0.1;
        
%         if Training
%             stimEndKey = stimStartKey + rawStimDur(eventKey)';
%         else
%             stimEndKey(:, run) = stimStartKey(:, run) + rawStimDur(eventKey(:,run))';
%         end
%         
%         % Display instructions
%         if Training
%             cd(FuncsLoc)
%             DisplayInstructions_bkfw_rtbox(Instructions, wPtr, RTBoxLoc); 
%             cd(expDir)
%         end

        % Wait for first pulse
        DrawFormattedText(wPtr, ['Waiting for first pulse. Block ' num2str(run)])
        Screen('Flip', wPtr); 
        
        RTBox('Clear'); 
        RTBox('UntilTimeout', 1);
        firstPulse(run) = RTBox('WaitTR');

        % Draw onto screen after recieving first pulse
        Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
        Screen('Flip', wPtr); 
        
        % Generate absolute time keys
        AbsEvEnd(:, run)     = firstPulse(run) + eventEndKey(:,run); 
        AbsEvStart(:, run)   = firstPulse(run) + eventStartKey(:,run); 
        AbsRecStart(:, run)  = firstPulse(run) + recStartKey(:, run);
        AbsStimEnd(:, run)   = firstPulse(run) + stimEndKey(:,run); 
        AbsStimStart(:, run) = firstPulse(run) + stimStartKey(:,run); 
        
        WaitTill(firstPulse(run) + p.epiTime);
                
        %% Present audio stimuli
        for event = 1:p.events
            eventStart(event, run) = GetSecs(); 
            
            % DRAW ON TEXT (flip screen, prepare next screen)
            DrawFormattedText(wPtr, stim_line{stimKey(event, run)}, 'center', 'center');
            WaitTill(AbsStimStart(event, run) - 0.1);
            stimStart(event, run) = Screen('Flip', wPtr, AbsStimStart(event, run));
            Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
            
            % START AUDIO RECORDING
            PsychPortAudio('Start', pahandle, 1, AbsRecStart(event, run), 1);
            
            % LEAVE IT FOR A BIT
            WaitTill(AbsStimEnd(event, run) - 0.1); 
            
            % REPLACE IT WITH FIXATION CROSS            
            stimEnd(event, run) = Screen('Flip', wPtr, AbsStimEnd(event, run));
            
            % RETRIEVE AUDIO DATA
            response{event, run} = PsychPortAudio('GetAudioData', pahandle);

            % WAIT UNTIL END OF EPI ACQUISITION
            WaitTill(AbsEvEnd(event, run));    
            eventEnd(event, run) = GetSecs(); 
            
        end

        WaitSecs(p.eventTime); 
        runEnd(run) = GetSecs(); 

        if run ~= subj.lastRun
            DrawFormattedText(wPtr, 'End of run. Great job!', 'center', 'center'); 
            Screen('Flip', wPtr); 
            WaitTill(GetSecs() + 6);
        end 
            
        
    end
    
catch err
    sca; 
    runEnd(run) = GetSecs();  %#ok<NASGU>
    cd(dir_funcs)
    disp('Dumping data...')
    OutputData
    cd(dir_scripts)
    PsychPortAudio('Close'); 
    disp('Done!')
    rethrow(err)
end

%% Closing down
Screen('CloseAll');
PsychPortAudio('Close'); 
DisableKeysForKbCheck([]); 

%% Save data
cd(dir_funcs)
disp('Please wait, saving data...')
OutputData
disp('All done!')
cd(dir_scripts)

% end
    