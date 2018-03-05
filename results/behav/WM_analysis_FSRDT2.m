clear all; close all; clc;

allvals = [] ;


dinfo = dir('*.xlsx');
for K = 1 : length(dinfo)
    thisfilename = dinfo(K).name; 
    if size(strfind(thisfilename, 'WM')) 
        [num,label]=xlsread(thisfilename);

    %stim_index =label((2:end),3);
    %categories =label(1,:);
    correct = sum(num(:,1));
    %total_trial_number = 48;
    %response_time = num(:,5);

%find total accuracy
    acc_total = sum(correct)/40;

%Count how many object/subject and clear/15 the subject got correct

%     runs = 6 ;
% 
%     a3_counter=0;
%     a4_counter=0;
%     a5_counter=0;
%     v3_counter=0;
%     v4_counter=0;
%     v5_counter=0;
%     
%     
%     conditions = {'a(3';
%                   'a(4';
%                   'a(5';
%                   'vg(3';
%                   'vg(4';
%                   'vg(5'};
% 
%     counters = [a3_counter, a4_counter, a5_counter, v3_counter, v4_counter, v5_counter];
% 
%     for run=1:runs;
%     
%         for j = 1:total_trial_number;
%           if any(~cellfun('isempty',strfind(stim_index(j),conditions(run,1)))) == 1 
%                counters(run) = correct(j) + counters(run);
%         
%           end 
%         end 
%     end
% 
% %not sure why counters(run) =/= object_clear_counter and ect.
% 
%     a3_counter=counters(1);
%     a4_counter=counters(2);
%     a5_counter=counters(3);
%     v3_counter=counters(4);
%     v4_counter=counters(5);
%     v5_counter=counters(6);
% 
%     %find the accuracy of each type 
%     
%     a3_acc = a3_counter / 6;
%     a4_acc = a4_counter / 8;
%     a5_acc = a5_counter / 10;
%     v3_acc = v3_counter / 6;
%     v4_acc = v4_counter / 8;
%     v5_acc = v5_counter / 10;
%     
%     %Find accuracy for auditory and visual 
%     auditory_acc = (a3_counter + a4_counter + a5_counter) / 24;
%     visual_acc = (v3_counter + v4_counter + v5_counter) / 24;
%     
%     %find accuracy for each block size 
%     block3_acc = (a3_counter + v3_counter) / 12;
%     block4_acc = (a4_counter + v4_counter) / 16;
%     block5_acc = (a5_counter + v5_counter) / 20;
%     
%     %count up RT for each condition
%     rt_a3_counter=0; rt_a4_counter=0; rt_a5_counter=0; rt_v3_counter=0;rt_v4_counter=0; rt_v5_counter=0;
%     rt_a3_num=0; rt_a4_num=0; rt_a5_num=0; rt_v3_num=0; rt_v4_num=0; rt_v5_num=0;
%     
%     rt_counters = [rt_a3_counter, rt_a4_counter, rt_a5_counter, rt_v3_counter, rt_v4_counter, rt_v5_counter];
%     rt_counters_num = [rt_a3_num, rt_a4_num, rt_a5_num, rt_v3_num, rt_v4_num, rt_v5_num];
%     
%     for run=1:runs;
%         for j = 1:total_trial_number;
%              
%             if any(~cellfun('isempty',strfind(stim_index(j),conditions(run,1)))) == 1 
%                   
%                   if correct(j) == 1    
%                       rt_counters(run) = response_time(j) + rt_counters(run);
%                       rt_counters_num(run) = 1 + rt_counters_num(run);
%                   end
%               end
%         end 
%      end 
%     
% 
%     rt_a3_counter = rt_counters(1); rt_a4_counter = rt_counters(2); 
%     rt_a5_counter = rt_counters(3); rt_v3_counter = rt_counters(4);
%     rt_v4_counter = rt_counters(5); rt_v5_counter = rt_counters(6);
% 
%     %find avg RT for each condition 
%     a3_rt = rt_a3_counter / rt_counters_num(1); 
%     a4_rt = rt_a4_counter / rt_counters_num(2);
%     a5_rt = rt_a5_counter / rt_counters_num(3);
%     v3_rt = rt_v3_counter / rt_counters_num(4);
%     v4_rt = rt_v4_counter / rt_counters_num(5);
%     v5_rt = rt_v5_counter / rt_counters_num(6);
%     
%     %turn NaN into 0's 
%     a3_rt(isnan(a3_rt)) = 0;
%     a4_rt(isnan(a4_rt)) = 0;
%     a5_rt(isnan(a5_rt)) = 0;
%     v3_rt(isnan(v3_rt)) = 0; 
%     v4_rt(isnan(v4_rt)) = 0;
%     v5_rt(isnan(v5_rt)) = 0; 
%     
%     right_rt = (sum(rt_counters) / sum(rt_counters_num)); 
%     
 
    
subjectvals = [string(thisfilename),correct]; 
allvals = [allvals; subjectvals]; 

    end 
end


