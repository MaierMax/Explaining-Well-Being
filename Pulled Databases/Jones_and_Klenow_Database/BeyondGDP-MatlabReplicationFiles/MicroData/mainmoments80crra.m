function [ca,la,Eu_age,sa,Sa,y,cbarUSRefYear,yCtry]=...
    mainmoments80crra(CountryInputs,Silent,ubar,beta,g,theta,epsilon,ZeroGrowthAge,gamma,clowerbar,SaveFile);

% mainmoments80crra.m    
%
%  -- Allows for CRRA/Trabandt/Uhlig and clowerbar
%
%    uofc=(consump+clowerbar).^(1-gamma)/(1-gamma); 
%    u(c,l) =ubar-1/(1-gamma)+uofc.*(1+(1-gamma)*vofell).^gamma;

%
% Returns the key moments for a given country/year that are needed for
% welfare calculations.
%
%   CountryInputs = {'China'       'CHN'   2002 1}
%                   where last item is TwoFiles 0=no, 1=yes
%   Silent = 1 to shut off verbose display
%   SaveFile = filename in which to save cleaned micro data (e.g. Malawi for checking negative utility)
% 
% 9/4/13: Use pwt80 and work with countries that have either
%         a single micro data file or separate exp / leisure files
%
% 2/1/13:
%   -- Add discounting and growth

Country=strmat(cell2mat(CountryInputs(1)));
Code=strmat(cell2mat(CountryInputs(2)));
Year=cell2mat(CountryInputs(3));
TwoFiles=cell2mat(CountryInputs(4));

yy=Year-1900; if yy>100; yy=yy-100; end;

if TwoFiles==0; % Single file contains all micro data
    fname=['Data/' Code '_' sprintf('%02d',yy) '.txt'];
    [hhidC,hhsizeC,ageC,hhexpC,leisure,weightC,garbage]=textread(fname);
    if ~all(garbage==0); disp 'Error: garbage column non zero!'; abc; end;
    weightL=weightC; hhidL=hhidC; ageL=ageC; hhsizeL=hhsizeC;
else; % Separate expenditure and leisure files
    disp 'Error! Shimer/Trabandt/Uhlig/CRRA case is nonseparable -- only single files allowed';
    keyboard;

    fnameExp=['Data/' Code '_' sprintf('%02d',yy) '_exp.txt'];
    fnameLeis=['Data/' Code '_' sprintf('%02d',yy) '_leisure.txt'];
    [hhidC,hhsizeC,ageC,hhexpC,weightC,garbage]=textread(fnameExp);
    if ~all(garbage==0); disp 'Error: garbage column non zero!'; abc; end;
    [hhidL,hhsizeL,ageL,leisure,weightL,garbage]=textread(fnameLeis);
    if ~all(garbage==0); disp 'Error: garbage column non zero!'; abc; end;
end;

ee=(1+epsilon)/epsilon;
MaxAge=100;
NumToShow=25;

global survivaldata survivalyears survivalages
global Brazil China France Germany India Indonesia Malawi Mexico SouthAfrica US Italy Russia Spain UK

load WHOSurvivalRate2013

% Check and fix weights
weightC_orig=weightC;
weightC=weightC/sum(weightC);
if ~Silent;
    disp 'Consumption...';
    fprintf('The sum of the raw sample weights (pre-adjustment) is %10.9f\n',sum(weightC_orig));
    fprintf('The sum of the raw sample weights (postadjustment) is %10.9f\n',sum(weightC));
    fprintf('The sum of raw hhexp unweighted is %10.4f\n',sum(hhexpC));
end;

weightL_orig=weightL;
weightL=weightL/sum(weightL);
if ~Silent;
    disp 'Leisure...';
    fprintf('The sum of the raw sample weights (pre-adjustment) is %10.9f\n',sum(weightL_orig));
    fprintf('The sum of the raw sample weights (postadjustment) is %10.9f\n',sum(weightL));
end;

% The demographic adjustment.
% That is, we create a new weight that is the existing sampling
% weight, normalized to sum to 1 for each age.  Our
% Rawls calculation will neutralize demographics (so that if a 40 year
% old in two countries gets the same consumption, it won't matter if we
% have tons of young people in one country but not the others).

weightbarC=zeros(length(hhidC),1)*NaN;
totweightC=zeros(MaxAge,1)*NaN;
for a=1:MaxAge;
  indx=find(ageC==a);
  totweightC(a)=sum(weightC(indx));
  weightbarC(indx)=weightC(indx)/sum(weightC(indx));
end;

weightbarL=zeros(length(hhidL),1)*NaN;
totweightL=zeros(MaxAge,1)*NaN;
for a=1:MaxAge;
  indx=find(ageL==a);
  totweightL(a)=sum(weightL(indx));
  weightbarL(indx)=weightL(indx)/sum(weightL(indx));
end;


