function [lambda,ytilde,negutil,yCtry]=lambdacrra80(CountryMain,CountryRef,Silent,ubar,beta,g,theta,epsilon,gamma,clowerbar,AnnualizeDivisor);

% lambdacrra80.m
%
% Like lambdastats80.m but for CRRA/clowerbar case (Shimer/Trabandt/Uhlig)
% Have to solve numerically for the lambda fixed point.
%
% Welfare calculation for a country using micro data.
%
%   CountryMain = {'China'       'CHN'   2002 1}
%                   where last item is TwoFiles 0=no, 1=yes
%   CountryMain is the main Country/Year
%   CountryRef is the reference point, e.g. US 2005 for levels
%      or same country in an earlier year for growth rates
%
%    AnnualizeDivisor = 2008-1984 -- amount to divide by for growth rates
%      (omit for level calculations);  
%
%   Silent = 1 to shut off verbose display
% 
% 8/21/14: No to next line. We keep leisure=1 for young...
% 8/18/14: Assign everyone under the age of 25 the average
%          (US-demography-weighted) leisure of people between the ages of 25 and 55.
%
% 9/4/13: Use pwt80 and work with countries that have either
%         a single micro data file or separate exp / leisure files
%
% 2/1/13:
%   -- Add discounting and growth


% AnnualizeDivisor if for Growth Rate calculations -- what number to divide
% by to annualize the growth rate. -- There is an additional correction for
% the Life Expectancy Term if the initial year is earlier than 1990: we only
% have consistent data on survival rates starting in 1990, so we just use an
% annualizing factor of T_LE=YearT-1990 for that variable.
if exist('AnnualizeDivisor')~=1; 
    T=1; % Divide just by 1 for levels
else; 
    T=AnnualizeDivisor(2)-AnnualizeDivisor(1); T_LE=T;
    if AnnualizeDivisor(1)<1990;
        T_LE=AnnualizeDivisor(2)-1990;
    end;
end;  

MaxAge=100;
ZeroGrowthAge=1; % Default for computation of welfare (only 40 for calibrating ubar)
t=(1:MaxAge)'-1;
ee=(1+epsilon)/epsilon;

% First, get the key moments for the Main and Reference countries
% Reference country variables will be referred to with a "Z"
disp ' '; disp ' '; disp ' ';
disp '**************************************************************';
disp '**************************************************************';
disp ' ';
CountryMain
[ca,la,Eu_age,sa,Sa,y,cbarUSRefYear,yCtry]=mainmoments80crra(CountryMain,Silent,ubar,beta,g,theta,epsilon,ZeroGrowthAge,gamma,clowerbar);
negutil(1)=sum(Eu_age<0); % Return a count of the number of ages for which expected utility is negative

CountryRef
SaveFile='CountryRefData'; % We need to save the micro data for lambda solution
[caZ,laZ,Eu_ageZ,saZ,SaZ,yZ,cbarUSRefYearZ,yCtryZ]=mainmoments80crra(CountryRef,Silent,ubar,beta,g,theta,epsilon,ZeroGrowthAge,gamma,clowerbar,SaveFile);



% Expected utility in main country
Vmain=sum((beta.^t).*Eu_age.*Sa)
Vref=sum((beta.^t).*Eu_ageZ.*SaZ)
negutil(2)=(Vmain<0);

% Now find the value of lambda in the Ref country that equates welfare
isitzero=@(lambda) e_solvelambda(lambda,Vmain,MaxAge,Silent,T,ubar,theta,ee,gamma,beta,ZeroGrowthAge,g,clowerbar);
if isitzero(.0001)<0;
    lambda=0; % If we give a high clowerbar, there may not be a lambda that reduces US utility down to Malawi...
else;
    lambda=fzerochad(isitzero,[0.01 2.5],2,5);
end;

ytilde=y./yZ;  % relative income (not x100)

CountryMain
CountryRef
fprintf('Vmain = %8.4f\n',Vmain);
fprintf(' Vref = %8.4f\n',Vref);
if T>1; disp 'Dividing by T for reporting the log values...'; end;
fprintf('Log lambda    = %8.5f   lambda=%8.4f\n',[log(lambda)/T*100 lambda]);
fprintf(' log ytilde   = %8.5f   ytilde=%8.4f\n',[log(ytilde)/T*100 ytilde]);


% ----------------------------------------------------------------
% Functions 
% ----------------------------------------------------------------

function e=e_solvelambda(lambda,Vmain,MaxAge,Silent,T,ubar,theta,ee,gamma,beta,ZeroGrowthAge,g,clowerbar);

% Note: weightbarC sums to one for each age
% There is no weightbarL b/c this nonseparable utility requires a single file

persistent CountryInputs hhidC hhsizeC ageC hhexpC weightC microC consump weightbarC hhidL hhsizeL ageL leisure weightL ca la Eu_age sa Sa
if isempty(consump); % Then load the Ref country data
    load CountryRefData;
end;

Eu_age=zeros(MaxAge,1)*NaN;  % Partial expectation of u(c+cbar,ell) in CRRA case, age a
for a=1:MaxAge;
  indx=find(ageC==a); % Consumption and Leisure simultaneously cannot use two data sets
  if ~isempty(indx);
    vofell=(-theta*(1-leisure(indx)).^ee)/ee;
    if gamma~=1;
        uofc=(lambda*consump(indx)*exp(g*(a-ZeroGrowthAge))+clowerbar).^(1-gamma)/(1-gamma); % w/ growth (40yr old is benchmark)
        util=ubar-1/(1-gamma)+uofc.*(1+(1-gamma)*vofell).^gamma;
    else; % log utility
        uofc=log(lambda*consump(indx)*exp(g*(a-ZeroGrowthAge))+clowerbar); % w/ growth (40yr old is benchmark)
        util=ubar+uofc+vofell;
    end;
    Eu_age(a)=sum(weightbarC(indx).*util);
  end;
end;

% Expected utility in Ref(lambda) country
Eu_age=interplin3(Eu_age,NaN);
t=(1:MaxAge)'-1;
Vref=sum((beta.^t).*Eu_age.*Sa);
e=Vmain-Vref;
