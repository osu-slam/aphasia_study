%% listening_v3.m
% Script to run perceptive language task for aphasia study. Ported from 
% isss_multiband_v7 on 5 March 2018. 
% Author - Matt Heard

% CHANGELOG (DD/MM/YY)
% 07/08/17  Started changelog. -- MH
% 07/08/17  Found error in "prepare timing keys" that overwrote eventStartKey
%   and stimStartKey every time code completed a run. Fixed! -- MH
% 09/08/17  Preparing for testing, making sure code looks pretty. -- MH
% 03/01/18  Updated to run subjects 11 through 14 (one tiny change on line
%   160) -- MH
% 05/03/18  Updated to run FST for aphasia study -- MH
% 07/03/18  V2, updating with errors I had while testing at CCBBI. Also 
%   changing jitterKey and presTime, set up TEST profile -- MH
% 26/03/18  Changing experiment length, this is now v3. Removed noise 
%   condition during mock scan, went from 16 to 8 trials. NOTE: CODE ONLY
%   WORKS FOR MOCK SCAN RIGHT NOW. NEED TO UPDATE WTIH FINAL STIMULI FOR 
%   BOTH PRE AND POST THERAPY SCANS. -- MH1
% 20/04/18  Stimuli finalized for pre- and post-therapy scans, am recoding
%   with 10 trials (8 stim, 2 noise) that are pseudo-randomized. NEEDS TO
%   BE TESTED TO SEE IF IT WORKS

% function listening_v3
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop;
Screen('Preference','VisualDebugLevel', 0);

try
    PsychPortAudio('Close'); 
catch
    disp('PPA already closed!')
end
InitializePsychSound

clearvars; clc; 
codeStart = GetSecs(); 
AudioDevice = PsychPortAudio('GetDevices', 3); 

%% Parameters
prompt = {...
    'Subject number (####YL)', ...
    'Which session (1 - pre/2 - post)', ...
    'First run (POST: 1. Note that 3 and 4 have been prepared as backups', ... 
    'Last run (POST: 2. Note that 3 and 4 have been prepared as backups)', ... 
    'RTBox connected (0/1):', ...
    'Script test (type "test" or leave blank)', ... 
    }; 
dlg_ans = inputdlg(prompt); 

subj.num  = dlg_ans{1};
if strcmp(subj.num, 'TEST')
    subj.whichSess = 1;
    subj.firstRun = 1;
    subj.lastRun  = 20;
    ConnectedToRTBox = 0;
    dlg_ans{6} = 'test';
else
    subj.whichSess = str2double(dlg_ans{2}); 
    subj.firstRun = str2double(dlg_ans{3}); 
    subj.lastRun  = str2double(dlg_ans{4}); 
    ConnectedToRTBox   = str2double(dlg_ans{5}); 
end

% Mock exception
if subj.firstRun == 0
    Mock = 1; 
    subj.firstRun = 1; 
    subj.lastRun = 1;
    t.events = 8;
else
    Mock = 0;
    t.events = 10; % for this version, running 8 stimuli, 1 noise, 1 silent (no noise or silent in mock)
end

% Test flag
if strcmp(dlg_ans{6}, 'test')
    Test = 1;
else
    Test = 0;
end

Screen('Preference', 'SkipSyncTests', Test);

% Scan type
scan.type   = 'Hybrid';
scan.TR     = 1.000; 
scan.epiNum = 10; 

% Number of stimuli
if Mock == 1
    numSentences = 48;
    numSpeechSounds = numSentences*4;
    numStim = numSpeechSounds+6;
else
    numSentences = 8; % 8 different sentence structures in stim folder
    numSpeechSounds = numSentences*4;
    numStim = numSpeechSounds+2; % Four structures per sentence, one noise, one silent
end

% Timing
t.runs = length(subj.firstRun:subj.lastRun); % Maximum 20

t.presTime   = 4.000;  % 4 seconds, may change
t.epiTime    = 10.000; % 10 seconds
t.eventTime  = t.presTime + t.epiTime;

t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition

t.rxnWindow = 3.000;  % 3 seconds
t.jitWindow = 1.000;  % 1 second, see notes below. 
    % For this experiment, the first second of the silent window will not
    % have stimuli presented. To code for this, I add an additional 1s
    % to the jitterKey. So, the jitter window ranges from 1s to 2s.
    
%% Paths
cd ..
dir_exp = pwd; 

if Mock == 1 % If mock
    dir_stim = fullfile(dir_exp, 'stim', 'listening_all');
    sesstag = 'mock';
elseif subj.whichSess == 1 % If session 1
    dir_stim = fullfile(dir_exp, 'stim', 'listening_pre_20Apr18');
    sesstag = 'pre';
else % If session 2
    dir_stim = fullfile(dir_exp, 'stim', 'listening_post_30Jul18');
    sesstag = 'post';
end

dir_scripts = fullfile(dir_exp, 'scripts');
dir_results = fullfile(dir_exp, 'results', subj.num);
dir_funcs   = fullfile(dir_scripts, 'functions');

cd ..

%% Preallocating timing variables
maxNumRuns = 20; 

