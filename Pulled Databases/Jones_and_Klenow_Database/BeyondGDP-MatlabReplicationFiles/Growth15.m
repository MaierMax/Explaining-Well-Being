% Growth15    
%
%  ------------------------------------------------------------------------
%  GROWTH -- This is the growth rate version of Rawls14.m: By what fraction
%  would you have to reduce an individual's consumption today in order to
%  make her indifferent between life today in some country and life in 1980
%  in that country?  Express as an annual change in log (growth rate).
%  ------------------------------------------------------------------------
%
%  VERSION 15: 8/26/14 -- Hours
%  VERSION 14: 8/13/14 -- pwt80
%  VERSION 13: 1/31/13 -- pwt71 and 1980-2007
%
%  VERSION 11: 12/29/10 update:  Improved Gini's (disp income) and 
%              hours data from The Conference Board (50 countries).
%              Note: The updates are integrated into MakeDataGrowth9.m, so
%              really all we need to do is re-run Growth9*.m.  That is,
%              this Growth15 is really just Growth9.  New name to help keep
%              results straight.
%                -- Also, Gini1980 = Gini2000 if missing 1980.  More countries.
%
%  VERSION 10:  None -- skipped number to keep consistent with Rawls11.m
%
%  VERSION 9: AdultPopulation and 40% marginal tax rate ==> lowers theta.
%              -- Use WBAdultPopulation in constructing epop ==> Aged >=15
%              -- U.S. marginal tax rate from Barro (38.X%)
%
%  VERSION 8:  Constant Frisch elasticity of *hours* instead of 
%                     leisure.  v(ell)=-theta*(1-ell)^ee/ee
%                     where ee:= (1+epsilon)/epsilon and epsilon=Frisch
%
%  VERSION 6: Leisure: v(ell)=theta*(ell^(1-rho)-1)/(1-rho)
%    Our prior log case was rho=1, but this implies a Frisch Ls elasticity of 4.
%    Here, we pick rho to match Hall's Ls elasticity of 0.7.
%
%  VERSION 5: PWT 6.3, updated WB life expectancy data. 
%    Uses geometric averages to smooth gdp, consumption, and leisure per capita.
%
%  VERSION 4: In previous versions, life expectancy is weighted by the flow
%  of utility in 1980. For China this leads to a very low weight. Ideally,
%  one would compute annual growth rates this way and then average ---
%  chaining. We do not have the annual data to make this work. Instead, what
%  we do in Version 4 is to compute the growth rate using the 1980 flow and
%  then using the 2000 flow and average. Something like the Tornqvist version of
%  chaining.
%
%  VERSION 3: Use better consumption ginis, from WIID2cGrowth.m
%   Time series version of ginis. Require either two incomes or two
%   consumption ginis; do not mix.
%     -- 1980 =  1974 - 1986 data
%        2000 =  1994 - 2004 data
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
%    u(c,l) = log(c) + theta*log(l)



% Parameters
SetParameters;
ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g);
epsilon=FrischLSElasticity;  % Frisch elasticity
ee=(1+epsilon)/epsilon;
ShowParameters;

% Calculate flow utility and "lifetime" utility
vofell=-theta*(1-ell).^ee/ee;
flow=(ubar+log(c)+vofell-1/2*sigma.^2);
V=lifeexp.*flow;



% Show the basic data
data=[V flow y c ell gini sigma lifeexp];
tle='V1 V2 flow1 flow2 y1 y2 c1 c2 ell1 ell2 gini1 gini2 sigma1 sigma2 lifeexp1 lifeexp2';

disp ' '; disp ' '; disp 'Basic Data, sorted by RGDPL2 2007'; disp ' ';
fprintf('Years: %4.0f - %4.0f\n',[yr1 yr2]);
[blah,indx]=sort(-y(:,2));
fmt='%8.3f';
cshow(namesSTR(indx,:),data(indx,:),fmt,tle);

% Now do the decomposition
% Average with both years as base year
loglam2007=1./lifeexp(:,2).*(V(:,2)-V(:,1));
loglam1980=-1./lifeexp(:,1).*(V(:,1)-V(:,2));
loglam=1/2*(loglam2007+loglam1980);
T=(yr2-yr1);
glam=1/T*loglam;
gy=1/T*log(y(:,2)./y(:,1));
Diff=glam-gy;   % Difference between the two measures of growth
ebar=lifeexp(:,1)./lifeexp(:,2);
ebar80=lifeexp(:,2)./lifeexp(:,1);