% Converting hhexp into Consumption and displaying data
microC=hhexpC./hhsizeC;
if ~Silent;
    disp ' ';
    disp 'Allocating hhexp to the members of the household: Adjustment = 1/hhsize';
    disp ' ';
    fmt='%8.0f %6.0f %6.0f %9.2f %10.7f %9.2f';
    tle='hhid hhsize age hhexp weight Consume';
    blah=[hhidC hhsizeC ageC hhexpC weightC microC];
    cshow(' ',blah(1:NumToShow,:),fmt,tle);
    fprintf('Unweighted mean microC (all obs) = %8.4f\n',mean(microC));
    fprintf('Unweighted stdev microC (all ob) = %8.4f\n',std(microC));
    fprintf('Weighted mean microC (all obs)   = %8.4f\n',sum(weightC.*microC));

    fmt='%8.0f %6.0f %6.0f %9.2f %10.7f';
    tle='hhid hhsize age leisure weight';
    blah=[hhidL hhsizeL ageL leisure weightL];
    cshow(' ',blah(1:NumToShow,:),fmt,tle);
    fprintf('Unweighted mean leisure (all obs) = %8.4f\n',mean(leisure));
    fprintf('Unweighted stdev leisure (all ob) = %8.4f\n',std(leisure));
    fprintf('Weighted mean leisure (all obs)   = %8.4f\n',sum(weightL.*leisure));
end;




% Incorporating PWT Consumption and GovtCons.
%  1. PWT Consumption:  Assign based on share of micro consumption
%       that each person obtains.
%  2. PWT GovtCons -- add per capita Govt Cons to each person.

load pwt80;

%rconsl2=rgdpl2.*(kc+kg)/100;  % Consumption includes both private and government
%rcons=cgdpe./pop.*(csh_c+csh_g);  % Note: these are *output* shares
ry=cgdpe./pop;  % Per capita
y=ry(Year-1949,eval(Code));  % Income for Country/Year
yCtry=y;

C=ry(Year-1949,eval(Code))*csh_c(Year-1949,eval(Code));
G=ry(Year-1949,eval(Code))*csh_g(Year-1949,eval(Code));
Ctotmicro=sum(weightC.*microC);  % Recall that the "weights" sum to one.


consump=C/Ctotmicro*microC + G;
if ~Silent;
    disp 'Now check that aggregation is satisfied.  These two should be equal:';
    fprintf('    PWT: C+G=%9.1f     Micro: sum(weight.*consump)=%9.1f\n',[C+G sum(weightC.*consump)]);
end;
if abs(C+G-sum(weightC.*consump))>1e-3; disp 'Adding up error... stopping'; keyboard; end;


% Fix consumption units (cbarUS2007=1, from PWT not demographically adjusted)

RefYear=2007;
Cus=ry([Year RefYear]-1949,USA).*csh_c([Year RefYear]-1949,USA);
Gus=ry([Year RefYear]-1949,USA).*csh_g([Year RefYear]-1949,USA);
cbarUSRefYear=Cus(2)+Gus(2)
cbarUS=(Cus(1)+Gus(1))/cbarUSRefYear;  % For the "Year" we are using
consump=consump/cbarUSRefYear;


% Show the results 
if ~Silent;
    data=[hhidC hhsizeC ageC hhexpC weightC microC consump weightbarC];
    %[blah indx]=sort(age);
    fmt='%8.0f %6.0f %6.0f %9.2f %10.7f %9.4f %9.4f %9.6f';
    tle='hhid hhsize age hhexp weight microC consump WghtBar';
    cshow(' ',data((1:NumToShow),:),fmt,tle);
end;

% Survival rates by age.
Sa=zeros(MaxAge,1)*NaN;
for a=1:MaxAge;  
  Sa(a)=survivalrate(a,Year,Country);
end;

% This is where the discounting shows up
betaToTheA=beta.^(1:MaxAge)';
sa=betaToTheA.*Sa/sum(betaToTheA.*Sa);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  KEY MOMENTS
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Average over each age group
ca=zeros(MaxAge,1)*NaN;
la=zeros(MaxAge,1)*NaN;
Eu_age=zeros(MaxAge,1)*NaN;  % Partial expectation of u(c+cbar,ell) in CRRA case, age a
for a=1:MaxAge;
  indx=find(ageC==a); % Consumption and Leisure simultaneously cannot use two data sets
  if ~isempty(indx);
    ca(a)=sum(weightbarC(indx).*consump(indx));
    la(a)=sum(weightbarL(indx).*leisure(indx));
    vofell=(-theta*(1-leisure(indx)).^ee)/ee;
    if gamma~=1;
        uofc=(consump(indx)*exp(g*(a-ZeroGrowthAge))+clowerbar).^(1-gamma)/(1-gamma); % w/ growth (40yr old is benchmark)
        util=ubar-1/(1-gamma)+uofc.*(1+(1-gamma)*vofell).^gamma;
    else; % log utility
        uofc=log(consump(indx)*exp(g*(a-ZeroGrowthAge))+clowerbar); % w/ growth (40yr old is benchmark)
        util=ubar+uofc+vofell;
    end;
    Eu_age(a)=sum(weightbarC(indx).*util);
  end;
end;


% Fix missing values. 
% For some ages (esp old), the micro sample may have no observations.
% For now, I will interpolate linearly.  At the top, just
% use the last value.  This shouldn't matter too much since people
% of very high ages get such low weight...

ca=interplin3(ca,NaN);  
la=interplin3(la,NaN);
Eu_age=interplin3(Eu_age,NaN);

% Display the results by age
if ~Silent;
    fmt='%6.0f %12.6f';
    disp ' ';
    ubar
    tle='Age c(a) l(a) Eu_age sa Sa totweightL';
    cshow(' ',[(1:MaxAge)' ca la Eu_age sa Sa totweightL],fmt,tle);
end;

if exist('SaveFile')==1;
    eval(['save ' SaveFile ' CountryInputs hhidC hhsizeC ageC hhexpC weightC microC consump weightbarC hhidL hhsizeL ageL leisure weightL ca la Eu_age sa Sa;']);
end;
