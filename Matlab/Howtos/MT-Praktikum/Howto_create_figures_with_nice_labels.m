%% Howto create figures
% 2024-09-07
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
%% at the beginning we create a simple figure with a plot of a single curve

% define plot range of parameter x
%x  = (0 : 0.05 : 5); % coarse steps    ==> faster computations
x = (0 : 0.001 : 5); % very fine steps ==> looks better in plots

% define  function to plot:  y = f(x)
y = 2* cos(3.5*pi*x) + 12.5;

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

% plot 1st curve (r = red, g = green, b = blue, k = black, m = magenta ...)
plot(x, y, '-r', DisplayName = 'curve: y = f(x)', LineWidth= 2);

% beautify figure
grid on;             % show grid lines (or 'grid minor', grid off' ...)
xlim auto;           % select plot range for x-axis automatically
ylim([9  16]);      % define a specific plot range for y-axis

% finally add axis labeling, title, and a legend to distinguish the curves
title('My title of this diagram');
xlabel('x-axis' );
ylabel('y-axis');
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

disp('Demontration howto create a figure with nice labels is done.');

return % end of file