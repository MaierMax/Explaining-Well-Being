function ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,StartAge,HHSizeEquivScale,Silent);
% GetUbarMicro  8/22/14
%
%  Calibrate ubar from 40-year old U.S. perspective, using the 2005 U.S. microdata.
%  Includes age-specific consumption, leisure, consumption inequality, and leisure inequality.
%
%  Older versions:
%  14: 8/20/13 -- pwt80
%  13: 1/29/13 -- Use pwt71
%  12: 3/1/12 -- Use pwt70
%
%  10: Same as version 9. 9/14/09 -- PWT 6.3
%
%  9: 40% marg tax rate on US  ==> lower theta and AdultPop is 15 and over
%
%  Calibrating ubar in utility function:
% 
%    u(c,l) = ubar + log(c) + v(ell)
%

disp 'Calculating ubar...';

epsilon=FrischLSElasticity;
ee=(1+epsilon)/epsilon;
%if exist('StartAge')~=1; StartAge=40; end; % Default for calibrating ubar
StartAge=40; % Calibrating ubar based on age 40 no matter what
             % This correctly does not affect StartAge for other programs, of course...

CountryMain={ 'US'          'USA'   2006  0}
if exist('Silent')==0; Silent=1; end;
if exist('HHSizeEquivScale')==0; HHSizeEquivScale=0; end;
ubarzero=0; % For calibrating ubar ==> Vtilde
[ca,la,logca,vofla,sa,Sa,y,logca2,la2,cbarUSRefYear]=mainmoments80(CountryMain,Silent,ubarzero,beta,g,theta,epsilon,StartAge,HHSizeEquivScale);
utila=ubarzero+logca+vofla;  % Expected flow utility for age a

ValueofLife=ValueofLife2005dollars;     % *98.754/89.099  % PCE from St.Louis Fed

% Consumption units are already set so that Cus2007=1
% Note: StartAge==40, so zero growth at that age already.
uprime40=1/ca(StartAge);        % Marginal utility of consumption at age 40

% Setup
ages=(StartAge:100)';
T=length(ages);
t=(1:T)'-1;           % Start with t=0


% Convert Value of Life into c0 units, i.e. c0=1
fprintf('Converting VSL into consumption units as in mainmoments80: cbarUSRefYear=%12.0f\n',cbarUSRefYear);
ValueofLife=ValueofLife*10^6/cbarUSRefYear
ValueofLifeUtils=ValueofLife*uprime40

% Compute Value of Life
% Note: all the survival probability stuff already starts at StartAge
SaUS=Sa(ages)/Sa(StartAge);  % All relative to starting survival probability Sa(40)=1

%cshow(' ',[ages ca(ages) la(ages) utila(ages)],'%6.0f %8.2f','ages ca la utila');

Vtilde=sum((beta.^t).*utila(ages).*SaUS);
ubar = (ValueofLifeUtils-Vtilde)/sum((beta.^t).*SaUS);
disp ' '; disp ' ';
fprintf('This calibration yields ubar = %8.4f\n',ubar);
disp ' ';

