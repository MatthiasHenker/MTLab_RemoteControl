%% Howto create an FGen object and control a signal generator remotely
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'Fgen' (version 1.0.7 or higher) and 'VisaIF' (version 2.4.3
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
%   - this enables you to create powerful scripts for full automated tests
%   - For full functionality an Agilent 33220A generator has to connected
%     to your computer. Normally, you won't have such a generator at home.
%   - Thus, we provide a demo mode for first tests at home.
%   - ATTENTION: the demo mode supports very few macros only
%       * methods: reset, identify, opc
%       * methods: configureOutput('frequency', VALUE)
%       * you will get no errors but warnings for all unsupported methods
%         and parameters in demo-mode --> read messages in command window

% you can check if there is a generator connected via USB and turned on
FGen.listAvailableVisaUsbDevices; % take a look on your command window

% is a signal generator connected to PC or do want to use the Demo-mode?
runDemoMode = true;  % true (demo) or false (with connected generator)
if runDemoMode
    interface = 'demo';
else
    interface = 'visa-usb'; %#ok<UNRCH>
end

% which function generator is used?
FGenType = 'Agilent-33220A';   % used in the lab (room S110)

% create object (constructor) --> same as for VisaIF class
myFGen = FGen(FGenType, interface);

% how much information should be printed out? ('none', 'few', or 'all')
%myFGen.ShowMessages = 'all'; % default is 'few'

% open the interface
myFGen.open;

% a reset at the beginning will set the generator to default state
%myFGen.reset;  % reset is not necessary in most cases

% -------------------------------------------------------------------------
% some initial configuration first

waveform  = 'sine';  % sine wave
amplitude = 2;       % 2 Vpp
unit      = 'Vpp';   % also available options are: 'Vrms', Vpp', 'dBm'
offset    = 0.5;     % in V
load      = inf;     % output impedance = High-Z

% configure generator (it is more readable this way)
myFGen.configureOutput('outputimp', load);     % set output impedance
myFGen.configureOutput('waveform' , waveform); % set waveform type
myFGen.configureOutput('offset'   , offset);   % set DC-offset
myFGen.configureOutput('amplitude', amplitude, ...
    'unit'     , unit);     % set amplitude

% -------------------------------------------------------------------------
% run a loop to sequentially set different frequencies

% define a list of log-spaced frequencies
% from 30Hz (= 3*10^1) to 30kHz (= 3*10^4) with 3 steps/decade
frequencies = 3* 10.^(1 : 1/3 : 4); % in Hz

% how many frequency values are defined?
NumFreq = length(frequencies);
disp(['Number of frequency points: ' num2str(NumFreq, '%d')]);

% optionally set first frequency in initialization section before the loop
myFGen.configureOutput('frequency', frequencies(1));

% finally turn on output of generator
myFGen.enableOutput; % enable signal output

% run loop to set all frequencies sequentially
for cnt = 1 : NumFreq
    % print out loop counter to show progress
    disp(['Loop counter: ' num2str(cnt) ' of ' num2str(NumFreq)]);
    
    % set N-th frequency value at generator
    myFGen.configureOutput('frequency', frequencies(cnt));
    
    % wait a moment to see progress (e.g. at display of generator)
    pause(0.5); % in s
end

% -------------------------------------------------------------------------
% finally close interface and delete object again
myFGen.close;
myFGen.delete;

disp('Generator Test Done.');

return % end of file