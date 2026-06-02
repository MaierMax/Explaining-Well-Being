% LambdaStats
%
%   Computes lambda welfare levels using 13 countries of micro data.
%   (Run ../SetParameters first to get baseline parameters.)

help LambdaStats


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CountryInputs={
 'Brazil'      'BRA'   2003  1
 'China'       'CHN'   2002  0
 'Spain'       'ESP'   2001  1
 'France'      'FRA'   2005  0
 'UK'          'GBR'   2005  0
 'Indonesia'   'IDN'   2006  0
 'India'       'IND'   2005  0
 'Italy'       'ITA'   2006  0
 'Mexico'      'MEX'   2006  0
 'Malawi'      'MWI'   2004  0
 'Russia'      'RUS'   2007  0
 'US'          'USA'   2006  0
 'SouthAfrica' 'ZAF'   1993  0 
}

iUS = find(strcmp(CountryInputs(:,2), 'USA'));
iMWI = find(strcmp(CountryInputs(:,2), 'MWI'));
if exist('CVEV')~=1; CVEV='EV'; end;  % Equivalent variation is default
if exist('HHSizeEquivScale')~=1; HHSizeEquivScale=0; end;
ubar=GetUbarMicro(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,[],HHSizeEquivScale);
epsilon=FrischLSElasticity;  % Frisch elasticity
if exist('StartAge')~=1; StartAge=1; end;

run ../ShowParameters
if exist('KidsGetAdultLeisure')~=1; KidsGetAdultLeisure=0; end;


for i=1:size(CountryInputs,1);

    RefYear=cell2mat(CountryInputs(i,3));
    if RefYear>2007; RefYear=2007; end;
    CountryRef={'US' 'USA' RefYear 0};
    
    if CVEV=='EV';
        [loglam,logy,termLE,termCY,terml,termCineq,termlineq,results,keyfacts,negutil]=...
            lambdastats80(CountryInputs(i,:),CountryRef,Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale,KidsGetAdultLeisure);
        KeyFacts(i,:)=keyfacts(:,1); % Only for main country, not for countryref...
    else;
        % CV -- just reverse the two countries and look at 1/lambda
        disp '***** Using the Compensating Variation to compute welfare *****';
        [loglam,logy,termLE,termCY,terml,termCineq,termlineq,results,keyfacts,negutil]=...
            lambdastats80(CountryRef,CountryInputs(i,:),Silent,ubar,beta,g,theta,epsilon,StartAge,HHSizeEquivScale,KidsGetAdultLeisure);
        results=-results; % Take 1/lambda for CV case to put in [0,1]. Here for decomp, next for lambda
        results(1)=exp(-loglam)*100; 
        results(2)=exp(-logy)*100;
        KeyFacts(i,:)=keyfacts(:,2); % Only for main country, not for countryref...
    end;
    Results(i,:)=results;
    NegUtil(i,:)=negutil'; % only valid for EV case

end;


% Now underlying data
cbar=KeyFacts(:,1);
lbar=KeyFacts(:,2);
stdlogc=KeyFacts(:,3);
stdell=KeyFacts(:,4);
lifeexp=KeyFacts(:,5);
cyraw=KeyFacts(:,6);
annualhours=(1-lbar)*16*365;
stdhours=stdell*16*365;

lambda=Results(:,1); 
ytilde=Results(:,2);
[blah,isort]=sort(-lambda);

if exist('tle')==1;
    diary('LambdaRobust.log');
    disp ' '; disp ' ';
    disp '------------------------------------------------------- ';
    disp(tle);
    disp '------------------------------------------------------- ';
    disp ' ';
end;

run ../ShowParameters

disp ' '; disp ' ';
disp 'Reporting any negative utilities, by age and for Vmain at StartAge';
disp 'Number of ages for which each country has negative expected utility at that age:';
cshow(CountryInputs(:,1),NegUtil,'%8.0f','NumAges Vmain?');

disp ' '; disp ' ';
disp 'UNDERLYING MICRO DATA FOR LEVELS OF WELFARE';
disp ' ';
tle='cbar lbar stdlogc stdell lifeexp cyraw';
cshow(CountryInputs(isort,1),KeyFacts(isort,:),'%8.3f',tle);

disp ' '; disp ' ';
disp 'UNDERLYING MICRO DATA FOR LEVELS OF WELFARE -- Better units';
disp ' ';
fmt='%8.1f %8.3f %8.0f %8.3f %8.0f';
tle='lifeexp cbar/y hours stdlogc stdhours';
blah=[lifeexp cyraw annualhours stdlogc stdhours];
cshow(CountryInputs(isort,1),blah(isort,:),fmt,tle);

fmt='..&..&..&..&..\\my{%4.1f}.. &..\\my{%5.3f}.. &..\\my{%5.0f}.. &..\\my{%5.3f}.. &..\\my{%5.0f}..\\\\';
cshow(CountryInputs(isort,1),blah(isort,:),fmt,tle);


disp ' '; disp ' ';
disp 'MAIN RESULTS FOR LEVELS OF WELFARE';
disp ' ';

fmt='%8.1f %8.1f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f';
tle='lambda ytilde logRatio termLE termCY termell Cineq lineq';
cshow(CountryInputs(isort,1),Results(isort,:),fmt,tle,'latex');
cshow('Average       ',mean(Results),fmt,[],[],1);

c=corrcoef(log(lambda),log(ytilde)); disp ' ';
fprintf('The correlation between loglambda and logytilde is %4.3f\n',c(1,2));
fprintf('The median absolute deviation from 1 for lambda/y is %8.4f\n',median(abs(lambda./ytilde-1)));
fprintf('Std(loglambda) = %6.2f   Std(log y) = %6.2f\n',[std(log(lambda)) std(log(ytilde))]);
fprintf('Ratio of lambda US/Malawi = %8.1f\n',lambda(iUS)/lambda(iMWI));

diary off;
