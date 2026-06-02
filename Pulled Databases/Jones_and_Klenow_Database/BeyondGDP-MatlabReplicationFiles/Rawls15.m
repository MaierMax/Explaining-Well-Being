% Rawls15.m
%
%  VERSION 15: 8/25/14 -- Call from master file that sets parameters and countries.
%  VERSION 14: 8/20/13 -- PWT8.0, with EV as baseline.
%
%  VERSION 13: 1/29/13 -- Use PWT 7.1  Assumes no discounting and g=0
%              for the macro calculation (as we've been doing).
%
%  VERSION 12: 3/1/12 -- Use PWT 7.0 and 2007.  Data grades and ginis
%                        as last 3 years since 1997.
%
%  VERSION 11: 12/29/10 update:  Improved Gini's (disp income) and 
%              hours data from The Conference Board (50 countries).
%              Note: The updates are integrated into MakeData9.m, so
%              really all we need to do is re-run Rawls10*.m.  That is,
%              this Rawls11 is really just Rawls10.  New name to help keep
%              results straight.
%
%  VERSION 10: Report geometric average of compensating variation and equivalent
%    variation ==> weight life expectancy term by the average of own and US flow.
%
%  VERSION 9: AdultPopulation and 40% marginal tax rate ==> lowers theta.
%              -- Use WBAdultPopulation in constructing epop ==> Aged >=15
%              -- U.S. marginal tax rate from Barro (38.X%)
%
%  VERSION 8:  Constant Frisch elasticity of *hours* instead of 
%                     leisure.  v(ell)=-theta*(1-ell)^ee/ee
%                     where ee:= (1+epsilon)/epsilon and epsilon=Frisch
%
%  VERSION 7: Use AnnualHours data from OECD and ILO (see AnnualHours2.m)
%
%  VERSION 6: Leisure: v(ell)=theta*(ell^(1-rho)-1)/(1-rho)
%    Our prior log case was rho=1, but this implies a Frisch Ls elasticity of 4.
%    Here, we pick rho to match Hall's Ls elasticity of 0.7.
%
%  VERSION 5: Use PWT 6.3 and rgdpl2
%    Uses geometric averages to smooth gdp, consumption, and leisure per capita.
%
%  VERSION 4: None, skipped so that Growth*.m and Rawls*.m will match up
%
%  VERSION 3: Use consumption gini's from WIID2cRatioXC.m
%
%  VERSION 2: Calibrate theta more carefully to the PWT6.2 data
%       ell =  1 - 1/3*epop
%  One possibility is we say a worker spends 1/3 of their waking time
%  working (40 hours worked a week, work 50 weeks a year, ~7.5 hours a day
%  for sleep => work 2000 hours out an annual waking time endowment of 6000
%  hours). Then L = 1 - (1/3)*(workers/population). And we use theta=5 to
%  fit the U.S. L = 1-(1/3)*(1/2) = 5/6. 
%
%  VERSION 1 of the Rawls calculation. See Baseline031609.pdf for the
%  theory stuff.  The data are from
%
%   1.  PWT 6.2 for consumption and leisure
%   2.  LifeExpectancyWB (.xls, .m) for life expectancy -- world bank.
%   3.  WIID2c (.xls) for inequality
%
%  The main output of the program is lambda, which answers the question: "To
%  what fraction, lambda, is someone willing to reduce her consumption in
%  the U.S. in order to avoid living in some other country i?".
%
%    Random person in U.S., with consumption reduced by lambda, versus
%    Random person in country i.
%
%    u(c,l) = log(c) + theta*log(l), where theta=2
%

help Rawls15

ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g);
epsilon=FrischLSElasticity;  % Frisch elasticity
ee=(1+epsilon)/epsilon;
yr0=1949;
yrT=2007;
ShowParameters;

% Calculate flow utility and "lifetime" utility
vofell=-theta*(1-ell).^ee/ee;
flow=(ubar+log(c)+vofell-1/2*sigma.^2);
V=lifeexp.*flow;


% Show the basic data
data=[V y c ell gini sigma lifeexp];
tle='V y c ell gini sigma lifeexp';

