% GrowthRobust.m  8/29/14
%
% Masterfile for Growth Robustness results. Detailed log files are 
% available for each case. See the main program for log file names.
%
% This program will not run successfully unless the underlying micro data
% files in Data/*.txt have been created using the Stata programs.

diarychad('GrowthRobust');
help GrowthRobust

% beta=1, g=0
diarychad('GrowthRobustBeta1Gis0');
clear all;
disp '------------------------------------------------------- ';
tle = ' Robustness -- beta = 1, g = 0'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
beta=1; g=0;
GrowthStats

% beta=0.96, g=0.02
diarychad('GrowthRobustBeta96');
clear all;
disp '------------------------------------------------------- ';
tle = ' Robustness -- beta = 0.96, g = 0.02'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
beta=0.96;
GrowthStats

% StartAge = 2
diarychad('GrowthRobustStartAge2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 2'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=2;
GrowthStats

% StartAge = 25
diarychad('GrowthRobustStartAge25');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 25'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=25;
GrowthStats


% StartAge = 40
diarychad('GrowthRobustStartAge40');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 40'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=40;
GrowthStats

% Theta for France
diarychad('GrowthRobustFrenchTheta');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Theta from France FOC '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
theta=15.93707; % From Pete ThetaCalibration-2014-11-04.xls
GrowthStats

% VSL = $5 million
diarychad('GrowthRobustVSL5');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- VSL = $5 million '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
ValueofLife2005dollars=5;
GrowthStats

% VSL = $7 million
diarychad('GrowthRobustVSL7');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- VSL = $7 million '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
ValueofLife2005dollars=7;
GrowthStats


% FrischLSElasticity=0.5  
diarychad('GrowthRobustFrisch05');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- FrischLSElasticity=0.5  '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
FrischLSElasticity=0.5; 
theta=41.189349;   % From Pete email 8/27/14
GrowthStats


% FrischLSElasticity=2.0  
diarychad('GrowthRobustFrisch20');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- FrischLSElasticity=2.0  '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
FrischLSElasticity=2.0;  
theta=8.3135909;  % From Pete email 8/27/14
GrowthStats

% CRRA log case just for consistency checking
diarychad('GrowthRobustCRRAlog');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: log case'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=1; clowerbar=0;
GrowthCRRA


% CRRA gamma = 1.5, clowerbar = .05
diarychad('GrowthRobustCRRA1.5');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: gamma = 1.5, clowerbar = .05'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=1.5; clowerbar=0.05; theta=12.268913;
GrowthCRRA


% CRRA gamma = 2.0, clowerbar = .2
diarychad('GrowthRobustCRRA2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: gamma = 2, clowerbar = .20'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=2; clowerbar=0.20; theta=9.0893532;
GrowthCRRA

% Kids Get Adult Leisure (rather than 100% leisure)
diarychad('GrowthRobustKidsLeisure1');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Kids Get Adult Leisure '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
KidsGetAdultLeisure=1;
GrowthStats

% Kids Get 50% Adult Leisure and 50% of 1
diarychad('GrowthRobustKidsLeisure2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Kids Get .5*Adult Leisure +.5*100percent'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
KidsGetAdultLeisure=2;
GrowthStats

% HHSizeEquivScale = 1
diarychad('GrowthRobustHHSizeEquivScale');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- HHSizeEquivScale = 1 ==> sqrt(hhsize)'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
HHSizeEquivScale = 1;
GrowthStats
