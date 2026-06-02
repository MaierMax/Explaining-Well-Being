% AnnualHoursPWT80    6/5/13
%
%  Use the PWT80 data directly for hours rather than TED (PWT gets it
%  from TED anyway).



clear;

if exist('AnnualHoursPWT80.log'); delete('AnnualHoursPWT80.log'); end;
diary AnnualHoursPWT80.log;
fprintf(['AnnualHoursPWT80                 ' date]);
disp ' ';
disp ' ';
help AnnualHoursPWT80

load pwt80

KeyYears=[1980 2007]';
AnnualHours=avh(KeyYears-1949,:);


% Check some countries
cshow(' ',[KeyYears AnnualHours(:,[USA FRA JPN HKG SGP ARG])],'%7.0f','Years usa fra jpn hkg sgp arg');

%  Averages for 1980 and 2007
disp 'For 2007 missing values:'
disp 'We will use US 2007 value to fill in any missing data';
disp 'For 1980 missing values: use 2007 value if it exists, otherwise US2007';

annualhours2007=AnnualHours(2,:)';
missinghours2007=isnan(annualhours2007);
annualhours2007=replace(annualhours2007,isnan(annualhours2007),annualhours2007(USA));
disp ' ';

annualhours1980=AnnualHours(1,:)';
missinghours1980=isnan(annualhours1980);
annualhours1980(missinghours1980)=annualhours2007(missinghours1980);
disp ' ';

cshow(names,[annualhours1980 annualhours2007],'%8.0f','1980 2007');

fprintf('We have hours data for this many countries in 2007: %4.0f\n',sum(~missinghours2007));
length(missinghours2007)

save AnnualHoursPWT80 AnnualHours annualhours1980 annualhours2007 missinghours1980 missinghours2007;

diary off;

