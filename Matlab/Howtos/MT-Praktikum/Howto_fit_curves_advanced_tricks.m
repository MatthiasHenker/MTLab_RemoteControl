%% Howto fit several curves with same parameters to measurement data series
% 2025-09-08
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
%% example: series resonant circuit
%    we want to fit several curves with same parameters to several noisy
%    measurement data
%
%    normally, the curve fitting toolbox support fitting of single curves
%    only ==> when you fit your several noisy data to curves separately,
%    you will get several (similar) estimations for your parameters
%
%    here a trick to merge all curves to a single fitting problem

% firstly we define some measurement data ==> load your own data here
f_meas   = [0.4 0.7 1.4  1.7  1.9  2.04 2.1  2.16 2.3  2.5  2.8 3.5 4.1 4.8] *1e3; % in Hz
U_R_meas = [0.4 0.2 1.   2.2  3.8  4.7  5.0  5.0  4.5  3.2  2.4 1.0 1.1 0.6]; % in V
U_C_meas = [5.1 5.7 8.5 11.4 15.7 18.3 18.6 18.4 15.4 10.5  6.4 2.9 2.0 1.5]; % in V
U_L_meas = [0.3 0.5 3.6  7.3 11.8 16.6 17.9 18.6 17.8 14.4 10.7 7.7 6.7 6.1]; % in V

% plot measurement values: only show data points, but do not connect points
figure(1);
plot(f_meas, U_R_meas, 'rx', DisplayName = 'U_R(f) - measurement values');
hold on;
plot(f_meas, U_C_meas, 'go', DisplayName = 'U_C(f) - measurement values');
plot(f_meas, U_L_meas, 'b*', DisplayName = 'U_L(f) - measurement values');
hold off;
grid on;
title('Series resonant circuit');
xlabel('Frequency f in Hz')
ylabel('Voltage U in V');
xlim auto;       % optionally scale x- and y-axis
ylim auto;

% our problem: How to find suitable coefficients for the best fitting curve? 
% see https://en.wikipedia.org/wiki/Least_squares
% ==> use the curve fitting toolbox
%
% as first step define a model to fit our data to
%  - we have several different curves with shared coefficients => merge all
% selector 1 : U_R as a function of frequency and parameters: U, rho, f0
%          2 : U_C                           same parameters
%          3 : U_L                           same parameters
myModel = @(U, rho, f0, f, select) ...
    (select == 1) .* U./sqrt(1+rho^2*(f./f0 - f0./f).^2)              + ... 
    (select == 2) .* U./sqrt(1+rho^2*(f./f0 - f0./f).^2) .*rho.*f0./f + ... 
    (select == 3) .* U./sqrt(1+rho^2*(f./f0 - f0./f).^2) .*rho.*f ./f0;

myFType = fittype(myModel, ...
    independent  = {'f', 'select'}, ...
    coefficients = {'U', 'rho', 'f0'});

% definition of some fit options
myOpts            = fitoptions(myFType);
myOpts.StartPoint = [5, 10, 1e3]; % ordered as in coeffnames(myFType) !!
myOpts.Lower      = [0,  0,  0 ]; % all coeffs must be positive  
myOpts.Display    = 'Notify'           ; % 'Notify', 'Final','Iter', 'Off'

% merge all data to match the definitions of the model above
% Note: data vectors have to be column vectors ==> use x' to transpose
x_data   = [f_meas'      ; f_meas'      ; f_meas'      ];
selector = [f_meas'*0 + 1; f_meas'*0 + 2; f_meas'*0 + 3];
y_data   = [U_R_meas'    ; U_C_meas'    ; U_L_meas'     ];

% now run actual curve fitting with the measurement data and options
myFit = fit([x_data, selector], y_data, myFType, myOpts);
% show results
disp(myFit);
% compare with true values
disp('True values of the parameters are:');
disp('       U   = 5    (in V) ');
disp('       rho = 3.7         ');
disp('       f0  = 2150 (in Hz)');

% define plot range
f_range    = (0: 1e-2 : 5) * 1e3; % in Hz
U_R_fitted = feval(myFit, [f_range' f_range'*0+1]);
U_C_fitted = feval(myFit, [f_range' f_range'*0+2]);
U_L_fitted = feval(myFit, [f_range' f_range'*0+3]);

% add plot of best fitting curve to your diagram
figure(1);
hold on;
plot(f_range, U_R_fitted, 'r-', DisplayName= 'U_R(f) - best fitting curve', LineWidth= 1.5);
plot(f_range, U_C_fitted, 'g-', DisplayName= 'U_C(f) - best fitting curve', LineWidth= 1.5);
plot(f_range, U_L_fitted, 'b-', DisplayName= 'U_L(f) - best fitting curve', LineWidth= 1.5);
hold off;
% add a legend
legend(Location= 'best');

% optionally get values of your wanted coefficients
%myFit.U;   % names of coefficients depend on your 'fittype' definition
%myFit.rho; % and so on

disp('Curve Fitting Test Done.');

return % end of file