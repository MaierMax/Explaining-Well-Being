function [loglam,logy,termLE,termCY,terml,termCineq,termlineq,results,KeyFacts,negutil]=...
    lambdastats80(CountryMain,CountryRef,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale,KidsGetAdultLeisure,AnnualizeDivisor);

% lambdastats80.m    
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
%    StartAge = 1 or 40 -- Compute lifetime utility starting from age StartAge
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

global MicroDataTXTFilesPresent  % For replicating basic results w/o micro data .txt files


% AnnualizeDivisor if for Growth Rate calculations -- what number to divide
% by to annualize the growth rate. -- There is an additional correction for
% the Life Expectancy Term if the initial year is earlier than 1990: we only
% have consistent data on survival rates starting in 1990, so we just use an
% annualizing factor of T_LE=YearT-1990 for that variable.
if exist('AnnualizeDivisor')~=1; 
    T=1; T_LE=1; % Divide just by 1 for levels
else; 
    T=AnnualizeDivisor(2)-AnnualizeDivisor(1); T_LE=T;
    if AnnualizeDivisor(1)<1990;
        T_LE=AnnualizeDivisor(2)-1990;
    end;
end;  
if exist('StartAge')~=1; StartAge=1; end;
if exist('HHSizeEquivScale')~=1; HHSizeEquivScale=0; end;
if exist('KidsGetAdultLeisure')~=1; KidsGetAdultLeisure=0; end;

MaxAge=100;
ee=(1+epsilon)/epsilon;

% First, get the key moments for the Main and Reference countries
% Reference country variables will be referred to with a "Z"
disp ' '; disp ' '; disp ' ';
disp '**************************************************************';
disp '**************************************************************';
disp ' ';


if MicroDataTXTFilesPresent;
    % When Micro data .txt files exist, we use them
    CountryMain
    [ca,la,logca,vofla,sa,Sa,y,logca2,la2,cbarUSRefYear,yCtry]=mainmoments80(CountryMain,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale);
    CountryRef
    [caZ,laZ,logcaZ,voflaZ,saZ,SaZ,yZ,logca2Z,la2Z,blah,yCtryZ]=mainmoments80(CountryRef,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale);
else;
    % People who download replication files from AER will not have the micro data.
    % This shortcut allows them to load the necessary moments to get basic results
    % First, the Ref country, so we can rename with "Z"
    Code=strmat(cell2mat(CountryRef(2)));
    Year=cell2mat(CountryRef(3));
    yy=Year-1900; if yy>100; yy=yy-100; end;
    sname=['Data/' Code '_' sprintf('%02d',yy) '.mat'];
    load(sname);
    caZ=ca; laZ=la; logcaZ=logca; voflaZ=vofla; saZ=sa; SaZ=Sa; yZ=y; logca2Z=logca2; la2Z=la2; yCtryZ=yCtry;

    % Now Main
    Code=strmat(cell2mat(CountryMain(2)));
    Year=cell2mat(CountryMain(3));
    yy=Year-1900; if yy>100; yy=yy-100; end;
    sname=['Data/' Code '_' sprintf('%02d',yy) '.mat'];
    load(sname);
end;

