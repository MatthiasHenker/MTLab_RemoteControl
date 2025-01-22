%% Howto create a pointer diagram
% 2025-01-22
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is an advanced sample script within a series of howto-files.
%
% This sample script is dealing with the symbolic solution of an equation
% system for a real transformer and its illustration.
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
disp('Solving equations system for real transformer ...');

% calculate all currents and voltages of a real transformer

% 1st step: Define all variables as symbols and make some assumptions
% (small letter for symbols and capital letter for numeric values)
%
% voltages in V as complex amplitudes
syms u_1 u_2_acute u_LR2_acute u_R2_acute  complex; %#ok<NASGU>
syms u_L2_acute u_h u_LR1 u_R1 u_L1        complex; %#ok<NASGU>
% currents in A as complex amplitudes
syms i_1 i_2_acute i_0 i_Fe i_mu           complex;
% resistor values in Ohm as positive reals
syms r_1 r_2_acute r_Fe r_a_acute          positive real;
% reactance values of inductors in Ohm as positive reals
syms x_L1 x_L2_acute x_mu x_La_acute       positive real;

% thus, we have:
%   - 9 voltages
%   - 5 currents
%   - 4 resistance values (3 for transformer + 1 for load Z_a = Ra+i*Xa)
%   - 4 reactance values  (3 for transformer + 1 for load Z_a = Ra+i*Xa)
% in total: 22 variables

% 2nd step: Define all equations (see schematic)
eq01 =  u_R1        ==      r_1  * i_1;
eq02 =  u_L1        == 1i * x_L1 * i_1;
eq03 =  u_LR1       ==         u_R1 + u_L1;
eq04 =  u_R2_acute  ==      r_2_acute  * i_2_acute;
eq05 =  u_L2_acute  == 1i * x_L2_acute * i_2_acute;
eq06 =  u_LR2_acute ==   u_R2_acute + u_L2_acute;
eq07 =  i_1         ==    i_2_acute + i_0;
eq08 =  i_0         ==         i_Fe + i_mu;
eq09 =  u_h         ==      r_Fe * i_Fe;
eq10 =  u_h         == 1i * x_mu * i_mu;
eq11 =  u_1         ==        u_LR1 + u_h;
eq12 =  u_h         ==  u_LR2_acute + u_2_acute;
eq13 =  u_2_acute   == (r_a_acute + 1i * x_La_acute) * i_2_acute;
eq14 =  r_1         ==     r_2_acute;
eq15 =  x_L1        ==     x_L2_acute;

% 3rd step: Merge all equations
eq_sys = [eq01, eq02, eq03, eq04, eq05, eq06, eq07, eq08, eq09, eq10, ...
    eq11, eq12, eq13, eq14, eq15];

% all equations form a linear system of equations with 22 variables
% assuming that all equations are linear independent we can eliminate
% (N-1) variables out of N equations ==> N = 15 in our case
%
% now we can eliminate some dependent variables
%  - 2 internal parameter values (because R1 = R2´ and L1 = L2´)
reduced_eq_sys = eliminate(eq_sys, [x_L2_acute, r_2_acute]);

% now define some parameter values of the transformer
%  - 6 out of 6 remaining resistance and reactance values
% and insert these numerical values in our equation system
R_1        =   60; % in Ohm
X_L1       =   40;
R_Fe       = 6000;
X_mu       = 3600;
% and for load parameters (Attention: Z_a´ = ü^2 * Z_a)
R_a_acute  = 500; % in Ohm
X_La_acute = 100;

% we will have 22 - 8 = 14 remaining variables in our equation system then
% thus, all 9 voltages and 5 currents are still unknown
final_eq_sys = subs(reduced_eq_sys, ...
    {r_1, x_L1, r_Fe, x_mu, r_a_acute, x_La_acute}, ...
    {R_1, X_L1, R_Fe, X_mu, R_a_acute, X_La_acute});

% how many independent equations are left?
disp(['  number of independent equations: ' num2str(length(final_eq_sys))]);

% solve this equation system as a function of the input voltage U_1
%  - we assume an input voltage unequal to zero
assume(u_1 ~= 0);
solution = solve(final_eq_sys, ...
    [u_2_acute, u_LR2_acute, u_R2_acute, u_L2_acute, u_h, u_LR1, u_R1, ...
    u_L1, i_1, i_2_acute, i_0, i_Fe, i_mu], 'ReturnConditions', true);

required_conditions = simplify(solution.conditions);
disp(['  Following conditions must be hold: ' char(required_conditions)]);

% Now we can check if all returned conditions can be met.
if isAlways(required_conditions)
    disp('  Assuming U_1~=0 then all conditions are met.');
else
    disp('  It is not possible to prove that all conditions have been met.');
end
disp('done');

