%% Howto to use the symbolic toolbox
% 2024-09-03
%
% HTW Dresden, Prof. Matthias Henker & Prof. Jens Schönherr
%
% University of Applied Sciences Dresden, Faculty of Electrical Engineering
%
% Notes: The script was tested with Matlab 2024a and requires the Symbolic Math
% Toolbox
%% Introduction
% This is a simple sample script from the series of howto-files. This sample
% script is demonstrating the power of the symbolic toolbox.
%
% As an example this script solves an actual exercise of the course 'analog
% circuit design' - 'Analoge Schaltungstechnik (AST)' exercise 10.1 (winter term
% 2019/20)
%
% For further reading type 'doc' to open documentation window and go to 'Symbolic
% Math Toolbox' (in left hand content menu)
%
% Just start this script (short cut 'F5') and get inspired
%% Here we start with the actual exercise
% Exercise (Übungsaufgabe) AST-10.1 in course analog circuit design.
%
%
%
% Problem: Calculate amplitude and phase response (Bode plot) of the given circuit
% as a function of the parameters R1, C1, R2, C2 and plot the amplitude and phase
% response for a frequency range of 10 Hz .. 1 MHz.
% 1st step: Define all variables as symbols and make some assumptions

clear;
close all;
clc;

syms U_E U_B U_N U_A     complex;       % voltages in V as complex amplitudes
syms I_R1 I_R2 I_C1 I_C2 complex;       % currents in A as complex amplitudes
syms G                   complex;       % gain is complex (amplitude ratio & phase)
syms R1 R2               positive real; % resistor values in Ohm as positive reals
syms C1 C2               positive real; % capacitor values in F as positive reals
syms f                   positive real; % frequency in Hz as positive real values
% 2nd step: Define all equations (see schematic)

% equation 1: gain as ratio of output to input voltages
eq1 =         G  == U_A / U_E;
% equations 2-6: U-I dependencies for all elementes
eq2 =  U_E - U_B == I_C1 / (1i*2*pi*f*C1);% U-I-relation at C1
eq3 =  U_B - U_N == I_R1 * R1;            % U-I-relation at R1
eq4 =        U_N == 0;                    % OPA: because U_P = 0 & U_N = U_P
eq5 =  U_A - U_N == I_R2 * R2;            % U-I-relation at R2
eq6 =  U_A - U_N == I_C2 / (1i*2*pi*f*C2);% U-I-relation at C2
% equation 7-8: node equations for currents
eq7 =      I_C1  == I_R1;                 % R1 & C1 as series elements
eq8 =    - I_R1  == I_C2 + I_R2;          % R2 & C2 in parallel
% 3rd step: Merge all equations and solve

eq_sys = [eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8];
%%
% *ATTENTION*:
%%
% * All equations form a linear system of equations
% * Assuming that all equations are linear independent we can eliminate (N-1)
% variables out of N equations ==> N = 8 in our case
% * We would get an error when equations are not independent)
%%
% Thus, we eliminate superfluous variables
%%
% * All voltages and currents are not of interest
% * We have 4 voltages and 4 currents but we can eliminate only 7 out of 8 equations
% * It is sensible to keep U_E (input voltage) in our equation system

reduced_eq_sys = eliminate(eq_sys, [I_R1, I_R2, I_C1, I_C2, U_B, U_N, U_A]);
%%
% Now we solve our equation system for gain 'G'
%
% *ATTENTION*: We will get a struct with the actual solution and some conditions
% as well

G_solution = solve(reduced_eq_sys, G, 'ReturnConditions', true);
% 4th step: Simplify solution and check if assumed conditions can be fulfilled
% It is strongly recommend to check if the returned conditions can be fulfilled

required_conditions = simplify(G_solution.conditions);
disp(['Following conditions must be hold: ' char(required_conditions)]);
%%
% In our case the condition that U_E must not be zero is returned. This really
% makes sense. U_E = 0 will produce no output of our circuit.
%
% We will add this assumption to our variables (see 1st step for our initial
% assumptions).

% we assume an input voltage unequal to zero
assumeAlso(U_E ~= 0);
%%
% Now we can check if all returned conditions can be met.

