function []=relabelaxis(vals,labs,whichaxis);

% function []=relabelaxis(vals,labs,whichaxis);
%
% Assigns the labels in "labs" to the values in "vals" 
% to the axis label in "whichaxis"
%
% Note: labs can be a collection of cells or strmat

if ~exist('whichaxis')==1; whichaxis='y'; end;

if whichaxis=='x';
    set(gca,'XTick',vals);
    set(gca,'XTickLabel',labs);
    % Also adjust XLim in case one of labels is outside the range:
    curlim=get(gca,'XLim');
    curlim(1)=min([curlim(1) min(vals)]');
    curlim(2)=max([curlim(2) max(vals)]');
    set(gca,'XLim',curlim);
else;
    set(gca,'YTick',vals);
    set(gca,'YTickLabel',labs);
    % Also adjust YLim in case one of labels is outside the range:
    curlim=get(gca,'YLim');
    curlim(1)=min([curlim(1) min(vals)]');
    curlim(2)=max([curlim(2) max(vals)]');
    set(gca,'YLim',curlim);
end;