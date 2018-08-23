%% naming_primes_v1_laptop.m
% Expressive language task for aphasia study with Time Woman. 

%(MM/DD/YY)-- CHANGELOG
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
% 07/10/18 -- V5_laptop is going to be used for post-screening today.
%   Interface is more friendly for use by other experimenters, does not use
%   jabberwocky sentences, and loops until experimenter presses 'ESC'. 
% 07/16/18 -- New version of code with different design:
%   a) Cutting from 16 to 12 trials, removing sentences with lowest
%   performance per rhythm. This will happen after tomorrow's test. 
%   b) changing scan time split from 4sec/10sec to 8sec/8sec. DONE!
%   c) adding visual cue one beat (~.9sec) before TW is to speak. ***
%   d) add new stimuli (first thing tomorrow!!!)
% 07/20/18 -- Finished vocoded stimuli, changed how stim load.
% 07/31/18 -- Updated for post-scan. 
% 08/16/18 -- Changed to short runs of 8 trials instead of 16 trials. 

% function naming_primes_v1_laptop
%% Startup
sca; DisableKeysForKbCheck([]); KbQueueStop; clearvars; clc; 
Screen('Preference','VisualDebugLevel', 0);  
codeStart = GetSecs(); 
try
    PsychPortAudio('Close'); 
catch
    disp('PPA already closed!')
end

InitializePsychSound
AudioDevice = PsychPortAudio('GetDevices', 3); % Changes based on OS
% Screen('Preference', 'SkipSyncTests', 1);

prompt = {...
    'Subject number (####YL)', ...
    'First run (1-6: 1&2 are rhy+sp+, 3&4 are rhy+sp-, 5&6 are rhy-sp+)', ... 
    'Last run (1-6)', ... 
    'RTBox connected (0/1):', ...
    }; 
dlg_ans = inputdlg(prompt); 

subj.num  = dlg_ans{1};
subj.firstRun = str2double(dlg_ans{2}); 
subj.lastRun  = str2double(dlg_ans{3}); 
ConnectedToRTBox   = str2double(dlg_ans{4}); 

fontsize = 36;
bpm      = 65;
color    = [255 0 0];
fs_trgt  = 44100; 
primeNum = 16; % Now there's a prime for each sentence!
stimType = {'voice9_rhythm9_rms', 'ch1_voice9_rhythm9_rms', 'voice9_rms'};
% 'ch1_voice9_rms';         % Vocoded (noise) without rhythms
% 'ch1_voice9_rhythm0_rms'; % Vocoded (noise) with loud rhythms
% 'ch1_voice9_rhythm9_rms'; % Vocoded (noise) with quiet rhythms
% 'rhythm0_rms';            % Loud rhythms
% 'rhythm9_rms';            % Quiet rhythms
% 'voice9_rms';             % Clear speech
% 'voice9_rhythm0_rms';     % Clear speech with loud rhythms
% 'voice9_rhythm9_rms';     % Clear speech with quiet rhythms

%% Paths
cd ..
dir_exp       = pwd; 
dir_results   = fullfile(dir_exp, 'results');
dir_scripts   = fullfile(dir_exp, 'scripts');
dir_stim      = fullfile(dir_exp, 'stim', 'naming_task');
dir_primes{1} = fullfile(dir_exp, 'stim', 'rhythm_primes', stimType{1}); 
dir_primes{2} = fullfile(dir_exp, 'stim', 'rhythm_primes', stimType{2}); 
dir_primes{3} = fullfile(dir_exp, 'stim', 'rhythm_primes', stimType{3}); 
dir_funcs     = fullfile(dir_scripts, 'functions');
% Instructions = 'instructions_lang.txt';

%% Timing
t.stimNum   = 16; % no jabberwocky!
t.sentNum   = 16; 
t.events    = 8;  % AS OF 8/16 EVENTS ARE NOT COUNTERBALANCED!!!
t.numBlocks = 6;

t.T          = (bpm/60)^-1; % duration of one beat of prime
t.wholePrime = t.T*8; % duration of entire stimuli
t.visCueTime = t.T*4; % time at which visual prime should be presented, 
                      % relative to the start of the prime

t.jitWindow   = 0.500; 
t.presTime    = 7.500; % CHECK THIS NUMBER against stimuli
t.epiTime     = 8.000;
t.eventTime   = t.jitWindow + t.presTime + t.epiTime;
t.runDuration = t.epiTime + ...   % After first pulse
    t.eventTime * t.events + ...  % Each event
    t.eventTime;                  % After last acquisition

% TEST -- Will primes be too long?
if t.T > t.presTime
    error('Check the potential length of primes, may be too long!')
end

% TEST -- Everything breaks if you change number of blocks...
if t.numBlocks ~= 3
    warning('t.numBlocks is not 3, code may not work!')
end

%% Preallocating timing variables. 
AbsEvStart    = NaN(t.events, t.numBlocks); 
AbsStimStart  = NaN(t.events, t.numBlocks); 
AbsVisCue     = NaN(t.events, t.numBlocks); 
AbsStimEnd    = NaN(t.events, t.numBlocks); 
AbsEvEnd      = NaN(t.events, t.numBlocks); 
eventEnd      = NaN(t.events, t.numBlocks); 
eventStart    = NaN(t.events, t.numBlocks); 
stimStart     = NaN(t.events, t.numBlocks); 
visCue        = NaN(t.events, t.numBlocks); 
stimEnd       = NaN(t.events, t.numBlocks); 
stimKey       = NaN(t.events, t.numBlocks); 
durationKey   = NaN(t.events, t.numBlocks); 

firstPulse = NaN(1, t.numBlocks); 
runEnd     = NaN(1, t.numBlocks); 