termLE2007=(1-ebar).*V(:,1)./lifeexp(:,1);
termLE1980=(ebar80-1).*V(:,2)./lifeexp(:,2);
termLE=1/2*(termLE2007+termLE1980);
termC =log(c(:,2))-log(c(:,1));
termell=vofell(:,2)-vofell(:,1);
termIn=-1/2*(sigma(:,2).^2-sigma(:,1).^2);

% Convert to growth rates.  
termLE=1/T*termLE; termC=1/T*termC; termell=1/T*termell; termIn=1/T*termIn;
iszero=-glam+termLE+termC+termell+termIn;

% Main decomposition of Lambda
KeyPeriods=[1980; 2007];   % The intervals over which we average
epop=epop(KeyPeriods-1949,:)';  % For reporting

termCY = termC-gy;

data=[[glam gy Diff termLE termCY termell termIn]*100 lifeexp cyraw ell sigma gini annualhoursgrowth epop hours];
tle='glam gy Diff termLE termCY termell termIneq lifeexp1 lifeexp2 cy1 cy2 ell1 ell2 sigma1 sigma2 gini1 gini2 h/w1 h/w2 epop1 epop2 hours1 hours2';
disp ' '; disp ' ';
disp ' '; disp 'Growth rates (percent), sorted by glam';
[blah,indx]=sort(-glam);
fmt='%7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.1f %7.1f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.1f %7.1f %7.0f %7.0f %7.3f %7.3f %7.0f %7.0f';
cshow(namesSTR(indx,:),data(indx,:),fmt,tle);



% Decomposition of the Diff term
iszero2=-Diff+termLE+termCY+termell+termIn;

data=[glam gy Diff termLE termCY termell termIn]*100;
tle='glam gy Diff termLE termCY termell termIneq';
disp ' '; disp ' ';
disp ' '; disp 'Decomposing the difference betw glam and gy, sorted by Diff';
[blah,indx]=sort(-Diff);
fmt='%8.2f';
cshow(namesSTR(indx,:),data(indx,:),fmt,tle);


disp ' '; disp ' ';
disp ' '; disp 'Decomposing the difference betw glam and gy, sorted by glam';
[blah,indx]=sort(-glam);
cshow(namesSTR(indx,:),data(indx,:),fmt,tle);



