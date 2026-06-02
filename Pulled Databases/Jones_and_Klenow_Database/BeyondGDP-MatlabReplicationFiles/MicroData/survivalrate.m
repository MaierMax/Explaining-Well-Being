function S=survivalrate(age,year,country);   % 6/25/13

% function S=survivalrate(age,year,country);
%
% Returns the cumulative survival rate for age/year/country.
% Based on WHOSurvivalRate2013.m data for 1990/2000/2011 with
% course age categories.
%  -- Interpolates linearly on both the age and time dimension
%     That is, we have 1990 and 2000 years and 17 and 22 ages
%     and may be asked to provide 1993 survival rate for a 21 year old;

global survivaldata survivalyears survivalages
global Brazil China France Germany India Indonesia Malawi Mexico SouthAfrica US Italy Russia Spain UK

%load WHOSurvivalRate2013

cty=eval(country);

% First interpolate by age for all three years.  Then get the year right.

S1=interp1(survivalages,survivaldata(:,1,cty),age,'linear');
S2=interp1(survivalages,survivaldata(:,2,cty),age,'linear');
S3=interp1(survivalages,survivaldata(:,3,cty),age,'linear');

if year<1990; disp 'Using 1990 for initial survival rate...'; year=1990; end;
S=interp1(survivalyears,[S1 S2 S3],year,'linear');

% Note: When using 1990 for initial survival rates, we will have a
% correction in the lambdastats80 file to use the average *annual* LE term
% between 1990 and whatever the end year is...
%
%  E.g. if 1984-2006 is our growth rate, then we will use 1990-2006 average
%  annual growth in the LE term.


