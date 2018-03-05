%% FSTanalysis_V4_MHedits.m
% Code to analyze behavioral data from pre-screening of aphasia patient.
% Edits by Matthew Heard to code originally written by Sanghoon Ahn. 

% CHANGELOG (DD/MM/YY)
% 05/03/18  --  Started making edits and documentation to code. MH

clear all; close all; clc;

allvals = [] ;


dinfo = dir('*FST.csv');
for K = 1 : length(dinfo) % For each FST file... -- MH
    thisfilename = dinfo(K).name; 
%     if size(strfind(thisfilename, 'setA')) > 0 || size(strfind(thisfilename, 'setB')) > 0
    % Not sure why the above condition was included. setA and setB may have
    % been part of the filename convention at COSI but is not relevant
    % here. MH
                

[num,label]=xlsread(thisfilename);

% Are the first 9 rows "training"? If so, then skip them? MH
stim_index =label((10:end),4); 
categories =label(1,:);
correct = num(9:end,3);
%correct_trial = num(1:14,3);
total_trial_number = 40;
response_time = num(9:end,5);

%find total accuracy
acc_total = sum(correct)/40;



%Count how many object/subject and clear/15 the subject got correct

runs = 4 ;

OC_counter=0;
SC_counter=0;
OD_counter=0;
SD_counter=0;

conditions = {'OM_clear', 'OF_clear';
              'SM_clear', 'SF_clear';
              'OM_SNR2', 'OF_SNR2';
              'SM_SNR2', 'SF_SNR2'};

counters = [OC_counter, SC_counter, 
           OD_counter,SD_counter];

for run=1:runs;
    
    for j = 1:total_trial_number;
          if any(~cellfun('isempty',strfind(stim_index(j),conditions(run,1)))) == 1 
               counters(run) = correct(j) + counters(run);
          elseif any(~cellfun('isempty',strfind(stim_index(j), conditions(run,2)))) == 1
               counters(run) = correct(j) + counters(run);
          end 
    end 
end

%not sure why counters(run) =/= object_clear_counter and ect.

OC_counter=counters(1);
SC_counter=counters(2);
OD_counter=counters(3);
SD_counter=counters(4);

%find the accuracy of each type 
trials_per_run = 10;
OC_acc = OC_counter / trials_per_run;
SC_acc = SC_counter / trials_per_run;
OD_acc = OD_counter / trials_per_run;
SD_acc = SD_counter / trials_per_run; 

%count up RT for each condition
rt_OC_counter=0; rt_SC_counter=0; rt_OD_counter=0; rt_SD_counter=0;
rt_counters = [rt_OC_counter, rt_SC_counter, rt_OD_counter, rt_SD_counter];

for run=1:runs;
    for j = 1:total_trial_number;
          if any(~cellfun('isempty',strfind(stim_index(j),conditions(run,1)))) == 1 
              
              if correct(j) == 1    
                  rt_counters(run) = response_time(j) + rt_counters(run);
              end
            
          elseif any(~cellfun('isempty',strfind(stim_index(j), conditions(run,2)))) == 1
             
              if correct(j) == 1 
                  rt_counters(run) = response_time(j) + rt_counters(run);
              end
          end 
    end 
end

rt_OC_counter = rt_counters(1); rt_SC_counter = rt_counters(2); 
rt_OD_counter = rt_counters(3); rt_SD_counter = rt_counters(4); 

%find avg RT for each condition 
OC_rt = rt_OC_counter / OC_counter;
SC_rt = rt_SC_counter / SC_counter;
OD_rt = rt_OD_counter / OD_counter;
SD_rt = rt_SD_counter / SD_counter; 

right_rt = ((rt_OC_counter + rt_SC_counter + rt_OD_counter + rt_SD_counter) / sum(correct)); 

% REACTION TIMES FOR WRONG RESPONSES %
%count up wrong RT for each condition
wrt_OC_counter=0; wrt_SC_counter=0; wrt_OD_counter=0; wrt_SD_counter=0;
wrt_counters = [wrt_OC_counter, wrt_SC_counter, wrt_OD_counter, wrt_SD_counter];

for run=1:runs;
    for j = 1:total_trial_number;
          if any(~cellfun('isempty',strfind(stim_index(j),conditions(run,1)))) == 1 
              
              if correct(j) == 0    
                  wrt_counters(run) = response_time(j) + wrt_counters(run);
              end
            
          elseif any(~cellfun('isempty',strfind(stim_index(j), conditions(run,2)))) == 1
             
              if correct(j) == 0 
                  wrt_counters(run) = response_time(j) + wrt_counters(run);
              end
          end 
    end 
end

wrt_OC_counter = wrt_counters(1); wrt_SC_counter = wrt_counters(2); 
wrt_OD_counter = wrt_counters(3); wrt_SD_counter = wrt_counters(4); 

