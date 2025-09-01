%% Howto create a SMU24xx object and control a Keithley SMU remotely
% 2025-09-01
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script and does not replace the need to read
% the manual of the SMU (SMU2450-ReferenceManual_Sep_2019.pdf)
%
% Requirements:
%   - tested with Matlab 2024b update 6 and installed toolboxes:
%     'Instrument Control Toolbox' and 'Instrument Control Toolbox Support
%     Package for National Instruments VISA and ICP Interfaces'
%   - 'SMU24xx' (version 1.0.0 or higher) and 'VisaIF' (version
%            3.0.2 or higher) class files
%
% Further hints:
%   - for further reading type 'doc SMU24xx'
%   - the SMU is assumed to be connected to your computer (LAN) and is
%     turned on
%   - a LED as device under test (DUT) is connected via front panel
%     terminals (2-wire) ==> (or 4-wire:) see script below
%
% just start this script (short cut 'F5') and get inspired
%
% Some general recommendations for operation of Keithley SMU
%   - read manual of SMU
%   - start with reset-method to avoid unknown old configuration of SMU
%   - start with setting of operation mode (sense and source functions)
%   - use showSettings-method to display actual configuration of SMU
%   - modify configuration of source and sense parameters to change from
%     default values
%   - start with limits (compliance levels) to avoid damages to DUT
%   - check that 2-wire or 4-wire connection of DUT matches configuration
%     (SenseParameters.RemoteSensing)
%   - trade-off: fixed range vs. auto range
%   - trade-off: NPLC- and filter-settings (noise vs. measurement speed)
%   - runMeasurement-method will turn on and off the source automatically,
%     ==> check settings and timing to avoid overheating of DUT
%

%% preparation
CleanMatlab = true;  % true or false

% optionally clean Matlab
if CleanMatlab  % set to true/false to enable/disable cleaning
    clear;      % clear all variables from the workspace (see 'help clear')
    close all;  % close all figures
    clc;        % clear command window
end

% -------------------------------------------------------------------------
%% here we go (actual test script)

% create object and open interface (default: tcpip)
mySMU = SMU24xx('2450');

% set SMU to known default settings
mySMU.reset;

% define operation mode: 'SVMI' or 'SIMV'
% SVMI: source voltage and sense (measure) current
% SIMV: source current and sense (measure) voltage
mySMU.OperationMode  = 'SVMI';

% modify source and sense parameters
mySMU.SourceParameters.OVProtectionValue = 5;     % 5 V to protect DUT
mySMU.SourceParameters.LimitValue        = 25e-3; % limit to 25 mA

% either 2-wire or 4-wire connection of DUT (default is 2-wire = 'off')
%mySMU.SenseParameters.RemoteSensing      = 'on'; % when 4-wire

% optionally change NPLC- and filter settings (slower or faster)
mySMU.SenseParameters.NPLCycles          = 2; % default: 1
%mySMU.SenseParameters.AverageCount       = 0; % default: 0 = no filtering

% display actual settings ==> check
mySMU.showSettings;

% configure and run actual measurement (here linear or logarithmical sweep)
result = mySMU.runMeasurement( ...
    timeout   =  60     , ... % increase timeout when averaging is used
    mode      = 'log'   , ... % or 'lin'
    points    =  60     , ... % 60 measurement steps for sweep
    start     =  0.5    , ... % from 0.5 V to 2.5 V
    stop      =  2.5    );

% show resulting I-V-diagram
figure(1);
plot(result.sourceValues, result.senseValues , '-g*');
title('I-V characteristic curve of a green LED');
xlabel(mySMU.SourceMode);
ylabel(mySMU.SenseMode);
grid on;
zoom on;

% use return if you want to exit this script early (before deleting object)
%return

% finally close interface and delete object again
mySMU.delete;

disp('SMU24xx Test Done.');
% -------------------------------------------------------------------------
% EOF (end of file)