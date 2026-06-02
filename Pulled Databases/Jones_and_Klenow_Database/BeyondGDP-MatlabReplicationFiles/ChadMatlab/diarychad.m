function []=diarychad(fname);

% function []=diarychad(fname);
% 
% Deletes the file 'fname.log' if it exits and opens it for diary.
% If fname.m exists, shows the help fname.m

if exist([fname '.log']); delete([fname '.log']); end;
diary([fname '.log']);
fprintf([fname '                 ' date]);
disp ' ';
disp ' ';
if exist([fname '.m']);
    eval(['help ' fname]);
end;