disp '------------------------------------------------------------------------';
keepit=~any(isnan(data'))';  % Countries we keep
cshow('Avg (unweight) ',mean(data(keepit,:)),fmt);
cshow('Avg (pop wght) ',weightedaverage(data,pop(2007-1949,:)',keepit),fmt);

% US rank for gy and glam
dd=data(indx,:);
rlam=find(dd(:,1)==glam(USA)*100);
disp ' ';
fprintf('US Rank for welfare growth: %3.0f\n',rlam);
[blah,indx]=sort(-gy);
dd=data(indx,:);
rgy=find(dd(:,2)==gy(USA)*100);
fprintf('US Rank for income  growth: %3.0f\n',rgy);
disp ' ';


% Summary statistics:  Medians for richest and poorest third of countries (lambda)
dd=packr(data); % Drop any rows with missing data
[blah,indx]=sort(-dd(:,1));
sorted=dd(indx,:);
NN=size(dd,1); NNN=round(NN/3);
topthird=median(sorted(1:NNN,:));
botthird=median(sorted((NN-NNN+1):NN,:));
disp ' ';
disp 'Medians of top/bottom third, according to glam';
cshow('Median Top 1/3:',topthird,fmt);
cshow('Median Bot 1/3:',botthird,fmt);

% Mean absolute deviations
disp ' ';
cshow('Mean Abs Dev:  ',meannan(abs(dd)),fmt);
cshow('Median Abs Dev:',median(packr(abs(dd))),fmt);
cshow('Standard Dev:  ',std(dd),fmt); disp ' ';

% Regional averages
disp 'Regional Averages';
for i=1:size(regnames,1);
  indx=find(region80==i);
  cshow(regnames(i,:),meannan(packr(data(indx,:))),fmt);
end;
disp ' ';
cshow('Western Europe  ',meannan(packr(data(westerneurope,:))),fmt);
%cshow('Eastern Europe  ',meannan(packr(data(easterneurope,:))),fmt); % two countries
cshow('Coastal Asia    ',meannan(packr(data(asiacoast,:))),fmt);
cshow('Latin America   ',meannan(packr(data(laamer,:))),fmt);


% Regional averages -- Population Weighted
disp ' ';
disp 'Regional Averages -- Population Weighted';
for i=1:size(regnames,1);
  cshow(regnames(i,:),weightedaverage(data,pop(2007-1949,:)',region80==i & keepit ),fmt);
end;
disp ' ';

cshow('Western Europe  ',weightedaverage(data,pop(2007-1949,:)',westerneurope & keepit),fmt);
%cshow('Eastern Europe  ',weightedaverage(data,pop(2007-1949,:)',easterneurope & keepit),fmt);
cshow('Coastal Asia    ',weightedaverage(data,pop(2007-1949,:)',asiacoast & keepit),fmt);
cshow('Latin America   ',weightedaverage(data,pop(2007-1949,:)',laamer & keepit),fmt);



disp ' ';
corrylam=corr(packr([gy glam]));
fprintf('The correlation between g(lambda) and g(y) is %8.4f\n',corrylam(1,2));


disp ' ';
fprintf('Number of countries: %4.0f\n',sum(~isnan(glam)));

% Make sure no errors in the adding-up conditions
if any(abs(iszero)>.00001); disp 'Error in iszero.  Stopping!'; keyboard; end;
if any(abs(iszero2)>.00001); disp 'Error in iszero2.  Stopping!'; keyboard; end;


% Graphs
namethese=zeros(length(gy),1);
namethese(ctys)=1;

figure(1); figsetup;
plotnamesym2(gy,glam,namesSTR,10,[],.02,.01,namethese);
hold on;
gg=[-.035 .08];
plot(gg,gg,'b-','LineWidth',1);
%ax=axis; ax(1)=-.042; ax(2)=.09; axis(ax);
axispercent('y',100); axispercent('x',100);
chadfig('Per capita GDP growth','Welfare growth',1,0);
makefigwide;
print Growth15.eps

figure(2); figsetup;
plotnamesym2(gy,Diff,namesSTR,10,[],.02,.008,namethese);
%ax=axis; ax(1)=-.042;  ax(2)=.09; axis(ax);
axispercent('y',100); axispercent('x',100);
chadfig('Per capita GDP growth','Difference between Welfare and Income growth',1,0);
makefigwide;
print Growth15B.eps


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show data for table in paper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Decomposition of the Diff term
termCY = termC-gy;
iszero2=-Diff+termLE+termCY+termell+termIn;

data=[glam gy Diff termLE termCY termell termIn]*100;
tle='glam gy Diff termLE termCY termell termIneq';
[blah,indx]=sort(-glam(ctys));
disp ' '; disp ' ';
disp ' '; disp 'Decomposing the difference betw glam and gy for key countries';
cshow(namesSTR(ctys(indx),:),data(ctys(indx),:),fmt,tle,'latex');

% Show the basic data
data=[lifeexp cyraw hours sigma];
tle='lifeexp1 lifeexp2 cy1 cy2 hours1 hours2 sigma1 sigma2';

disp ' '; disp ' '; disp 'Basic Data for key countries'; disp ' ';
fprintf('Years: %4.0f - %4.0f\n',[yr1 yr2]);

fmt='..&..&..&..&..\\my{%4.1f, %4.1f}.. &..\\my{%5.3f, %5.3f}.. &..\\my{%4.0f, %4.0f}.. &..\\my{%5.3f, %5.3f}..\\\\';
cshow(namesSTR(ctys(indx),:),data(ctys(indx),:),fmt,tle);
disp ' ';

fmt='%8.1f %8.1f %8.3f %8.3f %8.0f %8.0f %8.3f %8.3f';
cshow(namesSTR(ctys(indx),:),data(ctys(indx),:),fmt,tle);


%figure(3); figsetup;
%plotnamesym2(V(:,1),glam,namesSTR,10,[],1,.01,namethese);
%chadfig('Welfare level','Welfare growth',1,0);


diary off;