% Default is to give kids Leisure=1. This section allows for alternatives:
%  KidsGetAdultLeisure==0 ==> kids leisure is 1 (default)
%  KidsGetAdultLeisure==1 ==> kids leisure is the adult average (ages 25-55)
%  KidsGetAdultLeisure==2 ==> kids leisure is .5*AdultAverage + .5*100%  ==> weighted average of other two
if KidsGetAdultLeisure~=0;
    % Assign everyone under the age of 25 the average (US-demography-weighted) 
    % leisure of people between the ages of 25 and 55.
    %  -- Do this for main country and for reference country as well...
    AgestoAverage=(25:55)';
    AgestoImpute=(1:20)';
    disp 'Imputing ages 1-20 leisure from ages 25-55 average...';
    ellMiddleAge=sum(saZ(AgestoAverage).*la(AgestoAverage))/sum(saZ(AgestoAverage));
    ellMiddleAgeZ=sum(saZ(AgestoAverage).*laZ(AgestoAverage))/sum(saZ(AgestoAverage));
    
    if KidsGetAdultLeisure==2; % Average of the two cases
        disp 'Averaging (.5*adults + .5*100 percent)...';
        ellMiddleAge=.5*ellMiddleAge+.5;
        ellMiddleAgeZ=.5*ellMiddleAgeZ+.5;
    end;
    la(AgestoImpute)=ellMiddleAge;
    la2(AgestoImpute)=ellMiddleAge^2;
    vofla(AgestoImpute)=-(theta*(1-ellMiddleAge).^ee)/ee;

    laZ(AgestoImpute)=ellMiddleAgeZ;
    la2Z(AgestoImpute)=ellMiddleAgeZ^2;
    voflaZ(AgestoImpute)=-(theta*(1-ellMiddleAgeZ).^ee)/ee;
end;

utila=ubar+logca+vofla;  % Expected flow utility for age a
utilaZ=ubar+logcaZ+voflaZ;  % Expected flow utility for age a
negutil(1)=sum(utila<0); % Return a count of the number of ages for which expected utility is negative

