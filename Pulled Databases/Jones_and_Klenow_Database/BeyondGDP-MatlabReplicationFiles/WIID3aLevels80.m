% WIID3aLevels80.m  
%
% 8/12/14 -- Version 3a of WIID from June 2014
% 6/4/13  -- pwt80
% 1/29/13 -- PWT71
% 3/1/12 -- Take most recent 3 years since 1997.
%
% 8/16/11 -- Update to PWT70 order. Also keep track of which countries are
% based on consumption data and which are not.
%
% 12/16/10 -- Distinguish "disposable" income (after tax/transfer)
%             (treat similarly to consumption; project nondisp income if needed)
% 9/14/09 -- Updated to PWT6.3 order.
%
%   XCRatio the WIID2c data set.
%
%   In cleaning the csv file, I did the following:
%     1. na ==> NaN
%     2. Delete quotes
%     3. Separated by semicolon's
%   Then the file can be read with matlab's textread command.
%
%   CROSS SECTIONAL version -- no attempt at time series.
%   This version takes all data between 1990 and 200x and averages it,
%   separately for income and consumption.
%
%   Then projects in order to impute as consumption ginis...
%   4/20/09:  XCRatio -- imputes based solely on Ratio=.85
%
%   Data actually go through 2012 in some cases.

if exist('WIID3aLevels80.log'); delete('WIID3aLevels80.log'); end;
diary WIID3aLevels80.log;
fprintf(['WIID3aLevels80                 ' date]);
disp ' ';
disp ' ';
help WIID3aLevels80



clear;
%Country;Year;Mean;Median;Gini;Welfaredefn;IncSharU;UofAnala;Equivsc;PopCovr;AreaCovr;AgeCovr;Countrycode;Source_Comments;Source;D1;D2;D3;D4;D5;D6;D7;D8;D9;D10;Q1;Q2;Q3;Q4;Q5;P5;P95;Currency;Revision;Quality

fmt='%s %f %f %f %f %s %s %s %s %s %s %s %s %s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %f %f';
[wCountry,wyear,Mean,Median,wgini,WelfareDefn,IncSharU,UofAnala,Equivsc,PopCovr,AreaCovr,AgeCovr,Countrycode,Source_Comments,Source,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,Q1,Q2,Q3,Q4,Q5,P5,P95,Currency,Revision,Quality]=textread('WIID3a.csv',fmt,'delimiter','#','headerlines',2,'emptyvalue',NaN);

AfterThisYear=2000   % Starting year to consider
ClosetoThisYear=2007 % This is our most desired year
MostAppropriateNyears=3      % The 3 years closest

% The various quality threshholds, by concept:
ConsQuality=3
DispIncQuality=2
GrossIncQuality=2  % Don't use Gross Incomes, only Disposable


% Now we need to read each line of the database and create the gini matrix
% Year x Country, in the pwt80 order

load pwt80;
numRec=length(Countrycode);
N=length(codes);
Nyrs=length(years);  % 1950-2010

% Let's list the categories in AreaCovr
AreaCats={'All'};
for i=1:numRec;
   if any(ismember(AreaCats,AreaCovr(i)))==0;
     AreaCats=[AreaCats; AreaCovr(i)]; % Add to our list;
   end;
end;
AreaCats

% List the categories in WelfareDefn
AllCats={'Consumption'};
for i=1:numRec;
   if any(ismember(AllCats,WelfareDefn(i)))==0;
     AllCats=[AllCats; WelfareDefn(i)]; % Add to our list;
   end;
end;
AllCats

ConsCats={
     'Consumption'
  }

DispIncCats={
     'Monetary Income, Disposable'
     'Income,Disposable'
     'Disposable Income'
     'Monetary Income, Disposable, excl. self-empl. and property income'
     'Income Disposable, from taxable items'
     'Taxable Income, Disposable'
     'Monetary Income, Disposable (excluding property income)'
   }

