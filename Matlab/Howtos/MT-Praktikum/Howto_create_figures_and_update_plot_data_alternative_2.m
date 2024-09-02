%% Howto create figures
% 2024-09-02
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
%   - figure, plot
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
%% create a figure which will be updated in a loop (alternative option)

% procedure:
%  - initialize all data to plot with zeros (or something else)
%  - plot initial data and add labels and so on to beautify plot
%  - activate automatic update of graph on data change (linkdata)
%  - now the figure will update the plot when you modify your data
%  ==> Matlab will notice when your data has changed and update also your
%      plots

% NOTE: this alternative option is quite nice and very powerful but a bit
%       trickier to configure and not very fast

% define plot range
x  = (0 : 0.1 : 8);

% the actual y-values to plot are not known at the beginning
% we initialize all y-values as zeros
y = zeros(size(x));  % same size as your x-data

% at the beginning we initialize the figure window
fig2    = figure(2);
myplot2 = plot(x, y, ':b*');     % plot initial curve (all zeros)

% add labels, scale axes and so on
title(['my figure with periodic updates (alternative option ' ...
    'using linkdata-command)']);
xlabel('x-axis (unit)');
ylabel('y-axis (unit)');
xlim('auto');
ylim('auto');
grid minor;

% and now we turn on automatic update of graphs on data changes
myplot2(1).XDataSource = 'x';  % name of the variables holding the data
myplot2(1).YDataSource = 'y';
linkdata(fig2, 'on');

% now we run a loop over x-vector
for cnt = 1 : length(x)
    % we create an single value of y (e.g. a measurement value)
    % ==> here a random number from a normal distribution with
    %     a mean value 5 and standard deviation 0.5
    y(cnt) = 5 + 0.5*randn(1);
    
    % recommend an update of figure (Matlab decided when an update is done)
    refreshdata(fig2);
    
    % make a short pause (Matlab will use this pause to update figures
    % ==> otherwise update of figures will be postponed)
    pause(0.05); % 50ms are more than enough
end

% finally disable automatic update of graphs again
linkdata(fig2, 'off');

% -------------------------------------------------------------------------
%% this is the end

disp('Figure Test Done.');

return % end of file