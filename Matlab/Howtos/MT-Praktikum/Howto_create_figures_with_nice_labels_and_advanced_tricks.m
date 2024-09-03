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

% define plot ranges and functions to plot
x1 = (0 : 0.2 : 5);
y1 = 2* cos(1.5*pi*x1) + 15;

x2 = (0 : 1e-2 : 5);
y2 = 3* cos(2*pi*x2) + 9;

% create figure and plots: save graphics objects to variables
% ==> parameters of figure and plots can be easily modified later
myFig     = figure(1);
myPlot(1) = stairs(x1, y1, '-r', DisplayName = 'stairs curve');
hold on;
myPlot(2) = plot(x2, y2, '-.g',  DisplayName = 'continuous curve');
hold off;

% beautify figure: these commands you already know now
grid off;
xlim auto;
ylim([-1  21]);  % define a specific plot range for y-axis

% finally add axis labeling, title, and a legend to distinguish the curves
title('My more advanced plot.');
xlabel('x-axis (in unit)' );
ylabel('y-axis (in unit)');
legend(Location = 'northeast');

%% you can also modify the figure and its plots later

disp(['Note the appearance of the figure to notice the effect of ' ...
    'subsequent adjustments.']);
input('Press ''Enter'' to continue.');

% push figure to foreground again
figure(1);

%% the saved handles to the graphic objects allow modifications
%
% modifying size of text or ticks can be very helpful to create better
% readable plots (check size of text before you copy plots in your protocol)

% you can change properties of the plots (the two curves)
myPlot(1).LineWidth     = 3;           % thicker line
myPlot(1).Color         = [0.5 0.5 0]; % olive green instead of red
%
myPlot(2).Marker        = 'o';         % marks samples by small circles
myPlot(2).MarkerSize    = 8;           % enlarge marker (bigger circles)
%                                        mark only every twelfth sample
myPlot(2).MarkerIndices = myPlot(2).MarkerIndices(1:12:end);
myPlot(2).MarkerFaceColor = [0 0 1];   % marker filled with blue color
myPlot(2).MarkerEdgeColor = 'none';    % marker without edge color


% in a next step you can also change properties of the axes and text
myAxes = myFig.CurrentAxes; % get axes object of figure

% increase axis labeling for better readability
myAxes.FontSize        = 14;
myAxes.FontWeight      = 'bold';

% axes in dark blue instead of default black
myAxes.XColor          = [0.1 .1 .3];  % as RGB-triplet
myAxes.YColor          = [0.1 .1 .3];  % same color for both axes

% place ticks outside instead of inside (default is 'in')
myAxes.TickDir         = 'out';
myAxes.TickLength      = myAxes.TickLength *2; % double length of ticks

% enable grid lines for y-axis only
myAxes.YGrid           = 'on';
myAxes.GridLineStyle   = ':';                 % dotted line
myAxes.GridLineWidth   = 1;                   % slightly thicker
myAxes.GridAlpha       = 0.5;                 % slighty less transparent
myAxes.GridColor       = myAxes.GridColor *2; % slightly darker

% you can change text, size, style of labels and title
myAxes.XLabel.String   = 'my updated text of x-label';
myAxes.XLabel.FontSize = 12;   % reduce text size again
%
myAxes.Title.String    = 'my updated title';
myAxes.Title.FontAngle = 'italic';
myAxes.TitleFontSizeMultiplier = 1.5;  % enlarge title text by 50 %

disp('You can do much more. Read the documentation');
doc;  % open help center

%% changing properties of the surrounding figure is also possible

% push figure to foreground again
figure(1);

% change background color of the figure window (not of the actual plot area)
myFig.Color = [0.9 0.9 0.9]; % as RGB triplet (here a light gray)

% you can change the title of figure window (don't mess up with name of plot)
myFig.Name  = 'Name of the figure window.';

% you can enlarge the figure window and change its position on screen
myFig.Units    = 'Normalized';  % (0..1) for screen range
for counter = 1 : 5
    % 50% x 50% of screen size and moving on screen
    myFig.Position = [0.07*counter 0.07*counter 0.5 0.5];
    % wait a second then update position of figure
    pause(1);
end

disp('This is the end.');

return % end of file