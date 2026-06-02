% Rawls15Micro   
%
%  Does the "macro" calculation for the particular sample of micro
%  countries and for their specific years (e.g. 2002 instead of 2007).
%
%  VERSION 15: 8:26/14 -- Use SetParameters to get baseline.
%  VERSION 14: 8/20/13 -- PWT8.0, with EV as baseline.
%  See Rawls15.m for historical details.


if exist('Rawls15Micro.log'); delete('Rawls15Micro.log'); end;
diary Rawls15Micro.log;
fprintf(['Rawls15Micro                 ' date]);
disp ' ';
disp ' ';
help Rawls15Micro


clear all; clc

SetParameters
MakeDataMacroMicro15;

cd MicroData;
ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g);
cd ..;
ShowParameters;

epsilon=FrischLSElasticity;  % Frisch elasticity
ee=(1+epsilon)/epsilon;
ytilde=y(:,1)./y(:,2);


% Calculate flow utility and "lifetime" utility
vofell=-theta*(1-ell).^ee/ee;
flow=(ubar+log(c)+vofell-1/2*sigma.^2);
V=lifeexp.*flow;


% Show the basic data
data=[V(:,1) y(:,1) c(:,1) ell(:,1) gini(:,1) sigma(:,1) lifeexp(:,1)];
tle='V y c ell gini sigma lifeexp';

disp ' '; disp ' '; disp 'Basic Data, sorted by GDP'; disp ' ';
[blah,indx]=sort(-y(:,1));
fmt='%8.3f';
cshow(Names(indx,:),data(indx,:),fmt,tle);

% Decomposing V itself
disp ' '; disp 'The components of V';
data=[V(:,1) log(c(:,1)) vofell(:,1) -1/2*sigma(:,1).^2 flow(:,1) lifeexp(:,1)];
tle='V logc v(ell) -.5sig2 flow lifeexp';
cshow(Names(indx,:),data(indx,:),fmt,tle);

% Bring any negative "flows" of utility to our attention
% This means that shorter life expectancy raises welfare!
ineg=find(flow<0);  disp ' ';
fprintf('There are %3.0f countries with negative flow utility',length(ineg));
Names(ineg) 
disp ' ';


% Now do the decomposition -- geometric average of CV and EV
loglamEV=1./lifeexp(:,2).*(V(:,1)-V(:,2));
loglamCV=1./lifeexp(:,1).*(V(:,1)-V(:,2));
loglamGeo=1/2*(loglamEV+loglamCV);
lambdaGeo=exp(loglamGeo); lambdaCV=exp(loglamCV); lambdaEV=exp(loglamEV);
lambda=lambdaEV; % Baseline here is EV.
Ratio=lambda./ytilde;
ebar=lifeexp(:,1)./lifeexp(:,2);
ebar_i=lifeexp(:,2)./lifeexp(:,1);

termLE=(ebar-1).*V(:,1)./lifeexp(:,1);
%termLE_CV=(1-ebar_i).*V(USA)./lifeexp(USA);
%termLE=1/2*(termLE_US+termLE_i);
termC =log(c(:,1))-log(c(:,2));
termell=vofell(:,1)-vofell(:,2);
termIn=-1/2*(sigma(:,1).^2-sigma(:,2).^2);

% Check adding up
%iszeroUS=-loglamUS+termLE_US+termC+termell+termIn;
iszeroEV=-loglamEV+termLE+termC+termell+termIn;
keepit=~any(isnan(data'))';  % Countries we keep
save Rawls15MicroSample keepit



% Decomposition of the Ratio of Lambda/y
termCY = log(c(:,1)./y(:,1)) - log(c(:,2)./y(:,2));
iszero2=-log(Ratio)+termLE+termCY+termell+termIn;

% disp ' '; disp ' ';
% disp ' '; disp 'Decomposing the Ratio==Lambda/y, Ranked by Welfare';
% data=[lambda*100 ytilde*100 log(Ratio) termLE termCY termell termIn];
% fmt='%8.0f %8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.1f %8.3f %8.3f %8.3f %8.1f %8.0f';
% tle='lambda y logRat termLE termCY termell termInq';
% [blah,indx]=sort(-lambda);
% cshow(Names(indx,:),[data(indx,:)],fmt,tle);

data=[lambda*100 ytilde*100 log(Ratio) termLE termCY termell termIn];
tle='lambda y logRat termLE termCY termell termInq';
fmt='%8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.1f %8.3f %8.3f %8.3f %8.1f %8.0f %8.3f';


% Make sure no errors in the adding-up conditions
if any(abs(iszeroEV)>.00001); disp 'ERROR: Adding up problem with iszeroUS'; keyboard; end;
%if any(abs(iszero_i)>.00001); disp 'ERROR: Adding up problem with iszero_i'; keyboard; end;
if any(abs(iszero2)>.00001); disp 'Error in iszero2.  Stopping!'; keyboard; end;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display data for key countries for table in the paper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[blah,indx]=sort(-lambda);
disp ' '; disp ' ';
disp ' '; disp 'Decomposing the Ratio==Lambda/y for key countries';
cshow(Names(indx,:),data(indx,:),fmt,tle,'latex');
cshow('Average   ',mean(data),fmt,[],[],1);

disp ' '; disp ' ';
disp ' '; disp 'Decomposing the Ratio==Lambda/y -- unsorted';
cshow(Names,data,fmt,tle,'latex');

% % In levels instead of logs (e.g. for Class)
% data=[ytilde*100  lambda*100 exp([termLE termCY termell termIn])];
% tle2='y lambda termLE termCY termell termInq';
% cshow(Names(indx,:),data(indx,:),fmt,tle2,'latex');



% Then the raw data
data=[lifeexp(:,1) cyraw(:,1) ell(:,1) sigma(:,1)];
tle='lifeexp c/y ell sigma';

disp ' '; disp ' '; disp 'Raw underlying data for key countries'; disp ' ';
fmt='..&..&..&..&..\\my{%4.1f}.. &..\\my{%5.3f}.. &..\\my{%5.3f}.. &..\\my{%5.3f}..\\\\';
cshow(Names(indx,:),data(indx,:),fmt,tle);

fmt='%8.1f %8.3f %8.3f %8.3f';
cshow(Names(indx,:),data(indx,:),fmt,tle);


disp 'Check correlations with LambdaStatsResults';
lambdaMacro=lambda;
load MicroData/LambdaStatsResults;
lambdaMicro=lambda/100;
clear lambda

c=corrcoef(log([lambdaMacro lambdaMicro]));
fprintf('The correlation between log lambdaMicro and log lambdaMacro is %6.4f\n',c(1,2));
fprintf('The mean absolute deviation between log lambdaMicro and log lambdaMacro is %6.4f\n',mean(abs(log(lambdaMacro./lambdaMicro))));
diary off;