if isAlways(required_conditions)
    disp('Assuming U_E~=0 then all conditions are met.');
else
    disp('Prove that all conditions are met is not possible.');
end
%%
% And finally we simplify the solution to make it easier to read and print out
% our solution.

G_final = simplify(G_solution.G);
disp(['Solution for gain: G(f) = ' char(G_final)]);
% 5th step: Assign actual values to the parameters and create Bode plot

R1_e =  1e3;   %  1kOhm
R2_e = 10e3;   % 10kOhm
C1_e = 30e-9;  % 30nF
C2_e =  3e-9;  %  3nF
%%
% Define the frequency range for our Bode plot

% 10 Hz .. 1 MHz (log scaling with 20 steps / decade)
f_e = 10.^(1 : 1/20 : 6);
%%
% Substitute the parameters R1, R2, C1, C2, and f in our symbolic solution by
% the defined values above.

G_example = subs(G_final, {R1, R2, C1, C2, f}, {R1_e, R2_e, C1_e, C2_e, f_e});
% and convert to floating point numbers
G_example = double(G_example);
%%
% Hurray, we can plot the amplitude and phase response (Bode plot) in a common
% figure by using subplot.

myFig = figure(1);
tiledlayout(2,1);

nexttile;
semilogx(f_e, 20*log10(abs(G_example)), LineWidth = 1);
title('Amplitude response (dB)')
grid on;
ylabel('Gain (dB)')

nexttile;
semilogx(f_e, unwrap(angle(G_example))*180/pi, LineWidth = 1);
title('Phase response (Degree)')
grid on;
xlabel('Frequency (Hz)');
ylabel('Phase (deg)');
%%
% And as last step we save the figure to file.

% alternative file extensions are .emf and .jpg
FileName = 'Howto_solve_EquationSystems_with_Symbolic_Toolbox_Bode.png';
exportgraphics(myFig, FileName);
%%
% Done
%% Appendix
% There is even more you can do with Matlab.
% Determine maximum of amplitude response
% The solution for gain (G_final) depends on the symbolic parameters R1, R2,
% C1, C2, and f. We determine the magnitude of the gain.
%
% *ATTENTION*: The integration or differentiation of the abs-function will cause
% troubles.
%%
% * Thus, replace  abs(x)    by    sqrt( x * conj(x) )
% * ==> see <https://de.wikipedia.org/wiki/Betragsfunktion https://de.wikipedia.org/wiki/Betragsfunktion>
% (komplexe Betragsfunktion) or
% * ==> see <https://en.wikipedia.org/wiki/Absolute_value https://en.wikipedia.org/wiki/Absolute_value>
% (complex numbers)

G_magnitude = sqrt((G_final)*conj(G_final));
G_magnitude = simplify(G_magnitude);
disp(['Magnitude of gain: |G(f)| = ' char(G_magnitude)]);
%%
% Calculate first derivative of magnitude of gain (|G(f)|).

G_diff = diff(G_magnitude, f);
%%
% Search zero of derivative to find maximum of gain.

f_max = solve(G_diff == 0, f);
G_max = subs(G_magnitude, f, f_max);
f_max
G_max
%%
% Actually, we have to check if this solution is really a maximum (other options
% are minimum or turning point). ==> second derivative has to be negative at f_max.

G_diff_2 = diff(G_diff, f);
simplify(subs(G_diff_2, f, f_max))
%%
% Hurray again, since all parameters R1, R2, C1, and C2 are positive values
% the second derivative at f_max is always negative. ==> It is really a maximum
% for all possible parameter values R1, ... .
%
% Finally, we calculate gain G_max and its respective frequency f_max for the
% numerical values of the parameter values R1, R2, C1, and C2.

f_max_example = double(subs(f_max, {R1, R2, C1, C2}, {R1_e, R2_e, C1_e, C2_e}));
G_max_example = double(subs(G_max, {R1, R2, C1, C2, f}, {R1_e, R2_e, C1_e, C2_e, f_max}));
disp(['Maximum of gain: |G(f_max)| = ' num2str(20*log10(G_max_example), '%8.2f') ' dB']);
disp(['Respective frequency: f_max = ' num2str(f_max_example, '%8.2f') ' Hz']);
%%
% Done