%% fst_v1.m
% Script to run FST for aphasia study. Ported from isss_multiband_v7
% Author - Matt Heard

% CHANGELOG (DD/MM/YY)
% 07/08/17  Started changelog. -- MH
% 07/08/17  Found error in "prepare timing keys" that overwrote eventStartKey
%   and stimStartKey every time code completed a run. Fixed! -- MH
% 09/08/17  Preparing for testing, making sure code looks pretty. -- MH
% 03/01/18  Updated to run subjects 11 through 14 (one tiny change on line
%   160)
% 05/03/18  Updated to run FST for aphasia study

function fst_v1
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; 
Screen('Preference','VisualDebugLevel', 0);  
Screen('Preference', 'SkipSyncTests', 1);

PsychPortAudio('Close'); 
InitializePsychSound

clearvars; clc; 
codeStart = GetSecs(); 
AudioDevice = PsychPortAudio('GetDevices', 3); 

%% Parameters
prompt = {...
    'Subject number (####YL)', ...
    'Which session (1 - pre/2 - post)', ...
    'First run (1-4, enter 0 for mock)', ... 
    'Last run (1-4, enter 0 for mock)', ... 
    'RTBox connected (0/1):', ...
    'Script test (type word "test" or leave blank)', ... 
    }; 
dlg_ans = inputdlg(prompt); 

subj.Num  = dlg_ans{1};
subj.whichSess = dlg_ans{2}; 
subj.firstRun = str2double(dlg_ans{3}); 
subj.lastRun  = str2double(dlg_ans{4}); 
ConnectedToRTBox   = str2double(dlg_ans{5}); 
scriptTest = dlg_ans{6}; 

% Mock exception
if subj.firstRun == 0
    Mock = 1; 
    t.runs = 1;
else
    Mock = 0;
    t.runs = length(subj.firstRun:subj.lastRun); % Maximum 4
end

% Scan type
scan.type   = 'Hybrid';
scan.TR     = 1.000; 
scan.epiNum = 10; 

% Number of stimuli -- Needs work
NumSpStim = 192; % 192 different speech clips
NumStim   = 200; % 200 .wav files in stimuli folder
% Of these 200 .wav files, 4 are silent, 4 of noise, and 192 are sentences.
% Of these 192 speech sounds, this script chooses 8 per run (2 MO, 2 FO, 2 
% MS, 2 FS) for presentation. Subjects will not hear a
% repeated "sentence structure" (i.e. one stimuli of of 001, one stimuli of
% 002) in the entire experiment.

% Timing
t.events = 16; 

t.presTime   = 4.000;  % 4 seconds
t.epiTime    = 10.000; % 10 seconds
t.eventTime  = t.presTime + t.epiTime;

t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition

t.rxnWindow = 3.000;  % 3 seconds
t.jitWindow = 0.700;  % 1 second, see notes below. Likely will change?
    % For this experiment, the first second of the silent window will not
    % have stimuli presented. To code for this, I add an additional 1 s
    % to the jitterKey. So, the jitter window ranges from 1 s to 2 s.

% Training override
if Training
    NumSpStim = 4; 
    NumStim   = 5; 
    t.events  = 5; 
end
    
%% Paths
cd ..
dir_exp = pwd; 

dir_stim    = [dir_exp, '\fst'];
dir_scripts = [dir_exp, '\scripts'];
dir_results = [dir_exp, '\results'];
dir_funcs   = [dir_scripts, '\functions'];

cd ..

% Instructions = 'instructions_lang.txt';

%% Preallocating timing variables
maxNumRuns = 4; 

AbsEvStart   = NaN(t.events, maxNumRuns); 
AbsStimStart = NaN(t.events, maxNumRuns); 
AbsStimEnd   = NaN(t.events, maxNumRuns); 
AbsRxnEnd    = NaN(t.events, maxNumRuns); 
AbsEvEnd     = NaN(t.events, maxNumRuns); 
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

respTime = cell(t.events, maxNumRuns); 
respKey  = cell(t.events, maxNumRuns); 

%% File names
% if Training
%     filetag = [subj.Num '_' subj.Init '_practice_']; 
% else
    filetag = [subj.Num '_' subj.Init '_']; 
% end

ResultsXls = fullfile(dir_results, subj.Num, [filetag 'fst_results.xlsx']); 
Variables  = fullfile(dir_results, subj.Num, [filetag 'fst_variables.mat']); 