%find avg RT for each condition 
wOC_rt = wrt_OC_counter / (10 - OC_counter) ;
wSC_rt = wrt_SC_counter / (10 - SC_counter);
wOD_rt = wrt_OD_counter / (10 - OD_counter);
wSD_rt = wrt_SD_counter / (10 - SD_counter); 

wOC_rt(isnan(wOC_rt)) = 0;
wSC_rt(isnan(wSC_rt)) = 0;
wOD_rt(isnan(wOD_rt)) = 0;
wSD_rt(isnan(wSD_rt)) = 0; 

wrong_rt = ((wOC_rt + wSC_rt + wOD_rt + wSD_rt) / (40 - sum(correct))); 

%find ACC/run 
% run_divider = {(1:10), (11:20), (21:30), (31:40)};
% run1_count=0; run2_count=0; run3_count=0; run4_count=0; 
% run_counters = [run1_count, run2_count, run3_count, run4_count];
% 
% for run = 1:runs 
%     correct_for_run = correct(run_divider{run});
%     run_counters(run) = sum(correct(run_divider{run}));
% end
% 
% run1_count = run_counters(1); run2_count = run_counters(2); 
% run3_count = run_counters(3);run4_count = run_counters(4);
% 
% run1 = run1_count/trials_per_run; 
% run2 = run2_count/trials_per_run;
% run3 = run3_count/trials_per_run;
% run4 = run4_count/trials_per_run;

% Print Results
% 
% disp('----------------------------------------');
% disp('----------------------------------------');
% 
% disp(['mean accuracy for run1 is ' num2str(round(run1*100)) ' %']);
% disp(['mean accuracy for run2 is ' num2str(round(run2*100)) ' %']);
% disp(['mean accuracy for run3 is ' num2str(round(run3*100)) ' %']);
% disp(['mean accuracy for run4 is ' num2str(round(run4*100)) ' %']);
% 
% disp('----------------------------------------');
% disp('----------------------------------------');
% 
% disp(['mean accuracy for SC is ' num2str(SC_acc*100) ' %']);
% disp(['mean accuracy for OC is ' num2str(OC_acc*100) ' %']);
% disp(['mean accuracy for SD is ' num2str(SD_acc*100) ' %']);
% disp(['mean accuracy for OD is ' num2str(OD_acc*100) ' %']);
% 
% disp('----------------------------------------');
% disp('----------------------------------------');
% 
% disp(['mean RT for SC is ' num2str(SC_rt) ' ms']);
% disp(['mean RT for OC is ' num2str(OC_rt) ' ms']);
% disp(['mean RT for SD is ' num2str(SD_rt) ' ms']);
% disp(['mean RT for OD is ' num2str(OD_rt) ' ms']);
% 
% 
% %find SD for response times 
% 
% std_RT_SC=nanstd(SC_rt)/sqrt(length(SC_rt));
% std_RT_SD=nanstd(SD_rt)/sqrt(length(SD_rt));
% std_RT_OC=nanstd(OC_rt)/sqrt(length(OC_rt));
% std_RT_OD=nanstd(OD_rt)/sqrt(length(OD_rt));
% 
% 
% %Graph RT 
% %X=[1 2 3 4];
% %Y=[SC_rt, OC_rt, SD_rt, OD_rt];
% %SE=[std_RT_SC std_RT_OC std_RT_SD std_RT_OD];
% 
% %bar(X,Y);
% 
% %set(gca,'XTickLabel',['SC';'OC'; 'SD';'OD'])
% %xlabel('Sentence type','fontweight','bold','fontsize',12);
% %ylabel('RT (ms)','fontweight','bold','fontsize',12);
% 
% %hold on;
% 
% % h=errorbar(X,Y,SE,'.');
% 
% %graph accuracy
% %figure()
% %X1=[1 2 3 4];
% %Y1=[SC_acc, OC_acc, SD_acc, OD_acc] *100;
% 
% %bar(X1,Y1);
% 
% %set(gca,'XTickLabel',['SC';'OC'; 'SD';'OD'])
% %xlabel('Sentence type','fontweight','bold','fontsize',12);
% %ylabel('Accuracy (%)','fontweight','bold','fontsize',12);
% 
% %hold on;

    

subjectvals = [string(thisfilename),acc_total, SC_acc, OC_acc, SD_acc ,OD_acc];
%subjectvals = [string(thisfilename), right_rt, wrong_rt, SC_rt, OC_rt, SD_rt, OD_rt, wSC_rt, wOC_rt, wSD_rt, wOD_rt];
%subjectvals = [string(thisfilename),acc_total, SC_acc, OC_acc, SD_acc ,OD_acc, SC_rt, OC_rt, SD_rt, OD_rt, wSC_rt, wOC_rt, wSD_rt, wOD_rt, right_rt, wrong_rt];


allvals = [allvals; subjectvals]; 

%     end
end


