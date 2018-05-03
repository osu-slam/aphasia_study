%% Stimuli Check
% Makes sure stimuli are counterbalanced. Checks how many stimuli are from
% each pattern and each category. Then checks the sub-groups. It could be
% MUCH prettier, probably using structures to cut down on number of for
% loops, but this is good enough. 
% Author -- Matt. 

% Set variables for debugging
% ns = t.sentNum; 
% eventkey = stimKey; 

function stimulicheck_naming(ns, eventkey)
% Set up keys and preallocate when possible
sent = eventkey(eventkey <= ns); 
s = length(sent); 

requ = []; 
ques = []; 
self = [];
misc = [];

requKey = sort(horzcat(1:8:ns, 2:8:ns)); 
quesKey = sort(horzcat(3:8:ns, 4:8:ns)); 
selfKey = sort(horzcat(5:8:ns, 6:8:ns)); 
miscKey = sort(horzcat(7:8:ns, 8:8:ns)); 

% Pull out which stimuli are each pattern/each type
pat1Key = 1:8;
pat2Key = 9:16;
pat3Key = 17:24;
pat4Key = 25:32;

pat1 = [];
pat2 = [];
pat3 = [];
pat4 = [];

for ii = 1:length(sent)
    if     find(sent(ii) == requKey)
        requ = horzcat(requ, sent(ii)); 
    elseif find(sent(ii) == quesKey) 
        ques = horzcat(ques, sent(ii)); 
    elseif find(sent(ii) == selfKey) 
        self = horzcat(self, sent(ii)); 
    elseif find(sent(ii) == miscKey) 
        misc = horzcat(misc, sent(ii)); 
    end
    
    if     find(sent(ii) == pat1Key)
        pat1 = horzcat(pat1, sent(ii)); 
    elseif find(sent(ii) == pat2Key)
        pat2 = horzcat(pat2, sent(ii)); 
    elseif find(sent(ii) == pat3Key)
        pat3 = horzcat(pat3, sent(ii)); 
    elseif find(sent(ii) == pat4Key)
        pat4 = horzcat(pat4, sent(ii)); 
    end
    
end

% Prepare to pull out each combination
pat1requ = [];
pat1ques = [];
pat1self = [];
pat1misc = [];

pat2requ = [];
pat2ques = [];
pat2self = [];
pat2misc = [];

pat3requ = [];
pat3ques = [];
pat3self = [];
pat3misc = [];

pat4requ = [];
pat4ques = [];
pat4self = [];
pat4misc = [];

% Find each individual stimuli
for ii = 1:length(pat1)
    if find(pat1(ii) == requKey)
        pat1requ = horzcat(pat1requ, pat1(ii)); 
    elseif find(pat1(ii) == quesKey)
        pat1ques = horzcat(pat1ques, pat1(ii)); 
    elseif find(pat1(ii) == selfKey)
        pat1self = horzcat(pat1self, pat1(ii)); 
    elseif find(pat1(ii) == miscKey)
        pat1misc = horzcat(pat1misc, pat1(ii)); 
    end
end

for ii = 1:length(pat2)
    if find(pat2(ii) == requKey)
        pat2requ = horzcat(pat2requ, pat2(ii)); 
    elseif find(pat2(ii) == quesKey)
        pat2ques = horzcat(pat2ques, pat2(ii)); 
    elseif find(pat2(ii) == selfKey)
        pat2self = horzcat(pat2self, pat2(ii)); 
    elseif find(pat2(ii) == miscKey)
        pat2misc = horzcat(pat2misc, pat2(ii)); 
    end
end

for ii = 1:length(pat3)
    if find(pat3(ii) == requKey)
        pat3requ = horzcat(pat3requ, pat3(ii)); 
    elseif find(pat3(ii) == quesKey)
        pat3ques = horzcat(pat3ques, pat3(ii)); 
    elseif find(pat3(ii) == selfKey)
        pat3self = horzcat(pat3self, pat3(ii)); 
    elseif find(pat3(ii) == miscKey)
        pat3misc = horzcat(pat3misc, pat3(ii)); 
    end
end

for ii = 1:length(pat4)
    if find(pat4(ii) == requKey)
        pat4requ = horzcat(pat4requ, pat4(ii)); 
    elseif find(pat4(ii) == quesKey)
        pat4ques = horzcat(pat4ques, pat4(ii)); 
    elseif find(pat4(ii) == selfKey)
        pat4self = horzcat(pat4self, pat4(ii)); 
    elseif find(pat4(ii) == miscKey)
        pat4misc = horzcat(pat4misc, pat4(ii)); 
    end
end

% Double check that we have correct number of stimuli
numPat1 = length(pat1);
numPat2 = length(pat2);
numPat3 = length(pat3);
numPat4 = length(pat4);

numRequ = length(requ);
numQues = length(ques);
numSelf = length(self);
numMisc = length(misc);

numPat1Requ = length(pat1requ);
numPat1Ques = length(pat1ques);
numPat1Self = length(pat1self);
numPat1Misc = length(pat1misc);

numPat2Requ = length(pat2requ);
numPat2Ques = length(pat2ques);
numPat2Self = length(pat2self);
numPat2Misc = length(pat2misc);

numPat3Requ = length(pat3requ);
numPat3Ques = length(pat3ques);
numPat3Self = length(pat3self);
numPat3Misc = length(pat3misc);

numPat4Requ = length(pat4requ);
numPat4Ques = length(pat4ques);
numPat4Self = length(pat4self);
numPat4Misc = length(pat4misc);

if (numPat1 ~= s/4 || numPat2 ~= s/4 || numPat3 ~= s/4 || numPat4 ~= s/4 || ... 
    numRequ ~= s/4 || numQues ~= s/4 || numSelf ~= s/4 || numMisc ~= s/4 || ...
    numPat1Requ ~= s/16 || numPat1Ques ~= s/16 || numPat1Self ~= s/16 || numPat1Misc ~= s/16 || ...
    numPat2Requ ~= s/16 || numPat2Ques ~= s/16 || numPat2Self ~= s/16 || numPat2Misc ~= s/16 || ...
    numPat3Requ ~= s/16 || numPat3Ques ~= s/16 || numPat3Self ~= s/16 || numPat3Misc ~= s/16 || ...
    numPat4Requ ~= s/16 || numPat4Ques ~= s/16 || numPat4Self ~= s/16 || numPat4Misc ~= s/16)
    error('Check your stimuli list, something is wrong')
end

end