% Here are the cateogories:
%
%  Note: The "Income/Consumption" category looks useless. It appears to be
%        taken from WDI and duplicates other records. So I'm not using it.
% 
%AllCats = 
    % 'Consumption'
    % 'Income/Consumption'
    % 'Income'
    % 'Monetary Income, Disposable'
    % 'Income, ..'
    % 'Primary Income'
    % 'Income, Gross'
    % 'Income,Disposable'
    % 'Earnings, Gross'
    % 'Monetary Income'
    % 'Taxable Income, Net'
    % 'Taxable Income, Gross'
    % 'Monetary Income, Gross'
    % 'Market Income'
    % 'Disposable Income'
    % 'Monetary Income, Disposable, excl. self-empl. and property income'
    % 'Income Disposable, from taxable items'
    % 'Taxable Income'
    % 'Taxable Income, Disposable'
    % 'Earnings, Net'
    % 'Monetary Income, ..'
    % ''
    % 'Income,Net'
    % 'Earnings, ..'
    % 'Income, Factor'
    % 'Factor Income'
    % 'Monetary Income, Disposable (excluding property income)'
    % 'Taxable Income, property income excluded'
    % 'Taxable Income, Gross incl deductions'


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Steps:  Do this for Income and then for Consumption
%  1. Throw out observations from excluded categories:
%         -- not "All" in AreaCovr, Quality>3
%  2. Gather all the records for a given country.
%  3. Find the key years I'm looking for and average them
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NonDisp INCOME 
disp ' '; disp ' ';
disp '*************************************************************';
disp '* NON-DISPOSABLE INCOME';
disp '*************************************************************';

keepit=~ismember(WelfareDefn,ConsCats);  % Keep Income
keepit=keepit.*(~ismember(WelfareDefn,DispIncCats));  % Keep only NonDisposable Income
keepit=keepit.*(~ismember(WelfareDefn,{'Income/Consumption'}));  % Drop "Income/Consumption"
keepit=keepit.*(Quality<=GrossIncQuality);
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=AfterThisYear); 
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniNonInc=zeros(N,1)*NaN;

