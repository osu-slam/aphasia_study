cd('C:\Users\heard.49\Documents\GitHub\aphasia_study\results\behav')

xlsread('subject-1.WMT.csv')

acc_aud = data(1:24, 1);
acc_vis = data(25:48, 1);

total_acc_aud = sum(acc_aud) / 24
total_acc_vis = sum(acc_vis) / 24

