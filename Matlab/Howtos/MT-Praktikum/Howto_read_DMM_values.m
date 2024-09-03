%% Howto create a HandheldDMM object and read values from DMM
% 2024-09-03
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'HandheldDMM' class and package files are required
%
% This sample script is dealing with the creation of a HandheldDMM object
% and reading values from a connected DMM.
%
%   - for further reading type 'doc HandheldDMM' or 'HandheldDMM.doc'
%   - the DMM is assumed to be connected to your computer and is turned on
%   - OR you can run this script without a DMM by selecting DEMO mode
%   - set the DMM to the wanted settings manually (data logging only)
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

%% optional step to check which serial ports and packages are available

% informations about serial ports
HandheldDMM.listSerialPorts;
% alternatively you can start the device manager (Windows-computer)
%system('devmgmt.msc');

% informations about supported DMMs
HandheldDMM.listSupportedPackages;

% -------------------------------------------------------------------------
%% here we go

% Which DMM is connected? Which serial port has to be used?
type    = 'UT61E'; % either 'UT61E' or 'VC820'
%port    = 'COM7';  % select port where your DMM is connected to
port    = 'demo';  % no DMM connected ==> DEMO mode
%
%type    = 'VC820';
%port    = 'COM5';

% verbose or silent mode?
showMsg = true; % true = enable massages or false = disable messages

% create object (constructor)
myDMM  = HandheldDMM(type, port, showMsg);

% connect to serial port
myDMM.connect;

% how many samples should be acquired? (define a small number, please)
NumValues = 30;

% initialize vectors for the results
timeVector = (0 : NumValues-1) * myDMM.SamplePeriod;
dataVector = zeros(size(timeVector));

% remove all previous data from input buffer
myDMM.flush;

% run loop to acquire data sample by sample
for cnt = 1 : NumValues
    % read (single) measurement value and copy to data vector
    [dataVector(cnt), mode] = myDMM.read;
    
    % emulate pause between acquisition of samples
    if myDMM.DemoMode
        pause(0.3); % in s
    end
end

% plot results
figure(1);
plot(timeVector, dataVector, '-b*');
grid on;

% finally close interface and delete object again
myDMM.disconnect;
myDMM.delete;

disp('DMM Test Done.');

return % end of file