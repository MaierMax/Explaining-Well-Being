% GrowthCRRA
%
%   9/10/13 -- Master file for micro data welfare growth results.

disp ' '; disp ' ';
disp '------------------------------------------------------- ';
disp(tle);
disp '------------------------------------------------------- ';
disp ' ';

help GrowthCRRA

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Last two digits 0=single micro file, 1 if separate leisure/consumption
CountryInputs={
 %'Brazil'      'BRA'   2003 2008  1 1
 %'Spain'       'ESP'   2001  1
 %'China'       'CHN'   2002  0
 'France'      'FRA'   1984 2005  0 0
 'UK'          'GBR'   1985 2005  0 0
 'Indonesia'   'IDN'   1993 2006  0 0
 %'India'       'IND'   1983 2005  1 0
 'Italy'       'ITA'   1987 2006  0 0
 'Mexico'      'MEX'   1984 2006  0 0
 %'Malawi'      'MWI'   2004  0
 'Russia'      'RUS'   1998 2007  0 0
 'US'          'USA'   1984 2006  0 0
 %'SouthAfrica' 'ZAF'   1993  0 
}

if exist('clowerbar')~=1; clowerbar=0; end;

ubar=GetUbarMicroCRRA(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,40,gamma,clowerbar,Silent);
epsilon=FrischLSElasticity;  % Frisch elasticity
run ../ShowParameters


for i=1:size(CountryInputs,1);

    CountryInput1=CountryInputs(i,[1 2 4 6]);
    CountryInput0=CountryInputs(i,[1 2 3 5]);  % Reference / Initial year
    AnnualizeDivisor=[cell2mat(CountryInputs(i,3)) cell2mat(CountryInputs(i,4))]; % E.g. [1984 2006]
    T=AnnualizeDivisor(2)-AnnualizeDivisor(1);
    
    % EV
    clear functions; % To clear the "persistent" command from lambdacrra80
    [lEV,yy,negutil]=lambdacrra80(CountryInput1,CountryInput0,Silent,ubar,beta,g,theta,epsilon,gamma,clowerbar,AnnualizeDivisor);
    
    % CV -- just reverse the two periods
    clear functions; % To clear the "persistent" command from lambdacrra80
    [lCV,yyCV,negutilCV]=lambdacrra80(CountryInput0,CountryInput1,Silent,ubar,beta,g,theta,epsilon,gamma,clowerbar,AnnualizeDivisor);
    loglamEV=log(lEV);
    loglamCV=-log(lCV);   % Recall we take 1/lambda for CV case to put in [0,1]
    loglam=.5*(loglamEV+loglamCV);
    results(1)=loglam/T*100;  % Note well: The CRRA case makes no correction for T_LE!!!
    results(2)=log(yy)/T*100; % GDP growth rate
    Results(i,:)=results';
end;


glambda=Results(:,1); 
gy=Results(:,2);
Results(:,3)=glambda-gy;
[blah,isort]=sort(-glambda);


diary('GrowthRobust.log');
disp ' '; disp ' ';
disp '------------------------------------------------------- ';
disp(tle);
disp '------------------------------------------------------- ';
disp ' ';


disp ' '; disp ' ';
disp 'MAIN RESULTS FOR WELFARE GROWTH RATES';
disp ' ';
run ../ShowParameters

fmt='%8.2f';
tle='glambda gy Diff';
cshow(CountryInputs(isort,1),Results(isort,:),fmt,tle,'latex');
cshow('Average       ',mean(Results),fmt,[],'latex',1);
tokeep=([CountryInputs{:,3}]<1998);
cshow('Average (excl)',mean(Results(tokeep,:)),fmt,[],'latex',1);
disp '   Note: "excl" above excludes if start year not before 1998 -- Russia and Brazil.';

c=corrcoef(glambda,gy); disp ' ';
fprintf('The correlation between glambda and gy is %4.3f\n',c(1,2));
fprintf('The median absolute deviation of glambda from gy is %8.4f\n',median(abs(glambda-gy)));
disp 'Note well: The CRRA routine makes no correction for T_LE, unlike lambdastats80.';
disp '           That is, it treats yr0 as having 1990 Life Expectancy.';

diary off;
