%% picture_v1.m
% Expressive language task involving picture naming for aphasia study with 
% Time Woman. 

% CHANGELOG (DD/MM/YY)
% 19/02/18 -- Started script from isss_multiband as template. 
% 21/02/18 -- It works and looks pretty. Discussing with KM tomorrow. 
% 01/03/18 -- Scan time determined. Updating code with new timing. Also
%   moved around stimuli. Also changed to make recording not dependent on
%   PTB
% 05/03/18 -- Done with v2? 
% 07/03/18 -- V3 begins with updates made for compatibility at CCBBI. 
% 15/03/18 -- Forked from exp_v3 into picture task. Still needs testing at
%   mock scanner. 

function picture_v1
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; clearvars; clc; 
Screen('Preference','VisualDebugLevel', 0);  
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
inc = white - grey;


codeStart = GetSecs();  %#ok<NASGU>

%% Parameters
resolution = 800;

prompt = {...
    'Subject number (####YL)', ...
    'Which session (1 - pre/2 - post)', ...
    'First run (1-4), enter 0 for mock', ... 
    'Last run (1-4), enter 0 for mock', ... 
    'RTBox connected (0/1):', ...
    'Script test (type word "test" or leave blank):', ...
    }; 
dlg_ans = inputdlg(prompt); 

subj.num  = dlg_ans{1};
if strcmp(subj.num, 'TEST')
    subj.whichSess = 1;
    subj.firstRun = 1;
    subj.lastRun  = 4;
    ConnectedToRTBox = 0;
    dlg_ans{6} = 'test';
else
    subj.whichSess = dlg_ans{2}; 
    subj.firstRun = str2double(dlg_ans{3}); 
    subj.lastRun  = str2double(dlg_ans{4}); 
    ConnectedToRTBox   = str2double(dlg_ans{5}); 
end

% Test flag
if strcmp(dlg_ans{6}, 'test')
    Test = 1;
else
    Test = 0;
end
Screen('Preference', 'SkipSyncTests', Test);

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
scan.epiNum = 10; %#ok<STRNU> % Number of EPI acquisitions

% Timing
t.events      = 18; 
t.stimNum     = 18; 
t.jitWindow   = 1.000; % Change this?
t.presTime    = 4.000; % Change this?
t.epiTime     = 10.000; % Change this?
t.eventTime   = t.jitWindow + t.presTime + t.epiTime;
t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition
    
%% Paths
cd ..
dir_exp     = pwd; 

dir_results = fullfile(dir_exp, 'results');
dir_scripts = fullfile(dir_exp, 'scripts');
dir_stim    = fullfile(dir_exp, 'stim', 'picture_task', num2str(resolution));

dir_funcs   = fullfile(dir_scripts, 'functions');

% Instructions = 'instructions_lang.txt';

%% Preallocating timing variables. 
maxNumRuns = 4;

AbsEvStart    = NaN(t.events, maxNumRuns); 
AbsStimStart  = NaN(t.events, maxNumRuns); 
AbsStimEnd    = NaN(t.events, maxNumRuns); 
AbsEvEnd      = NaN(t.events, maxNumRuns); 
eventEnd      = NaN(t.events, maxNumRuns); 
eventEndKey   = NaN(t.events, maxNumRuns); 
eventStart    = NaN(t.events, maxNumRuns);
eventStartKey = NaN(t.events, maxNumRuns); 
jitterKey     = NaN(t.events, maxNumRuns); 
stimKey       = NaN(t.events, maxNumRuns);
stimStart     = NaN(t.events, maxNumRuns); 
stimEnd       = NaN(t.events, maxNumRuns); 
stimStartKey  = NaN(t.events, maxNumRuns); 
stimEndKey    = NaN(t.events, maxNumRuns); 

firstPulse = NaN(1, maxNumRuns); 
runEnd     = NaN(1, maxNumRuns); 

%% File names
filetag = [subj.num '_aphasia_']; 

ResultsXls = fullfile(dir_results, subj.num, [filetag 'pic_results.xlsx']);  %#ok<NASGU>
Variables  = fullfile(dir_results, subj.num, [filetag 'pic_variables.mat']); %#ok<NASGU>
    
%% Load stim
cd(dir_stim)
stim_files = dir('*.png');

% CHECK -- Did we load correct number of stimuli???
if length(stim_files) ~= t.stimNum
    sca
    error('length(stim_files) ~= t.stimNum: check stimuli folder or t.stimNum')
end

stim_name = cell(t.stimNum, 1);
stim_image = cell(t.stimNum, 1);
for ii = 1:t.stimNum
    stim_name{ii} = fullfile(stim_files(ii).folder, stim_files(ii).name);
    [img, ~, a] = imread(stim_name{ii}, 'png');
    stim_image{ii} = cat(3, img, a);
end

% Shuffle events 
for ii = subj.firstRun:subj.lastRun
    stimKey(:, ii) = Shuffle(1:t.stimNum);
end

%% Open PTB and RTBox
[wPtr, rect] = Screen('OpenWindow', 0, white);
Screen('BlendFunction', wPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
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
        AbsStimEnd(:, blk)   = firstPulse(blk) + stimEndKey(:,blk); 
        AbsStimStart(:, blk) = firstPulse(blk) + stimStartKey(:,blk); 
        
        WaitTill(firstPulse(blk) + t.epiTime);
                
        %% Present visual stimuli
        for evt = 1:t.events
            eventStart(evt, blk) = GetSecs(); 
            
            % DRAW ON IMAGE (flip screen, prepare next screen)
            imageTexture = Screen('MakeTexture', wPtr, stim_image{stimKey(evt, blk)});
            Screen('DrawTexture', wPtr, imageTexture, [], [], 0);
            WaitTill(AbsStimStart(evt, blk) - 0.1);
            stimStart(evt, blk) = Screen('Flip', wPtr, AbsStimStart(evt, blk));
            Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
            
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
    