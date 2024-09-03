%% Howto create figures
% 2024-09-03
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% This sample script is dealing with the creation of simple diagrams (in
% Matlab called figures). Matlab is very powerful and can create many
% different graphics. This a a very short introduction only.
%
%   - for further reading use 'help figure' or 'doc figure' as starting
%     point in the Matlab help
%   - or search for 'graphics' in the Matlab help
%
% here is list of some important keywords (Matlab commands)
%   - figure, plot, hold, grid, xlabel, ylabel, title, legend
%
% just start this script (short cut 'F5') and get inspired

%% here we start

CleanMatlab = true; % true or false

% optionally clean Matlab
if CleanMatlab  % set to true/false to enable/disable cleaning
    clear;      % clear all variables from the workspace (see 'help clear')
    close all;  % close all figures
    clc;        % clear command window
end

% save figure(s) to file? 'SaveFigures' is used later on in the script
SaveFigures = true;  % true or false

% -------------------------------------------------------------------------
%% at the beginning we create a simple figure with a plot of two curves

% define plot range of parameter x
%x  = (0 : 0.05 : 5); % coarse steps    ==> faster computations
x = (0 : 0.001 : 5); % very fine steps ==> looks better in plots

% define two functions to plot:  y1 = f1(x) and y2 = f2(x)
y1 = 2* cos(3.5*pi*x) + 12.5;
y2 = 3* sin(5.5*pi*x) +  7.5;

% now create a figure and plot both functions
% plot command with two mandatory arguments for x and y data
%   third argument mit plot options is optional
%       e.g. 'r-*' means red ('r') color, solid ('-') line,
%                  and asterix ('*') to mark data points
%   you can add even more options in the way
%       ParameterName = ParameterValue
%       here with Diplayname which is used for a legend

% create new figure window  (or push to foreground when already existing)
% ==> next plot command will be done in current figure (in foreground)
% ==> you can select where to plot when several figures exist
myFig = figure(1);  % figure counter: 1, 2, 3 ...

% plot 1st curve
plot(x, y1, '-r', DisplayName = 'connector A');

% prevent overwritting the 1st plot
hold on;

% plot 2nd curve
% ==> plot will be added to previous plot   when 'hold on'
% ==> plot will overwrite previous plot     when 'hold off'
plot(x, y2, '-g', DisplayName = 'connector B');

% allow overwritting again ==> next plot command will start new plot again
hold off;

% beautify figure
grid on;             % show grid lines (or 'grid minor', grid off' ...)
xlim auto;           % select plot range for x-axis automatically
ylim([-0.2  15.2]);  % define a specific plot range for y-axis

% finally add axis labeling, title, and a legend to distinguish the curves
title('Current Consumtion of Test Circuit');
xlabel('Time (in s)' );
ylabel('Currents (in A)');
legend(Location = 'Best'); % or a specific Location = 'NorthEast' ...

%% finally we want to save the figures to file
% figure will be saved as shown on screen ==> check readability of text

if SaveFigures
    FileName = './myFigure_01.png';  % or *.bmp, *.tiff, *.jpg ...
    exportgraphics(myFig, FileName);
end

% -------------------------------------------------------------------------
%% instead of the 'plot' command you can also try out some other styles:
% semilogx  - Semi-log scale plot for x-axis
% semilogy  - same but            for y-axis
% loglog    - log scale plot for both axes
% stem      - plot discrete sequence data
% ...
% type 'doc' in command window to open the HELP CENTER
% go to category 'Documentation Home' =>  'Matlab' => 'Graphics'
% with lots of information about creating figures with helpful examples


%% this is the end

disp('Demontration howto create a figure with  done.');

return % end of file