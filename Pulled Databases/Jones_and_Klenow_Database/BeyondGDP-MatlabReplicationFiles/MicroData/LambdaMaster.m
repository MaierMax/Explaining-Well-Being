% LambdaMaster.m  8/29/14
%
% Masterfile for Lambda results -- growth rates and levels

% People who download replication files from AER will not have the micro data.
% This shortcut allows them to load the necessary moments to get basic results
% 
% Users should set "NoMicroDataTXTFiles" appropriately

diarychad('LambdaMasterLevels');
clear all;

run ../SetParameters  % Baseline parameter values
LambdaStats
save LambdaStatsResults CountryInputs KeyFacts Results lambda ytilde ubar theta beta g epsilon;


diarychad('LambdaMasterGrowth');
clear all;
run ../SetParameters  % Baseline parameter values
GrowthStats
save GrowthStatsResults CountryInputs KeyFacts Results glambda gy ubar theta beta g epsilon;

% Note well: Need to run LambdaRobust before running PlotMicroResults
% PlotMicroResults
% disp 'Remember to copy new graphs over to Dropbox...';