disp ' '; disp ' '; disp 'Basic Data, sorted by GDP'; disp ' ';
fprintf('Year: %4.0f\n',[yrT]);
[blah,indx]=sort(-y);
fmt='%8.3f';
cshow(namesShort(indx,:),data(indx,:),fmt,tle);

% Decomposing V itself
disp ' '; disp 'The components of V';
data=[V log(c) vofell -1/2*sigma.^2 flow lifeexp];
tle='V logc v(ell) -.5sig2 flow lifeexp';
cshow(namesShort(indx,:),data(indx,:),fmt,tle);

% Bring any negative "flows" of utility to our attention
% This means that shorter life expectancy raises welfare!
ineg=find(flow<0);  disp ' ';
fprintf('There are %3.0f countries with negative flow utility',length(ineg));
names(ineg) 
disp ' ';


% Now do the decomposition -- geometric average of CV and EV
loglamEV=1/lifeexp(USA)*(V-V(USA));
loglamCV=1./lifeexp.*(V-V(USA));
loglamGeo=1/2*(loglamEV+loglamCV);
lambdaGeo=exp(loglamGeo); lambdaCV=exp(loglamCV); lambdaEV=exp(loglamEV);
lambda=lambdaEV; % Baseline here is EV.
Ratio=lambda./y;
ebar=lifeexp./lifeexp(USA);
ebar_i=lifeexp(USA)./lifeexp;

termLE=(ebar-1).*V./lifeexp;
%termLE_CV=(1-ebar_i).*V(USA)./lifeexp(USA);
%termLE=1/2*(termLE_US+termLE_i);
termC =log(c)-log(c(USA));
termell=vofell-vofell(USA);
termIn=-1/2*(sigma.^2-sigma(USA)^2);

