%% Howto create figures
% 2025-09-08
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

% -------------------------------------------------------------------------
%% at the beginning we create a simple figure with a plot of two curves

% define plot range of parameter x
x = (0 : 1e-3 : 3);     % very fine steps ==> looks better in plots

% define two functions to plot:  y1 = f1(x) and y2 = f2(x)
y_1 = 2* cos(3.2*pi*x) + 12.6;
y_2 = 3* sin(5.5*pi*x) +  7.4;

% now create a figure and plot both functions
myFig = figure(1);      % figure counter: 1, 2, 3 ...

% plot 1st curve (r = red, g = green, b = blue, k = black, m = magenta ...)
plot(x, y_1, '-r', LineWidth= 1.8, DisplayName= 'curve 1');

% prevent overwritting the 1st plot ==> IMPORTANT!
hold on;

% plot 2nd curve
% ==> plot will be added to previous plot   when 'hold on'
% ==> plot will overwrite previous plot     when 'hold off'
plot(x, y_2, '-b', LineWidth= 0.9, DisplayName= 'curve 2');

% now shade a specific area below the second curve
range_1 = (0.6 <= x & x < 1.6);
% area is an alternative plot-command
area(x(range_1), y_2(range_1), ...   % use '...' for line breaks in commands
    FaceColor= [0.95 0.45 0.85], ...
    EdgeColor= 'b', ...
    LineWidth= 1.8, ...
    DisplayName= 'shaded area');

% allow overwritting again ==> next plot command will start new plot again
hold off;

% beautify figure and dd axis labeling, title, and a legend
grid minor;
title('Current Consumtion of Test Circuit');
xlabel('Time (in s)' );
ylabel('Currents (in A)');
legend(Location = 'best');

disp('Demontration howto create a figure with two curves is done.');
% end of file