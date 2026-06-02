% PlotMicroResults  12/29/10 -- Plots of raw data
%   8/20/13 for pwt80
%  11/10/14 for beta=1, g=0 case

if exist('PlotMicroResults.log'); delete('PlotMicroResults.log'); end;
diary PlotMicroResults.log;
fprintf(['PlotMicroResults                 ' date]);
disp ' ';
disp ' ';
help PlotMicroResults

clear all;

OverWrite=1

disp 'Please be sure LambdaMaster has been run.';
disp 'This program will load the micro data from that run...';
%wait;

%CountryInputs lambda ytilde ubar theta beta g epsilon;
load LambdaStatsResults
names=CountryInputs(:,1);
namethese=ones(length(lambda)); % Show all names in graphs
y=ytilde/100;
lambda=lambda/100;

figure(1); figsetup;
plotlog(log(y),lambda,names,'1/128 1/64 1/32 1/16 1/8 1/4 1/2 1',10,[],.5,.2,namethese);
set(gca,'XTick',log([1/128 1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/128.1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
ax=axis; ax(1)=-5; ax(4)=log(1.3); axis(ax);
hold on;
gg=[log(1/128) log(1)];
plot(gg,gg,'b-','LineWidth',1);
chadfig('GDP per person (US=1)','Welfare, \lambda',1,0);
makefigwide;
print -dpsc PlotMicroResults.ps
%OverWrite=input('Press the number 1 to overwrite PlotMicroResults1.eps');
if OverWrite==1;
    print PlotMicroResults1.eps
end;

figure(2); figsetup;
plotnamesym2(log(y),lambda./y,names,10,[],.8,.15,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
ax=axis; ax(3)=.35; ax(4)=1.5; axis(ax);
set(gca,'YTick',(.5:.25:1.5));
hold on;
gg=[log(1/128) log(.95)];
plot(gg,[1 1],'b--','LineWidth',1.5);
%chadfig('GDP per person (US=1)','Lambda / GDP per person',1,0);
%chadfig('GDP per person (US=1)','Welfare \div GDP per person',1,0);
chadfig('GDP per person (US=1)','The ratio of Welfare to Income',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
%OverWrite=input('Press the number 2 to overwrite PlotMicroResults2.eps');
if OverWrite==2;
    print PlotMicroResults2.eps
end;


disp ' ';
disp 'Please be sure the beta=1, g=0 case from LambdaRobust has been run.';
disp 'This program will load the micro data from that run for raw data graphs.';
%wait;

clear all;

%CountryInputs lambda ytilde ubar theta beta g epsilon;
load LambdaStatsResultsBeta1Gis0
names=CountryInputs(:,1);
namethese=ones(length(lambda)); % Show all names in graphs
y=ytilde/100;
lambda=lambda/100;

% Now underlying data
cbar=KeyFacts(:,1);
lbar=KeyFacts(:,2);
stdlogc=KeyFacts(:,3);
stdell=KeyFacts(:,4);
lifeexp=KeyFacts(:,5);

figure(1); figsetup;
plotnamesym2(log(y),lifeexp,names,10,[],.4,3,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
ax=axis; ax(3)=48; axis(ax);
chadfig('GDP per person','Life expectancy',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsLife.eps

figure(2); figsetup;
plotnamesym2(log(y),stdlogc,names,10,[],.4,.08,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
set(gca,'YTick',(.4:.1:.9));
ax=axis; ax(3)=.38; axis(ax);
chadfig('GDP per person','Standard deviation of log consumption',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsStdC.eps


% % Weekly Hours
% weeklyhours=(1-lbar)*16*365/52;
% stdhours=stdell*16*365/52;

% figure(3); figsetup;
% plotnamesym2(log(y),weeklyhours,names,10,[],.4,2,namethese);  %,[],0.035,0.0);
% set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
% set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
% ax=axis; ax(3)=9.5; axis(ax);
% chadfig('GDP per person','Weekly hours worked per person',1,0);
% makefigwide;
% print -append -dpsc PlotMicroResults.ps
% print PlotMicroResultsHours.eps

% figure(4); figsetup;
% plotnamesym2(log(y),stdhours,names,10,[],.6,2,namethese);  %,[],0.035,0.0);
% set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
% set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
% ax=axis; ax(3)=13.5; axis(ax);
% chadfig('GDP per person','Standard deviation of weekly hours worked',1,0);
% makefigwide;
% print -append -dpsc PlotMicroResults.ps
% print PlotMicroResultsStdL.eps

% Annual Hours
annualhours=(1-lbar)*16*365;
stdhours=stdell*16*365;

figure(3); figsetup;
plotnamesym2(log(y),annualhours,names,10,[],.8,40,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
%ax=axis; ax(3)=9.5; axis(ax);
chadfig('GDP per person','Annual hours worked per person',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsHours.eps


figure(4); figsetup;
plotnamesym2(log(y),stdhours,names,10,[],.6,2,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
set(gca,'YTick',(700:100:1200));
ax=axis; ax(3)=675; axis(ax);
chadfig('GDP per person','Standard deviation of annual hours worked',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsStdL.eps


figure(5); figsetup;
plotlog(log(y),cbar,names,'1/64 1/32 1/16 1/8 1/4 1/2 1',10,[],.6,.2,namethese);
%plotnamesym2(log(y),cbar,names,10,[],.4,.08,namethese);  %,[],0.035,0.0);
set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
%ax=axis; ax(3)=.38; axis(ax);
chadfig('GDP per person','Consumption (US 2007 PWT=1)',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsCons.eps

% %%%%%%%%%%%%%%%%%%%
% GROWTH RATE RESULTS
% %%%%%%%%%%%%%%%%%%%

%wait('Now showing growth rate results...');

load GrowthStatsResults 
names=CountryInputs(:,1);
namethese=ones(length(glambda)); % Show all names in graphs

figure(1); figsetup;
plotnamesym2(gy,glambda,names,10,[],.2,.2,namethese);
hold on;
gg=[0 10];
plot(gg,gg,'b-','LineWidth',1);
%ax=axis; ax(1)=-.042; ax(2)=.09; axis(ax);
set(gca,'YTick',(0:2:10)');
set(gca,'XTick',(0:2:10)');
axispercent('y'); axispercent('x');
chadfig('Per capita GDP growth','Welfare growth',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsG1.eps

figure(2); figsetup;
plotnamesym2(gy,glambda-gy,names,10,[],.2,.1,namethese);
%ax=axis; ax(1)=-.042;  ax(2)=.09; axis(ax);
set(gca,'YTick',(-1:2)');
set(gca,'XTick',(0:2:10)');
axispercent('y'); axispercent('x');
chadfig('Per capita GDP growth','Difference between Welfare and Income growth',1,0);
makefigwide;
print -append -dpsc PlotMicroResults.ps
print PlotMicroResultsG2.eps
