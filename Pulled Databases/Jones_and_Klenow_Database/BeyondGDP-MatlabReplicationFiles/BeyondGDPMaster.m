% BeyondGDPMaster.m  9/10/15
%
%  Master file for running all programs (both micro and macro)
%  for the Beyond GDP project.

clear all;
SetParameters;

% First the micro results
cd MicroData;
LambdaMaster
PlotMicroResults

% The Robustness programs require MicroDataTXTFilesPresent = 1  
% That is, they require the underlying *.txt micro data from household surveys.
% If you have these files, change the setting in SetParameters.m and
% uncomment the next two lines.
%LambdaRobust
%GrowthRobust

% Now the macro results
cd ..
RawlsLevels
RawlsGrowth
Rawls15Micro

disp ' ';
disp 'BeyondGPMaster has successfully completed.';
disp 'See the relevant log files for the results.';
disp ' ';
