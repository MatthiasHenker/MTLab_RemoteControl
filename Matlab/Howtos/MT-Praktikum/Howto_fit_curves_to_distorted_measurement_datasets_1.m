%% Howto create figures
% 2024-09-03
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
%% example 1 (shortest script, for more details see example 2)

% your noisy measurement values ==> you can replace them by your own data
x_meas = [ 0.1 0.4 0.7 1.2 1.3 1.4 1.8 2.1 2.5 2.6  2.8  3.2  3.6  3.8];
y_meas = [-0.1 0.5 0.1 0.3 0.4 1.1 1.9 3.6 5.4 8.1 13.8 19.8 34.6 39.8];

% plot measurement values: only show data points, but do not connect points
figure(1);
plot(x_meas, y_meas, 'r*', ...
    LineWidth   = 1      , ...
    DisplayName = 'measurement values');
grid on;

title('Curve fitting: fit to exponential function y(x) = A*exp(B*x)');
xlabel('x values')
ylabel('y values');

% your problem: find best fitting curve of type y = A*exp(B*x)
%
% as first step define your wanted curve as symbolic equation
%  - use 'x' independent variable (y = f(x))
%  - all other variables are the unknown coefficients you are searching for
myFType = fittype('A*exp(B*x)');    % ==> adjust definition to your needs

% now create fit object with your data and curve definition
% Notes: 
%   - data vectors have to be column vectors ==> use x' to transpose
%   - Matlab will output a warning that no starting point is given for the
%     coefficients ==> see also files *_2.m and *_3.m for more details
myFit = fit(x_meas', y_meas', myFType);
% show results
disp(myFit);

% now plot the best fitting curve into your diagram
figure(1);
% define plot range (like x_meas but equally spaced with small steps)
x_range = (0 : 0.01 : 4);

% evaluate best fitting curve for your x values
y_fitted = feval(myFit, x_range);

hold on;
plot(x_range, y_fitted, '--b', ...
    LineWidth   = 1             , ...
    DisplayName = sprintf('best fitting curve with A=%g and B=%g', ...
    myFit.A, myFit.B));
hold off;
% add a legend
legend('Location', 'northwest');

%% this is the end

disp('Curve Fitting Test Done.');

return % end of file