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
%  - manipulate the data of the plot-object directly
% explanation of some background details:
%  - when you plot data in Matlab then the data will be copied to the
%    plot-object ==> that means that you can modify your original data but
%    the plot remain unchanged
%  - because you have access to the plot-object you can modify the plot
%    very directly

% NOTE: this alternative option is also quite nice ==> compare it with the
%       linkdata-command

% define plot range
x  = (0 : 0.1 : 8);

% the actual y-values to plot are not known at the beginning
% we initialize all y-values as zeros
y = zeros(size(x));

% at the beginning we initialize the figure window
fig3  = figure(3);
myplot3 = plot(x, y, ':b*');     % plot initial curve (all zeros)
% ATTENTION: the x- and y-data are copied to the plot-object now
% the original x- and y-data vectors are not of interest anymore

% add labels, scale axes and so on
title(['my figure with periodic updates (alternative option ' ...
    'modifying plot-data directly)']);
xlabel('x-axis (unit)');
ylabel('y-axis (unit)');
xlim('auto');
ylim('auto');
grid minor;

% now we run a loop over x-vector
for cnt = 1 : length(x)
    % we create an single value of y (e.g. a measurement value)
    % ==> here a random number from a normal distribution with
    %     a mean value 5 and standard deviation 0.5
    newvalue = 5 + 0.5*randn(1);
    
    % instead of storing the new values in the y-data vector we write the
    % new data values directly to the plot-object
    % ==> we modify the plot data
    myplot3(1).YData(cnt) = newvalue;
    
    % optionally make a pause (otherwise it's to fast to see the updates)
    % ==> otherwise update of figures will possibly be postponed
    pause(0.05);    % e.g. 0.05s
end

% -------------------------------------------------------------------------
%% this is the end

disp('Figure Test Done.');

return % end of file