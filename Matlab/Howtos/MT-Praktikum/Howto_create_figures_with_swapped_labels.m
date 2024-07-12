%% Howto create figures
% 2024-03-27
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
%% creating a simple figure with a single curve

% define plot range of parameter x
x  = (0 : 0.05 : 10); % coarse steps    ==> faster computations
%x = (0 : 0.001 : 10); % very fine steps ==> looks better in plots

% define some parameters
a = 2;
b = -13;
c = 7;

% define a function to plot
y = a*x.^2 + b*x + c;

% now create a figure and plot function
fig1 = figure(1);    % create a figure window
plot(x, y, '-r', DisplayName = 'parabolic function');
grid on;             % show grid

% there are also many alternatives to 'plot' command:
% semilogx  - Semi-log scale plot for x-axis
% semilogy  - same but            for y-axis
% loglog    - log scale plot for both axes
% stem      - plot discrete sequence data
% ... see Matlab Documentation - Category 'Graphics' with lots of figures
% and examples

% now finalize and beautify figure
title('my amazing figure');
xlabel('x-axis (with units)');
ylabel('y-axis (with units)');
legend(Location = 'north');


%% now we want to change some properties of the figure

% it is also possible to move the axis labels to the right and top side 
fig1_axes = gca;         % save handle to current axes object
fig1_axes.XAxisLocation = 'top';
fig1_axes.YAxisLocation = 'right';

% optionally is ia also possible to change the tick labels
xticks(0:pi:3*pi);
xticklabels({'0','\pi','2\pi','3\pi'});

%% this is the end

disp('Figure Test Done.');

return % end of file