%% exp_v4.m
% Expressive language task for aphasia study with Time Woman. 

% CHANGELOG (DD/MM/YY)
% 02/19/18 -- Started script from isss_multiband as template. 
% 02/21/18 -- It works and looks pretty. Discussing with KM tomorrow. 
% 03/01/18 -- Scan time determined. Updating code with new timing. Also
%   moved around stimuli. Also changed to make recording not dependent on
%   PTB
% 03/05/18 -- Done with v2? 
% 03/07/18 -- V3 begins with updates made for compatibility at CCBBI. 
% 03/15/18 -- New mock stimuli. Here is why I added them:
%    1) Starts with a "wo-" sound, TW has said "wow" before
%    3) Includes a word ("dime") that rhymes with "time"
%    4) Starts with "tie", which sounds similar to "time"
%    6) Includes "tissue", which is similar but not the same as "time"
%    9) Starts with the word "time"
%   10) TW has said the word "try", can she say "trying"?
%   12) Features the word "time" as a root of a larger word
%   14) Another "ti-" sound that closely resembles "time"
%   Also changed the jabberwocky to test "ti-" and words that rhyme with 
%   time. 
% 03/26/18 -- V4 has a change in experiment length (10 trials). NOTE: DOES
%   NOT INCLUDE BASELINE (jabberwocky). 
% 05/02/18 -- V5 is the version used in pre-screening. Double checking that
%   script is working and that stimuli are counterbalanced. Each run
%   consists of four patterns, two sentences each, and two jabberwocky. 
% 07/10/18 -- In progress of updating for post-test. Each run now consists 
%   of the 16 sentences which TW has learned. Make sure to double check 
%   this code is ready for scanning! AS OF NOW IT WILL NOT COMPLETE!

% function naming_v5
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; clearvars; clc; 
Screen('Preference','VisualDebugLevel', 0);  

codeStart = GetSecs(); 
AudioDevice = PsychPortAudio('GetDevices', 3); % Changes based on OS

%% Parameters
prompt = {...
    'Subject number (####YL)', ...
    'Which session (1 - pre/2 - post)', ...
    'First run (POST: 1. Note that 3 and 4 have been prepared as backups', ... 
    'Last run (POST: 2. Note that 3 and 4 have been prepared as backups)', ... 
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
    subj.whichSess = str2double(dlg_ans{2}); 
    subj.firstRun = str2double(dlg_ans{3}); 
    subj.lastRun  = str2double(dlg_ans{4}); 
    ConnectedToRTBox = str2double(dlg_ans{5}); 
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
    t.events = 10; % changed with v4
    subj.firstRun = 1;
    subj.lastRun = 1;
else
    Mock = 0;
    t.runs = length(subj.firstRun:subj.lastRun); % Maximum 4
    t.events = 10; % changed with v5
end

% Scan type -- Change this?
scan.type   = 'Hybrid';
scan.TR     = 1.000; 
scan.epiNum = 10; % Number of EPI acquisitions

%% Paths
cd ..
dir_exp     = pwd; 

dir_results = fullfile(dir_exp, 'results');
dir_scripts = fullfile(dir_exp, 'scripts');
dir_stim    = fullfile(dir_exp, 'stim', 'naming_task');

dir_funcs   = fullfile(dir_scripts, 'functions');

% Instructions = 'instructions_lang.txt';

%% Timing
if subj.whichSess == 1
    t.stimNum = 36; % changed with V5, includes jabberwocky
    t.sentNum = 32;  
    load(fullfile(dir_funcs, 'naming_sentence_order_pre.mat'))
elseif subj.whichSess == 2
    t.stimNum = 20; % have not checked jabberwocky with Yune
    t.sentNum = 16; 
    warning('Jabberwocky sentences have not been set.')
    x = 's';
    while ~isempty(x)
        x = input('Press enter to confirm that this message has been read.');
    end
    
    warning('Counterbalance has not been ensured. Order of primes is random!')
    x = 's';
    while ~isempty(x)
        x = input('Press enter to confirm that this message has been read.');
    end
    
end

t.jitWindow   = 1.000; 
t.presTime    = 3.000; 
t.epiTime     = 10.000;
t.eventTime   = t.jitWindow + t.presTime + t.epiTime;
t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition

%% Preallocating timing variables. 
maxNumRuns = 20;

AbsEvStart    = NaN(t.events, maxNumRuns); 
AbsStimStart  = NaN(t.events, maxNumRuns); 
AbsStimEnd    = NaN(t.events, maxNumRuns); 
AbsEvEnd      = NaN(t.events, maxNumRuns); 
eventEnd      = NaN(t.events, maxNumRuns); 
eventEndKey   = NaN(t.events, maxNumRuns); 
eventStart    = NaN(t.events, maxNumRuns);
eventStartKey = NaN(t.events, maxNumRuns); 
jitterKey     = NaN(t.events, maxNumRuns); 
stimStart     = NaN(t.events, maxNumRuns); 
stimEnd       = NaN(t.events, maxNumRuns); 
stimStartKey  = NaN(t.events, maxNumRuns); 
stimEndKey    = NaN(t.events, maxNumRuns); 

firstPulse = NaN(1, maxNumRuns); 
runEnd     = NaN(1, maxNumRuns); 

%% File names
ResultsXls = fullfile(dir_results, subj.num, [subj.num '_exp_results.xlsx']); 
Variables  = fullfile(dir_results, subj.num, [subj.num '_exp_variables.mat']);
    
%% Load stim
if Test
    stim_filename = 'naming_task_stim_scripttest.txt.';
elseif Mock
    stim_filename = 'naming_task_stim_mock.txt.';
else
    if subj.whichSess == 1
        stim_filename = 'naming_task_stim_pre_02May18.txt';
    elseif subj.whichSess == 2
        stim_filename = 'naming_task_stim_post_10Jul18.txt';
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
    error('length(stim_line) ~= t.stimNum: check stimuli or t.stimNum')
end

% Load predetermined counterbalance
cd(dir_funcs)
stimulicheck_naming(t.sentNum, stimKey)

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
        jitterKey(:, blk) = rand(t.events, 1);
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

% end
    