%% Howto create figures
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% This sample script is dealing with fitting curves to measurement data
% (regression: see also https://en.wikipedia.org/wiki/Regression_analysis)
% Matlab is very powerful and can make your life easier with lots of
% toolboxes such as the 'Curve Fitting Toolbox'. This a a very short
% introduction only.
%
% ATTENTION: The Curve Fitting Toolbox is required to run this script.
% You can download and install this toolbox directly in Matlab: Just go to
% HOME tab --> Add-Ons --> Get Add-Ons and search for Curve Fitting Toolbox
%
%   - for further reading use 'help fit' or 'doc fit' as starting point in
%     the Matlab help (after installation of toolbox)
%   - or search for 'curve fitting' in the Matlab help window
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
%% example 3 (using anonymous functions in Matlab ==> for experts)

% your noisy measurement values ==> you can replace them by your own data
x_meas = (0 : 0.2 : 10);
A      = 1.4;          % amplitude of sine wave
F      = 2.1;          % normalized frequency
Phase  = -50 * pi/180; % phase offset
% add some noise to your curve
y_meas = A* sin(F * x_meas + Phase) + 0.2 * randn(size(x_meas));

% plot measurement values: only show data points, but do not connect points
figure(1);
plot(x_meas, y_meas, 'r*');
grid on;
title('Example 3');
xlabel('x values')
ylabel('y values');
xlim auto;       % optionally scale x- and y-axis
ylim auto;
zoom on;         % click into figure window will zoom in at default

% your problem: you expect a sine wave (y = A* sin(F * x + Phase) but your
% measurement values do not fit to a perfect sine wave
%   - your data are somewhat distorted
%   - How to find suitable coefficients 'A', 'F' and 'Phase' to get the
%     best fitting curve
% ==> with the curve fitting toolbox even newbies can solve this problem

% as first step define your wanted curve as symbolic equation
%  - use 'x' for your data (y = f(x))
%  - all other variables are the unknown coefficients you are searching for
%
% this time with anonymous function in Matlab
%  - just to show you some tricks: it is easier then to compare the best
%    fitting curve with the original undistorted data
myFitFunc = @(A, F, Phase, x) (A* sin(F*x + Phase));

% now create fit object with your data and options
% Note: data vectors have to be column vectors ==> use x' to transpose
myFit = fit(x_meas', y_meas', myFitFunc, ...
    'StartPoint', [1 2 -45*pi/180]);  % you need some good start values
% show results
disp(myFit);

% plot best fitting curve in your diagram
figure(1);
% define plot range
x_range = (min(x_meas) : 1e-2 : max(x_meas));
hold on;
% original undistorted curve  : y = f(x) with original coefficients
plot(x_range, myFitFunc(A, F, Phase, x_range), '--g');
% estimated best fitting curve: y = f(x) with fitted coefficients
plot(x_range, myFitFunc(myFit.A, myFit.F, myFit.Phase, x_range), ':b');
hold off;
% add a legend
legend('measurement values', 'original curve', 'best fitting curve');

%% this is the end

disp('Curve Fitting Test Done.');

return % end of file