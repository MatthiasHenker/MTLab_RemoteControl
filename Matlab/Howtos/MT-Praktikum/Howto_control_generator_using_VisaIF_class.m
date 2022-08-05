%% Howto create a VisaIF object and control a signal generator remotely
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'VisaIF' class file is required (version 2.4.3 or higher)
%
% This sample script shows the creation of a VisaIF object and how to
% control a connected function generator
%
%   - for further reading type 'VisaIF.doc' in Matlab command window
%   - the generator is assumed to be connected to your computer and is
%     turned on
%   - a demo mode can be used for first tests at home without a generator
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

% NOTES:
%   - For full functionality an Agilent 33220A generator has to connected
%     to your computer. Normally, you won't have such a generator at home.
%   - Thus, we provide a demo mode for first tests at home.
%   - ATTENTION: The demo mode only supports the following SCPI commands
%       * FREQ value, FREQ?
%       * methods: reset, identify, opc

% you can check if there is a device connected via USB and turned on
VisaIF.listAvailableVisaUsbDevices; % take a look on your command window

% Is the signal generator connected or do yout want to use the Demo-mode?
runDemoMode = true;  % true (demo) or false (with connected generator)
if runDemoMode
    interface = 'demo';
else
    interface = 'visa-usb'; %#ok<UNRCH>
end

% which function generator is connected (or emulated)?
FGenType = 'Agilent-33220A';

% create object (constructor)
myFGen = VisaIF(FGenType, interface);

% show all available properties of this class
disp(myFGen)

% how much information should be printed out? ('none', 'few', or 'all')
%myFGen.ShowMessages = 'few'; % default is 'all'

% open Visa interface
myFGen.open;

% -------------------------------------------------------------------------
% define a list of frequencies to be set at the generator in a loop
linSpacing = false;  % true for linear OR false for log spacing
if linSpacing
    % linear spacing: from 10Hz to 100Hz with 5 equally spaced values
    frequencies  = linspace(10, 100, 5); %#ok<UNRCH>
else
    % log spacing: from e.g. 20Hz (= 2*10^1) to 20kHz (= 2*10^4) with
    % 3 steps/decade
    numOfStepsDecade = 3;
    frequencies      = 2* 10.^(1 : 1/numOfStepsDecade : 4); % in Hz
    % Note: you can also use logspace (see 'help logspace')
    %frequencies  = 2* logspace(1, 4, 10); % same result as above
end
% how many frequency values are defined?
NumFreq = length(frequencies);
disp(['Number of frequency points: ' num2str(NumFreq, '%d')]);

% -------------------------------------------------------------------------

% run loop to set all frequencies sequentially
for cnt = 1 : NumFreq
    % print out loop counter to show progress
    disp(['Loop counter: ' num2str(cnt) ' of ' num2str(NumFreq)]);
    
    % set frequency at generator (convert frequency value to characters)
    myFGen.write(['FREQ ' num2str(frequencies(cnt), '%0.5f')]);
    
    % wait a moment to see progress (e.g. at display of generator)
    pause(0.4); % in s
end

% read current frequency setting
myFGen.query('freq?');

% finally close interface and delete object again
myFGen.close;
myFGen.delete;

disp('Generator Test Done.');

return % end of file