for blk = 1:3
    temp = Shuffle(1:16)';
    stimKey(:, blk) = temp(1:t.events); % temporary fix. events are not counterbalanced
    stimKey(:, blk+3) = temp(t.events+1:t.sentNum);
end

eventStartKey = repmat((t.epiTime + [0:t.eventTime:((t.events-1)*t.eventTime)]'), [1, t.numBlocks]);  %#ok<NBRAK>
jitterKey     = t.jitWindow * rand(t.events, t.numBlocks);
stimStartKey  = eventStartKey + jitterKey; 
visCueKey     = stimStartKey + t.visCueTime; 
stimEndKey    = stimStartKey + t.presTime;
eventEndKey   = eventStartKey + t.eventTime;

%% File names
ResultsXls = fullfile(dir_results, subj.num, 'post_scan_naming_primes_v2_results.xlsx'); 
Variables  = fullfile(dir_results, subj.num, 'post_scan_naming_primes_v2_variables.mat');

%% Load stim
stim_filename = 'naming_task_stim_post_10Jul18_behav.txt.';
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

fs = cell(1, t.numBlocks);
prime_aud = struct(stimType{1}, [], stimType{2}, [], stimType{3}, []);
prime_end = struct(stimType{1}, [], stimType{2}, [], stimType{3}, []);

for jj = 1:3
    cd(dir_primes{jj})
    % prime_aud = cell(1, t.primesNum); 
    fs{jj} = nan(1, primeNum);
    files = dir('*.wav'); 
    for ii = 1:length(files)
        [prime_aud(ii).(stimType{jj}), fs{jj}(ii)] = audioread(files(ii).name); 
        prime_aud(ii).(stimType{jj}) = [prime_aud(ii).(stimType{jj}), prime_aud(ii).(stimType{jj})]'; 
        prime_end(ii).(stimType{jj}) = length(prime_aud(ii).(stimType{jj}))/fs{jj}(ii);
    end
    
end

cd(dir_scripts)

% CHECK -- Did we load correct number of stimuli???
if length(stim_line) ~= t.stimNum
    sca
    error('length(stim_line) ~= t.stimNum: check stimuli or t.stimNum')
end

% CHECK -- Are the primes ok?
if length(prime_aud) ~= primeNum
    error('length(prime_aud) ~= primeNum: check primes or t.primeNum')
elseif ~all(cellfun(@(x) all(x == fs_trgt), fs))
    error('sampling rates not equal to 44100: check primes')
end

%% Open PTB and RTBox
[wPtr, rect] = Screen('OpenWindow', 0, 185);
DrawFormattedText(wPtr, 'Please wait, preparing experiment...');
Screen('Flip', wPtr);

centerX = rect(3)/2;
centerY = rect(4)/2;
crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 
HideCursor(); 
RTBox('fake', 1);
pahandle = PsychPortAudio('Open', [], [], [], fs_trgt);
Screen('TextSize', wPtr, fontsize); 

try
    for blk = subj.firstRun:subj.lastRun
        % Wait for first pulse
        DrawFormattedText(wPtr, ['Press "5%" to begin, or "ESC" to quit. Block ' num2str(blk)]);
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
        AbsVisCue(:, blk)    = firstPulse(blk) + visCueKey(:,blk); 
        
        WaitTill(firstPulse(blk) + t.epiTime);
                
        %% Present visual stimuli
        for evt = 1:t.events
            eventStart(evt, blk) = GetSecs(); 
            
            % PREPARE AUDIO AND TEXT(flip screen, prepare the prime)
            if blk > 3
                stimnum = blk - 3;
            else
                stimnum = blk;
            end
            
            PsychPortAudio('FillBuffer', pahandle, prime_aud(stimKey(evt, blk)).(stimType{stimnum}));
            DrawFormattedText(wPtr, stim_line{stimKey(evt, blk)}, 'center', 'center', [0 0 0]);
            WaitTill(AbsStimStart(evt, blk) - 0.1);
            
            % START AUDIO AND DRAW TEXT
            stimStart(evt, blk) = Screen('Flip', wPtr, AbsStimStart(evt, blk));
            PsychPortAudio('Start', pahandle, 1, [], 1); % play ASAP when flip is done
            DrawFormattedText(wPtr, stim_line{stimKey(evt, blk)}, 'center', 'center', color);
            
            % LEAVE IT UNTIL IT'S TIME TO CUE
            WaitTill(AbsVisCue(evt, blk) - 0.1);
            
            % IT'S CUE TIME (flip screen, prepare fixation cross)
            visCue(evt, blk) = Screen('Flip', wPtr, AbsVisCue(evt, blk));
            Screen('DrawLines', wPtr, crossCoords, 2, 0, [centerX, centerY]);
            
            % REPLACE IT WITH FIXATION CROSS            
            stimEnd(evt, blk) = Screen('Flip', wPtr, AbsStimEnd(evt, blk));

            % WAIT UNTIL END OF EPI ACQUISITION
            WaitTill(AbsEvEnd(evt, blk)); 
            eventEnd(evt, blk) = GetSecs(); 
            
        end

        WaitSecs(t.eventTime); 
        runEnd(blk) = GetSecs(); 

        DrawFormattedText(wPtr, 'End of run. Great job!', 'center', 'center', [0 0 0]); 
        Screen('Flip', wPtr); 
        WaitTill(GetSecs() + 6);
                    
    end
    
catch err
    sca; 
    runEnd(blk) = GetSecs();  %#ok<NASGU>
    cd(dir_funcs)
    disp('Dumping data...')
    OutputData_reading_primes_v3
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
OutputData_reading_primes_v3
disp('All done!')
cd(dir_scripts)

% end
    