% WIID3aGrowth80.m  
%
%  8/12/14  -- pwt80 and WIID3a
%
%         "1980" = 3 years closest to 1980, between 1975 and 1985
%         "2007" = 3 most recent years after 2000 (similar to Levels)
%
% 12/28/10 -- Distinguish "disposable" income (after tax/transfer)
%             (treat similarly to consumption; project nondisp income if needed)
%          -- Return 2000 level from WIID2cXCRatio63disp if missing values
%
% 9/16/09 -- PWT 6.3 order
%
%   Growth the WIID2c data set.
%
%   In cleaning the csv file, I did the following:
%     1. na ==> NaN
%     2. Delete quotes
%     3. Separated by semicolon's
%   Then the file can be read with matlab's textread command.
%
%   Time series version of ginis. Require either two incomes or two
%   consumption ginis; do not mix.
%     -- 1980 =  1974 - 1986 data
%        2000 =  1994 - 2004 data
%
%   Then projects in order to impute as consumption ginis...
%   4/20/09:  Growth -- imputes based solely on Ratio=.85

if exist('WIID3aGrowth80.log'); delete('WIID3aGrowth80.log'); end;
diary WIID3aGrowth80.log;
fprintf(['WIID3aGrowth80                 ' date]);
disp ' ';
disp ' ';
help WIID3aGrowth80



clear;
load WIIDGiniLevels80
GiniLevel2007=GiniConsumption;  % To use as constant for missing values at end

fmt='%s %f %f %f %f %s %s %s %s %s %s %s %s %s %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %f %f';
[wCountry,wyear,Mean,Median,wgini,WelfareDefn,IncSharU,UofAnala,Equivsc,PopCovr,AreaCovr,AgeCovr,Countrycode,Source_Comments,Source,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,Q1,Q2,Q3,Q4,Q5,P5,P95,Currency,Revision,Quality]=textread('WIID3a.csv',fmt,'delimiter','#','headerlines',2,'emptyvalue',NaN);

% 1980 - 2007
YearRange1980=[1975 1985]
YearRange2007=[2000 2012]
MostAppropriateNyears=3   % Max # of observations to average

% The various quality threshholds, by concept:
ConsQuality=3
DispIncQuality=2
GrossIncQuality=2