disp ' ';
disp 'Utility and Leisure (after any imputed values)...';
cshow(' ',[(1:length(la))' la laZ la2 la2Z vofla voflaZ utila utilaZ],'%6.0f %8.4f','Age la laZ la2 la2Z vofla voflaZ utila utilaZ');


% Now average over ages, weighting by survival rates in reference country
cbar=sum(saZ.*ca);
lbar=sum(saZ.*la);
Elogc=sum(saZ.*logca);
Evofl=sum(saZ.*vofla);
voflbar=-theta*(1-lbar).^ee/ee;
Eell2=sum(saZ.*la2);
Elogc2=sum(saZ.*logca2);

cbarZ=sum(saZ.*caZ);
lbarZ=sum(saZ.*laZ);
ElogcZ=sum(saZ.*logcaZ);
EvoflZ=sum(saZ.*voflaZ);
voflbarZ=-theta*(1-lbarZ).^ee/ee;
Eell2Z=sum(saZ.*la2Z);
Elogc2Z=sum(saZ.*logca2Z);

% KeyFacts to save, including standard deviations, demographically neutralized
% For making nice graphs and tables of the underlying data
cyraw=cbar*cbarUSRefYear/yCtry; % Demographically adjusted ratio of consumption to GDP (for comparison)
stdlogc=sqrt(Elogc2-(Elogc).^2);
stdell=sqrt(Eell2-(lbar).^2);
lifeexp=sum(Sa);

cyrawZ=cbarZ*cbarUSRefYear/yCtryZ; % Demographically adjusted ratio of consumption to GDP (for comparison)
stdlogcZ=sqrt(Elogc2Z-(ElogcZ).^2);
stdellZ=sqrt(Eell2Z-(lbarZ).^2);
lifeexpZ=sum(SaZ);

KeyFacts(:,1)=[cbar lbar stdlogc stdell lifeexp cyraw];
KeyFacts(:,2)=[cbarZ lbarZ stdlogcZ stdellZ lifeexpZ cyrawZ];


betaToTheA=beta.^((1:MaxAge)'-StartAge);
betaToTheA(1:(StartAge-1))=0;
DeltaSa=betaToTheA.*(Sa-SaZ)/sum(betaToTheA.*SaZ);

Vmain=sum(betaToTheA.*utila.*Sa);
negutil(2)=(Vmain<0);
Vref=sum(betaToTheA.*utilaZ.*SaZ);
loglamQuick=1/T*(Vmain-Vref)/sum(betaToTheA.*SaZ);

% Value of life for a 40 year old. Start growth at age 40.
Age40=40-StartAge+1;
c40=ca(Age40)*exp(-g*40);
uprime40=1/c40;        % Marginal utility of consumption at age 40
Sa40=Sa(Age40:end)/Sa(Age40);  % All relative to starting survival probability Sa(40)=1
beta40=betaToTheA(Age40:end)/betaToTheA(Age40);
utila40=utila - g*40; % Start growth at age 40 rather than 1
V40=sum(beta40.*utila40(Age40:end).*Sa40);
ValueofLife=V40/uprime40*cbarUSRefYear;


ytilde=y./yZ;  % relative income (not x100)
logy=log(ytilde);

% And finally, the terms of the decomposition
termLE=sum(DeltaSa.*utila);
termC=log(cbar)-log(cbarZ);
termCY=termC-log(ytilde);
terml=voflbar-voflbarZ;
termCineq=Elogc-log(cbar) - (ElogcZ-log(cbarZ));
termlineq=(Evofl-voflbar) - (EvoflZ-voflbarZ);
if T>1; termLE=termLE/T_LE; termC=termC/T; termCY=termCY/T; terml=terml/T; termCineq=termCineq/T; termlineq=termlineq/T; logy=logy/T; end;% Growth rates
loglam=termLE+termC+terml+termCineq+termlineq;
lambda=exp(loglam);

if T==1;
    results=[lambda*100 ytilde*100 loglam-logy termLE termCY terml termCineq termlineq];
else; % Growth rates
    results=100*[loglam logy loglam-logy termLE termCY terml termCineq termlineq];
end;

if ~Silent;
    disp ' '; disp ' ';
    disp '==========================================================';
    disp ' ';
    CountryMain
    CountryRef
    disp ' ';
    fprintf('ubar  =%8.5f\n',ubar);
    fprintf('theta =%8.5f\n',theta);
    disp ' ';
    
    fprintf('cbar           =%8.4f\n',cbar);
    fprintf('lbar           =%8.4f\n',lbar);
    fprintf('Elogc-log(cbar)=%8.4f\n',Elogc-log(cbar));
    fprintf('Evofl-voflbar  =%8.4f\n',Evofl-voflbar);

    disp ' ';
    fprintf('cbarZ            =%8.4f\n',cbarZ);
    fprintf('lbarZ            =%8.4f\n',lbarZ);
    fprintf('ElogcZ-log(cbarZ)=%8.4f\n',ElogcZ-log(cbarZ));
    fprintf('EvoflZ-voflbarZ  =%8.4f\n',EvoflZ-voflbarZ);


    disp ' ';
    fprintf('Life expectancy = sum(Sa) = %4.1f\n',sum(Sa));
    fprintf('Life expectancy Z = sum(SaZ)= %4.1f\n',sum(SaZ));
    fprintf('Vmain = %8.4f\n',Vmain);
    fprintf(' Vref = %8.4f\n',Vref);
    fprintf('Value of Life at Age 40:  Dollars = %12.0f   Ratio to c(40)=%6.1f\n',[ValueofLife V40]);
    
    disp ' '; disp ' ';
    fprintf('Log lambda    = %8.5f\n',loglam);
    fprintf(' log ytilde   = %8.5f\n',logy);
    fprintf(' termLE       = %8.5f\n',termLE);
    fprintf(' termCY       = %8.5f\n',termCY);
    fprintf(' termLeis     = %8.5f\n',terml);
    fprintf(' Ineq(C)      = %8.5f\n',termCineq);
    fprintf(' Ineq(Leis)   = %8.5f\n',termlineq);

    disp ' '; 
    fprintf('Lambda*100  =%7.1f\n',100*lambda);
    fprintf('   ytilde   =%7.1f\n',100*ytilde);
    fprintf(' log Ratio  =%7.3f\n',loglam-logy);

    fmt='%10.3f';
    tle='lambda ytilde logRatio termLE termCY termell Cineq lineq';
    Country=strmat(cell2mat(CountryMain(1)));
    cshow(Country,results,fmt,tle);
end;

if T==T_LE & abs(loglam-loglamQuick)>1e-8; disp 'lambdastats80 error: loglam and loglamQuick too far apart?'; 
        loglam
        loglamQuick
        lambda
        exp(loglamQuick)
        keyboard; 
end;