i=1;
while i<=numRec;
  if keepit(i);  % If this record is a keeper
    j=i;         % Current record
    ctry=Countrycode(i);
    data=[];
    while ismember(ctry,Countrycode(j));
        if keepit(j);
          data=[data; wyear(j) wgini(j)];
        end;
        j=j+1; if j>numRec; break; end;
    end;
    % Now sort by year
    if size(data,1)>1;
      [blah,isort]=sort(data);
      data=data(isort(:,1),:);
    end;

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data,'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(data(:,2)));
    data=packr(data); % Drop missing values
    cyear=data(:,1);
    cgini=data(:,2);    
    [blah ii]=sort(abs(cyear-ClosetoThisYear));
    meanN=mean(cgini(ii(1:min([length(ii) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniNonInc(' cell2mat(ctry) ')=meanN;']);       
    else;
      fprintf(['No country: ' cell2mat(ctry)]); disp ' ';
    end;
    
    i=j-1;  % Update i so that it points to last obs of same country
  end; %if keepit
  i=i+1;
end;


% DISPOSABLE INCOME 
disp ' '; disp ' ';
disp '*************************************************************';
disp '* DISPOSABLE INCOME';
disp '*************************************************************';

%Keep DispInc numbers even if Quality=NaN if Revision==5

keepit=~ismember(WelfareDefn,ConsCats);  % Keep Income
keepit=keepit.*ismember(WelfareDefn,DispIncCats);  % Keep only Disposable Income
keepit=keepit.*( (Quality<=DispIncQuality) | (isnan(Quality) & Revision==5));
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=AfterThisYear);  % Everything after year
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniDispInc=zeros(N,1)*NaN;

i=1;
while i<=numRec;
  if keepit(i);  % If this record is a keeper
    j=i;         % Current record
    ctry=Countrycode(i);
    data=[];
    while ismember(ctry,Countrycode(j));
        if keepit(j);
          data=[data; wyear(j) wgini(j)];
        end;
        j=j+1; if j>numRec; break; end;
    end;
    % Now sort by year
    if size(data,1)>1;
      [blah,isort]=sort(data);
      data=data(isort(:,1),:);
    end;

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data,'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(data(:,2)));
    data=packr(data); % Drop missing values
    cyear=data(:,1);
    cgini=data(:,2);    
    [blah ii]=sort(abs(cyear-ClosetoThisYear));
    meanN=mean(cgini(ii(1:min([length(ii) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniDispInc(' cell2mat(ctry) ')=meanN;']);       
    else;
      fprintf(['No country: ' cell2mat(ctry)]); disp ' ';
    end;
     
    i=j-1;  % Update i so that it points to last obs of same country
  end; %if keepit
  i=i+1;
end;


% CONSUMPTION 

disp ' '; disp ' ';
disp '*************************************************************';
disp '* CONSUMPTION';
disp '*************************************************************';

%Keep Consumption numbers even if Quality=NaN if Revision==5

keepit=ismember(WelfareDefn,ConsCats);  % Keep consumption
keepit=keepit.*( (Quality<=ConsQuality) | (isnan(Quality) & Revision==5));
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=AfterThisYear);  % Everything after this year
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniCons=zeros(N,1)*NaN;

i=1;
while i<=numRec;
  if keepit(i);  % If this record is a keeper
    j=i;         % Current record
    ctry=Countrycode(i);
    data=[];
    while ismember(ctry,Countrycode(j));
        if keepit(j);
          data=[data; wyear(j) wgini(j)];
        end;
        j=j+1; if j>numRec; break; end;
    end;
    % Now sort by year
    if size(data,1)>1;
      [blah,isort]=sort(data);
      data=data(isort(:,1),:);
    end;

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data,'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(data(:,2)));
    data=packr(data); % Drop missing values
    cyear=data(:,1);
    cgini=data(:,2);
    [blah ii]=sort(abs(cyear-ClosetoThisYear));
    meanN=mean(cgini(ii(1:min([length(ii) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniCons(' cell2mat(ctry) ')=meanN;']);       
    else;
      fprintf(['No country: ' cell2mat(ctry)]); disp ' ';
    end;
    
    i=j-1;  % Update i so that it points to last obs of same country
  end; %if keepit
  i=i+1;
end;


figure(1); figsetup;
plotreg(giniDispInc,giniCons,codes,1);
ax=axis; ax(1)=20; axis(ax);
%hold on;
%x=(22:77)'; ff=exp(beta(1)+beta(2)*log(x));
%plot(x,ff,'b-');
chadfig('DispIncome Gini','Consumption Gini',1,0);
print WIID3aLevels801.ps

figure(2); figsetup;
plotreg(giniNonInc,giniDispInc,codes,1);
ax=axis; ax(1)=20; axis(ax);
%hold on;
%x=(22:77)'; ff=exp(beta(1)+beta(2)*log(x));
%plot(x,ff,'b-');
chadfig('NonDispInc Gini','DispIncome Gini',1,0);
print WIID3aLevels801b.ps

% The Ratio criterion
avgIncratio=meannan(giniDispInc./giniNonInc);
fprintf('The average ratio of giniNon / giniDisp is %6.4f\n',avgIncratio);
avgConsratio=meannan(giniCons./giniDispInc);
fprintf('The average ratio of giniC / giniY is %6.4f\n',avgConsratio);


GrossMissing=isnan(giniNonInc);

% Now do the projection to impute DispInc ginis
Dmissing=isnan(giniDispInc);
GiniDisp=giniDispInc; % Original
Forecast=avgIncratio*giniNonInc; % Impute
GiniDisp(Dmissing)=Forecast(Dmissing); % Replace missing with imputed


% Now do the projection to impute Consumption ginis
smplConsGini=~isnan(giniCons);
Cmissing=isnan(giniCons);
GiniConsumption=giniCons; % Original
Forecast=avgConsratio*GiniDisp; % Impute
GiniConsumption(Cmissing)=Forecast(Cmissing); % Replace missing with imputed


% Plot to "see" the imputations
figure(3); figsetup;
plotname(giniNonInc(Dmissing),GiniDisp(Dmissing),codes(Dmissing),8,'b')
hold on;
plotname(giniNonInc,giniDispInc,codes)
ax=axis; ax(1)=20; axis(ax);
chadfig('NonIncome Gini','DispInc Gini',1,0);
print WIID3aLevels802a.ps

figure(4); figsetup;
plotname(giniDispInc(Cmissing),GiniConsumption(Cmissing),codes(Cmissing),8,'b')
hold on;
plotname(giniDispInc,giniCons,codes)
ax=axis; ax(1)=20; axis(ax);
chadfig('Income Gini','Consumption Gini',1,0);
print WIID3aLevels802b.ps

% Finally, show the final data
disp ' '; disp ' ';
disp '*****************************************************************';
disp ' '; disp 'The final consumption ginis';
disp 'The columns are';
disp ' NonInc  = Non-Disposable Income gini';
disp ' DispInc = Disposable Income gini';
disp ' GiniDisp= Disposable Income gini, including fitted';
disp ' Cons    = Consumption gini (data)';
disp ' Forecast= Forecast of cons gini based on Ratio';
disp ' Final   = Cgini when data, or Ratio*IncGini';
disp '*****************************************************************';
cshow(namesSTR,[giniNonInc giniDispInc GiniDisp giniCons Forecast GiniConsumption],'%10.1f','NonInc DispInc Fitted Cons Forecast Final');


% Create the missing data variable
GiniMissing=zeros(length(Cmissing),1)*NaN;
GiniMissing(smplConsGini)=1;  % Consumption
GiniMissing(Cmissing & (~Dmissing))=2;  % Disp Y
GiniMissing(Cmissing & Dmissing & (~GrossMissing))=3;  % Income
GiniMissing(Cmissing & Dmissing & GrossMissing)=4;  % Missing all gini ==> US Value

disp ' ';
fprintf('We have original consumption ginis for %3.0f countries\n',sum(smplConsGini));
fprintf('We have final ginis for %3.0f countries\n',sum(GiniMissing~=4));
fprintf('   Original Consump Ginis:  %3.0f\n',sum(GiniMissing==1));
fprintf('   Original DispInc Ginis:  %3.0f\n',sum(GiniMissing==2));
fprintf('   Original GrosInc Ginis:  %3.0f\n',sum(GiniMissing==3));
fprintf('   No Gini data (US value): %3.0f\n',sum(GiniMissing==4));


disp ' ';
disp 'Now, list the countries...';
fprintf('   Original Consumption Ginis:  %3.0f\n',sum(smplConsGini));
say(namesSTR(smplConsGini,:)); disp ' '; disp ' ';
fprintf('   Original DispInc Ginis:  %3.0f\n',sum(Cmissing & (~Dmissing)));
say(namesSTR(Cmissing & (~Dmissing),:)); disp ' '; disp ' ';
fprintf('   Original GrosInc Ginis:  %3.0f\n',sum(Cmissing & Dmissing & (~GrossMissing)));
say(namesSTR(Cmissing & Dmissing & ~GrossMissing,:)); disp ' '; disp ' ';
fprintf('   No Gini Data at all (US value): %3.0f\n',sum(GiniMissing==4));
say(namesSTR(GiniMissing==4,:)); disp ' '; disp ' ';

disp ' ';
disp 'Assigning US value to all countries missing data';
GiniConsumption(GiniMissing==4)=GiniConsumption(USA);


save WIIDGiniLevels80 GiniConsumption GiniMissing

diary off;



% Notes "EPHC" = Argentina geographic coverage -- mainly large urban areas
%     http://www.depeco.econo.unlp.edu.ar/cedlas/monitoreo/pdfs/review_argentina.pdf
