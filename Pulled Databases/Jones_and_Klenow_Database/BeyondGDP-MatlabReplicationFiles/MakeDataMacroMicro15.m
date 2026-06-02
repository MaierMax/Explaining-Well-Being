% MakeDataMacroMicro15  8/20/13
%
% Basic program to set up the data for the Rawls project
%  -- for Micro/Macro comparisons -- just the specific countries/years
%
%  VERSION 14: PWT 80


help MakeDataMacroMicro15

disp 'Note: not running "clear all" within MakeDataMacroMicro15...';

load pwt80;

load regions80             % region = 1-7 region code from pwt70 directory
load WIIDGiniLevels80      % GiniConsumption Nx1 WIID3a for cross-section
load LifeExpectancyWB80    % lifeWB (in TxN PWT format, just decades)
namesShort=namesSTR(:,1:15); % Shorten names for display
load AnnualHoursPWT80      % Use PWT for hours
load WBAdultPopulation80     % pop15over is % aged 15 and higher. TxN annual


CountryInputs={
 'Brazil'      'BRA'   2003 
 'China'       'CHN'   2002 
 'Spain'       'ESP'   2001 
 'France'      'FRA'   2005 
 'UK'          'GBR'   2005 
 'Indonesia'   'IDN'   2006 
 'India'       'IND'   2005 
 'Italy'       'ITA'   2006 
 'Mexico'      'MEX'   2006 
 'Malawi'      'MWI'   2004 
 'Russia'      'RUS'   2007 
 'US'          'USA'   2006 
 'SouthAfrica' 'ZAF'   1993 
}

Names=CountryInputs(:,1);
CCodes=CountryInputs(:,2);
Year=cell2mat(CountryInputs(:,3));
NN=length(CCodes);


% %%%%%%%%%%%%%%%%%%%%%
% SETUP 
% %%%%%%%%%%%%%%%%%%%%%

workers=emp; %rgdpl2./rgdpl2wok.*pop;
             %epop=workers./(pop.*pop15over/100);  % Ratio of employment to pop aged 15 and over
epop=workers./pop;  % Ratio of employment to pop; no adult adjustment (as in micro)
disp 'ell=1-annualhours/(16*365)*epop';

disp ' ';
disp '##########################################'
disp ' Note well: leisure = 1-emp/totalpop here';
disp '##########################################'
disp ' ';


% Note: csh_r includes both trade in services and the residual.
%   csh_x and csh_m are just merchandise trade, not services!!
%   See national_accounts_in_pwt80.pdf or even just legend in pwt80.xlsx
%   So let's just use csh_c+csh_g for our consumption measure.
%   Do not divide by any sum.
% For more on real vs nominal shares, see User Guide, p. 32 and
% Inklaar email of June 26, 2013 response to my queries.
%  csh_c is a *real* share, which is what we want, since we want to 
%  make real comparisons of consumption across countries.


%rconsl2=rgdpl2.*(kc+kg)/100;  % Consumption includes both private and government
rcons=cgdpe./pop.*(csh_c+csh_g);  % Note: these are *output* shares
ry=cgdpe./pop;  % Per capita


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOOP over country-year observations
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:NN; 
    % Life Expectancy linearly interpolated from decadal data
    ctys(i)=eval(CCodes{i});
    fittedLE=interplin3(lifeWB(:,[ctys(i) USA]));
    lifeexp(i,:)=fittedLE(Year(i)-1949,:);
    
    % Leisure
    annualhours=avh(Year(i)-1949,[ctys(i) USA]);
    if isnan(annualhours(1));
        annualhours(1)=annualhours(2); % Use USA value if missing
    end;
    ell(i,:)=1-epop(Year(i)-1949,[ctys(i) USA]).*annualhours/(16*365);   % 5840=16*365 -- have 16 hours per day avail.

    % Consumption
    y(i,:)=ry(Year(i)-1949,[ctys(i) USA]);  % rgdpl2
    c(i,:)=rcons(Year(i)-1949,[ctys(i) USA]);
end;

cyraw=c./y;  % For data display later
c=c/rcons(2007-1949,USA); % Normalize so both c and y equal 1 for USA in 2007.
y=y/ry(2007-1949,USA);

% Gini Coefficients -- just use macro data since we're already averaging over
% years close to those for the micro data. I tried to see if we could do better
% with specific years, but the answer is no.

gini=zeros(length(ctys),2);
gini(:,1)=GiniConsumption(ctys);
gini(:,2)=GiniConsumption(USA); % The comparison
sigma=sqrt(2)*norminv((1+gini/100)/2);


% Look at data...

