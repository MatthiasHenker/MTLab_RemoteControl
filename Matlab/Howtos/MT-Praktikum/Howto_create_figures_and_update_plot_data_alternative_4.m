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
%   - figure, plot, animatedline
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
%  - initialize figure and use animatedline-command
%  - run loop: add new data and update figure

% NOTE: this alternative option is also nice and pretty but quite different
%       to the usual plot commands

% define plot range
x  = (0 : 0.1 : 8);

% the actual y-values to plot are not known at the beginning
% we initialize all y-values as zeros
y = zeros(1, length(x));

% at the beginning we initialize the figure window
fig3   = figure(3);
myline = animatedline; % with empty plot data at the beginning

% beautify figure
myline.Color           = [0.9 0.1 0.2]; % e.g. as RGB triplet
myline.LineStyle       = '-.';
myline.Marker          = 'o';
myline.MarkerSize      = 10;
myline.MarkerFaceColor = 'g';           % e.g. as color name
myline.MarkerEdgeColor = [0 0 1];       % or as RGB triplet
%
title(['my figure with periodic updates (alternative option ' ...
    'using animatedline-command)']);
xlabel('x-axis (unit)');
ylabel('y-axis (unit)');
grid on;
xlim([x(1) x(end)]);  % compare with   xlim('auto');
ylim('auto');

% now we run a loop over x-vector
for cnt = 1 : length(x)
    
    % we create an single value of y (e.g. a measurement value)
    y = 3 + 0.6*randn(1);
    % add new data pair to curve (myline) => myline becomes longer each run
    addpoints(myline, x(cnt), y);
    % update curve (limit update rate slightly)
    drawnow limitrate;
    
    % optionally make a pause (otherwise it's to fast to see the updates)
    pause(0.05);    % e.g. 0.05s
    
end

% -------------------------------------------------------------------------
%% this is the end

disp('Figure Test Done.');

return % end of file