% SetParameters.m
%
%  Simple function to establish the key benchmark parameters for the paper.

% Set path to include various microdata .m files and data files
% Make sure all relevant files are in path
curdir=pwd;
if isempty(strfind(curdir,'MicroData'));
    path(curdir,path); 
    path([curdir '/MicroData'],path); 
    path([curdir '/MicroData/Data'],path); 
    if exist('ChadMatlab')==7; 
        path([curdir '/ChadMatlab'],path); 
    end; 
end;

FrischLSElasticity=1.0;  % From Pistaferri via Hall (2009)
theta=14.172748;    % From Pete. See also MicroData/CalibrateTheta-2014-08-15
ValueofLife2005dollars=6;
beta=.99;
g=.02;

Silent=0;         % Keep detailed results turned on for Micro data. Off is Silent=1


% People who download replication files from the AER will not have the micro data.
% This shortcut allows them to load the necessary moments to get basic results.
% 
% Such users should set "MicroDataTXTFilesPresent=0" here.
% Note: the LambdaRobust.m and GrowthRobust.m programs require the *.txt
%  micro data files, so they require setting MicroDataTXTFilesPresent = 1

global MicroDataTXTFilesPresent
%MicroDataTXTFilesPresent = 1     % We *have* the Data/*.txt files
MicroDataTXTFilesPresent = 0   % We *do not have* the Data/*.txt files