% Now we need to read each line of the database and create the gini matrix
% Year x Country, in the pwt80 order
load pwt80;
numRec=length(Countrycode);
N=length(codes);
Nyrs=length(years);  



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
keepit=keepit.*(Quality<=GrossIncQuality);
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=YearRange1980(1)); 
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniNonInc=zeros(N,2)*NaN;

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
    cyear=data(:,1);
    
    
    % First, get the 1980 observation = 1975 - 1985
    indx=find(cyear>=YearRange1980(1) & cyear<=YearRange1980(2));
    cgini=data(indx,2);

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));
    
    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i80]=sort(abs(cyear-1980)); 
    meanN=mean(cgini(i80(1:min([length(i80) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniNonInc(' cell2mat(ctry) ',1)=meanN;']);       
    end;
    
    % Next, get the 2007 observation 
    cyear=data(:,1);
    indx=find(cyear>=YearRange2007(1) & cyear<=YearRange2007(2));
    cgini=data(indx,2);
    
    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));

    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i07]=sort(abs(cyear-2007)); 
    meanN=mean(cgini(i07(1:min([length(i07) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniNonInc(' cell2mat(ctry) ',2)=meanN;']);       
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

keepit=~ismember(WelfareDefn,ConsCats);  % Keep Income
keepit=keepit.*ismember(WelfareDefn,DispIncCats);  % Keep only Disposable Income
keepit=keepit.*( (Quality<=DispIncQuality) | (isnan(Quality) & Revision==5));
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=YearRange1980(1));  % Everything after year
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniDispInc=zeros(N,2)*NaN;

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
    cyear=data(:,1);
    
    % First, get the 1980 observation = 1975 - 1985
    indx=find(cyear>=YearRange1980(1) & cyear<=YearRange1980(2));
    cgini=data(indx,2);

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));
    
    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i80]=sort(abs(cyear-1980)); 
    meanN=mean(cgini(i80(1:min([length(i80) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniDispInc(' cell2mat(ctry) ',1)=meanN;']);       
    end;
    
    % Next, get the 2007 observation 
    cyear=data(:,1);
    indx=find(cyear>=YearRange2007(1) & cyear<=YearRange2007(2));
    cgini=data(indx,2);
    
    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));

    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i07]=sort(abs(cyear-2007)); 
    meanN=mean(cgini(i07(1:min([length(i07) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniDispInc(' cell2mat(ctry) ',2)=meanN;']);       
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


keepit=ismember(WelfareDefn,ConsCats);  % Keep consumption
keepit=keepit.*( (Quality<=ConsQuality) | (isnan(Quality) & Revision==5));
keepit=keepit.*ismember(AreaCovr,'All').*ismember(PopCovr,'All');
keepit=keepit.*(wyear>=YearRange1980(1));  % Everything after this year
fprintf('Total number of records kept: %5.0f\n',sum(keepit));


% Now step through the records;
giniCons=zeros(N,2)*NaN;

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
    cyear=data(:,1);
    
    % First, get the 1980 observation = 1975 - 1985
    indx=find(cyear>=YearRange1980(1) & cyear<=YearRange1980(2));
    cgini=data(indx,2);

    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));
    
    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i80]=sort(abs(cyear-1980)); 
    meanN=mean(cgini(i80(1:min([length(i80) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniCons(' cell2mat(ctry) ',1)=meanN;']);       
    end;
    
    % Next, get the 2007 observation
    cyear=data(:,1);
    indx=find(cyear>=YearRange2007(1) & cyear<=YearRange2007(2));
    cgini=data(indx,2);
    
    % Show the underlying data
    disp ' '; disp(ctry);
    cshow(' ',data(indx,:),'%8.0f %8.2f');
    fprintf('Mean: %8.2f\n',mean(cgini));

    pdata=packr(data(indx,:)); % Drop missing values
    cyear=pdata(:,1);
    cgini=pdata(:,2);
    [blah i07]=sort(abs(cyear-2007)); 
    meanN=mean(cgini(i07(1:min([length(i07) MostAppropriateNyears]))));
    fprintf('Mean for N closest years: %8.2f\n',meanN);
    if exist(cell2mat(ctry));
      eval(['giniCons(' cell2mat(ctry) ',2)=meanN;']);       
    end;    
        
    i=j-1;  % Update i so that it points to last obs of same country
  end; %if keepit
  i=i+1;
end;



%%%%%%%%%%%%%%%%%%%%%
% IMPUTE 
%%%%%%%%%%%%%%%%%%%%%

% The Ratio criterion
avgIncratio=meannan(giniDispInc./giniNonInc);
fprintf('The average ratio of giniDisp / giniNon is %6.4f %6.4f\n',avgIncratio);
avgIncratio=mean(avgIncratio')
avgConsratio=meannan(giniCons./giniDispInc);
fprintf('The average ratio of giniC / giniDisp is %6.4f %6.4f\n',avgConsratio);
avgConsratio=mean(avgConsratio')

GrossMissing=isnan(giniNonInc);
GrossMissing=any(GrossMissing')';

% Now do the projection to impute DispInc ginis
Dmissing=isnan(giniDispInc);
Dmissing=any(Dmissing')'; % missing in either year then put income for both
GiniDisp=giniDispInc; % Original
Forecast=avgIncratio*giniNonInc; % Impute
GiniDisp(Dmissing,:)=Forecast(Dmissing,:); % Replace missing with imputed

% Now do the projection to impute Consumption ginis
Cmissing=isnan(giniCons);
Cmissing=any(Cmissing')'; % missing in either year then put income for both
smplConsGini=~Cmissing;
GiniConsumption=giniCons; % Original
Forecast=avgConsratio*GiniDisp; % Impute
GiniConsumption(Cmissing,:)=Forecast(Cmissing,:); % Replace missing with imputed

% Replace finalmissing with 2007 value from WIID2cXCRatio71 for *both* years
finalmissing=any(isnan(GiniConsumption)');
GiniConsumption(finalmissing,1)=GiniLevel2007(finalmissing);
GiniConsumption(finalmissing,2)=GiniLevel2007(finalmissing);
MissingGini=finalmissing;
fprintf('The number of countries for which we have 1980 and 2007 true data = %3.0f\n',sum(~finalmissing));



% Plot to "see" the imputations
figure(1); figsetup;
plotname(GiniDisp(~Dmissing,1),GiniDisp(~Dmissing,2),codes(~Dmissing),8,'b')
hold on;
plotname(GiniDisp(Dmissing,1),GiniDisp(Dmissing,2),codes(Dmissing),8,'g')
ax=axis; ax(1)=20; ax(2)=60; ax(3)=20; ax(4)=60; axis(ax);
%plot([20 55],[20 55]);
title('Disp Income');
chadfig('1980','2000',1,0);
print WIID3aGrowth80D.ps

figure(2); figsetup;
plotname(GiniConsumption(~Cmissing,1),GiniConsumption(~Cmissing,2),codes(~Cmissing),8,'b')
hold on;
plotname(GiniConsumption(Cmissing,1),GiniConsumption(Cmissing,2),codes(Cmissing),8,'g')
%ax=axis; ax(2)=60; axis(ax);
%plot([20 55],[20 55]);
title('Consumption');
chadfig('1980','2000',1,0);
print WIID3aGrowth80C.ps


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
cshow(namesSTR,[giniNonInc giniDispInc giniCons GiniConsumption],'%10.1f','Non80 N2007 Disp80 D2007 Cons80 C2007 Final80 F2007');


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
fprintf('  No Gini data (Constant): %3.0f\n',sum(GiniMissing==4));

disp ' ';
nn=sum(all(~isnan(GiniConsumption'))');
%nn=sum(GiniConsumption~=0);
fprintf('The number of countries for which we have 1980 and 2007 data = %3.0f\n',nn(1));

save WIIDGiniGrowth80 GiniConsumption MissingGini

diary off;