AbsEvStart    = NaN(t.events, maxNumRuns); 
AbsStimStart  = NaN(t.events, maxNumRuns); 
AbsStimEnd    = NaN(t.events, maxNumRuns); 
AbsRxnEnd     = NaN(t.events, maxNumRuns); 
AbsEvEnd      = NaN(t.events, maxNumRuns); 
ansKey        = NaN(t.events, maxNumRuns); 
eventEnd      = NaN(t.events, maxNumRuns); 
eventEndKey   = NaN(t.events, maxNumRuns); 
eventStart    = NaN(t.events, maxNumRuns);
eventStartKey = NaN(t.events, maxNumRuns); 
jitterKey     = NaN(t.events, maxNumRuns); 
recStart      = NaN(t.events, maxNumRuns);
recStartKey   = NaN(t.events, maxNumRuns);
stimDuration  = NaN(t.events, maxNumRuns); 
stimEnd       = NaN(t.events, maxNumRuns); 
stimEndKey    = NaN(t.events, maxNumRuns);
stimStart     = NaN(t.events, maxNumRuns); 
stimStartKey  = NaN(t.events, maxNumRuns); 

firstPulse = NaN(1, maxNumRuns); 
runEnd     = NaN(1, maxNumRuns); 

respTime = cell(t.events, maxNumRuns); 
respKey  = cell(t.events, maxNumRuns); 

%% File names
ResultsXls = fullfile(dir_results, [subj.num '_listening_' sesstag '_results.xlsx']); 
Variables  = fullfile(dir_results, [subj.num '_listening_' sesstag '_variables.mat']); 

%% Load stim
% Stimuli
cd(dir_stim) 
files = dir('*.wav'); 

% TEST - Did all files load correctly?
if length(files) ~= numStim
    error('Check the number of stimuli you listed or number of files in stim dir!')
end

ad = cell(1, length(files));
fs = cell(1, length(files));

for ii = 1:length(files)
    [adTemp, fsTemp] = audioread(files(ii).name);
    ad{ii} = [adTemp'; adTemp']; % Convert mono to stereo
    fs{ii} = fsTemp;
    if ii ~= 1 % Check samplingrate is same across files 
        if fs{ii} ~= fs{ii-1}
            error('Your sampling rates are not all the same. Stimuli will not play correctly.')
        end
    end
end
fs = fs{1}; 

audinfo(length(ad)) = audioinfo(files(end).name); % Preallocate struct
for ii = 1:length(files)
    audinfo(ii) = audioinfo(files(ii).name); 
end

rawStimDur = nan(1, length(ad));
for ii = 1:length(ad)
    rawStimDur(ii) = audinfo(ii).Duration; 
end

%% Make keys
% jitterKey -- How much is the silent period jittered by?
for ii = subj.firstRun:subj.lastRun
    jitterKey(:, ii) = 1 + rand(t.events, 1); % Add 1 because stimuli are short
end

% speechkey -- Which speech stimuli should we use this run?
% eventkey -- In what order will stimuli be presented?
% randomstim = NaN(8, maxNumRuns); % There are 8 sentences to present

if Mock
%     sentence = repmat([129:4:192]', 1, 4); 
%     noise = [];
    % RANDOM STIM ORDER:    
    sentence = [137; 141; 145; 153; 161; 169; 181; 189];
    noise = repmat([197; 198], 1, 4);    
    randomStimOrder = 1;
    
elseif subj.whichSess == 1
    load(fullfile(dir_funcs, 'listening_sentence_order_pre.mat'))
    randomStimOrder = 0;
    eventKey = sentence_order;
    
    % RANDOM STIM ORDER: 
%     sentence = Shuffle(repmat([1:4:32]', 1, maxNumRuns));
%     noise = [33, 34];
%     randomStimOrder = 1;
    
elseif subj.whichSess == 2
    load(fullfile(dir_funcs, 'listening_sentence_order_pre.mat'))
    randomStimOrder = 0;
    eventKey = sentence_order(:, 17:20);
end

if randomStimOrder
    for ii = subj.firstRun:subj.lastRun % v3 -- went from 16 to 8 trials
        randomstim(:, ii) = Shuffle(vertcat( ... 
            0 * ones(2, 1), ...  
            1 * ones(2, 1), ...  
            2 * ones(2, 1), ... 
            3 * ones(2, 1) ... 
            ));   %#ok<SAGROW>
    end
    speechKey = sentence + randomstim;
    eventKey  = vertcat(speechKey, noise); 
end

% anskey -- What should have subjects responded with?
for ii = 1:t.events
    for j = subj.firstRun:subj.lastRun
        if     eventKey(ii, j) > numSpeechSounds % Noise
            ansKey(ii, j) = 3; 
        elseif mod(eventKey(ii, j), 2) == 0      % Male
            ansKey(ii, j) = 2; 
        elseif mod(eventKey(ii, j), 2) == 1      % Female
            ansKey(ii, j) = 1; 
        end
    end
end

%% Check counterbalance
% Do we want to use the same stimuli in the pre- and post-training scan
% sessions?
cd(dir_funcs)
stimulicheck_fst(numSpeechSounds, eventKey); 

for ii = subj.firstRun:subj.lastRun
    stimDuration(:, ii) = rawStimDur(eventKey(:,ii))'; 
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
        eventEndKey           = eventStartKey + t.eventTime;
        stimStartKey(:, blk)  = eventStartKey(:, blk) + jitterKey(:, blk); 
        stimEndKey(:, blk)    = stimStartKey(:, blk) + rawStimDur(eventKey(:,blk))';
        rxnEndKey             = stimEndKey + t.rxnWindow; 

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

            PsychPortAudio('FillBuffer', pahandle, ad{eventKey(evt, blk)});
            WaitTill(AbsStimStart(evt, blk)-0.1); 

            stimStart(evt, blk) = PsychPortAudio('Start', pahandle, 1, AbsStimStart(evt, blk), 1);
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
    OutputData_fst
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
OutputData_fst
disp('All done!')
cd(dir_scripts)

% end
