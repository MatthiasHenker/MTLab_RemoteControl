%% Howto create an FGen object and control a signal generator remotely
% 2024-08-26
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'Fgen' (version 3.0.0 or higher) and 'VisaIF' (version 3.0.1
%            or higher) class files are required
%
% This sample script is dealing with the creation of a FGen object and
% how to control a connected Agilent function generator
%
%   - for further reading type 'FGen.doc'
%   - the generator is assumed to be connected to your computer and is
%     turned on
%   - a (very restricted) demo mode is available for first tests at home
%     without a generator
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
%% here we go

% NOTES:
%   - the FGen class provides some high-level SPCI-command macros for
%     typical actions like selecting waveform, setting amplitude,
%     DC-offset, frequency and so on
%   - this enables you to create powerful scripts for automated tests
%   - For full functionality e.g. an Agilent 33220A generator has to be
%     connected to the computer. Normally, you won't have such a generator
%     at home. Thus, a demo mode is provided for first tests at home.
%   - ATTENTION: the demo mode supports very few macros only
%       * methods: reset, identify, opc
%       * methods: configureOutput('frequency', VALUE)
%       * you will get no errors but warnings for all unsupported methods
%         and parameters in demo-mode --> read messages in command window

% you can check if there is a generator connected via USB and turned on
USBDeviceList = FGen.listAvailableVisaUsbDevices(true); % show results

% which function generator is to be controlled remotely?
FGenType = 'Agilent-33220A';    % available generators
%FGenType = 'KEYSIGHT-33511B';   % in the lab (room S 110)

% SELECT: true (demo) or false (control actually connected generator)
runDemoMode = false; % true or false
if runDemoMode || isempty(USBDeviceList)
    interface = 'demo';
else
    interface = 'visa-usb';
end

% -------------------------------------------------------------------------
% create object (constructor) and open interface
myFGen = FGen(FGenType, interface);

% how much information should be printed out? ('none', 'few', or 'all')
%myFGen.ShowMessages = 'all'; % default is 'few'

% optionally perform a reset to set the generator to default state
%myFGen.reset;  % reset is not necessary in most cases

% -------------------------------------------------------------------------
% some initial configuration first
%
% most methods (here 'configureOutput') have several parameters,
% these parameters can be set all at once or splitted up in separate calls

% set expected impedance of load (normally 50 Ohms or High-Z = inf)
myFGen.configureOutput(outputimp = inf); % or 50 in 'Ohm'

% set waveform type - available options are: 'sine', 'rect',  'ramp', ...
myFGen.configureOutput(waveform  = 'sine');

% set amplitude     - available options are: 'Vrms', Vpp', 'dBm'
myFGen.configureOutput(amplitude = 2, unit = 'Vpp');

% set DC-offset     - always in 'V'
myFGen.configureOutput(offset    = 0.5);

% -------------------------------------------------------------------------
% run a loop to sequentially set different frequencies

% define a list of log-spaced frequencies
% from 30Hz (= 3*10^1) to 30kHz (= 3*10^4) with 3 steps/decade
freqValues = 3* 10.^(1 : 1/3 : 4); % in Hz

% how many frequency values are defined?
NumFreq = length(freqValues);
disp(['Number of frequency points: ' num2str(NumFreq, '%d')]);

% optionally set first frequency in initialization section before the loop
myFGen.configureOutput(frequency = freqValues(1));

% finally turn on output of generator
myFGen.enableOutput; % enable signal output

% run loop to set all frequencies sequentially
for cnt = 1 : NumFreq
    % print out loop counter to show progress
    disp(['Loop counter: ' num2str(cnt) ' of ' num2str(NumFreq)]);

    % set N-th frequency value at generator
    myFGen.configureOutput(frequency = freqValues(cnt));

    % wait a moment to see progress (e.g. at display of generator)
    pause(0.8); % in s
end

% -------------------------------------------------------------------------
% finally close interface and delete object again
myFGen.delete;

disp('Generator Test Done.');

return % end of file