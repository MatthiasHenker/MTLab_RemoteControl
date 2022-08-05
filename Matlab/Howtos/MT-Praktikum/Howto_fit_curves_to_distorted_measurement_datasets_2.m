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
%% example 2 (like example 1 but with more comments and options)

% your noisy measurement values ==> you can replace them by your own data
x_meas = [-0.6 -0.1  0.4  0.7  1.2  1.3  1.4  1.8  2.1  2.5  2.6  2.8];
y_meas = [-6.6 -4.5 -3.6 -0.9 -0.8  1.4  4.1  3.9  7.6  8.4  9.1 10.4];

% plot measurement values: only show data points, but do not connect points
figure(1);
plot(x_meas, y_meas, 'r*');
grid on;
title('Example 2');
xlabel('x values')
ylabel('y values');
xlim auto;       % optionally scale x- and y-axis
ylim auto;
zoom on;         % click into figure window will zoom in at default

% your problem: you expect a linear curve (y = m*x + n) but your
% measurement values do not fit to a perfect line
%   - your data are somewhat distorted
%   - How to find suitable coefficients 'm' and 'n' to get the best fitting
%     curve 'y = m*x + n'? see https://en.wikipedia.org/wiki/Least_squares
% ==> with the curve fitting toolbox even newbies can solve this problem

% as first step define your wanted curve as symbolic equation
%  - use 'x' for your data (y = f(x))
%  - all other variables are the unknown coefficients you are searching for
myFType = fittype('m*x + n');    % ==> adjust definition to your needs
%
% for your information only: check that everything is fine
disp('Some properties of your fit object:');
disp(myFType);
disp(indepnames(myFType))   % should be 'x'
disp(dependnames(myFType))  % should be 'y'   (y = f(x))
disp(coeffnames(myFType))   % ORDERED!!! list of your coefficients
%disp(formula(myFType))     % should be identical to your fittype def.

% optionally, you can define some fit options like start values for your
% coefficients
%   - when you have a rough idea about your unknown coefficients
%   - drop these lines when you have no idea about your coefficients
myOpts  = fitoptions(myFType);
myOpts.StartPoint = [2 -3];  % ordered as in coeffnames(myFType) !!
% ... for experts: there are more options available

% now create fit object with your data and options
% Note: data vectors have to be column vectors ==> use x' to transpose
myFit = fit(x_meas', y_meas', myFType, myOpts);
% show results
disp(myFit);
% optionally get values of your wanted coefficients
%m = myFit.m;  % names of coefficients depend on your 'fittype' definition
%n = myFit.n;

% plot best fitting curve in your diagram
figure(1);
% define plot range
x_range = (-1: 0.1 : 3);
% evaluate best fitting curve for your x values (plot range)
y_fit_curve = feval(myFit, x_range);
hold on;
plot(x_range, y_fit_curve, '--b');
hold off;
% add a legend
legend('measurement values', 'best fitting curve');

%% this is the end

disp('Curve Fitting Test Done.');

return % end of file