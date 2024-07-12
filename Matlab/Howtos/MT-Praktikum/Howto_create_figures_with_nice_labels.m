%% Howto create figures
% 2024-07-12
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
%% at the beginning a simple figure with two curves

% define plot range of parameter x
x  = (0 : 0.05 : 10); % coarse steps    ==> faster computations
%x = (0 : 0.001 : 10); % very fine steps ==> looks better in plots

% define some parameters
M1 = 2;
M2 = M1 + 1;

% define two functions to plot
y1 = cos(M1*pi*x);
y2 = sin(M2*pi*x);


% now create a figure and plot both functions
% plot command with two mandatory arguments for x and y data
%   third argument mit plot options is optional 
%       'r-*' means red ('r') color, solid ('-') line, 
%                   and asterix ('*') to mark data points
%   you can add even more options in the way
%       ParameterName = ParameterValue
%       here with Diplayname which is used for a legend
fig1 = figure(1);    % create a figure window
plot(x, y1, '-r*', DisplayName = 'cos curve');  % plot 1st curve
hold on;             % prevent overwritting of 1st plot
plot(x, y2, '--b', DisplayName = 'sin curve');  % plot 2nd curve
hold off;            % allow overwritting again (when script is rerun)

% there are also many alternatives to 'plot' command:
% semilogx  - Semi-log scale plot for x-axis
% semilogy  - same but            for y-axis
% loglog    - log scale plot for both axes
% stem      - plot discrete sequence data
% ... see Matlab Documentation - Category 'Graphics' with lots of figures
% and examples

% now finalize and beautify figure
title('my first figure');
xlabel('x-axis (unit)');
ylabel('y-axis (unit)');
legend(Location = 'Best'); % or specific Location= 'NorthEast'

grid minor;          % show a fine grid (or 'grid on', grid off')
xlim auto;           % scale x- and y-axis separately
ylim([min(y1)-0.1 max(y1)+0.1]);
zoom on;             % click into figure window will zoom in at default

%% now we want to change some properties of the figure

% background color
fig1.Color = [0.8 0.9 0.7]; % as RGB triplet

% change title of figure window
fig1.Name  = 'Howto create a nice figure';

%% we also can change even more properties

axes1 = fig1.CurrentAxes; % get axes object of figure

% now change some properties of axes
axes1.FontSize                = 14;
axes1.FontWeight              = 'bold';
axes1.TitleFontSizeMultiplier = 2.5;
axes1.TickDir                 = 'out';
axes1.TickLength              = [0.01 0.01];
axes1.XColor                  = [0.9 .1 .6];     % as RGB-triplet

%% finally we want to save the figure to file
% (figure will be saved as shown on screen)

% enlarge figure before for finer resolution to 80% x 80% of screen size
fig1.Units    = 'Normalized';
fig1.Position = [0.1 0.1 0.8 0.8];

% and save file (alternatives are .emf, .jgp, ...)
if SaveFigures
    FileName = './myFigure_01';
    saveas(fig1, [FileName '.png']);
end


%% this is the end

disp('Figure Test Done.');

return % end of file