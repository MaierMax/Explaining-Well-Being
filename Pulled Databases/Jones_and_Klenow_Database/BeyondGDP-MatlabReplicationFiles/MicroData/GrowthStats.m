% GrowthStats
%
%   9/10/13 -- Master file for micro data welfare growth results.

help GrowthStats

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Last two digits 0=single micro file, 1 if separate leisure/consumption
CountryInputs={
'Brazil'      'BRA'   2003 2008  1 1
%'Spain'       'ESP'   2001  1
%'China'       'CHN'   2002  0
'France'      'FRA'   1984 2005  0 0
'UK'          'GBR'   1985 2005  0 0
'Indonesia'   'IDN'   1993 2006  0 0
'India'       'IND'   1983 2005  1 0
'Italy'       'ITA'   1987 2006  0 0
'Mexico'      'MEX'   1984 2006  0 0
%'Malawi'      'MWI'   2004  0
'Russia'      'RUS'   1998 2007  0 0
'US'          'USA'   1984 2006  0 0
%'SouthAfrica' 'ZAF'   1993  0 
}

if exist('HHSizeEquivScale')~=1; HHSizeEquivScale=0; end;
ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,[],HHSizeEquivScale);
epsilon=FrischLSElasticity;  % Frisch elasticity
if exist('StartAge')~=1; StartAge=1; end;

run ../ShowParameters
if exist('KidsGetAdultLeisure')~=1; KidsGetAdultLeisure=0; end;


for i=1:size(CountryInputs,1);

    CountryInput1=CountryInputs(i,[1 2 4 6]);
    CountryInput0=CountryInputs(i,[1 2 3 5]);  % Reference / Initial year
    AnnualizeDivisor=[cell2mat(CountryInputs(i,3)) cell2mat(CountryInputs(i,4))]; % E.g. [1984 2006]

    % EV
    [loglamEV,logy,termLE,termCY,terml,termCineq,termlineq,resultsEV,keyfacts]=...
        lambdastats80(CountryInput1,CountryInput0,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale,KidsGetAdultLeisure,AnnualizeDivisor);
    KeyFacts(i,:,1)=keyfacts(:,2); % i, LastYear, FirstYear
    KeyFacts(i,:,2)=keyfacts(:,1); % Switch order, so lifeexp0 then lifeexpT
    
    % CV -- just reverse the two periods
    [loglamCV,logy,termLE,termCY,terml,termCineq,termlineq,resultsCV,keyfacts]=...
        lambdastats80(CountryInput0,CountryInput1,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale,KidsGetAdultLeisure,AnnualizeDivisor);
    loglamCV=-loglamCV;   % Recall we take 1/lambda for CV case to put in [0,1]
    resultsCV=-resultsCV; % ditto
    loglam=.5*(loglamEV+loglamCV)*100;
    results=.5*(resultsEV+resultsCV);
    results(1)=loglam;
    Results(i,:)=results;
end;


% Now underlying data
cbar=squeeze(KeyFacts(:,1,:));
lbar=squeeze(KeyFacts(:,2,:));
stdlogc=squeeze(KeyFacts(:,3,:));
stdell=squeeze(KeyFacts(:,4,:));
lifeexp=squeeze(KeyFacts(:,5,:));
cyraw=squeeze(KeyFacts(:,6,:));
annualhours=(1-lbar)*16*365;
stdhours=stdell*16*365;

glambda=Results(:,1); 
gy=Results(:,2);
[blah,isort]=sort(-glambda);


if exist('tle')==1;
    diary('GrowthRobust.log');
    disp ' '; disp ' ';
    disp '------------------------------------------------------- ';
    disp(tle);
    disp '------------------------------------------------------- ';
    disp ' ';
end;

run ../ShowParameters

% disp ' '; disp ' ';
% disp 'UNDERLYING MICRO DATA FOR LEVELS OF WELFARE';
% disp ' ';
% tle='cbar0 cbarT lbar0 lbarT stdlogc0 stdlogcT stdell0 stdellT lifeexp0 lifeexpT cyraw0 cyrawT';
% cshow(CountryInputs(isort,1),KeyFacts(isort,:),'%8.3f',tle);

disp ' '; disp ' ';
disp 'UNDERLYING MICRO DATA FOR LEVELS OF WELFARE -- Better units';
disp ' ';
fmt='%8.1f %8.1f %8.3f %8.3f %8.0f %8.0f %8.3f %8.3f %8.0f %8.0f';
tle='lifeexp0 lifeexpT cy0 cyT hours0 hoursT stdlogc0 stdlogcT stdhours0 stdhoursT';
blah=[lifeexp cyraw annualhours stdlogc stdhours];
cshow(CountryInputs(isort,1),blah(isort,:),fmt,tle);

fmt='..&..&..&..&..\\my{%4.1f, %4.1f}.. &..\\my{%5.3f, %5.3f}.. &..\\my{%3.0f, %3.0f}.. &..\\my{%5.3f, %5.3f}.. &..\\my{%3.0f, %3.0f}..\\\\';
cshow(CountryInputs(isort,1),blah(isort,:),fmt,tle);


disp ' '; disp ' ';
disp 'MAIN RESULTS FOR WELFARE GROWTH RATES';
disp ' ';

fmt='%8.2f';
tle='glambda gy Diff termLE termCY termell Cineq lineq';
cshow(CountryInputs(isort,1),Results(isort,:),fmt,tle,'latex');
cshow('Average       ',mean(Results),fmt,[],'latex',1);
tokeep=([CountryInputs{:,3}]<1998);
cshow('Average (excl)',mean(Results(tokeep,:)),fmt,[],'latex',1);
disp '   Note: "excl" above excludes if start year not before 1998 -- Russia and Brazil.';

c=corrcoef(glambda,gy); disp ' ';
fprintf('The correlation between glambda and gy is %4.3f\n',c(1,2));
fprintf('The median absolute deviation of glambda from gy is %8.4f\n',median(abs(glambda-gy)));

diary off;
