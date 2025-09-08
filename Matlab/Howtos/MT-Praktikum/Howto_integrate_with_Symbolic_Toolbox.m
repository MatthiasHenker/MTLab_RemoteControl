%% Howto use the Symbolic Math Toolbox to calculate an integral
% 2025-09-08
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

% the following variables should be symbolic with certain assumptions
syms b x real;    % variables (here 'b' and 'x') are real valued

% and we also have known numeric values for variables
a = 2;

% define an expression with numeric and symbolic values
% a       - is numeric and known
% b and x - are symbolic and there actual values are not known yet
f = a*sin(b*x);

% show the defined expression
disp('The expression "f" is defined as:');
pretty(f);

% calculate an indefinite integral
f_int = int(f, x);
% or alternatively the definite integral in the interval (1, 3)
%f_integrated = int(f, x, 1, 3);

% show result
disp('The solution for the symbolic integral "f_integrated" is:');
pretty(f_int);

% the integral still contain symbolic values which can be replaced by
% different numeric values as examples
%            variable 'a' is already a numerical value   (e.g. amplitude)
% substitute (replace) symbol 'b' by a numerical value   (e.g. frequency)
% substitute (replace) symbol 'x' by a numerical vector  (e.g. time-values)
b_num     =  0.75;
x_num     = (-2 : 0.01 : 10);
f_num     = double(subs(f,     {b, x}, {b_num, x_num}));
%
% and substitute these variables also in integral
f_int_num = double(subs(f_int, {b, x}, {b_num, x_num}));

% Important notes: the variables f and f_int still contain symbolic values
% whereas the variables f_num and f_int_num are numeric and can be
% redefined with different substitutions for the variables a, b, and x

% show diagram with original function and its (indefinite) integral
myFig = figure(1);
plot(x_num, f_num,     '-g', LineWidth = 1.5, ...
    DisplayName = 'original function f (sin)');
hold on;
plot(x_num, f_int_num, '-r', LineWidth = 1.5, ...
    DisplayName = 'indefinite integral (cos)');
hold off;

title('Demonstrate power of Symbolic Math Toolbox');
xlabel('independent variable ''x''');
ylabel('dependent variable ''y''');
legend(Location = 'best');
grid on;


disp('Symbolic Math Test Done.');

return % end of file