%% Howto create figures
% 2022-08-05
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
%% create a figure which will be updated in a loop (simplest option)

% procedure:
%  - initialize all data to plot with zeros (or something else)
%  - plot initial data and set hold off to enable overwriting diagram
%  - run loop with new data in each loop and overwrite previous plot
%    by selected plot command again and again

% define plot range
x  = (0 : 0.1 : 8);

% the actual y-values to plot are not known at the beginning
% we initialize all y-values with zeros
y = zeros(size(x));

% at the beginning we initialize the figure window
fig1 = figure(1);
hold off;              % previous plots will be deleted and overwritten
plot(x, y, ':m*');     % plot initial curve (all data values are zeros)

% now we run a loop over x-vector
for cnt = 1 : length(x)
    % we create a single value for y (e.g. a measurement value)
    % ==> here a random number from a normal distribution with
    %     a mean value 3 and a standard deviation 0.6
    y(cnt) = 3 + 0.6*randn(1);
    
    % make a short pause (otherwise it is to fast to see the updates)
    pause(0.1); % 0.1s
    
    % update figure (actually it will be erased)
    figure(fig1);      % only required when you have more than one figure
    plot(x, y, ':m*'); % overwrite previous plot (because of 'hold off')
    
end

% at the end finalize and beautify figure
title('my figure with periodic updates (simplest option)');
xlabel('x-axis (unit)');
ylabel('y-axis (unit)');
grid on;
axis auto;

% -------------------------------------------------------------------------
%% this is the end

disp('Figure Test Done.');

return % end of file
