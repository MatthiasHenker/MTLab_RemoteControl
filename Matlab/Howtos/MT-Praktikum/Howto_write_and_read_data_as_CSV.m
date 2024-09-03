%% Howto save data as CSV-file (and read in the data later again)
% 2024-09-03
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% This sample script is dealing with writing and reading data in CSV
% format (comma separated values). The files contain all data in text form.
% Pros:
%   + files can be used in a very flexible way (see following lines))
%   + files (data) are human readable
%   + can be read on different platforms (windows, linux, macos)
%   + or by different software (Excel, Matlab, Python, ...)
% Cons:
%   - larger file size (than binary),
%   - slow read/write speed on large files
%   - be careful, to avoid conversion errors
%
%   * for further reading type e.g. 'doc writematrix'
%   * relevant Matlab keywords are
%     - writematrix / readmatrix
%     - writetable  / readtable
%     - csvwrite    / csvread    (obsolete)
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
% ==> here we only deal with the use of CSV-files (data in text form)

% define filename with timestamp to distinguish different files
TimeStamp    = datetime('now', TimeZone = 'local', Format = 'yyyy-MM-dd__HH-mm-ss');
FileName_row = ['myDataFile_with_row_vectors_'    char(TimeStamp) '.csv'];
FileName_col = ['myDataFile_with_column_vectors_' char(TimeStamp) '.csv'];

% we combine all data to a single matrix
% option 1: 1st row for x-data
%           2nd row for y1-data
%           3rd row for y2-data
myData = [x ; y1 ; y2];
% and write data to file (values separated by ';')
writematrix(myData, FileName_row, Delimiter = ';');

% option 2: 1st column for x-data
%           2nd column for y1-data
%           3rd column for y2-data
myData = [x' y1' y2'];
% save to another file to prevent overwriting first file
writematrix(myData, FileName_col, Delimiter = ';');

% you can also include headers with names of variables
% ==> see 'doc table' and 'doc writetable'
% ==> for later use when you are an expert

%% now check the created files with a file explorer
% ==> open the files with a standard editor
% ==> or open them with Excel
%       Attention: for german users: set use of ',' and '.' correctly
%       - Excel -> Datei -> Optionen -> Erweitert ->
%           Trennzeichen vom Betriebssystem übernehmen: NEIN
%           Dezimaltrennzeichen:   '.'
%           Tausendertrennzeichen: ','


%% finally we want to read in the data again (option 1)

% clear all previous data
clear myData x y*;

% read file (option 1)
myData = readmatrix(FileName_row, Delimiter = ';');
% and extract data
x  = myData(1, :);    % 1st row
y1 = myData(2, :);    % 2nd row
y2 = myData(3, :);    % 3rd row

% here are the data vectors again (show first elements only)
disp('first values of read data:');
disp( x(1:5));
disp(y1(1:5));
disp(y2(1:5));

%% finally we want to read in the data again (option 2)

% clear some data
clear myData x y*;

% read file (option 2)
myData = readmatrix(FileName_col, Delimiter = ';');
% and extract data
x  = myData(:, 1)';   % 1st column
y1 = myData(:, 2)';   % 2nd column
y2 = myData(:, 3)';   % 3rd column

% here are the data vectors again (show first elements only)
disp('first values of read data:');
disp( x(1:5));
disp(y1(1:5));
disp(y2(1:5));

% final statement: which option is better?
disp('Writing data in column vectors to CSV-files is the better option!');
disp('  - maximum length of line in text files is no problem then.');
disp('  - it is easier to read when you check content of CSV-files.');
disp('Howto Script Done.');

return % end of file