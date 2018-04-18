load('RT.mat')

close all
figure(1)
hold on
bar(1:3, RT.summary(1:3, 1), 'r')
bar(4:5, RT.summary(4:5, 1), 'g')
bar(6:7, RT.summary(6:7, 1), 'b')
errorbar(RT.summary(:, 1), RT.summary(:, 6), 'k', 'LineStyle', 'none')

% labels = {'Session', 'Run #', 'average RT'};
% sess = vertcat(repmat('09-Mar', 54, 1), repmat('16-Mar', 31, 1), repmat('27-Mar', 20, 1));
% runs = vertcat(ones(18, 1), 2*ones(18, 1), 3*ones(18, 1), ones(14, 1), 2*ones(17, 1), ones(10, 1), 2*ones(10, 1));
% RTs  = vertcat(RT.sess1.run1, RT.sess1.run2, RT.sess1.run3, RT.sess2.run1, RT.sess2.run2, RT.sess3.run1, RT.sess3.run2);

sess = {'09-Mar'; '09-Mar'; '09-Mar'; '16-Mar'; '16-Mar'; '27-Mar'; '27-Mar'};
runnum = [1; 2; 3; 1; 2; 1; 2];
allRTs  = [RT.sess1.run1; RT.sess1.run2; RT.sess1.run3; RT.sess2.run1; RT.sess2.run2; RT.sess3.run1; RT.sess3.run2];
avgRT = RT.summary(:, 1);
% names = {'Sesson', 'Run', 'RT'};

T = table(sess, runnum, avgRT);
Meas = table([1 2]', 'VariableNames', {'Measures'});
rm = fitrm(T, 'runnum-avgRT~sess', 'WithinDesign', Meas);
anovatbl = ranova(rm);