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
Screen('Preference', 'SkipSyncTests', 1);

fontsize = 36;
bpm      = 65;
color    = [255 0 0];
primeNum = 16; % Now there's a prime for each sentence!

%% Paths
cd ..
dir_exp     = pwd; 
dir_results = fullfile(dir_exp, 'results');
dir_scripts = fullfile(dir_exp, 'scripts');
dir_stim    = fullfile(dir_exp, 'stim', 'naming_task');
dir_primes  = fullfile(dir_exp, 'stim', 'rhythm_primes'); 
dir_funcs   = fullfile(dir_scripts, 'functions');
% Instructions = 'instructions_lang.txt';

%% Timing
t.stimNum = 16; % no jabberwocky!
t.sentNum = 16; 
t.events  = 16; 

t.T          = (bpm/60)^-1; % duration of one beat of prime
t.wholePrime = t.T*8; % duration of entire stimuli
t.visCueTime = t.T*3; % time at which visual prime should be presented, 
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

%% Preallocating timing variables. 
AbsEvStart    = NaN(t.events, 1); 
AbsStimStart  = NaN(t.events, 1); 
AbsVisCue     = NaN(t.events, 1); 
AbsStimEnd    = NaN(t.events, 1); 
AbsEvEnd      = NaN(t.events, 1); 
eventEnd      = NaN(t.events, 1); 
eventEndKey   = NaN(t.events, 1); 
eventStart    = NaN(t.events, 1);
eventStartKey = NaN(t.events, 1); 
jitterKey     = NaN(t.events, 1); 
stimStart     = NaN(t.events, 1); 
visCue        = NaN(t.events, 1);
stimEnd       = NaN(t.events, 1); 
stimStartKey  = NaN(t.events, 1); 
visCueKey     = NaN(t.events, 1); 
stimEndKey    = NaN(t.events, 1); 
stimKey       = NaN(t.events, 1); 
durationKey   = NaN(t.events, 1); 

firstPulse = NaN(1, 1); 
runEnd     = NaN(1, 1); 

%% File names
ResultsXls = fullfile(dir_results, 'post_screen_naming_primes_17Jul18', 'naming_primes_laptop_results.xlsx'); 
Variables  = fullfile(dir_results, 'post_screen_naming_primes_17Jul18', 'naming_primes_laptop_variables.mat');
    
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

cd(dir_primes)
% prime_aud = cell(1, t.primesNum); 
fs = nan(1, primeNum);
files = dir('*.wav'); 
for ii = 1:length(files)
    [prime_aud{ii}, fs(ii)] = audioread(files(ii).name); %#ok<SAGROW>
    prime_aud{ii} = [prime_aud{ii}, prime_aud{ii}]'; %#ok<SAGROW>
    prime_end{ii} = length(prime_aud{ii})/fs(ii); %#ok<SAGROW>
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
elseif ~all(fs == 44100)
    error('sampling rates not equal to 44100: check primes')
end

blk = 1;

%% Open PTB and RTBox
[wPtr, rect] = Screen('OpenWindow', 0, 185);
DrawFormattedText(wPtr, 'Please wait, preparing experiment...');
Screen('Flip', wPtr);

centerX = rect(3)/2;
centerY = rect(4)/2;
crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 
HideCursor(); 
RTBox('fake', 1);
pahandle = PsychPortAudio('Open', [], [], [], fs(1));
Screen('TextSize', wPtr, fontsize); 

%% Prepare test
try
    while 1

        DrawFormattedText(wPtr, 'Please wait, preparing run...');
        Screen('Flip', wPtr); 

        % Prepare timing keys
        if blk ~= 1
            AbsEvStart    = [AbsEvStart,    NaN(t.events, 1)]; %#ok<AGROW>
            AbsStimStart  = [AbsStimStart,  NaN(t.events, 1)]; %#ok<AGROW>
            AbsVisCue     = [AbsVisCue,     NaN(t.events, 1)]; %#ok<AGROW>
            AbsStimEnd    = [AbsStimEnd,    NaN(t.events, 1)]; %#ok<AGROW>
            AbsEvEnd      = [AbsEvEnd,      NaN(t.events, 1)]; %#ok<AGROW>
            eventEnd      = [eventEnd,      NaN(t.events, 1)]; %#ok<AGROW>
            eventEndKey   = [eventEndKey,   NaN(t.events, 1)]; %#ok<AGROW>
            eventStart    = [eventStart,    NaN(t.events, 1)]; %#ok<AGROW>
            eventStartKey = [eventStartKey, NaN(t.events, 1)]; %#ok<AGROW>
            jitterKey     = [jitterKey,     NaN(t.events, 1)]; %#ok<AGROW>
            stimStart     = [stimStart,     NaN(t.events, 1)]; %#ok<AGROW>
            visCue        = [visCue,        NaN(t.events, 1)]; %#ok<AGROW>
            stimEnd       = [stimEnd,       NaN(t.events, 1)]; %#ok<AGROW>
            stimStartKey  = [stimStartKey,  NaN(t.events, 1)]; %#ok<AGROW>
            visCueKey     = [visCueKey,     NaN(t.events, 1)]; %#ok<AGROW>
            stimEndKey    = [stimEndKey,    NaN(t.events, 1)]; %#ok<AGROW>
            stimKey       = [stimKey,       NaN(t.events, 1)]; %#ok<AGROW>
            durationKey   = [durationKey,   NaN(t.events, 1)]; %#ok<AGROW>

            firstPulse = [firstPulse, NaN(1, 1)]; %#ok<AGROW>
            runEnd     = [runEnd,     NaN(1, 1)]; %#ok<AGROW>
        end
        
        stimKey(:, blk) = Shuffle(1:16)';
        
        eventStartKey(:, blk) = t.epiTime + [0:t.eventTime:((t.events-1)*t.eventTime)]'; %#ok<NBRAK>
        jitterKey(:, blk)     = t.jitWindow * rand(t.events, 1);
        stimStartKey(:, blk)  = eventStartKey(:, blk) + jitterKey(:, blk); 
        visCueKey(:, blk)     = stimStartKey(:, blk) + t.visCueTime; 
        stimEndKey(:, blk)    = stimStartKey(:, blk) + t.presTime;
        eventEndKey(:, blk)   = eventStartKey(:, blk) + t.eventTime;

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
            PsychPortAudio('FillBuffer', pahandle, prime_aud{stimKey(evt, blk)});
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
        
        blk = blk + 1;
                    
    end
    
catch err
    sca; 
    runEnd(blk) = GetSecs();  %#ok<NASGU>
    cd(dir_funcs)
    disp('Dumping data...')
    OutputData_reading_primes_v2
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
    