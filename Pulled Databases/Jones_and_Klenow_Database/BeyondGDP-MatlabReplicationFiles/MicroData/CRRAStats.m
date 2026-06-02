% CRRAStats
%
%   Computes lambda welfare levels using 13 countries of micro data.
%   CRRA/Trabandt-Uhlig-Shimer version with clowerbar.
%
%   (Run ../SetParameters first to get baseline parameters.)

help CRRAStats

CountryInputs={
% 'Brazil'      'BRA'   2003  1   % Require single data set for cons and leis
 'China'       'CHN'   2002  0
% 'Spain'       'ESP'   2001  1 
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
%iMWI = find(strcmp(CountryInputs(:,2), 'MWI'));
if exist('CVEV')~=1; CVEV='EV'; end;  % Equivalent variation is default
if exist('clowerbar')~=1; clowerbar=0; end;

ubar=GetUbarMicroCRRA(ValueofLife2005dollars,FrischLSElasticity,theta,beta,g,40,gamma,clowerbar,Silent);
epsilon=FrischLSElasticity;  % Frisch elasticity

run ../ShowParameters

lambda=zeros(size(CountryInputs,1),1)*NaN;
NegUtil=zeros(size(CountryInputs,1),2)*NaN;
ytilde=lambda;

for i=1:size(CountryInputs,1);

    clear functions; % To clear the "persistent" command from lambdacrra80
    RefYear=cell2mat(CountryInputs(i,3));
    if RefYear>2007; RefYear=2007; end;
    CountryRef={'US' 'USA' RefYear 0};
    [l,yy,negutil]=lambdacrra80(CountryInputs(i,:),CountryRef,Silent,ubar,beta,g,theta,epsilon,gamma,clowerbar);
    lambda(i)=l*100; ytilde(i)=yy*100;
    NegUtil(i,:)=negutil';
end;



diary('LambdaRobust.log');
disp ' '; disp ' ';
disp '------------------------------------------------------- ';
disp(tle);
disp '------------------------------------------------------- ';
disp ' ';

disp ' '; disp ' ';
disp 'MAIN RESULTS FOR LEVELS OF WELFARE';
disp ' ';

run ../ShowParameters

fmt='%8.1f %8.1f %8.3f %8.0f %8.0f';
tle='lambda ytilde logRatio NegUtil Vmain<0?';
Results=[lambda ytilde log(lambda./ytilde) NegUtil];
[blah,isort]=sort(-lambda);

cshow(CountryInputs(isort,1),Results(isort,:),fmt,tle,'latex');
cshow('Average       ',mean(Results),fmt,[],[],1);

disp ' '; disp 'NegUtil denotes number of ages at which expected utility is negative';
c=corrcoef(log(lambda),log(ytilde)); disp ' ';
fprintf('The correlation between loglambda and logytilde is %4.3f\n',c(1,2));
fprintf('The median absolute deviation from 1 for lambda/y is %8.4f\n',median(abs(lambda./ytilde-1)));
fprintf('Std(loglambda) = %6.2f   Std(log y) = %6.2f\n',[std(log(lambda)) std(log(ytilde))]);
%fprintf('Ratio of lambda US/Malawi = %8.1f\n',lambda(iUS)/lambda(iMWI));

diary off;