% Check adding up
%iszeroUS=-loglamUS+termLE_US+termC+termell+termIn;
iszeroEV=-loglamEV+termLE+termC+termell+termIn;
keepit=~any(isnan(data'))';  % Countries we keep
save Rawls15Sample keepit

% Basic CV and EV results
data=[lambdaGeo lambdaCV lambdaEV y]*100;
tle='lambda lambdaCV lambdaEV y';
disp ' '; disp ' ';
disp ' '; disp 'CV and EV results...';
[blah,indx]=sort(-lambdaEV);
fmt='%8.1f';
cshow(namesShort(indx,:),data(indx,:),fmt,tle);
% Mean absolute deviation for Ratio
disp ' ';
fprintf('Avg: The mean absolute deviation for logRatio is %8.4f\n',meannan(abs(log(lambdaGeo./y))));
fprintf('EV:  The mean absolute deviation for logRatio is %8.4f\n',meannan(abs(log(lambdaEV./y))));
fprintf('CV:  The mean absolute deviation for logRatio is %8.4f\n',meannan(abs(log(lambdaCV./y))));
fprintf('Avg: The mean absolute deviation from 1 for Ratio is %8.4f\n',meannan(abs(lambdaGeo./y-1)));
fprintf('EV:  The mean absolute deviation from 1 for Ratio is %8.4f\n',meannan(abs(lambdaEV./y-1)));
fprintf('CV:  The mean absolute deviation from 1 for Ratio is %8.4f\n',meannan(abs(lambdaCV./y-1)));

% Median absolute deviation for Ratio
disp ' ';  lambdas=[lambdaEV lambdaCV];
fprintf('Avg: The median absolute deviation for logRatio is %8.4f\n',median(abs(log(lambdaGeo(keepit)./y(keepit)))));
fprintf('EV:  The median absolute deviation for logRatio is %8.4f\n',median(abs(log(lambdas(keepit,1)./y(keepit)))));
fprintf('CV:  The median absolute deviation for logRatio is %8.4f\n',median(abs(log(lambdas(keepit,2)./y(keepit)))));
fprintf('Avg: The median absolute deviation from 1 for Ratio is %8.4f\n',median(abs(lambdaGeo(keepit)./y(keepit)-1)));
fprintf('EV:  The median absolute deviation from 1 for Ratio is %8.4f\n',median(abs(lambdas(keepit,1)./y(keepit)-1)));
fprintf('CV:  The median absolute deviation from 1 for Ratio is %8.4f\n',median(abs(lambdas(keepit,2)./y(keepit)-1)));


% % Main decomposition of Lambda
% data=[lambda*100 y*100 Ratio c loglamEV termLE termC termell termIn];
% tle='lambda y Ratio c loglam termLE termC termell termIneq';
% disp ' '; disp ' ';
% disp ' '; disp 'Decomposing Lambda, Ranked by Welfare';
 ctyorder=(1:length(lambda))';

% [blah,indx]=sort(-lambda);
% fmt='%8.1f %8.1f %8.2f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f';
% cshow(namesShort(indx,:),[data(indx,:)],fmt,tle);

% Decomposition of the Ratio of Lambda/y
termCY = log(c./y) - log(c(USA)/y(USA));
iszero2=-log(Ratio)+termLE+termCY+termell+termIn;

%epop=geomaverage(epop,KeyPeriod-1949)';  % For reporting
epop=epop(KeyPeriod-1949,:)';  % For reporting


% data=[lambda*100 y*100 log(Ratio) termLE termCY termell termIn lifeexp cyraw ell sigma gini annualhours epop];
% tle='lambda y logRat termLE termCY termell termInq lifeexp C/Y ell sigma gini AnnHour epop';
% disp ' '; disp ' ';
% disp ' '; disp 'Decomposing the Ratio==Lambda/y, Ranked by Ratio';
% [blah,indx]=sort(-Ratio);
% fmt='%8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.1f %8.3f %8.3f %8.3f %8.1f %8.0f %8.3f';
% cshow(namesShort(indx,:),data(indx,:),fmt,tle);

% Same thing, but sorting by lambda
disp ' '; disp ' ';
disp ' '; disp 'Decomposing the Ratio==Lambda/y, Ranked by Welfare';
data=[lambda*100 y*100 log(Ratio) termLE termCY termell termIn lifeexp cyraw ell sigma gini annualhours epop hours];
fmt='%8.0f %8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.1f %8.3f %8.3f %8.3f %8.1f %8.0f %8.3f %8.0f';
tle='pwt lambda y logRat termLE termCY termell termInq lifeexp C/Y ell sigma gini AnnHour epop hours';
[blah,indx]=sort(-lambda);
cshow(namesShort(indx,:),[ctyorder(indx) data(indx,:)],fmt,tle);

disp '------------------------------------------------------------------------';
cshow('Avg (unweight) ',mean(data(keepit,:)),fmt);
cshow('Avg (pop wght) ',weightedaverage(data,pop(2007-1949,:)',keepit),fmt);


data=[lambda*100 y*100 log(Ratio) termLE termCY termell termIn];
tle='lambda y logRat termLE termCY termell termInq';
fmt='%8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.1f %8.3f %8.3f %8.3f %8.1f %8.0f %8.3f';


% Summary statistics:  Medians for richest and poorest third of countries (lambda)
dd=packr(data); % Drop any rows with missing data
[blah,indx]=sort(-dd(:,1));
sorted=dd(indx,:);
NN=size(dd,1); NNN=round(NN/3);
topthird=median(sorted(1:NNN,:));
botthird=median(sorted((NN-NNN+1):NN,:));
disp ' ';
disp 'Medians of top/bottom third, according to lambda';
cshow('Median Top 1/3:',topthird,fmt);
cshow('Median Bot 1/3:',botthird,fmt);

% Mean absolute deviation for Ratio
disp ' ';
fprintf('The mean absolute deviation for logRatio is %8.4f\n',meannan(abs(log(Ratio))));
fprintf('The mean absolute deviation from 1 for Ratio is %8.4f\n',meannan(abs(Ratio-1)));

disp ' ';
corrylam=corr(packr([log(y) log(lambda)]));
fprintf('The correlation between log(lambda) and log(y) is %8.4f\n',corrylam(1,2));
corrylam=corr(packr([y lambda]));
fprintf('The correlation between lambda and y is %8.4f\n',corrylam(1,2));

fprintf('The stdev(log lambda) is %8.4f\n',std(log(packr(lambda))));
fprintf('The stdev(log y) is %8.4f\n',std(log(packr(y))));



% Make sure no errors in the adding-up conditions
if any(abs(iszeroEV)>.00001); disp 'ERROR: Adding up problem with iszeroUS'; keyboard; end;
%if any(abs(iszero_i)>.00001); disp 'ERROR: Adding up problem with iszero_i'; keyboard; end;
if any(abs(iszero2)>.00001); disp 'Error in iszero2.  Stopping!'; keyboard; end;

% Summary statistics:  
disp ' ';
dd=packr(data); % Drop any rows with missing data
disp ' ';
cshow('Avg (unweight) ',mean(data(keepit,:)),fmt);           
cshow('Avg (pop wght) ',weightedaverage(data,pop(2007-1949,:)',keepit),fmt);
cshow('Mean Abs Dev:  ',meannan(abs(dd)),fmt);               
cshow('Median Abs Dev:',median(packr(abs(dd))),fmt);         
cshow('Standard Dev:  ',std(dd),fmt);                          

% Regional averages
disp ' ';
disp 'Regional Averages';
for i=1:size(regnames,1);
  indx=find(region80==i);
  cshow(regnames(i,:),meannan(packr(data(indx,:))),fmt);
end;
disp ' ';
cshow('Western Europe  ',meannan(packr(data(westerneurope,:))),fmt);
cshow('Eastern Europe  ',meannan(packr(data(easterneurope,:))),fmt); % two countries
cshow('Latin America   ',meannan(packr(data(laamer,:))),fmt);
cshow('Coastal Asia    ',meannan(packr(data(asiacoast,:))),fmt);


% Regional averages -- Population Weighted
keepit=~any(isnan(data'))';  % Countries we keep
disp ' ';
disp 'Regional Averages -- Population Weighted';
for i=1:size(regnames,1);
  cshow(regnames(i,:),weightedaverage(data,pop(2007-1949,:)',region80==i & keepit ),fmt);
end;
disp ' ';

cshow('Western Europe  ',weightedaverage(data,pop(2007-1949,:)',westerneurope & keepit),fmt);
cshow('Eastern Europe  ',weightedaverage(data,pop(2007-1949,:)',easterneurope & keepit),fmt);
cshow('Coastal Asia    ',weightedaverage(data,pop(2007-1949,:)',asiacoast & keepit),fmt);
cshow('Latin America   ',weightedaverage(data,pop(2007-1949,:)',laamer & keepit),fmt);

disp ' ';
fprintf('Number of countries: %4.0f\n',sum(~isnan(lambda)));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display data for key countries for table in the paper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Same thing, but sorting by lambda
[blah,indx]=sort(-lambda(ctys));
disp ' '; disp ' ';
disp ' '; disp 'Decomposing the Ratio==Lambda/y for key countries';
cshow(namesShort(ctys(indx),:),data(ctys(indx),:),fmt,tle,'latex');

% In levels instead of logs (e.g. for Class)
data=[y*100  lambda*100 exp([termLE termCY termell termIn])];
tle2='y lambda termLE termCY termell termInq';
cshow(namesShort(ctys(indx),:),data(ctys(indx),:),fmt,tle2,'latex');

% Then the raw data
data=[lifeexp cyraw hours sigma];
tle='lifeexp c/y hours sigma';

disp ' '; disp ' '; disp 'Raw underlying data for key countries'; disp ' ';
fprintf('Year: %4.0f\n',[yrT]);
fmt='..&..&..&..&..\\my{%4.1f}.. &..\\my{%5.3f}.. &..\\my{%4.0f}.. &..\\my{%5.3f}..\\\\';
cshow(namesShort(ctys(indx),:),data(ctys(indx),:),fmt,tle);

fmt='%8.1f %8.3f %8.0f %8.3f';
cshow(namesShort(ctys(indx),:),data(ctys(indx),:),fmt,tle);
