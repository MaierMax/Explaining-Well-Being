% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeDataGrowth15
%
% Basic program to set up the Growth data for the Rawls project
%  Copied from Growth6g and augmented as in MakeData.m
%
%  VERSION 15: Update version number
%  VERSION 14: PWT 80 -- 8/12/14
%  VERSION 13 
%   1/31/13: pwt71 and 1980-2007
%   1/19/11: TEDAnnualHours
%  12/29/10: Get annualhoursgrowth just from AnnualHours
%
%  VERSION 9:  Use Adult Population age >=15 in constructing epop
%    From WBAdultPopulation.m.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help MakeDataGrowth15

load pwt80;

load regions80             % region = 1-7 region code from pwt80 directory
load WIIDGiniGrowth80      % Nx2  Yrs = 1980 and 2007
load LifeExpectancyWB80    % lifeWB (in TxN PWT format, just decades)
namesSTR=namesSTR(:,1:15); % Shorten names for display
load AnnualHoursPWT80      % 1980 and 2000 hours
load WBAdultPopulation80     % pop15over is % aged 15 and higher. TxN as in PWT


yr1=1980
yr2=2007
yrs=[yr1 yr2];
%KeyPeriods=[1978 1982; 1998 2002];   % The intervals over which we average
KeyPeriods=[yr1; yr2];   % The intervals over which we average

% Convert Gini coefficients into std devs (assuming lognormal)
gini=GiniConsumption;
sigma=sqrt(2)*norminv((1+gini/100)/2);

% Get life expectancy
lifeexp=lifeWB(yrs-1949,:)';

% Get consumption and leisure
annualhoursgrowth=[annualhours1980 annualhours2007];
workers=emp;  %rgdpl2./rgdpl2wok.*pop;
disp 'Kids leisure=1';
epop=workers./pop;  % Ratio of employment to pop; no adult adjustment (as in micro)
%epop=workers./(pop.*pop15over/100);  % Ratio of employment to pop aged 15 and over
ell1980=1-mult(epop',annualhoursgrowth(:,1)/(16*365))';   % 5840=16*365 -- have 16 hours per day avail.
ell2007=1-mult(epop',annualhoursgrowth(:,2)/(16*365))';   % 5840=16*365 -- have 16 hours per day avail.
disp 'ell=1-annualhours/(16*365)*epop';


% Consumption and Income
%rconsl2=rgdpl2.*(kc+kg)/100;  % Consumption includes both private and government
rcons=cgdpe./pop.*(csh_c+csh_g);  % Note: these are *output* shares
ry=cgdpe./pop;  % Per capita
y=ry(KeyPeriods-1949,:)';
c=rcons(KeyPeriods-1949,:)';
ell1980=ell1980(yr1-1949,:)'; % uses 1980 annual hours
ell2007=ell2007(yr2-1949,:)'; % uses 2007 annual hours
ell=[ell1980 ell2007];
hours=(1-ell)*16*365; % for display

cyraw=c./y;  % For data display later
c=c/c(USA,2); % Normalize so both c and y equal 1 for USA in 2007.
y=y/y(USA,2);

disp ' ';
disp 'Dropping any countries identified as outliers by pwt80:';
%isoutlier=ismember(i_outlier(KeyPeriod-1949,:),'Outlier')==1;
isoutlier = outliersAfter1980==1; % More stringent criteria. See regions80.m
disp(namesSTR(isoutlier,:)); disp ' ';
c(isoutlier,1)=NaN;


smpl=~isnan(y.*c.*lifeexp.*gini.*annualhoursgrowth);
smpl=smpl(:,1).*smpl(:,2);
fprintf('We have basic data for this many countries: %6.0f\n',sum(smpl));
