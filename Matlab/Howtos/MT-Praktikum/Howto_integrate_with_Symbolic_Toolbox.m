%% Howto use the Symbolic Math Toolbox to calculate an integral
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: The Symbolic Math Toolbox is required to run this script.
% You can download and install this toolbox directly in Matlab: Just go to
% HOME tab --> Add-Ons --> Get Add-Ons and search for Symbolic Math Toolbox
%
% This sample script is dealing with the use of the symbolic math toolbox.
%
%   - for further reading type 'doc symbolic math toolbox'
%
% just start this script (short cut 'F5') and get inspired

%% here we start

CleanMatlab = true;  % true or false

% optionally clean Matlab
if CleanMatlab  % set to true/false to enable/disable cleaning
    clear;      % clear all variables from the workspace (see 'help clear')
    close all;  % close all figures
    clc;        % clear command window
end

% -------------------------------------------------------------------------
%% here we go

% define some numeric values
a = 2;                    % in unit (m, s, kg or whatever)
b = 0.3;                  % in unit ...

% the following variables should be symbolic with certain assumptions
syms c d real
syms e   integer

% define an expression with numeric and symbolic values
f = a*c*sin(e*d) + b;
% show the defined expression
disp('The expression ''f'' is defined as:');
pretty(f);

% calculate an indefinite integral
myInt = int(f, d);
% or alternatively the definite integral in the interval (1, 3)
%myInt = int(f, d, 1, 3);
% show result
disp('The solution for the symbolic integral ''myInt'' is:');
pretty(myInt);

% the integral still contain symbolic values which can be replaced by
% different numeric values as examples
% substitute (replace) symbol c by numerical value -2.1
% substitute (replace) symbol e by numerical value  5
% substitute (replace) symbol d by numerical vector (-2 : 0.1 : 10)
c_num     = -2.1;
e_num     = 5;
d_num     = (-2 : 0.05 : 10);
f_num     = double(subs(f,     {c, e, d}, {c_num, e_num, d_num}));
%
% and substitute these variables also in integral
myInt_num = double(subs(myInt, {c, e, d}, {c_num, e_num, d_num}));

% Important notes: the variables f and myInt still contain symbolic values
% whereas the variables f_num and myInt_num are numeric and can be
% redefined with different substitutions for the variables c, d, and e

% show diagram with original function and its (indefinite) integral
myFig = figure(1);
plot(d_num, f_num, '-g', 'LineWidth', 1.5);
hold on;
plot(d_num, myInt_num, '-r', 'LineWidth', 1.5);
hold off;
title('Demonstrate power of Symbolic Math Toolbox');
xlabel('variable d');
ylabel('original function f and indefinite integral');
grid on;


disp('Symbolic Math Test Done.');

return % end of file