% Howto output analog signals with a daq-interface
%
% This script uses a NI-DAQ device to convert digital data to analog
% voltages.
% Voltage 1:  ao0 (Single Ended)
%
% HTW Dresden, faculty of electrical engineering
% - Measurement Engineering -
% @Robert Stoll, @Matthias Henker
% created: 2020-09-04
% edited:  2024-09-04
% version: file is under git control
%
% -------------------------------------------------------------------------
% This is a simple sample script from the series of howto-files
%
% This script is based on the script (copy and run the listed commands below)
% >> openExample('daq/demo_compactdaq_intro')
% from Help Center "Acquire Data Using NI Devices"
% >> web('https://de.mathworks.com/help/daq/acquire-data-using-ni-devices.html')
%
% ATTENTION: The 'Data Acquisition Toolbox', a connected NI-USB device
%            and its hardware support package is required.
%--------------------------------------------------------------------------

%% Clean Matlab
CleanMatlab = true; % true or false

% optionally clean Matlab
if CleanMatlab       % set to true/false to enable/disable cleaning
    daqreset;        % resets DAQ Toolbox and deletes all daq objects
    clear variables; % clear all variables
    close all;       % close all figures
    clc;             % clear command window
end

%% 1. Define Variables / Some preparations

% create a signal for output generation
sampleRate = 1000; % in Sa/s (or Hz) for NI-USB-6001: maximum is 5e3
numSamples = 5000;

time       = (0 : numSamples-1) / sampleRate;
amplitude  = 5;    % in Volt
% sine wave (samples as row vector)
numPeriods = 10;
% example output values
signalData = amplitude *sin(numPeriods *2*pi* (0:numSamples-1)/numSamples);


%% 2. Discover Available Devices
% 2.1) list all available DAQ devices of National Instruments™
DeviceList = daqlist('ni');

disp('Display all available DAQ-devices:');
disp(DeviceList);
% ! use 'daqreset' if not all devices are listed correctly and try again

% exit when no compatible device is connected to your computer
if (isempty(DeviceList))
    error('No DAQ-Device connected! This demo-script requires a DAQ-device.');
end

% 2.2) display more details of the connected device
devIdx     = 1;         % change when more than one device is connected
deviceInfo = DeviceList.DeviceInfo(devIdx);

disp('Display detailed information about selected DAQ-device:');
disp(deviceInfo);

%% 3. Configure DAQ-Device and Write Data to DAQ-Box
% 3.1) create NI daq interface object
DAQBox = daq('ni');

% 3.2) Add output channel ('ao0' and 'ao1' are available)
ch0    = DAQBox.addoutput(deviceInfo.ID, 'ao0', 'Voltage');

% Show the channel config
disp('Display configuration of selected channels:');
disp(DAQBox.Channels);

% 3.3) Start data output
% configure sample rate
DAQBox.Rate = sampleRate;

% select option (demonstrates different commands and options)
option = 2;  % 1, 2 or 3

% Option 1: write only a single value ==> constant output signal
if option == 1
    voltageOut = 5; % in Volt
    DAQBox.write(voltageOut);
end

% Option 2: upload a periodic signal and repeat it infinitely
if option == 2
    % load waveform to daq interface
    % !!! data vector has to be a column vector !!! => transpose vector
    DAQBox.preload(signalData');
    % start to output data periodically
    DAQBox.start('RepeatOutput');
end

% Option 3: similar to option 2, but update signal in between
if option == 3
    DAQBox.preload(signalData');
    DAQBox.start('RepeatOutput');

    % update signal
    disp('Update output data:');
    for i = 1 : 5
        disp(['... ' num2str(i)]);
        pause(1);
        DAQBox.write(abs(signalData)'); % change preloaded data
        pause(1);
        DAQBox.write(signalData');      % change preloaded data
    end
end

% 3.4) Stop signal generation
%     When signal generation at NI-USB-device is stopped then last output
%     value is hold at output (until a new value is defined).

% It, is recommended to set output at the end to zero to avoid shortcuts
stopGen = true;  % true or false (0 or 1 as shorthand alternative)
if stopGen
    DAQBox.stop;
    DAQBox.write(0);
end

%% 4. Display data

figure(1);
if option == 1
    plot(time, voltageOut*ones(size(time)), '-b', DisplayName= 'ch0: ao0');
else
    plot(time, signalData,                  '-r', DisplayName= 'ch0: ao0');
end
grid on;

title('Output on channel ao0');
xlabel('Time t / s');
ylabel('Voltage  U / V');
legend(Location='best');

%--------------------------------------------------------------------------
%% More Informationen
%This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))

% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')

% Write output scans to hardware channels
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.write.html')
