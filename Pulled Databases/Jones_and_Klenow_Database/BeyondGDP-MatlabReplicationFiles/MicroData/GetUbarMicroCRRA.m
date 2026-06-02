function ubar=GetUbarMicroCRRA(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,ZeroGrowthAge,gamma,clowerbar,Silent);
% GetUbarMicroCRRA  8/22/14
%
%  Calibrate ubar from 40-year old U.S. perspective, using the 2005 U.S. microdata.
%  Includes age-specific consumption, leisure, consumption inequality, and leisure inequality.
%
%  October 2014 -- For CRRA/cbar/Shimer/Trabandt/Uhlig case
%
%  Calibrating ubar in utility function:
%
%    uofc=(consump+CBar(k)).^(1-gamma)/(1-gamma); 
%    u(c,l) =ubar-1/(1-gamma)+uofc.*(1+(1-gamma)*vofell).^gamma;


disp 'Calculating ubar...';

epsilon=FrischLSElasticity;
ee=(1+epsilon)/epsilon;

CountryMain={ 'US'          'USA'   2006  0}
if exist('Silent')==0; Silent=1; end;
if exist('ZeroGrowthAge')==0; ZeroGrowthAge=40; end;
if exist('gamma')==0; gamma=1; end;
if exist('clowerbar')==0; clowerbar=0; end;
ubarzero=0; % irrelevant, just for getting Sa

% Pass with a zero ubar so Eu_age can be used to compute ubar!
[ca,la,Eu0_age,sa,Sa,y,cbarUSRefYear,yCtry]=...
    mainmoments80crra(CountryMain,Silent,ubarzero,beta,g,theta,epsilon,ZeroGrowthAge,gamma,clowerbar);


ValueofLife=ValueofLife2005dollars;     % *98.754/89.099  % PCE from St.Louis Fed
StartAge=40

% Consumption units are already set so that Cus2007=1
if gamma==1;
    uprime40=1/(ca(StartAge)*exp(g*(StartAge-ZeroGrowthAge))+clowerbar)         % Marginal utility of consumption at age 40
else;
    vofell=(-theta*(1-la(StartAge)).^ee)/ee;  % Compute mu at average leisure
    uprime40=((ca(StartAge)*exp(g*(StartAge-ZeroGrowthAge))+clowerbar)^(-gamma)) * (1+(1-gamma)*vofell).^gamma;
end;

% Setup
ages=(40:100)';
T=length(ages);
t=(1:T)'-1;           % Start with t=0

%cshow(' ',[ages ca(ages) la(ages) Eu0_age(ages)],'%6.0f %8.2f','ages ca la Eu0_age');


% Convert Value of Life into c0 units, i.e. c0=1
fprintf('Converting VSL into consumption units as in mainmoments80: cbarUSRefYear=%12.0f\n',cbarUSRefYear);
ValueofLife=ValueofLife*10^6/cbarUSRefYear
ValueofLifeUtils=ValueofLife*uprime40

% Compute Value of Life
SaUS=Sa(ages)/Sa(StartAge);  % All relative to starting survival probability Sa(40)=1

Vtilde=sum((beta.^t).*Eu0_age(ages).*SaUS);
ubar = (ValueofLifeUtils-Vtilde)/sum((beta.^t).*SaUS);
disp ' '; disp ' ';
fprintf('This calibration yields ubar = %8.4f\n',ubar);
disp ' ';


