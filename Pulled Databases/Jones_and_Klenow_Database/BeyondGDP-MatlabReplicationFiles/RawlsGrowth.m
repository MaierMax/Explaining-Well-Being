% RawlsGrowth    8/25/14
%
%  Masterfile for levels results. Currently calls Rawls15.m after picking various parameters
%  and calls PlotBasicResults for the main results graphs.

if exist('RawlsGrowth.log'); delete('RawlsGrowth.log'); end;
diary RawlsGrowth.log;
fprintf(['RawlsGrowth                 ' date]);
disp ' ';
disp ' ';
help RawlsGrowth

clear all; clc

MakeDataGrowth15;

% Parameters
SetParameters;

% Key countries to show
ctys=[CHN KOR MUS HKG SGP IDN EGY THA TUR MYS IND IRL JPN ITA FRA GBR BWA USA BRA MEX COL ZAF CIV]';
namethese=zeros(length(y),1);
namethese(ctys)=1;

Growth15
%PlotBasicResults
% PlotBasicData  % The basic data plots; unnecessary now we'll use the micro results


diary off;