%% Load stim -- will need work
% Stimuli, check counterbalance
cd(dir_funcs) 
[audio, fs, rawStimDur, jitterKey, eventKey, answerKey, speechKey] = ...
    LoadStimAndKeys(dir_stim, t.events, subj.firstRun, subj.lastRun, NumSpStim, maxNumRuns, Training);
fs = fs{1}; % Above func checks that all fs are the same.  

% Do we want to use the same stimuli in the pre- and post-training scan
% sessions? Also, still need to check that SNR = 2 is acceptable but cannot
% do so until Sanghoon gets back to me (05 Mar 18). 


if ~Training
    cd(dir_funcs)
    stimulicheck(NumSpStim, eventKey); 
end
cd(dir_exp)

for i = subj.firstRun:subj.lastRun
    stimDuration(:, i) = rawStimDur(eventKey(:,i))'; 
end

%% Open PTB, RTBox, PsychPortAudio
[wPtr, rect] = Screen('OpenWindow', 0, 185);
DrawFormattedText(wPtr, 'Please wait, preparing experiment...');
Screen('Flip', wPtr);

centerX = rect(3)/2;
centerY = rect(4)/2;
crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 
HideCursor(); 
RTBox('fake', ~ConnectedToRTBox);

pahandle = PsychPortAudio('Open', [], [], [], fs);

%% Prepare test
try
    for blk = subj.firstRun:subj.lastRun

        DrawFormattedText(wPtr, 'Please wait, preparing run...');
        Screen('Flip', wPtr); 

        % Prepare timing keys
        eventStartKey(:, blk) = t.epiTime + [0:t.eventTime:((t.events-1)*t.eventTime)]'; %#ok<NBRAK>
        stimStartKey(:, blk)  = eventStartKey(:, blk) + jitterKey(:, blk); 

%         if Training
%             stimEndKey = stimStartKey + rawStimDur(eventKey)';
%         else
            stimEndKey(:, blk) = stimStartKey(:, blk) + rawStimDur(eventKey(:,blk))';
%         end

        rxnEndKey   = stimEndKey + t.rxnWindow; 
        eventEndKey = eventStartKey + t.eventTime;

        % Display instructions
%         if Training
%             cd(dir_funcs)
%             DisplayInstructions_bkfw_rtbox(Instructions, wPtr, RTBoxLoc); 
%             cd(dir_exp)
%         end


        % Wait for first pulse
        DrawFormattedText(wPtr, ['Waiting for first pulse. Block ', num2str(blk)]); 
        Screen('Flip', wPtr); 
        
        RTBox('Clear'); 
        RTBox('UntilTimeout', 1);
        firstPulse(blk) = RTBox('WaitTR'); 

        % Draw onto screen after recieving first pulse
        Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
        Screen('Flip', wPtr); 

        % Generate absolute time keys
        AbsEvStart(:, blk)   = firstPulse(blk) + eventStartKey(:,blk); 
        AbsStimStart(:, blk) = firstPulse(blk) + stimStartKey(:,blk); 
        AbsStimEnd(:, blk)   = firstPulse(blk) + stimEndKey(:,blk); 
        AbsRxnEnd(:, blk)    = firstPulse(blk) + rxnEndKey(:,blk); 
        AbsEvEnd(:, blk)     = firstPulse(blk) + eventEndKey(:,blk); 

        WaitTill(firstPulse(blk) + t.epiTime); 

        %% Present audio stimuli
        for evt = 1:t.events
            eventStart(evt, blk) = GetSecs(); 

            PsychPortAudio('FillBuffer', pahandle, audio{eventKey(evt, blk)});
            WaitTill(AbsStimStart(evt, blk)-0.1); 

            stimStart(evt, blk) = PsychPortAudio('Start', pahandle, 1, AbsStimStart(evt, blk));
            WaitTill(AbsStimEnd(evt, blk)); 
            stimEnd(evt, blk) = GetSecs; 
            RTBox('Clear'); 

            [respTime{evt, blk}, respKey{evt, blk}] = RTBox(AbsRxnEnd(evt, blk)); 

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
%     OutputData
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
% cd(dir_funcs)
% disp('Please wait, saving data...')
% OutputData
% disp('All done!')
% cd(dir_scripts)

% end