% output values for defined input voltage
%   optionally rotate U_1 for nicer plot (angle = 0°)
U_1          = 220               *exp(1i*pi/180 * 0);  % in V
results      = subs(solution, u_1, U_1);
%
% upscale all currents
iScaleFactor = 1e3;                            % in mA instead of A
%
I_1          = double(results.i_1)                * iScaleFactor;
I_2_acute    = double(results.i_2_acute)          * iScaleFactor;
I_0          = double(results.i_0)                * iScaleFactor;
I_Fe         = double(results.i_Fe)               * iScaleFactor;
I_mu         = double(results.i_mu)               * iScaleFactor;
U_2_acute    = double(results.u_2_acute);
U_LR2_acute  = double(results.u_LR2_acute);
U_R2_acute   = double(results.u_R2_acute);
U_L2_acute   = double(results.u_L2_acute);
U_h          = double(results.u_h);
U_LR1        = double(results.u_LR1);
U_R1         = double(results.u_R1);
U_L1         = double(results.u_L1);

% -------------------------------------------------------------------------
% column vector with all pointers to draw
% (as complex numbers: x = real part and y = imag part)
AllPointers = [   ...
    I_1         ; ...
    I_2_acute   ; ...
    I_0         ; ...
    I_Fe        ; ...
    I_mu        ; ...
    U_1         ; ...
    U_2_acute   ; ...
    U_LR2_acute ; ...
    U_R2_acute  ; ...
    U_L2_acute  ; ...
    U_h         ; ...
    U_LR1       ; ...
    U_R1        ; ...
    U_L1       ];

% offsets for all pointers (same order as for 'AllPointers')
AllPointerOffsets = [        ...
    0                      ; ...
    0                      ; ...
    I_2_acute              ; ...
    I_2_acute + I_mu       ; ...
    I_2_acute              ; ...
    0                      ; ...
    0                      ; ...
    U_2_acute              ; ...
    U_2_acute              ; ...
    U_2_acute + U_R2_acute ; ...
    0                      ; ...
    U_h                    ; ...
    U_h                    ; ...
    U_h + U_R1            ];

% -------------------------------------------------------------------------
% prepare pointer diagram

% cell array with plot parameters
% {DisplayName, LineWidth, LineStyle, Color} ==> you can adapt these values
AllPointerParameters = { ...
    "I_1"     , 2.5  , "-" , [1.0 0.0 0.0] ; ...
    "I_2´"    , 2.5  , "-" , [0.9 0.3 0.0] ; ...
    "I_0"     , 1.5  , ":" , [0.8 0.3 0.1] ; ...
    "I_{Fe}"  , 1.5  , "--", [0.7 0.2 0.2] ; ...
    "I_\mu"   , 1.5  , "--", [0.6 0.0 0.5] ; ...
    "U_1"     , 2.5  , "-" , [0.0 1.0 0.0] ; ...
    "U_2´"    , 2.5  , "-" , [0.1 0.8 0.1] ; ...
    "U_{LR2}´", 1.5  , ":" , [0.2 0.7 0.3] ; ...
    "U_{R2}´" , 1.5  , "--", [0.2 0.6 0.4] ; ...
    "U_{L2}´" , 1.5  , "--", [0.0 0.6 0.7] ; ...
    "U_h"     , 1.5  , "-" , [0.2 0.4 0.6] ; ...
    "U_{LR1}" , 1.5  , ":" , [0.3 0.4 0.2] ; ...
    "U_{R1}"  , 1.5  , "--", [0.3 0.4 0.4] ; ...
    "U_{L1}"  , 1.5  , "--", [0.3 0.4 0.9]};

% scales size of all arrow heads in diagram   ==> you can adapt this value
HeadScaleFactor = max(abs(AllPointers)) * 0.07;

% aux variables for pointer diagram
X = real(AllPointerOffsets);
Y = imag(AllPointerOffsets);
U = real(AllPointers);
V = imag(AllPointers);
A = HeadScaleFactor ./ abs(AllPointers);

myFig = figure(1);
for idx = 1 : length(AllPointers)
    quiver(X(idx), Y(idx), U(idx), V(idx)          , ...
        DisplayName = AllPointerParameters{idx, 1} , ...
        LineWidth   = AllPointerParameters{idx, 2} , ...
        LineStyle   = AllPointerParameters{idx, 3} , ...
        Color       = AllPointerParameters{idx, 4} , ...
        AutoScale   = "off"                        , ...
        MaxHeadSize = A(idx));
    hold on;
end
hold off;
axis equal;
grid on;
legend(Location = "bestoutside");
title("Pointer diagram for transformer");
xlabel("real part (voltages in V, currents in mA)");
ylabel("imaginary part");
zoom on;

% enlarge diagram (0..1) for screen range
myFig.Units    = 'Normalized';
% 40% x 60% of screen size and moving on screen
myFig.Position = [0.3 0.2 0.4 0.6];

% alternative file extensions are .emf and .jpg
FileName = "Howto_create_pointer_diagram.png";
exportgraphics(myFig, FileName);

% EOF