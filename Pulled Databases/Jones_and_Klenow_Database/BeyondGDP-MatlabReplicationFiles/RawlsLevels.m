% RawlsLevels    8/25/14
%
%  Masterfile for levels results. Currently calls Rawls15.m after picking various parameters
%  and calls PlotBasicResults for the main results graphs.

if exist('RawlsLevels.log'); delete('RawlsLevels.log'); end;
diary RawlsLevels.log;
fprintf(['RawlsLevels                 ' date]);
disp ' ';
disp ' ';
help RawlsLevels

clear all; clc
SetParameters;
MakeData15;

% Key countries to show
%ctys=[USA FRA ITA DEU GBR ISR JPN HKG SGP KOR MEX RUS BRA THA IDN ZAF IND BWA CHN MWI]';
ctys=[USA FRA NOR SWE DEU IRL JPN HKG SGP KOR CHL THA VNM ZAF BWA ARG ZWE KEN]';
namethese=zeros(length(y),1);
namethese(ctys)=1;

Rawls15
PlotBasicResults
% PlotBasicData  % The basic data plots; unnecessary now we'll use the micro results


diary off;
