%% Howto save data as MAT-file (and read in the data later again)
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% This sample script is dealing with writing and reading data in binary
% format (Matlab-specific MAT-file).
% Pros:
%   + easy to use
%   + all variable types in Matlab can be used
%   + compact
% Cons:
%   - Matlab specific
%   - tricky to read without Matlab
%
%   * for further reading type e.g. 'doc save'
%   * relevant Matlab keywords are
%     - save / load
%
% just start this script (short cut 'F5') and get inspired

%% here we start

CleanMatlab = true;  % true or false

% optionally clean Matlab
if CleanMatlab  % set to true/false to enable/disable cleaning
    clear;      % clear all variables from the workspace (see 'help clear')
    close all;  % close all figures
    clc;        % clear command window
end

% -------------------------------------------------------------------------
%% here we go

% definition of some data we want to save
x  = (0 : 0.4 : 10);
y1 = 3.5 * sin(2*pi*x + 0.21);
y2 = 1.3 * log10(5*x + 0.1);

% the variables x, y1, and y2 are floating point numbers (double)
% ==> there are different ways to save data
% ==> here we only deal with the use of MAT-files (Matlab data)

% definition of a filename
FileNameBase  = 'myDataFile';
TimeStamp     = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
FileExtension = '.mat';
% merge all parts
FileName      = [FileNameBase '_' TimeStamp FileExtension];

% and save data in file (list all variables you want to save)
save(FileName, 'x', 'y1', 'y2')

% check what is inside your saved file
disp('show details about content of mat-file:');
whos('-file', FileName)

% there are lot of options
% ==> see 'doc save'
% ==> for later use when you are an expert

%% finally we want to read in the data again

% clear some data before
clear myData x y*;

% read file and load saved variables to workspace again
load(FileName);

% here are the data vectors again (show first elements only)
disp('first values of read data:');
disp( x(1:5));
disp(y1(1:5));
disp(y2(1:5));

disp('Howto Script Done.');

return % end of file