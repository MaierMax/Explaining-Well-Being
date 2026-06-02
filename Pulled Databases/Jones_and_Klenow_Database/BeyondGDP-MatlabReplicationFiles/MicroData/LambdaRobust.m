% LambdaRobust.m  8/29/14
%
% Masterfile for Lambda Robustness results. Detailed log files are 
% available for each case. See the main program for log file names.
%
% This program will not run successfully unless the underlying micro data
% files in Data/*.txt have been created using the Stata programs.


diarychad('LambdaRobust');
help LambdaRobust

% beta=1, g=0
diarychad('LambdaRobustBeta1Gis0');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- beta = 1, g = 0'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
beta=1; g=0;
LambdaStats
% Save results for PlotMicroData.m
save LambdaStatsResultsBeta1Gis0 CountryInputs KeyFacts Results lambda ytilde ubar theta beta g epsilon;

% beta=0.96, g=0.02
diarychad('testRobustBeta96');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- beta = 0.96, g = 0.02'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
beta=0.96;
LambdaStats


% StartAge = 2
diarychad('LambdaRobustStartAge2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 2'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=2;
LambdaStats

% StartAge = 25
diarychad('testRobustStartAge25');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 25'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=25;
LambdaStats


% StartAge = 40
diarychad('LambdaRobustStartAge40');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- StartAge = 40'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
StartAge=40;
LambdaStats

% Theta for France
diarychad('LambdaRobustFrenchTheta');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Theta from France FOC '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
theta=15.93707; % From Pete ThetaCalibration-2014-11-04.xls
LambdaStats

% CV
diarychad('LambdaRobustCV');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Compensating Variation'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
CVEV='CV'
LambdaStats

% VSL = $5 million
diarychad('LambdaRobustVSL5');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- VSL = $5 million '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
ValueofLife2005dollars=5;
LambdaStats

% VSL = $7 million
diarychad('LambdaRobustVSL7');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- VSL = $7 million '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
ValueofLife2005dollars=7;
LambdaStats


% FrischLSElasticity=0.5  
diarychad('LambdaRobustFrisch05');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- FrischLSElasticity=0.5  '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
FrischLSElasticity=0.5; 
theta=41.189349;   % From Pete email 8/27/14
LambdaStats


% FrischLSElasticity=2.0  
diarychad('LambdaRobustFrisch20');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- FrischLSElasticity=2.0  '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
FrischLSElasticity=2.0;  
theta=8.3135909;  % From Pete email 8/27/14
LambdaStats

% CRRA log case just for consistency checking
diarychad('LambdaRobustCRRAlog');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: log case'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=1; clowerbar=0;
CRRAStats

% CRRA gamma = 1.5, clowerbar = .05
diarychad('LambdaRobustCRRA1.5');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: gamma = 1.5, clowerbar = .05'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=1.5; clowerbar=0.05; theta=12.268913;
CRRAStats

% CRRA gamma = 2.0, clowerbar = .2
diarychad('LambdaRobustCRRA2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- CRRA: gamma = 2, clowerbar = .20'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
gamma=2; clowerbar=0.20; theta=9.0893532;
CRRAStats



% Kids Get Adult Leisure (rather than 100% leisure)
diarychad('LambdaRobustKidsLeisure1');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Kids Get Adult Leisure '; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
KidsGetAdultLeisure=1;
LambdaStats

% Kids Get 50% Adult Leisure and 50% of 1
diarychad('LambdaRobustKidsLeisure2');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- Kids Get .5*Adult Leisure +.5*100percent'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
KidsGetAdultLeisure=2;
LambdaStats

% HHSizeEquivScale = 1
diarychad('testRobustHHSizeEquivScale');
clear all;
disp '------------------------------------------------------- ';
tle= ' Robustness -- HHSizeEquivScale = 1 ==> sqrt(hhsize)'; disp(tle);
disp '------------------------------------------------------- ';
disp ' ';
run ../SetParameters
HHSizeEquivScale = 1;
LambdaStats


