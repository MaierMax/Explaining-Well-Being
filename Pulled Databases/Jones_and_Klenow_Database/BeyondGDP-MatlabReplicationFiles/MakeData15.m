% MakeData15  8/25/14
%
% Basic program to set up the data for the Rawls project
%
%  VERSION 15: Version 4.0 of the paper
%  VERSION 14: PWT 80
%  VERSION 13: PWT 71
%  VERSION 12: PWT 70
%  VERSION 9:  Use Adult Population age >=15 in constructing epop


help MakeData15

disp 'Note: not running "clear all" within MakeData15...';

load pwt80;

load regions80             % region = 1-7 region code from pwt70 directory
load WIIDGiniLevels80      % GiniConsumption Nx1 WIID3a for cross-section
load LifeExpectancyWB80    % lifeWB (in TxN PWT format, just decades)
namesShort=namesSTR(:,1:15); % Shorten names for display
load AnnualHoursPWT80      % Use PWT for hours
load WBAdultPopulation80     % pop15over is % aged 15 and higher.

% Convert Gini coefficients into std devs (assuming lognormal)
gini=GiniConsumption;
sigma=sqrt(2)*norminv((1+gini/100)/2);

% Get life expectancy
lifeexp=lifeWB(2007-1949,:)';


% Get consumption and leisure
annualhours=annualhours2007;
workers=emp; %rgdpl2./rgdpl2wok.*pop;

disp 'Kids leisure=1';
epop=workers./pop;  % Ratio of employment to pop; no adult adjustment (as in micro)
%disp 'Kids leisure = adult leisure!'                                     
%epop=workers./(pop.*pop15over/100);  % Ratio of employment to pop aged 15 and over

ell=1-mult(epop',annualhours/(16*365))';   % 5840=16*365 -- have 16 hours per day avail.
disp 'ell=1-annualhours/(16*365)*epop';
hours=(1-ell)*16*365;  % Per capita annual hours, including epop

% Note: csh_r includes both trade in services and the residual.
%   csh_x and csh_m are just merchandise trade, not services!!
%   See national_accounts_in_pwt80.pdf or even just legend in pwt80.xlsx
%   So let's just use csh_c+csh_g for our consumption measure.
%   Do not divide by any sum.
% For more on real vs nominal shares, see User Guide, p. 32 and
% Inklaar email of June 26, 2013 response to my queries.
%  csh_c is a *real* share, which is what we want, since we want to 
%  make real comparisons of consumption across countries.


% Choose year for cross section
KeyPeriod=2007  
%rconsl2=rgdpl2.*(kc+kg)/100;  % Consumption includes both private and government
rcons=cgdpe./pop.*(csh_c+csh_g);  % Note: these are *output* shares
ry=cgdpe./pop;  % Per capita

y=ry(KeyPeriod-1949,:)';  % rgdpl2
c=rcons(KeyPeriod-1949,:)';
ell=ell(KeyPeriod-1949,:)';
hours=(1-ell)*16*365;  % Per capita annual hours, including epop

cyraw=c./y;  % For data display later
c=c/c(USA); % Normalize so both c and y equal 1 for USA in 2007.
y=y/y(USA);

% For calibrating theta from US foc;  see Klenow email 8/26/13
%USMarginalTax=mean([.387 .390 .392 .385 .380]')  % From Barro-Redlick (2010)
%USMarginalTax=.353  % 2006 (last year) From Barro-Redlick (2010)
%USMarginalTax=.26  % Ohanian et al (2011) for 2003 (last year, so we can have France)
%USMarginalTax=.340  % OECD Table I.4 (http://www.oecd.org/ctp/tax-policy/oecdtaxdatabase.htm#TaxingWages
                    %  France will be 0.558 from same source; these are for 2005

% % Check the cshares
% figure(1); figsetup;
% plotnamesym(log(y(smpl)),csh_c(smpl)+csh_g(smpl),namesSTR(smpl,:),10,[],.02,.004);
% set(gca,'XTick',log([1/64 1/32 1/16 1/8 1/4 1/2 1]));
% set(gca,'XTickLabel',strmat('1/64.1/32.1/16.1/8.1/4.1/2. 1 ','.'));
% %ax=axis; ax(1)=log(1/40); axis(ax);
% chadfig('GDP per person','csh_c + csh_g',1,0);


disp ' ';
disp 'Dropping any countries identified as outliers by pwt80:';
isoutlier=ismember(i_outlier(KeyPeriod-1949,:),'Outlier')==1;
isoutlier = isoutlier' | outliersAfter1980==1; % More stringent criteria. See regions80.m
disp(namesSTR(isoutlier,:)); disp ' ';
c(isoutlier)=NaN;

smpl=~isnan(y.*c.*lifeexp.*gini.*ell);
fprintf('We finally have basic data for this many countries: %6.0f\n',sum(smpl));


% Correlation matrix for our key variables?
blah=[y lifeexp c ell sigma];
blah=blah(smpl,:);
Correlations=corr(blah);
tle='y lifeexp c ell sigma';
cshow(strmat(tle),Correlations,'%7.2f',tle);



